#!/bin/bash
#
# Dash Skills 每日自動更新
# 由 launchd 執行（scripts/launchd/com.dash.skills-auto-update.plist，每天 06:00），
# .zshrc 在當天還沒跑完時用 launchctl kickstart 補觸發。不要直接在殼層 source：
# 2026-09-26 到 10-03 每天在前景跑到閘門掃描就被中斷，8 天沒有 commit。
#
# 功能：
# 1. 同步外部 skills
# 2. 掃描並自動 redact 機敏資料 (防止 GitHub Push Protection 阻擋)
# 3. 如果有變更，自動 commit 並 push 到 GitHub
#

SKILL_DIR="$HOME/Documents/github/dash-skills"
LAST_UPDATE_FILE="$SKILL_DIR/.last-update"
TODAY=$(date +%Y-%m-%d)

# 檢查今天是否已更新
if [ -f "$LAST_UPDATE_FILE" ] && [ "$(cat "$LAST_UPDATE_FILE")" = "$TODAY" ]; then
    return 0 2>/dev/null || exit 0
fi

# 檢查目錄是否存在
if [ ! -d "$SKILL_DIR" ]; then
    return 0 2>/dev/null || exit 0
fi

# 用鎖防止兩個實例同時跑，.last-update 等整趟跑完才寫（腳本尾端）
# 2026-07-23 事故：同時兩個實例搶 .git/index.lock，git add 撞鎖被誤判成「無實質差異」；
# 更壞的情況是一邊 redact 的 sed 還在改檔、另一邊已 git add，機敏資料被 commit 進去。
# 2026-10-03：原本為了擋第二個實例而在開頭就寫 .last-update，中途被中斷時當天不再重跑，
# 改成鎖之後中斷不會留下「已完成」標記，下次觸發會補跑。
LOCK_DIR="$SKILL_DIR/.auto-update.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    # 鎖裡記的 PID 已不存在就是被砍掉留下的殘留鎖
    # PID 還沒寫進去（另一個實例剛建鎖）也當作在跑
    _lock_pid=$(cat "$LOCK_DIR/pid" 2>/dev/null)
    if [ -z "$_lock_pid" ] || kill -0 "$_lock_pid" 2>/dev/null; then
        return 0 2>/dev/null || exit 0
    fi
    rm -rf "$LOCK_DIR"
    mkdir "$LOCK_DIR" 2>/dev/null || { return 0 2>/dev/null || exit 0; }
fi
echo $$ > "$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR"' EXIT

# 把 external/ 整個退回 HEAD：HEAD 沒有的檔案一併移除
_restore_external() {
    git checkout HEAD -- external > /dev/null 2>&1
    git clean -fdqx -- external > /dev/null 2>&1
}

# 保存原始目錄，結束時還原（sourced 時會影響 shell 工作目錄）
_dash_original_dir="$PWD"

echo "[dash-skills] 每日同步 ($(date '+%H:%M'))"

cd "$SKILL_DIR"

# 暫存工作目錄：同步、釘版、遮蔽、閘門都在 repo 的第二個工作目錄裡做，過了閘門才套用到這裡的 external/。
# ~/.claude/skills 的連結指向這裡，以前直接寫進來時，閘門判定前的幾分鐘未審內容就能被載入
# （2026-11-16 審查確認）。放在專案目錄外：目錄內的 CLAUDE.md 會在讀到旁邊檔案時被載入。
STAGE_DIR="$HOME/Library/Caches/dash-skills-staging"
export DASH_SKILLS_REPORT_DIR="$SKILL_DIR/security-reports"
BASE=$(git rev-parse HEAD)

