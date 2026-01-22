#!/bin/bash
# Stop Hook (Session End) - 工作階段結束時保存狀態
# 來源: everything-claude-code (MIT License)
#
# 安裝方式: 複製到 ~/.claude/hooks/session-end.sh
# chmod +x ~/.claude/hooks/session-end.sh

SESSIONS_DIR="${HOME}/.claude/sessions"
TODAY=$(date '+%Y-%m-%d')
SESSION_FILE="${SESSIONS_DIR}/${TODAY}-session.tmp"

mkdir -p "$SESSIONS_DIR"

# 如果今天已有 session 檔案，更新結束時間
if [ -f "$SESSION_FILE" ]; then
  # 更新 Last Updated 時間戳
  sed -i '' "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date '+%H:%M')/" "$SESSION_FILE" 2>/dev/null || \
  sed -i "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date '+%H:%M')/" "$SESSION_FILE" 2>/dev/null
  echo "[SessionEnd] 已更新工作階段檔案: $SESSION_FILE" >&2
else
  # 建立新的 session 檔案
  cat > "$SESSION_FILE" << EOF
# 工作階段: $(date '+%Y-%m-%d')
**日期:** $TODAY
**開始時間:** $(date '+%H:%M')
**最後更新:** $(date '+%H:%M')

---

## 目前狀態

[工作階段上下文]

### 已完成
- [ ]

### 進行中
- [ ]

### 下次工作階段備註
-

### 需載入的上下文
\`\`\`
[相關檔案]
\`\`\`
EOF
  echo "[SessionEnd] 已建立工作階段檔案: $SESSION_FILE" >&2
fi
