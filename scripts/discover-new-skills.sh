#!/bin/bash
#
# Dash Skills - 新 skill 發現腳本
#
# 掃描以下來源，比對 update-external.sh 已抓清單，列出可考慮加入的新 skill：
#   - anthropics/skills (官方)
#   - vercel-labs/agent-skills (branches)
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

# Vercel branches 雜訊過濾規則 (regex)
VERCEL_NOISE_REGEX='^(main|shu/|v0/|copilot/|elsigh-|bhrigu/|f/|trim-skills-folder|install|add-async-react-skill|background-skill|more-react|restructure-react-best-practices|slack-agent-tj)'

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

# === 2. vercel-labs/agent-skills branches 比對 ===
out "--- vercel-labs/agent-skills (branches) ---"

remote_vercel_branches=$(curl -s "https://api.github.com/repos/vercel-labs/agent-skills/branches?per_page=100" \
    | python3 -c "import sys,json; [print(x['name']) for x in json.load(sys.stdin)]" 2>/dev/null)

if [ -z "$remote_vercel_branches" ]; then
    out "  錯誤：無法取得 vercel-labs/agent-skills branches"
else
    # 本地已抓的 vercel branches
    # 從 update-external.sh 抽出 branch="..." 行 (vercel-labs/agent-skills 的)
    local_vercel=$(grep -B1 -A2 'repo="vercel-labs/agent-skills"' "$UPDATE_SCRIPT" \
        | grep 'local branch=' \
        | sed 's/.*branch="//;s/"//' | sort -u)
    # _update_vercel_agent_skill helper 呼叫的 branch (第 2 個參數)
    local_vercel_helper=$(grep -oE '_update_vercel_agent_skill "[^"]+" "[^"]+"' "$UPDATE_SCRIPT" \
        | awk -F'"' '{print $4}' | sort -u)
    local_vercel=$(echo -e "$local_vercel\n$local_vercel_helper" | sort -u | grep -v '^$')

    total_remote=$(echo "$remote_vercel_branches" | wc -l | tr -d ' ')
    out "  線上 branches 總數: $total_remote"
    out "  已抓 branches: $(echo "$local_vercel" | wc -l | tr -d ' ')"
    out ""
    out "  缺漏 (已過濾雜訊 dev/v0/copilot branches):"
    missing_count=0
    while IFS= read -r br; do
        # 跳過雜訊
        echo "$br" | grep -qE "$VERCEL_NOISE_REGEX" && continue
        # 已抓
        echo "$local_vercel" | grep -qx "$br" && continue
        out "    - $br"
        missing_count=$((missing_count + 1))
    done <<< "$remote_vercel_branches"
    [ "$missing_count" = "0" ] && out "    (無，全部值得加的都已涵蓋)"
fi
out ""

# === 3. summary ===
out "--- summary ---"
out "  下一步：手動 review 上述清單，認為值得加入的 skill"
out "  在 $UPDATE_SCRIPT 加 update_xxx() 函數 + 加進 all_updates 陣列 + show_available 顯示"
[ "$WRITE_REPORT" = "1" ] && out "" && out "  Report 已寫入: $REPORT_FILE"

exit 0