# 重設成這裡的 HEAD 並清空；不存在就建立。路徑上是別的東西時停止，不刪除。
_prepare_stage() {
    local main_git stage_git
    main_git=$(cd "$(git rev-parse --git-common-dir)" && pwd -P)
    if [ -e "$STAGE_DIR" ]; then
        stage_git=$(cd "$STAGE_DIR" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null) || return 1
        [ "$(cd "$STAGE_DIR" && cd "$stage_git" && pwd -P)" = "$main_git" ] || return 1
        [ "$(cd "$STAGE_DIR" && git rev-parse --show-toplevel)" = "$(cd "$STAGE_DIR" && pwd -P)" ] || return 1
        git -C "$STAGE_DIR" checkout -q --detach --force "$BASE" || return 1
        git -C "$STAGE_DIR" reset -q --hard "$BASE" || return 1
    else
        mkdir -p "$(dirname "$STAGE_DIR")"
        git worktree prune
        git worktree add -q --detach "$STAGE_DIR" "$BASE" > /dev/null 2>&1 || return 1
    fi
    git -C "$STAGE_DIR" clean -ffdqx
}
if ! _prepare_stage; then
    echo "[dash-skills] 暫存工作目錄 $STAGE_DIR 無法使用（不是這個 repo 的工作目錄或建立失敗），停止；external/ 沒有變動"
    exit 1
fi
cd "$STAGE_DIR"

# [1/5] 同步外部 skills
echo "[dash-skills] [1/5] 同步外部 skills..."
# 同步放在自己的程序群組，結束或逾時後整個群組一起停掉：
# 同步腳本逾時只停掉它直接開的子程序，底下還在跑的 git、cp 會在閘門檢查時繼續寫檔
DASH_SKILLS_NO_PUSH=1 perl -e 'setpgrp(0, 0); alarm(120); exec @ARGV' ./scripts/update-external.sh > /dev/null 2>&1 &
sync_pid=$!
wait "$sync_pid"
sync_exit=$?
kill -KILL -- "-$sync_pid" 2>/dev/null
if [ "$sync_exit" -ne 0 ]; then
    echo "[dash-skills] [1/5] 同步逾時或失敗，跳過"
fi
# 個別 skill 的失敗不會讓整支同步失敗，只記在 .last-sync-failures；這裡把它印出來，
# 每日巡檢讀的是主目錄那一份，從暫存目錄複製回去。
[ -f .last-sync-failures ] && cp .last-sync-failures "$SKILL_DIR/.last-sync-failures"
if [ -s .last-sync-failures ]; then
    echo "[dash-skills]   警告：有 skill 同步失敗（$(head -1 .last-sync-failures)）"
    tail -n +2 .last-sync-failures | sed 's/^/[dash-skills]     - /'
fi

# 釘死已知風險引用：external/ 的 skill 會教 agent 寫 trivy-action@master、aquasec/trivy:latest，
# 2026-03 Trivy 發行鏈遭入侵（GHSA-69fq-xp46-6x23）時這類可變引用正是被改指向的入口。
# 上游每天覆蓋，所以每次同步後、symlink 載入前重跑；冪等，詳見 scripts/pin-refs.py
python3 ./scripts/pin-refs.py external 2>&1 | sed 's/^/[dash-skills]   /'




