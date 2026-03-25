#!/bin/bash
#
# Dash Skills - 外部 Skill 同步腳本
# 從官方來源更新 external/ 目錄下的 skills
#

# 不用 set -e，各函數自行處理錯誤避免整體中斷

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

# ux-designer (bencium/design-skill) - 已移除 (repo 不存在)
# ui-agents (JakobStadler/claude-code-ui-agents) - 已移除 (repo 不存在)
# claude-designer (joeseesun/claude-designer-skill) - 已移除 (repo 不存在)

# 函數：更新 frontend-design (Anthropic 官方)
update_frontend_design() {
    local skill_dir="$EXTERNAL_DIR/frontend-design"
    local temp_dir=$(mktemp -d)
    local repo="anthropics/skills"

    echo "更新: frontend-design (Anthropic 官方)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    cd repo
    git sparse-checkout set skills/frontend-design 2>/dev/null

    if [ -d "skills/frontend-design" ]; then
        rm -rf "$skill_dir"
        cp -r skills/frontend-design "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 accessibility-agents
update_accessibility_agents() {
    local skill_dir="$EXTERNAL_DIR/accessibility-agents"
    local temp_dir=$(mktemp -d)
    local repo="Community-Access/accessibility-agents"

    echo "更新: accessibility-agents (57 agents)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo/claude-code-plugin/agents" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/claude-code-plugin/agents "$skill_dir/"
        cp repo/claude-code-plugin/CLAUDE.md "$skill_dir/" 2>/dev/null || true
        cp repo/claude-code-plugin/AGENTS.md "$skill_dir/" 2>/dev/null || true
        cp repo/claude-code-plugin/README.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 bencium-marketplace (UX 設計)
update_bencium_marketplace() {
    local skill_dir="$EXTERNAL_DIR/bencium-marketplace"
    local temp_dir=$(mktemp -d)
    local repo="bencium/bencium-marketplace"

    echo "更新: bencium-marketplace (UX audit + typography)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    rm -rf "$skill_dir"
    mkdir -p "$skill_dir"
    cp repo/README.md "$skill_dir/" 2>/dev/null || true
    for skill in bencium-controlled-ux-designer bencium-innovative-ux-designer design-audit typography; do
        [ -d "repo/$skill" ] && cp -r "repo/$skill" "$skill_dir/"
    done
    echo "  狀態: 已更新"

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

# 注意: neon-ai-rules 已移除 (含敏感資料，改用 neon-skills)

# === 寫作 / 敘事 / 語言學 Skills ===

# 函數：更新 humanizer-en (英文去 AI 痕跡)
update_humanizer_en() {
    local skill_dir="$EXTERNAL_DIR/humanizer-en"
    local temp_dir=$(mktemp -d)
    local repo="blader/humanizer"

    echo "更新: humanizer-en"
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

# 函數：更新 creative-writing-skills (6 個子 skill)
update_creative_writing_skills() {
    local skill_dir="$EXTERNAL_DIR/creative-writing-skills"
    local temp_dir=$(mktemp -d)
    local repo="haowjy/creative-writing-skills"

    echo "更新: creative-writing-skills (6 sub-skills)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -d "repo/creative-writing-skills" ]; then
        rm -rf "$skill_dir"
        cp -r repo/creative-writing-skills "$skill_dir"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
        echo "  包含:"
        ls -1 "$skill_dir" | grep "^cw-" | while read s; do
            echo "    - $s"
        done
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 paper-writer-skill (EN+JA 學術寫作)
update_paper_writer_skill() {
    local skill_dir="$EXTERNAL_DIR/paper-writer-skill"
    local temp_dir=$(mktemp -d)
    local repo="kgraph57/paper-writer-skill"

    echo "更新: paper-writer-skill (EN+JA)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null

    if [ -f "repo/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/SKILL.md repo/README.md repo/README.ja.md "$skill_dir/" 2>/dev/null
        cp -r repo/templates "$skill_dir/" 2>/dev/null || true
        cp -r repo/references "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 content-research-writer
update_content_research_writer() {
    local skill_dir="$EXTERNAL_DIR/content-research-writer"
    local temp_dir=$(mktemp -d)
    local repo="ComposioHQ/awesome-claude-skills"

    echo "更新: content-research-writer"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    git clone --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" repo 2>/dev/null

    cd repo
    git sparse-checkout set content-research-writer 2>/dev/null

    if [ -d "content-research-writer" ]; then
        rm -rf "$skill_dir"
        cp -r content-research-writer "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 doc-coauthoring (Anthropic 官方)
update_doc_coauthoring() {
    local skill_dir="$EXTERNAL_DIR/doc-coauthoring"
    local temp_dir=$(mktemp -d)
    local repo="anthropics/skills"

    echo "更新: doc-coauthoring (Anthropic 官方)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    cd repo
    git sparse-checkout set skills/doc-coauthoring 2>/dev/null

    if [ -d "skills/doc-coauthoring" ]; then
        rm -rf "$skill_dir"
        cp -r skills/doc-coauthoring "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 storytelling (SCAR 框架)
update_storytelling() {
    local skill_dir="$EXTERNAL_DIR/storytelling"
    local temp_dir=$(mktemp -d)
    local repo="gtmagents/gtm-agents"

    echo "更新: storytelling (SCAR 框架)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    cd repo
    git sparse-checkout set plugins/content-marketing/skills/storytelling 2>/dev/null

    if [ -d "plugins/content-marketing/skills/storytelling" ]; then
        rm -rf "$skill_dir"
        cp -r plugins/content-marketing/skills/storytelling "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# === 影片製作類 Skills ===

# 函數：更新 remotion-video-skill (程式化影片製作)
update_remotion_video() {
    local skill_dir="$EXTERNAL_DIR/remotion-video-skill"
    local temp_dir=$(mktemp -d)
    local repo="wshuyi/remotion-video-skill"

    echo "更新: remotion-video-skill (Remotion 程式化影片)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -f "repo/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/SKILL.md "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/README_CN.md "$skill_dir/" 2>/dev/null || true
        cp -r repo/scripts "$skill_dir/" 2>/dev/null || true
        cp -r repo/templates "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 顯示可用的 skills
show_available() {
    echo "可用的外部 Skills:"
    echo ""
    echo "  開發類:"
    echo "  - react-best-practices    (Vercel Labs)"
    echo "  - agent-browser           (Vercel Labs)"
    echo "  - web-design-guidelines   (Vercel Labs)"
    echo "  - neon-skills             (Neon Database, 6 skills)"
    echo "  - frontend-design         (Anthropic 官方, 前端設計)"
    echo "  - accessibility-agents    (Community-Access, 57 a11y agents)"
    echo "  - bencium-marketplace     (bencium, UX audit + typography)"
    echo ""
    echo "  影片製作類:"
    echo "  - remotion-video-skill    (wshuyi, Remotion 程式化影片製作)"
    echo ""
    echo "  寫作 / 敘事類:"
    echo "  - humanizer-en            (blader, EN 去 AI 痕跡)"
    echo "  - humanizer-zh-tw         (kevintsai1202, ZH-TW 去 AI 痕跡) [強制]"
    echo "  - creative-writing-skills (haowjy, 6 sub-skills: 散文/腦力激盪/故事批評)"
    echo "  - paper-writer-skill      (kgraph57, EN+JA 學術寫作)"
    echo "  - content-research-writer (ComposioHQ, 研究寫作夥伴)"
    echo "  - doc-coauthoring         (Anthropic 官方, 文件共筆)"
    echo "  - storytelling            (GTM Agents, SCAR 敘事框架)"
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
    update_frontend_design
    echo ""
    update_accessibility_agents
    echo ""
    update_bencium_marketplace
    echo ""
    update_humanizer_zh_tw
    echo ""
    # 寫作 / 敘事類
    update_humanizer_en
    echo ""
    update_creative_writing_skills
    echo ""
    update_paper_writer_skill
    echo ""
    update_content_research_writer
    echo ""
    update_doc_coauthoring
    echo ""
    update_storytelling
    echo ""
    # 影片製作類
    update_remotion_video
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
            "humanizer-zh-tw")
                update_humanizer_zh_tw
                ;;
            "humanizer-en"|"humanizer")
                update_humanizer_en
                ;;
            "creative-writing-skills"|"creative-writing"|"cw")
                update_creative_writing_skills
                ;;
            "paper-writer-skill"|"paper-writer")
                update_paper_writer_skill
                ;;
            "content-research-writer"|"content-writer")
                update_content_research_writer
                ;;
            "doc-coauthoring"|"doc")
                update_doc_coauthoring
                ;;
            "storytelling"|"story")
                update_storytelling
                ;;
            "remotion-video-skill"|"remotion-video"|"remotion")
                update_remotion_video
                ;;
            *)
                echo "警告: 未知的 skill: $skill"
                show_available
                ;;
        esac
        echo ""
    done
fi

# === npm CLI 工具更新 ===
echo "更新: agent-browser CLI"
CURRENT_AB=$(npm ls -g agent-browser --depth=0 2>/dev/null | grep agent-browser | sed 's/.*@//')
LATEST_AB=$(npm view agent-browser version 2>/dev/null)
if [ -n "$LATEST_AB" ] && [ "$CURRENT_AB" != "$LATEST_AB" ]; then
    echo "  $CURRENT_AB -> $LATEST_AB"
    npm install -g agent-browser@latest > /dev/null 2>&1
    echo "  狀態: 已更新"
else
    echo "  狀態: 已是最新 ($CURRENT_AB)"
fi

echo ""
echo "同步完成!"

# === 自動 commit + push ===
cd "$REPO_DIR"
if [ -n "$(git status --porcelain)" ]; then
    TODAY=$(date +%Y-%m-%d)
    git add -A
    git commit -m "chore: 每日同步外部 skills ($TODAY)"
    git push
    echo ""
    echo "已自動 commit 並推送 ($TODAY)"
else
    echo "無變更，跳過 commit"
fi
