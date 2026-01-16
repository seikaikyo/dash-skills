#!/bin/bash
#
# Dash Skills 每日自動更新
# 加到 .zshrc 讓每天第一次開 terminal 時自動同步
#

SKILL_DIR="$HOME/Documents/github/dash-skills"
LAST_UPDATE_FILE="$SKILL_DIR/.last-update"
TODAY=$(date +%Y-%m-%d)

# 檢查今天是否已更新
if [ -f "$LAST_UPDATE_FILE" ] && [ "$(cat "$LAST_UPDATE_FILE")" = "$TODAY" ]; then
    exit 0
fi

# 檢查目錄是否存在
if [ ! -d "$SKILL_DIR" ]; then
    exit 0
fi

echo "[dash-skills] 每日同步外部 skills..."

cd "$SKILL_DIR"

# 同步外部 skills (靜音模式，只顯示錯誤)
./scripts/update-external.sh > /dev/null 2>&1

# 記錄更新日期
echo "$TODAY" > "$LAST_UPDATE_FILE"

echo "[dash-skills] 同步完成"