# 掃描並自動 redact 機敏資料
# GitHub Push Protection 會擋已知格式的 key，即使是文件中的範例
# 用 grep -rlZ + while read -d '' 處理含空白的檔名
redact_secrets() {
    local changed=0
    local scan_dirs="external/"
    local -a includes=(--include='*.md' --include='*.txt' --include='*.yml' --include='*.yaml'
        --include='*.json' --include='*.js' --include='*.ts' --include='*.py'
        --include='*.toml' --include='*.cfg' --include='*.ini' --include='*.env*'
        --include='*.sh' --include='*.html' --include='*.mdc')

    local _changed_flag="$scan_dirs/.redact_changed"
    rm -f "$_changed_flag"

    # 輔助函數：掃描 + redact（grep -rl + while read，IFS= 保留空白檔名）
    _redact() {
        local pattern="$1" replacement="$2" label="$3"
        grep -rlE "$pattern" "${includes[@]}" "$scan_dirs" 2>/dev/null | \
        while IFS= read -r f; do
            sed -i '' -E "s/$pattern/$replacement/g" "$f"
            echo "[dash-skills]   redact $label: $f"
            touch "$_changed_flag"
        done
    }

    # Stripe keys
    _redact 'sk_(test|live)_[a-zA-Z0-9]{10,}' 'sk_\1_REDACTED' 'Stripe key'
    _redact 'rk_(test|live)_[a-zA-Z0-9]{10,}' 'rk_\1_REDACTED' 'Stripe restricted key'

    # GitHub tokens: ghp_ / gho_ / ghu_ / ghs_ / ghr_
    _redact 'gh[pousr]_[a-zA-Z0-9]{36,}' 'gh_REDACTED' 'GitHub token'

    # AWS Access Key: AKIA + 16 uppercase
    _redact 'AKIA[0-9A-Z]{16}' 'AKIA_REDACTED_KEY' 'AWS key'

    # Anthropic API key: sk-ant-xxx
    _redact 'sk-ant-[a-zA-Z0-9_-]{20,}' 'sk-ant-REDACTED' 'Anthropic key'

    # OpenAI: sk-proj-xxx
    _redact 'sk-proj-[a-zA-Z0-9_-]{20,}' 'sk-proj-REDACTED' 'OpenAI key'

    # Google Cloud / Firebase: AIza + 35 chars
    _redact 'AIza[a-zA-Z0-9_-]{35}' 'AIza_REDACTED' 'Google API key'

    # Slack tokens: xoxb- / xoxp- / xoxs- / xoxa-
    _redact 'xox[bpsa]-[a-zA-Z0-9-]{20,}' 'xox_REDACTED' 'Slack token'

    # Private keys（只警告，不自動 redact）
    grep -rlE '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----' "${includes[@]}" "$scan_dirs" 2>/dev/null | \
    while IFS= read -r f; do
        echo "[dash-skills]   警告: 發現 private key，需手動處理: $f"
    done

    if [ -f "$_changed_flag" ]; then
        rm -f "$_changed_flag"
        return 1
    fi
    return 0
}

# [2/5] 清理 + 機敏資料遮蔽：排在閘門之前（2026-09-25）。
# 上游範例金鑰每天同步回來都是未遮蔽的，遮蔽前跟 HEAD 比一定有差異；
# 放在閘門之後的話，資安教材類集合每天都被當成「有變更」整包重掃，每個最多 240 秒。
echo "[dash-skills] [2/5] 清理 + 機敏資料遮蔽..."

# 清理 iCloud sync 衝突副本
icloud_dupes=$(find external/ -name "* [0-9]*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$icloud_dupes" -gt 0 ]; then
    echo "[dash-skills]   清理 $icloud_dupes 個 iCloud 衝突副本"
    find external/ -name "* [0-9]*" -type f -delete 2>/dev/null
    find external/ -depth -name "* [0-9]*" -type d -exec rm -rf {} \; 2>/dev/null
fi

if ! redact_secrets; then
    echo "[dash-skills]   已 redact 機敏資料"
fi

# [3/5] 裝載前閘門：趕在 symlink 重建（載入點）與 commit 之前。
# 有變更的 external 目錄要過兩關：新增內容的差異規則（隱形字元、解碼執行、要 agent 瞞著使用者等），
# 與 SkillSpector 掃描（baseline 外的新告警）。任一不過、掃描失敗或逾時，該目錄退回上一個已提交版本，
# 被擋下的內容存到 security-reports/quarantine/ 供人工判讀。詳見 scripts/gate-external.py
echo "[dash-skills] [3/5] 外部 skills 裝載前閘門..."
python3 -u ./scripts/gate-external.py 2>&1 | sed 's/^/[dash-skills]   /'
gate_exit=${PIPESTATUS[0]}
# 閘門沒有正常跑完（崩潰、檢查出錯）就不能信任暫存目錄的結果：不套用、不提交。
# 2026-11-16 審查確認：上游放一個無法解碼的位元組就能讓閘門在退回前中止，
# 以前這裡只看得到 sed 的結束碼，沒過閘門的內容照樣被提交推送。
if [ "$gate_exit" -ne 0 ]; then
    echo "[dash-skills] 閘門沒有正常完成（結束碼 $gate_exit），不套用這次同步，停止提交與推送；external/ 沒有變動"
    exit 1
