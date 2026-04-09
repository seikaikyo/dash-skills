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

# 通用函數：更新 anthropics/skills repo 中的 skill
_update_anthropic_skill() {
    local name="$1"
    local skill_dir="$EXTERNAL_DIR/$name"
    local temp_dir=$(mktemp -d)
    local repo="anthropics/skills"

    echo "更新: $name (Anthropic 官方)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    cd repo
    git sparse-checkout set "skills/$name" 2>/dev/null

    if [ -d "skills/$name" ]; then
        rm -rf "$skill_dir"
        cp -r "skills/$name" "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 frontend-design (Anthropic 官方)
update_frontend_design() { _update_anthropic_skill "frontend-design"; }

# 函數：更新 canvas-design (Anthropic 官方 - 視覺設計/海報/藝術品)
update_canvas_design() { _update_anthropic_skill "canvas-design"; }

# 函數：更新 pdf (Anthropic 官方 - PDF 讀寫/合併/分割/OCR)
update_pdf() { _update_anthropic_skill "pdf"; }

# 函數：更新 docx (Anthropic 官方 - Word 文件讀寫編輯)
update_docx() { _update_anthropic_skill "docx"; }

# 函數：更新 xlsx (Anthropic 官方 - Excel 讀寫格式化)
update_xlsx() { _update_anthropic_skill "xlsx"; }

# 函數：更新 pptx (Anthropic 官方 - PowerPoint 簡報製作)
update_pptx() { _update_anthropic_skill "pptx"; }

# 函數：更新 mcp-builder (Anthropic 官方 - MCP server 建置指南)
update_mcp_builder() { _update_anthropic_skill "mcp-builder"; }

# 函數：更新 skill-creator (Anthropic 官方 - Skill 建置/測試/迭代)
update_skill_creator() { _update_anthropic_skill "skill-creator"; }

# 函數：更新 webapp-testing (Anthropic 官方 - Playwright 前端測試)
update_webapp_testing() { _update_anthropic_skill "webapp-testing"; }

# 函數：更新 theme-factory (Anthropic 官方 - 文件/簡報主題工廠)
update_theme_factory() { _update_anthropic_skill "theme-factory"; }

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
update_doc_coauthoring() { _update_anthropic_skill "doc-coauthoring"; }

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

# === 安全 / 資安類 Skills ===

# 函數：更新 trailofbits-security (35+ security plugins)
update_trailofbits_security() {
    local skill_dir="$EXTERNAL_DIR/trailofbits-security"
    local temp_dir=$(mktemp -d)
    local repo="trailofbits/skills"

    echo "更新: trailofbits-security (35+ plugins)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        # 複製所有 plugin 目錄（排除 .git 和非 skill 檔案）
        for dir in repo/*/; do
            local dirname=$(basename "$dir")
            [ "$dirname" = ".git" ] && continue
            [ "$dirname" = ".github" ] && continue
            [ -d "$dir" ] && cp -r "$dir" "$skill_dir/"
        done
        cp repo/CLAUDE.md "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
        echo "  包含: $(ls -1d "$skill_dir"/*/ 2>/dev/null | wc -l | tr -d ' ') plugins"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 claude-code-owasp (OWASP Top 10:2025 + ASVS 5.0)
update_claude_code_owasp() {
    local skill_dir="$EXTERNAL_DIR/claude-code-owasp"
    local temp_dir=$(mktemp -d)
    local repo="agamm/claude-code-owasp"

    echo "更新: claude-code-owasp (OWASP Top 10:2025)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -f "repo/.claude/skills/owasp-security/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/.claude/skills/owasp-security/SKILL.md "$skill_dir/"
        cp repo/OWASP-2025-2026-Report.md "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 trailofbits-skills-curated (審核過的 skill marketplace)
update_trailofbits_skills_curated() {
    local skill_dir="$EXTERNAL_DIR/trailofbits-skills-curated"
    local temp_dir=$(mktemp -d)
    local repo="trailofbits/skills-curated"

    echo "更新: trailofbits-skills-curated (審核過的 marketplace)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        # 複製 plugins 目錄
        [ -d "repo/plugins" ] && cp -r repo/plugins "$skill_dir/"
        cp repo/CLAUDE.md "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 anthropic-cybersecurity-skills (MITRE ATT&CK 734+ skills)
update_anthropic_cybersecurity_skills() {
    local skill_dir="$EXTERNAL_DIR/anthropic-cybersecurity-skills"
    local temp_dir=$(mktemp -d)
    local repo="mukul975/Anthropic-Cybersecurity-Skills"

    echo "更新: anthropic-cybersecurity-skills (MITRE ATT&CK 734+ skills)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/skills "$skill_dir/" 2>/dev/null || true
        cp -r repo/.claude "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 security-skills (SecOps/SOAR 自動化)
update_security_skills() {
    local skill_dir="$EXTERNAL_DIR/security-skills"
    local temp_dir=$(mktemp -d)
    local repo="eth0izzle/security-skills"

    echo "更新: security-skills (SecOps/SOAR)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        # 複製 skills 目錄和文件
        for dir in repo/*/; do
            local dirname=$(basename "$dir")
            [ "$dirname" = ".git" ] && continue
            [ "$dirname" = ".github" ] && continue
            [ -d "$dir" ] && cp -r "$dir" "$skill_dir/"
        done
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 security-audit (OWASP/CWE/NIST/MITRE 白箱審計)
update_security_audit() {
    local skill_dir="$EXTERNAL_DIR/security-audit"
    local temp_dir=$(mktemp -d)
    local repo="afiqiqmal/claude-security-audit"

    echo "更新: security-audit (白箱/灰箱安全審計)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/CLAUDE.md "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        [ -d "repo/commands" ] && cp -r repo/commands "$skill_dir/"
        [ -d "repo/references" ] && cp -r repo/references "$skill_dir/"
        [ -d "repo/targets" ] && cp -r repo/targets "$skill_dir/"
        cp repo/security-audit-guidelines.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 sentry-security-review (Sentry 官方 security review)
update_sentry_security_review() {
    local skill_dir="$EXTERNAL_DIR/sentry-security-review"
    local temp_dir=$(mktemp -d)
    local repo="getsentry/skills"

    echo "更新: sentry-security-review (Sentry 官方)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo/plugins/sentry-skills/skills" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/plugins/sentry-skills/skills/* "$skill_dir/"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 ot-security-mcp (IEC 62443 OT 安全)
update_ot_security_mcp() {
    local skill_dir="$EXTERNAL_DIR/ot-security-mcp"
    local temp_dir=$(mktemp -d)
    local repo="Ansvar-Systems/ot-security-mcp"

    echo "更新: ot-security-mcp (IEC 62443)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/package.json "$skill_dir/" 2>/dev/null || true
        [ -d "repo/src" ] && cp -r repo/src "$skill_dir/"
        [ -d "repo/skills" ] && cp -r repo/skills "$skill_dir/"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# === 設計類 Skills (手動來源) ===

# 函數：更新 interface-design (儀表板/後台介面設計)
update_interface_design() {
    local skill_dir="$EXTERNAL_DIR/interface-design"
    local temp_dir=$(mktemp -d)
    local repo="Dammyjay93/interface-design"

    echo "更新: interface-design (介面設計系統)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -f "repo/.claude/skills/interface-design/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -r repo/.claude/skills/interface-design/* "$skill_dir/"
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 ui-ux-pro-max (50 styles + 21 palettes)
update_ui_ux_pro_max() {
    local skill_dir="$EXTERNAL_DIR/ui-ux-pro-max"
    local temp_dir=$(mktemp -d)
    local repo="nextlevelbuilder/ui-ux-pro-max-skill"

    echo "更新: ui-ux-pro-max (50 styles + 21 palettes)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    if [ -d "repo/.claude/skills/ui-ux-pro-max" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        # 複製所有子 skills
        for s in repo/.claude/skills/*/; do
            local sname=$(basename "$s")
            cp -r "$s" "$skill_dir/$sname"
        done
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
        echo "  包含: $(ls -1d "$skill_dir"/*/ 2>/dev/null | wc -l | tr -d ' ') sub-skills"
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
    echo "  - canvas-design           (Anthropic 官方, 視覺設計/海報/藝術品)"
    echo "  - pdf                     (Anthropic 官方, PDF 讀寫/合併/OCR)"
    echo "  - docx                    (Anthropic 官方, Word 文件讀寫)"
    echo "  - xlsx                    (Anthropic 官方, Excel 讀寫格式化)"
    echo "  - pptx                    (Anthropic 官方, PowerPoint 簡報)"
    echo "  - mcp-builder             (Anthropic 官方, MCP server 建置)"
    echo "  - skill-creator           (Anthropic 官方, Skill 建置/測試)"
    echo "  - webapp-testing          (Anthropic 官方, Playwright 前端測試)"
    echo "  - theme-factory           (Anthropic 官方, 文件/簡報主題工廠)"
    echo "  - accessibility-agents    (Community-Access, 57 a11y agents)"
    echo "  - bencium-marketplace     (bencium, UX audit + typography)"
    echo "  - interface-design        (Dammyjay93, 儀表板/後台介面設計)"
    echo "  - ui-ux-pro-max           (nextlevelbuilder, 50 styles + 21 palettes)"
    echo ""
    echo "  安全 / 資安類:"
    echo "  - trailofbits-security       (Trail of Bits, 35+ security plugins)"
    echo "  - claude-code-owasp          (agamm, OWASP Top 10:2025 + ASVS 5.0)"
    echo "  - trailofbits-skills-curated (Trail of Bits, 審核過的 marketplace)"
    echo "  - anthropic-cybersecurity-skills (mukul975, MITRE ATT&CK 734+ skills)"
    echo "  - security-skills            (eth0izzle, SecOps/SOAR 自動化)"
    echo "  - security-audit             (afiqiqmal, OWASP/CWE/NIST 白箱審計)"
    echo "  - sentry-security-review     (Sentry 官方, security code review)"
    echo "  - ot-security-mcp            (Ansvar, IEC 62443 OT 安全)"
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
    # 沒有參數，平行更新全部（各 clone 同時執行）
    LOG_DIR=$(mktemp -d)
    trap 'rm -rf "$LOG_DIR"' EXIT

    all_updates=(
        update_react_best_practices
        update_agent_browser
        update_web_design_guidelines
        update_neon_skills
        update_frontend_design
        update_accessibility_agents
        update_bencium_marketplace
        update_humanizer_zh_tw
        update_humanizer_en
        update_creative_writing_skills
        update_paper_writer_skill
        update_content_research_writer
        update_doc_coauthoring
        update_storytelling
        update_trailofbits_security
        update_claude_code_owasp
        update_trailofbits_skills_curated
        update_anthropic_cybersecurity_skills
        update_security_skills
        update_security_audit
        update_sentry_security_review
        update_ot_security_mcp
        update_interface_design
        update_ui_ux_pro_max
        update_remotion_video
        update_canvas_design
        update_pdf
        update_docx
        update_xlsx
        update_pptx
        update_mcp_builder
        update_skill_creator
        update_webapp_testing
        update_theme_factory
    )

    total=${#all_updates[@]}
    done_count=0

    # 進度條函數（寫到 stderr，\r 覆蓋同一行）
    show_progress() {
        local current=$1 total=$2 name=$3
        local pct=$((current * 100 / total))
        local filled=$((pct / 5))  # 20 格寬
        local empty=$((20 - filled))
        local bar=""
        [ "$filled" -gt 0 ] && bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
        [ "$empty" -gt 0 ] && bar="${bar}$(printf '%*s' "$empty" '' | tr ' ' '-')"
        printf '\r  [%s] %d/%d %s        ' "$bar" "$current" "$total" "$name" >&2
    }

    # 平行啟動所有更新（子 shell fork 自動繼承函數定義）
    pids=()
    for fn in "${all_updates[@]}"; do
        ( $fn ) > "$LOG_DIR/$fn.log" 2>&1 &
        pids+=($!)
    done

    # npm 更新也平行跑（不計入 skill 進度條，但同時執行）
    (
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
    ) > "$LOG_DIR/npm_update.log" 2>&1 &
    npm_pid=$!

    # 監控進度 + 45 秒 timeout
    _start_time=$(date +%s)
    # 追蹤已完成的 job（避免重複計算）
    declare -a _job_done
    for i in "${!all_updates[@]}"; do _job_done[$i]=0; done
    last_done="waiting..."

    while true; do
        done_count=0
        for i in "${!all_updates[@]}"; do
            if [ "${_job_done[$i]}" -eq 1 ]; then
                done_count=$((done_count + 1))
            elif ! kill -0 "${pids[$i]}" 2>/dev/null; then
                _job_done[$i]=1
                done_count=$((done_count + 1))
                last_done="${all_updates[$i]#update_}"
                last_done="${last_done//_/-}"
            fi
        done
        show_progress "$done_count" "$total" "$last_done"
        [ "$done_count" -ge "$total" ] && break

        # 45 秒硬上限：kill 所有仍在跑的 job
        _elapsed=$(( $(date +%s) - _start_time ))
        if [ "$_elapsed" -ge 45 ]; then
            for i in "${!pids[@]}"; do
                kill "${pids[$i]}" 2>/dev/null
            done
            printf '\r  [####################] 逾時，已終止剩餘 job            \n' >&2
            break
        fi

        sleep 0.3
    done
    [ "$done_count" -ge "$total" ] && \
        printf '\r  [####################] %d/%d done                       \n' "$total" "$total" >&2

    # 等待全部完成（回收 exit code）
    wait "${pids[@]}" 2>/dev/null
    wait "$npm_pid" 2>/dev/null

    # 統計結果
    ok=0 fail=0 timeout_count=0
    for fn in "${all_updates[@]}"; do
        if grep -q '狀態: 已更新' "$LOG_DIR/$fn.log" 2>/dev/null; then
            ok=$((ok + 1))
        elif grep -q '狀態: 逾時' "$LOG_DIR/$fn.log" 2>/dev/null; then
            timeout_count=$((timeout_count + 1))
        else
            fail=$((fail + 1))
        fi
    done
    echo ""
    echo "  結果: $ok 成功 / $fail 失敗 / $timeout_count 逾時 (共 $total)"
    echo ""

    # 只印出失敗/逾時的詳細資訊，成功的跳過（減少輸出噪音）
    for fn in "${all_updates[@]}"; do
        if ! grep -q '狀態: 已更新' "$LOG_DIR/$fn.log" 2>/dev/null; then
            cat "$LOG_DIR/$fn.log"
            echo ""
        fi
    done

    rm -rf "$LOG_DIR"
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
            "trailofbits-security"|"trailofbits"|"tob")
                update_trailofbits_security
                ;;
            "claude-code-owasp"|"owasp")
                update_claude_code_owasp
                ;;
            "trailofbits-skills-curated"|"tob-curated"|"skills-curated")
                update_trailofbits_skills_curated
                ;;
            "anthropic-cybersecurity-skills"|"cybersecurity"|"mitre")
                update_anthropic_cybersecurity_skills
                ;;
            "security-skills"|"secops"|"soar")
                update_security_skills
                ;;
            "security-audit"|"audit")
                update_security_audit
                ;;
            "sentry-security-review"|"sentry-review")
                update_sentry_security_review
                ;;
            "ot-security-mcp"|"ot-security")
                update_ot_security_mcp
                ;;
            "interface-design")
                update_interface_design
                ;;
            "ui-ux-pro-max"|"ux-pro-max")
                update_ui_ux_pro_max
                ;;
            "canvas-design"|"canvas")
                update_canvas_design
                ;;
            "pdf")
                update_pdf
                ;;
            "docx"|"word")
                update_docx
                ;;
            "xlsx"|"excel")
                update_xlsx
                ;;
            "pptx"|"powerpoint"|"ppt")
                update_pptx
                ;;
            "mcp-builder"|"mcp")
                update_mcp_builder
                ;;
            "skill-creator"|"skill")
                update_skill_creator
                ;;
            "webapp-testing"|"playwright")
                update_webapp_testing
                ;;
            "theme-factory"|"theme")
                update_theme_factory
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
# 在 skill 同步的平行 wait 期間就已開始（npm_log 在上方平行區產生）
if [ -f "$LOG_DIR/npm_update.log" ] 2>/dev/null; then
    cat "$LOG_DIR/npm_update.log"
else
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
fi

echo ""
echo "同步完成!"

# === 自動 commit + push ===
# 從 auto-update.sh 呼叫時跳過（由呼叫端統一 redact + commit + push）
if [ -z "$DASH_SKILLS_NO_PUSH" ]; then
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
else
    echo "跳過 commit（由呼叫端處理）"
fi
