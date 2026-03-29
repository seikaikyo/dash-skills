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

echo "[dash-skills] 每日同步外部 skills..."

cd "$SKILL_DIR"

# 同步外部 skills (靜音模式，120 秒 timeout 避免卡住)
# DASH_SKILLS_NO_PUSH: 讓 update-external.sh 跳過 commit+push，由本腳本統一 redact 後再推
if ! DASH_SKILLS_NO_PUSH=1 perl -e 'alarm(120); exec @ARGV' ./scripts/update-external.sh > /dev/null 2>&1; then
    echo "[dash-skills] 同步逾時或失敗，跳過"
fi

# 掃描並自動 redact 機敏資料
# GitHub Push Protection 會擋已知格式的 key，即使是文件中的範例
# 用 grep -rl 批次掃描，只對命中的檔案跑 sed（5000+ 檔 x 6 pattern → 6 次 grep）
redact_secrets() {
    local changed=0
    local scan_dirs="external/"
    local include="--include=*.md --include=*.txt --include=*.yml --include=*.yaml \
        --include=*.json --include=*.js --include=*.ts --include=*.py \
        --include=*.toml --include=*.cfg --include=*.ini --include=*.env* \
        --include=*.sh --include=*.html --include=*.mdc"

    # Stripe keys: sk_test_xxx / sk_live_xxx / rk_test_xxx / rk_live_xxx
    for f in $(grep -rlE 'sk_(test|live)_[a-zA-Z0-9]{10,}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/sk_(test|live)_[a-zA-Z0-9]{10,}/sk_\1_REDACTED/g' "$f"
        echo "[dash-skills] redact Stripe key: $f"
        changed=1
    done
    for f in $(grep -rlE 'rk_(test|live)_[a-zA-Z0-9]{10,}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/rk_(test|live)_[a-zA-Z0-9]{10,}/rk_\1_REDACTED/g' "$f"
        echo "[dash-skills] redact Stripe restricted key: $f"
        changed=1
    done

    # GitHub tokens: ghp_ / gho_ / ghu_ / ghs_ / ghr_
    for f in $(grep -rlE 'gh[pousr]_[a-zA-Z0-9]{36,}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/gh([pousr])_[a-zA-Z0-9]{36,}/gh\1_REDACTED/g' "$f"
        echo "[dash-skills] redact GitHub token: $f"
        changed=1
    done

    # AWS Access Key: AKIA + 16 uppercase
    for f in $(grep -rlE 'AKIA[0-9A-Z]{16}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/AKIA[0-9A-Z]{16}/AKIA_REDACTED_KEY/g' "$f"
        echo "[dash-skills] redact AWS key: $f"
        changed=1
    done

    # OpenAI: sk-proj- / sk- (48+ chars)
    for f in $(grep -rlE 'sk-proj-[a-zA-Z0-9_-]{20,}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/sk-proj-[a-zA-Z0-9_-]{20,}/sk-proj-REDACTED/g' "$f"
        echo "[dash-skills] redact OpenAI key: $f"
        changed=1
    done

    # Slack tokens: xoxb- / xoxp- / xoxs- / xoxa-
    for f in $(grep -rlE 'xox[bpsa]-[a-zA-Z0-9-]{20,}' $include "$scan_dirs" 2>/dev/null); do
        sed -i '' -E 's/xox([bpsa])-[a-zA-Z0-9-]{20,}/xox\1-REDACTED/g' "$f"
        echo "[dash-skills] redact Slack token: $f"
        changed=1
    done

    # Private keys
    for f in $(grep -rlE '-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----' $include "$scan_dirs" 2>/dev/null); do
        echo "[dash-skills] 警告: 發現 private key，需手動處理: $f"
    done

    return $changed
}

# 清理 iCloud sync 衝突副本 (e.g. "SKILL 2.md", "README 3.md")
icloud_dupes=$(find external/ -name "* [0-9]*" 2>/dev/null | wc -l | tr -d ' ')
if [ "$icloud_dupes" -gt 0 ]; then
    echo "[dash-skills] 清理 $icloud_dupes 個 iCloud 衝突副本..."
    find external/ -name "* [0-9]*" -type f -delete 2>/dev/null
    find external/ -depth -name "* [0-9]*" -type d -exec rm -rf {} \; 2>/dev/null
fi

# 檢查是否有變更
if [ -n "$(git status --porcelain)" ]; then
    echo "[dash-skills] 偵測到變更，掃描機敏資料..."

    # 自動 redact
    if redact_secrets; then
        : # 沒有 redact
    else
        echo "[dash-skills] 已自動 redact 機敏資料"
    fi

    # 提交變更
    git add -A
    git commit -m "chore: 每日同步外部 skills ($TODAY)" > /dev/null 2>&1

    # 推送到 GitHub
    push_output=$(git push 2>&1)
    push_exit=$?
    if [ $push_exit -eq 0 ]; then
        echo "[dash-skills] 已推送到 GitHub"
    elif echo "$push_output" | grep -q "push declined\|remote rejected"; then
        echo "[dash-skills] 推送被 GitHub 擋住，可能仍有機敏資料"
        echo "[dash-skills] 請手動執行: cd $SKILL_DIR && git push"
    else
        echo "[dash-skills] 推送失敗，請手動執行 git push"
    fi
else
    echo "[dash-skills] 無變更"
fi

# 記錄更新日期
echo "$TODAY" > "$LAST_UPDATE_FILE"

echo "[dash-skills] 同步完成"

# === claude-config 備份 ===
CLAUDE_CONFIG_DIR="$HOME/Documents/github/claude-config"
if [ -d "$CLAUDE_CONFIG_DIR" ] && [ -x "$CLAUDE_CONFIG_DIR/sync.sh" ]; then
    echo "[claude-config] 同步全域設定..."
    "$CLAUDE_CONFIG_DIR/sync.sh" > /dev/null 2>&1

    cd "$CLAUDE_CONFIG_DIR"
    git add -A
    if git diff --cached --quiet; then
        echo "[claude-config] 無變更"
    else
        if git commit -m "sync: $TODAY" > /dev/null 2>&1; then
            if git push > /dev/null 2>&1; then
                echo "[claude-config] 已備份到 GitHub"
            else
                echo "[claude-config] 推送失敗，請手動 git push"
            fi
        else
            echo "[claude-config] commit 失敗"
        fi
    fi
fi

# 還原工作目錄
cd "$_dash_original_dir" 2>/dev/null
unset _dash_original_dir