fi

# 閘門檢查完的暫存 external/ 記成 git 物件，之後只套用這個物件，暫存目錄後來再有變動也不影響
git add -- external
staged_tree=$(git write-tree)
cd "$SKILL_DIR"

# 閘門比對的基準是開始時的 HEAD；執行期間這裡有新 commit，比對結果就不能用
if [ "$(git rev-parse HEAD)" != "$BASE" ]; then
    echo "[dash-skills] 執行期間 HEAD 改變，不套用這次同步，下次重跑；external/ 沒有變動"
    exit 1
fi

# 從 git 物件套用：刪除、權限與已放行的連結都照物件內容，不跟隨任何連結
if ! git restore --source="$staged_tree" --staged --worktree -- external || ! git clean -fdqx -- external; then
    echo "[dash-skills] 套用暫存目錄的結果失敗，external/ 退回上一個已提交版本，停止提交與推送"
    _restore_external
    exit 1
fi

# 重建 ~/.claude/skills symlink，新增的 external skill 才會被 Claude Code 載入
new_links=$(./scripts/link.sh 2>&1 | grep "建立連結" || true)
if [ -n "$new_links" ]; then
    echo "$new_links" | sed 's/^/[dash-skills]   /'
fi

# 保險：external/ 的符號連結只准指到同一個集合內的檔案，而且要在放行清單裡。
# 閘門會隔離，這裡擋閘門沒跑到的情況；檢查本身跑失敗也停。
# 連結若被提交，下一次用會跟隨連結的工具處理時可能把本機檔案內容帶進公開 repo。
if ! stray_links=$(python3 ./scripts/gate-external.py --stray-links 2>&1); then
    echo "[dash-skills] external/ 有未放行的符號連結，停止提交與推送："
    echo "$stray_links" | sed 's/^/[dash-skills]   /'
    _restore_external
    exit 1
fi

