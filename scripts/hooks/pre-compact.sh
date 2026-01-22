#!/bin/bash
# PreCompact Hook - 壓縮前保存狀態
# 來源: everything-claude-code (MIT License)
#
# 安裝方式: 複製到 ~/.claude/hooks/pre-compact.sh
# chmod +x ~/.claude/hooks/pre-compact.sh

SESSIONS_DIR="${HOME}/.claude/sessions"
COMPACTION_LOG="${SESSIONS_DIR}/compaction-log.txt"

mkdir -p "$SESSIONS_DIR"

# 記錄壓縮事件及時間戳
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Context 壓縮觸發" >> "$COMPACTION_LOG"

# 如果有活動的 session 檔案，標記壓縮發生
ACTIVE_SESSION=$(ls -t "$SESSIONS_DIR"/*.tmp 2>/dev/null | head -1)
if [ -n "$ACTIVE_SESSION" ]; then
  echo "" >> "$ACTIVE_SESSION"
  echo "---" >> "$ACTIVE_SESSION"
  echo "**[壓縮於 $(date '+%H:%M')]** - Context 已摘要化" >> "$ACTIVE_SESSION"
fi

echo "[PreCompact] 壓縮前狀態已保存" >&2
