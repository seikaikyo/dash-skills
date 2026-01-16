#!/bin/bash
#
# Dash Skills - 外部 Skill 同步腳本
# 從官方來源更新 external/ 目錄下的 skills
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXTERNAL_DIR="$REPO_DIR/external"

echo "=== Dash Skills - 外部 Skill 同步 ==="
echo ""

# 函數：更新 react-best-practices
update_react_best_practices() {
    local skill_dir="$EXTERNAL_DIR/react-best-practices"
    local temp_dir=$(mktemp -d)
    local branch="react-best-practices"
    local repo="vercel-labs/agent-skills"

    echo "更新: react-best-practices"
    echo "  來源: https://github.com/$repo/tree/$branch"

    # Clone sparse checkout
    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null

    cd repo
    git sparse-checkout set skills/react-best-practices 2>/dev/null

    # 複製更新的檔案
    if [ -d "skills/react-best-practices" ]; then
        rm -rf "$skill_dir"
        cp -r skills/react-best-practices "$skill_dir"

        # 更新 metadata
        local today=$(date +%Y-%m-%d)
        if [ -f "$skill_dir/SKILL.md" ]; then
            sed -i '' "s/^updated:.*/updated: $today/" "$skill_dir/SKILL.md" 2>/dev/null || true
        fi

        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗 - 找不到來源檔案"
    fi

    # 清理
    rm -rf "$temp_dir"
}

# 函數：更新 agent-browser
update_agent_browser() {
    local skill_dir="$EXTERNAL_DIR/agent-browser"
    local temp_dir=$(mktemp -d)
    local branch="main"
    local repo="vercel-labs/agent-browser"

    echo "更新: agent-browser"
    echo "  來源: https://github.com/$repo"

    # Clone sparse checkout
    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null

    cd repo
    git sparse-checkout set skills/agent-browser 2>/dev/null

    # 複製更新的檔案
    if [ -d "skills/agent-browser" ]; then
        # 保留本地的 EXTENSIONS.md（如果有自訂內容）
        local has_extensions=false
        if [ -f "$skill_dir/EXTENSIONS.md" ]; then
            cp "$skill_dir/EXTENSIONS.md" "$temp_dir/EXTENSIONS.md.bak"
            has_extensions=true
        fi

        rm -rf "$skill_dir"
        cp -r skills/agent-browser "$skill_dir"

        # 還原 EXTENSIONS.md
        if [ "$has_extensions" = true ]; then
            cp "$temp_dir/EXTENSIONS.md.bak" "$skill_dir/EXTENSIONS.md"
        fi

        # 更新 metadata
        local today=$(date +%Y-%m-%d)
        if [ -f "$skill_dir/SKILL.md" ]; then
            sed -i '' "s/^updated:.*/updated: $today/" "$skill_dir/SKILL.md" 2>/dev/null || true
        fi

        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗 - 找不到來源檔案"
    fi

    # 清理
    rm -rf "$temp_dir"
}

# 主程式
echo "檢查外部 Skills..."
echo ""

# 根據參數決定更新哪些
if [ $# -eq 0 ]; then
    # 沒有參數，更新全部
    update_react_best_practices
    echo ""
    update_agent_browser
else
    # 有參數，更新指定的
    for skill in "$@"; do
        case "$skill" in
            "react-best-practices")
                update_react_best_practices
                ;;
            "agent-browser")
                update_agent_browser
                ;;
            *)
                echo "警告: 未知的 skill: $skill"
                echo "可用的 skills: react-best-practices, agent-browser"
                ;;
        esac
        echo ""
    done
fi

echo "同步完成!"
echo ""
echo "如果有更新，請執行:"
echo "  git add -A && git commit -m 'chore: 同步外部 skills' && git push"