# 檢查是否有變更
if [ -n "$(git status --porcelain)" ]; then
    # [4/5] 提交 + 推送
    # 指名 stage（2026-07-25）：本 repo 為 public，git add -A 與 redact_secrets
    # 之間存在 race condition，腳本開頭註解已載明風險。git add <path> 涵蓋新增/修改/刪除。
    git add external openspec pi-agent scripts skills *.md 2>/dev/null || true
    if git diff --cached --quiet; then
        echo "[dash-skills] [4/5] 無實質差異，跳過推送"
    else
        echo "[dash-skills] [4/5] 提交並推送..."
        if ! git commit -m "chore: daily external skills sync ($TODAY)" > /dev/null 2>&1; then
            echo "[dash-skills]   commit 失敗，跳過推送"
            commit_ok=0
        else
            commit_ok=1
        fi

        push_output=""
        push_exit=1
        if [ "$commit_ok" -eq 1 ]; then
            push_output=$(git push 2>&1)
            push_exit=$?

            # 遠端有本機沒有的 commit（雲端 routine 合 PR、另一台機器）時先 rebase 再推。
            # 2026-09-07 到 09-16：security-radar 的 14 個 PR 合進遠端，這裡沒 rebase 補救，
            # non-fast-forward 每天靜默失敗，兩個 sync commit 卡了 9 天沒上去。
            if [ $push_exit -ne 0 ] && echo "$push_output" | grep -qE "fetch first|non-fast-forward|tip of your current branch is behind"; then
                echo "[dash-skills]   遠端有新 commit，先 rebase 再推"
                if git pull --rebase origin main > /dev/null 2>&1; then
                    push_output=$(git push 2>&1)
                    push_exit=$?
                else
                    git rebase --abort > /dev/null 2>&1
                    echo "[dash-skills]   rebase 有衝突，已 abort，請手動處理"
                fi
            fi
        fi

        if [ $push_exit -eq 0 ]; then
            echo "[dash-skills]   已推送到 GitHub"

            # Push 後自動檢查 GitGuardian（3 秒後查，等 webhook 處理）
            if [ -n "$GITGUARDIAN_API_KEY" ]; then
                sleep 3
                gg_count=$(curl -s "https://api.gitguardian.com/v1/incidents/secrets?status=TRIGGERED&per_page=1" \
                  -H "Authorization: Token $GITGUARDIAN_API_KEY" 2>/dev/null | \
                  python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)
                if [ -n "$gg_count" ] && [ "$gg_count" -gt 0 ] 2>/dev/null; then
                    echo "[dash-skills]   GitGuardian: $gg_count 個新 incident，需處理"
                fi
            fi
        elif echo "$push_output" | grep -q "push declined\|remote rejected"; then
            echo "[dash-skills]   推送被 GitHub 擋住，可能仍有機敏資料"
            echo "[dash-skills]   請手動執行: cd $SKILL_DIR && git push"
        elif [ "$commit_ok" -eq 1 ]; then
            echo "[dash-skills]   推送失敗，請手動執行 git push"
            echo "$push_output" | tail -5 | sed 's/^/[dash-skills]   /'
        fi
    fi
else
    echo "[dash-skills] [4/5] 無變更，跳過推送"
fi

# [5/5] claude-config 備份
CLAUDE_CONFIG_DIR="$HOME/Documents/github/claude-config"
if [ -d "$CLAUDE_CONFIG_DIR" ] && [ -x "$CLAUDE_CONFIG_DIR/sync.sh" ]; then
    echo "[dash-skills] [5/5] claude-config 備份..."
    "$CLAUDE_CONFIG_DIR/sync.sh" > /dev/null 2>&1

    cd "$CLAUDE_CONFIG_DIR"
    # 指名 stage（2026-07-25），清單與 claude-config/sync.sh 內一致
    git add CLAUDE.md settings.json sync.sh zshrc mcp-servers.json infra.md sora-prompt-skeleton.md hooks-index.md frontend-pitfalls.md backend-pitfalls.md commit-rules.md writing-style.md compliance.md design-system.md observability.md browser-tools.md profile-sync.md global-rule-incidents.md hooks commands rules skills scripts launchagents projects 2>/dev/null || true
    if git diff --cached --quiet; then
        echo "[dash-skills]   無變更"
    else
        if git commit -m "sync: $TODAY" > /dev/null 2>&1; then
            # 遠端有新 commit 時（另一台機器/網頁編輯）先 rebase 再推，避免 non-fast-forward 每日靜默失敗
            push_ok=0
            if push_output=$(git push 2>&1); then
                push_ok=1
            else
                git pull --rebase origin main > /dev/null 2>&1
                if push_output=$(git push 2>&1); then
                    push_ok=1
                fi
            fi
            if [ "$push_ok" -eq 1 ]; then
                echo "[dash-skills]   已備份到 GitHub"
            else
                echo "[dash-skills]   推送失敗，請手動 git push"
                echo "$push_output" | tail -5 | sed 's/^/[dash-skills]   /'
            fi
        else
            echo "[dash-skills]   commit 失敗"
        fi
    fi
else
    echo "[dash-skills] [5/5] claude-config 目錄不存在，跳過"
fi

echo "$TODAY" > "$LAST_UPDATE_FILE"
echo "[dash-skills] 完成"

# 還原工作目錄
cd "$_dash_original_dir" 2>/dev/null
unset _dash_original_dir
