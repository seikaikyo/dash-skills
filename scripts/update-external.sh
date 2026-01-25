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

    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null

    cd repo
    git sparse-checkout set skills/react-best-practices 2>/dev/null

    if [ -d "skills/react-best-practices" ]; then
        rm -rf "$skill_dir"
        cp -r skills/react-best-practices "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

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

    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null

    cd repo
    git sparse-checkout set skills/agent-browser 2>/dev/null

    if [ -d "skills/agent-browser" ]; then
        # 保留本地的 EXTENSIONS.md
        local has_extensions=false
        if [ -f "$skill_dir/EXTENSIONS.md" ]; then
            cp "$skill_dir/EXTENSIONS.md" "$temp_dir/EXTENSIONS.md.bak"
            has_extensions=true
        fi

        rm -rf "$skill_dir"
        cp -r skills/agent-browser "$skill_dir"

        if [ "$has_extensions" = true ]; then
            cp "$temp_dir/EXTENSIONS.md.bak" "$skill_dir/EXTENSIONS.md"
        fi

        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 web-design-guidelines
update_web_design_guidelines() {
    local skill_dir="$EXTERNAL_DIR/web-design-guidelines"
    local temp_dir=$(mktemp -d)
    local branch="web-design-guidelines"
    local repo="vercel-labs/agent-skills"

    echo "更新: web-design-guidelines"
    echo "  來源: https://github.com/$repo/tree/$branch"

    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null

    cd repo
    git sparse-checkout set skills/web-design-guidelines 2>/dev/null

    if [ -d "skills/web-design-guidelines" ]; then
        rm -rf "$skill_dir"
        cp -r skills/web-design-guidelines "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 neon-skills
update_neon_skills() {
    local skill_dir="$EXTERNAL_DIR/neon-skills"
    local temp_dir=$(mktemp -d)
    local repo="neondatabase/ai-rules"

    echo "更新: neon-skills (6 skills)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -d "repo/neon-plugin/skills" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/neon-plugin/skills/* "$skill_dir/"
        echo "  狀態: 已更新"
        echo "  包含:"
        ls -1 "$skill_dir" | while read s; do
            echo "    - $s"
        done
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 ux-designer
update_ux_designer() {
    local skill_dir="$EXTERNAL_DIR/ux-designer"
    local temp_dir=$(mktemp -d)
    local repo="bencium/design-skill"

    echo "更新: ux-designer"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -f "repo/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        # 複製主要檔案
        cp repo/SKILL.md "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/ACCESSIBILITY.md "$skill_dir/" 2>/dev/null || true
        cp repo/RESPONSIVE-DESIGN.md "$skill_dir/" 2>/dev/null || true
        cp repo/MOTION-SPEC.md "$skill_dir/" 2>/dev/null || true
        cp repo/DESIGN-SYSTEM-TEMPLATE.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 ui-agents
update_ui_agents() {
    local skill_dir="$EXTERNAL_DIR/ui-agents"
    local temp_dir=$(mktemp -d)
    local repo="JakobStadler/claude-code-ui-agents"

    echo "更新: ui-agents"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -d "repo/prompts" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/prompts "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/CONTRIBUTING.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        # 複製 .claude 目錄（如果存在）
        [ -d "repo/.claude" ] && cp -r repo/.claude "$skill_dir/"
        echo "  狀態: 已更新"
        echo "  類別:"
        ls -1 "$skill_dir/prompts" | while read c; do
            echo "    - $c"
        done
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 humanizer-zh-tw
update_humanizer_zh_tw() {
    local skill_dir="$EXTERNAL_DIR/humanizer-zh-tw"
    local temp_dir=$(mktemp -d)
    local repo="kevintsai1202/Humanizer-zh-TW"

    echo "更新: humanizer-zh-tw (強制)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -f "repo/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/SKILL.md "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 neon-ai-rules (完整版)
update_neon_ai_rules() {
    local skill_dir="$EXTERNAL_DIR/neon-ai-rules"
    local temp_dir=$(mktemp -d)
    local repo="neondatabase/ai-rules"

    echo "更新: neon-ai-rules (完整規則)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -f "repo/CLAUDE.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/CLAUDE.md "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        # 複製所有 .mdc 檔案
        cp repo/*.mdc "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
        echo "  規則檔案:"
        ls -1 "$skill_dir"/*.mdc 2>/dev/null | xargs -n1 basename | while read f; do
            echo "    - $f"
        done
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 顯示可用的 skills
show_available() {
    echo "可用的外部 Skills:"
    echo "  - react-best-practices  (Vercel Labs)"
    echo "  - agent-browser         (Vercel Labs)"
    echo "  - web-design-guidelines (Vercel Labs)"
    echo "  - neon-skills           (Neon Database, 6 skills)"
    echo "  - neon-ai-rules         (Neon Database, 完整規則 + .mdc 文件)"
    echo "  - ux-designer           (bencium, UI/UX 設計指導)"
    echo "  - ui-agents             (JakobStadler, 提示詞模板集)"
    echo "  - humanizer-zh-tw       (kevintsai1202, 去除 AI 痕跡) [強制]"
    echo ""
}

# 主程式
if [ $# -eq 0 ]; then
    # 沒有參數，更新全部
    update_react_best_practices
    echo ""
    update_agent_browser
    echo ""
    update_web_design_guidelines
    echo ""
    update_neon_skills
    echo ""
    update_neon_ai_rules
    echo ""
    update_ux_designer
    echo ""
    update_ui_agents
    echo ""
    update_humanizer_zh_tw
elif [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    show_available
    exit 0
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
            "web-design-guidelines")
                update_web_design_guidelines
                ;;
            "neon-skills"|"neon")
                update_neon_skills
                ;;
            "neon-ai-rules")
                update_neon_ai_rules
                ;;
            "ux-designer")
                update_ux_designer
                ;;
            "ui-agents")
                update_ui_agents
                ;;
            "humanizer-zh-tw"|"humanizer")
                update_humanizer_zh_tw
                ;;
            *)
                echo "警告: 未知的 skill: $skill"
                show_available
                ;;
        esac
        echo ""
    done
fi

echo "同步完成!"
echo ""
echo "如果有更新，請執行:"
echo "  git add -A && git commit -m 'chore: 同步外部 skills' && git push"
