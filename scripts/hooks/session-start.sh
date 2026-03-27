#!/bin/bash
# SessionStart Hook - 載入先前工作階段上下文
# 來源: everything-claude-code (MIT License)
#
# 安裝方式: 複製到 ~/.claude/hooks/session-start.sh
# chmod +x ~/.claude/hooks/session-start.sh

SESSIONS_DIR="${HOME}/.claude/sessions"
LEARNED_DIR="${HOME}/.claude/skills/learned"

# 檢查最近 7 天的 session 檔案
recent_sessions=$(find "$SESSIONS_DIR" -name "*.tmp" -mtime -7 2>/dev/null | wc -l | tr -d ' ')

if [ "$recent_sessions" -gt 0 ]; then
  latest=$(ls -t "$SESSIONS_DIR"/*.tmp 2>/dev/null | head -1)
  echo "[SessionStart] 發現 $recent_sessions 個近期工作階段" >&2
  echo "[SessionStart] 最新: $latest" >&2
fi

# 檢查已學習的 skills
learned_count=$(find "$LEARNED_DIR" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

if [ "$learned_count" -gt 0 ]; then
  echo "[SessionStart] $learned_count 個已學習 skill 可用於 $LEARNED_DIR" >&2
fi

# Sentry 錯誤檢查
SENTRY_CHECK="${HOME}/.claude/hooks/sentry-check.sh"
if [ -x "$SENTRY_CHECK" ]; then
  "$SENTRY_CHECK"
fi

# 架構文件檢查
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$PROJECT_ROOT" ]; then
  if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    echo "[SessionStart] 此專案缺少 CLAUDE.md，建議先建立架構文件" >&2
  else
    claude_ts=$(git -C "$PROJECT_ROOT" log -1 --format=%ct -- CLAUDE.md 2>/dev/null)
    if [ -n "$claude_ts" ]; then
      claude_days=$(( ($(date +%s) - claude_ts) / 86400 ))
    if [ "$claude_days" -gt 30 ]; then
        echo "[SessionStart] CLAUDE.md 已 ${claude_days} 天未更新，請確認是否需要同步" >&2
      fi
    fi
  fi
fi
