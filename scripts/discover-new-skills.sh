#!/bin/bash
#
# Dash Skills - 新 skill 發現腳本
#
# 掃描以下來源，比對 update-external.sh 已抓清單，列出可考慮加入的新 skill：
#   - anthropics/skills (官方)
#   - vercel-labs/agent-skills (main 分支 skills/)
#
# 用法:
#   bash scripts/discover-new-skills.sh           # 印到 stdout
#   bash scripts/discover-new-skills.sh --report  # 同時寫 ~/.claude/reports/skill-discovery-YYYY-MM-DD.txt
#
# 加到 weekly cron 範例 (每週一 09:00):
#   0 9 * * 1 bash ~/Documents/github/dash-skills/scripts/discover-new-skills.sh --report
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
UPDATE_SCRIPT="$REPO_DIR/scripts/update-external.sh"
TODAY=$(date +%Y-%m-%d)
REPORT_DIR="$HOME/.claude/reports"
REPORT_FILE="$REPORT_DIR/skill-discovery-$TODAY.txt"


WRITE_REPORT=0
[ "$1" = "--report" ] && WRITE_REPORT=1

# 輸出 helper：同時寫 stdout 和 report file
out() {
    if [ "$WRITE_REPORT" = "1" ]; then
        echo "$@" | tee -a "$REPORT_FILE"
    else
        echo "$@"
    fi
}

[ "$WRITE_REPORT" = "1" ] && mkdir -p "$REPORT_DIR" && : > "$REPORT_FILE"

out "=== Dash Skills 新 skill 發現 ($TODAY) ==="
out ""

# === 1. anthropics/skills 比對 ===
out "--- anthropics/skills (官方) ---"

# 線上目前所有 skills
remote_anthropic=$(curl -s "https://api.github.com/repos/anthropics/skills/contents/skills" \
    | python3 -c "import sys,json; [print(x['name']) for x in json.load(sys.stdin) if x['type']=='dir']" 2>/dev/null)

if [ -z "$remote_anthropic" ]; then
    out "  錯誤：無法取得 anthropics/skills 清單"
else
    # 本地已抓的 anthropic skills (grep _update_anthropic_skill "name" 行)
    local_anthropic=$(grep -oE '_update_anthropic_skill "[^"]+"' "$UPDATE_SCRIPT" | sed 's/_update_anthropic_skill "//;s/"//' | sort -u)

    out "  線上: $(echo "$remote_anthropic" | wc -l | tr -d ' ') 個 / 已抓: $(echo "$local_anthropic" | wc -l | tr -d ' ') 個"
    out ""
    out "  缺漏 (可考慮加入):"
    missing_count=0
    for skill in $remote_anthropic; do
        if ! echo "$local_anthropic" | grep -qx "$skill"; then
            out "    - $skill"
            missing_count=$((missing_count + 1))
        fi
    done
    [ "$missing_count" = "0" ] && out "    (無，全部已涵蓋)"
fi
out ""

# === 2. vercel-labs/agent-skills main 比對 ===
# 只看 main 分支 skills/ 底下的目錄；未合併的工作分支沒經過審查，不列為候選
out "--- vercel-labs/agent-skills (main) ---"

remote_vercel=$(curl -s "https://api.github.com/repos/vercel-labs/agent-skills/contents/skills?ref=main" \
    | python3 -c "import sys,json; [print(x['name']) for x in json.load(sys.stdin) if x['type']=='dir']" 2>/dev/null)

if [ -z "$remote_vercel" ]; then
    out "  錯誤：無法取得 vercel-labs/agent-skills 清單"
else
    # 本地已抓的 vercel skills：helper 第 1 個參數 + 專用函數 sparse-checkout 的 skills/<name>
    local_vercel=$( (grep -oE '_update_vercel_agent_skill "[^"]+"' "$UPDATE_SCRIPT" | sed 's/_update_vercel_agent_skill "//;s/"//'
                     grep -oE 'sparse-checkout set skills/[A-Za-z0-9_-]+' "$UPDATE_SCRIPT" | sed 's|.*skills/||') | sort -u)

    out "  線上: $(echo "$remote_vercel" | wc -l | tr -d ' ') 個 / 已抓: $(echo "$local_vercel" | wc -l | tr -d ' ') 個"
    out ""
    out "  缺漏 (可考慮加入):"
    missing_count=0
    for skill in $remote_vercel; do
        if ! echo "$local_vercel" | grep -qx "$skill"; then
            out "    - $skill"
            missing_count=$((missing_count + 1))
        fi
    done
    [ "$missing_count" = "0" ] && out "    (無，全部已涵蓋)"
fi
out ""

# === 3. summary ===
out "--- summary ---"
out "  下一步：手動 review 上述清單，認為值得加入的 skill"
out "  在 $UPDATE_SCRIPT 加 update_xxx() 函數 + 加進 all_updates 陣列 + show_available 顯示"
[ "$WRITE_REPORT" = "1" ] && out "" && out "  Report 已寫入: $REPORT_FILE"

exit 0
