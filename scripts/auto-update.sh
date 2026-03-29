#!/bin/bash
#
# Dash Skills 每日自動更新
# 加到 .zshrc 讓每天第一次開 terminal 時自動同步
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

# 保存原始目錄，結束時還原（sourced 時會影響 shell 工作目錄）
_dash_original_dir="$PWD"

echo "[dash-skills] 每日同步 ($(date '+%H:%M'))"

cd "$SKILL_DIR"

# [1/4] 同步外部 skills
echo "[dash-skills] [1/4] 同步 25 個外部 skills..."
if ! DASH_SKILLS_NO_PUSH=1 perl -e 'alarm(120); exec @ARGV' ./scripts/update-external.sh > /dev/null 2>&1; then
    echo "[dash-skills] [1/4] 同步逾時或失敗，跳過"
fi

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

# [2/4] 清理 + 安全掃描
echo "[dash-skills] [2/4] 清理 + 機敏資料掃描..."

# 清理 iCloud sync 衝突副本
icloud_dupes=$(find external/ -name "* [0-9]*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$icloud_dupes" -gt 0 ]; then
    echo "[dash-skills]   清理 $icloud_dupes 個 iCloud 衝突副本"
    find external/ -name "* [0-9]*" -type f -delete 2>/dev/null
    find external/ -depth -name "* [0-9]*" -type d -exec rm -rf {} \; 2>/dev/null
fi

# 檢查是否有變更
if [ -n "$(git status --porcelain)" ]; then
    # 自動 redact
    if redact_secrets; then
        : # 沒有 redact
    else
        echo "[dash-skills]   已 redact 機敏資料"
    fi

    # [3/4] 提交 + 推送
    echo "[dash-skills] [3/4] 提交並推送..."
    git add -A
    git commit -m "chore: 每日同步外部 skills ($TODAY)" > /dev/null 2>&1

    push_output=$(git push 2>&1)
    push_exit=$?
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
    else
        echo "[dash-skills]   推送失敗，請手動執行 git push"
    fi
else
    echo "[dash-skills] [3/4] 無變更，跳過推送"
fi

# 記錄更新日期
echo "$TODAY" > "$LAST_UPDATE_FILE"

# [4/4] claude-config 備份
CLAUDE_CONFIG_DIR="$HOME/Documents/github/claude-config"
if [ -d "$CLAUDE_CONFIG_DIR" ] && [ -x "$CLAUDE_CONFIG_DIR/sync.sh" ]; then
    echo "[dash-skills] [4/4] claude-config 備份..."
    "$CLAUDE_CONFIG_DIR/sync.sh" > /dev/null 2>&1

    cd "$CLAUDE_CONFIG_DIR"
    git add -A
    if git diff --cached --quiet; then
        echo "[dash-skills]   無變更"
    else
        if git commit -m "sync: $TODAY" > /dev/null 2>&1; then
            if git push > /dev/null 2>&1; then
                echo "[dash-skills]   已備份到 GitHub"
            else
                echo "[dash-skills]   推送失敗，請手動 git push"
            fi
        else
            echo "[dash-skills]   commit 失敗"
        fi
    fi
else
    echo "[dash-skills] [4/4] claude-config 目錄不存在，跳過"
fi

echo "[dash-skills] 完成"

# 還原工作目錄
cd "$_dash_original_dir" 2>/dev/null
unset _dash_original_dir
