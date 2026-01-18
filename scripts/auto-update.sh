#!/bin/bash
#
# Dash Skills 每日自動更新
# 加到 .zshrc 讓每天第一次開 terminal 時自動同步
#
# 功能：
# 1. 同步外部 skills
# 2. 如果有變更，自動 commit 並 push 到 GitHub
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

echo "[dash-skills] 每日同步外部 skills..."

cd "$SKILL_DIR"

# 同步外部 skills (靜音模式，只顯示錯誤)
./scripts/update-external.sh > /dev/null 2>&1

# 檢查是否有變更
if [ -n "$(git status --porcelain)" ]; then
    echo "[dash-skills] 偵測到變更，自動提交..."

    # 提交變更
    git add -A
    git commit -m "chore: 每日同步外部 skills ($TODAY)" > /dev/null 2>&1

    # 推送到 GitHub
    if git push > /dev/null 2>&1; then
        echo "[dash-skills] 已推送到 GitHub"
    else
        echo "[dash-skills] 推送失敗，請手動執行 git push"
    fi
else
    echo "[dash-skills] 無變更"
fi

# 記錄更新日期
echo "$TODAY" > "$LAST_UPDATE_FILE"

echo "[dash-skills] 同步完成"
