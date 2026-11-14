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
    local branch="main"
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
        cp -RP skills/react-best-practices "$skill_dir"
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
        cp -RP skills/agent-browser "$skill_dir"

        if [ "$has_extensions" = true ]; then
            cp "$temp_dir/EXTENSIONS.md.bak" "$skill_dir/EXTENSIONS.md"
        fi

        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# web-design-guidelines 不再同步（2026-11-10）：上游 SKILL.md 只是空殼，每次執行都叫 agent 用 WebFetch
# 抓遠端規則並照做，真正的指令不經過同步閘門。改為自建 skills/web-design-guidelines（靜態規則）。

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
        cp -RP repo/neon-plugin/skills/* "$skill_dir/"
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
        cp -RP "skills/$name" "$skill_dir"
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

# 函數：更新 claude-api (Anthropic 官方 - Claude API/SDK 開發指南，含 7 種語言範例)
update_claude_api() { _update_anthropic_skill "claude-api"; }

# 函數：更新 brand-guidelines (Anthropic 官方 - 品牌指引)
update_brand_guidelines() { _update_anthropic_skill "brand-guidelines"; }

# 函數：更新 web-artifacts-builder (Anthropic 官方 - 單檔互動 demo 建置)
update_web_artifacts_builder() { _update_anthropic_skill "web-artifacts-builder"; }

# 函數：更新 algorithmic-art (Anthropic 官方 - p5.js 演算法藝術)
update_algorithmic_art() { _update_anthropic_skill "algorithmic-art"; }

# 函數：更新 internal-comms (Anthropic 官方 - 內部溝通文件)
update_internal_comms() { _update_anthropic_skill "internal-comms"; }

# 函數：更新 slack-gif-creator (Anthropic 官方 - Slack 動畫 GIF 製作)
update_slack_gif_creator() { _update_anthropic_skill "slack-gif-creator"; }


# 通用函數：更新 vercel-labs/agent-skills 指定 branch + skills 子目錄
_update_vercel_agent_skill() {
    local name="$1"          # 來源子目錄名（skills/<name>）
    local branch="$2"        # 來源 branch
    local dest="${3:-$name}" # 本地目的目錄名（預設等於 name）
    local skill_dir="$EXTERNAL_DIR/$dest"
    local temp_dir=$(mktemp -d)
    local repo="vercel-labs/agent-skills"

    echo "更新: $dest (Vercel Labs $branch)"
    echo "  來源: https://github.com/$repo/tree/$branch"

    cd "$temp_dir"
    if ! git clone --depth 1 --filter=blob:none --sparse \
        "https://github.com/$repo.git" \
        --branch "$branch" repo 2>/dev/null; then
        echo "  狀態: 跳過（branch 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    cd repo
    git sparse-checkout set "skills/$name" 2>/dev/null

    if [ -d "skills/$name" ]; then
        rm -rf "$skill_dir"
        cp -RP "skills/$name" "$skill_dir"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗"
    fi

    rm -rf "$temp_dir"
}

# 函數：更新 deploy-to-vercel (Vercel 部署 skill)
update_deploy_to_vercel() {
    _update_vercel_agent_skill "deploy-to-vercel" "main"
}

# 函數：更新 vercel-optimize (Vercel 官方，以 metrics 為準的成本與效能優化審查)
update_vercel_optimize() {
    _update_vercel_agent_skill "vercel-optimize" "main"
}


# 函數：更新 doc-coauthoring (Anthropic 官方)
update_doc_coauthoring() { _update_anthropic_skill "doc-coauthoring"; }


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
            [ -d "$dir" ] && cp -RP "$dir" "$skill_dir/"
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


# trailofbits-skills-curated 不再同步（2026-11-10）：內容是 Trail of Bits 轉載的第三方作者 skill，
# 不是原廠自己寫的；其中 wooyun-legacy 是攻擊手法庫。集合型目錄 Claude Code 也載入不到。


# 函數：更新 cloudflare-security-audit (Cloudflare 多 agent 編排式滲透審計)
update_cloudflare_security_audit() {
    local skill_dir="$EXTERNAL_DIR/cloudflare-security-audit"
    local temp_dir=$(mktemp -d)
    local repo="cloudflare/security-audit-skill"

    echo "更新: cloudflare-security-audit (多 agent 編排式滲透審計)"
    echo "  來源: https://github.com/$repo"

    cd "$temp_dir"
    if ! git clone --depth 1 "https://github.com/$repo.git" repo 2>/dev/null; then
        echo "  狀態: 跳過（repo 不可用）"
        rm -rf "$temp_dir"
        return 0
    fi

    # 2026-10 上游把檔案從 repo 根目錄移到 skills/security-audit/；整個目錄複製，
    # 不再逐檔列舉（上游常新增 .md / .cjs，列舉會漏）。README 與 LICENSE 仍在根。
    local src="repo/skills/security-audit"
    if [ -f "$src/SKILL.md" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -RP "$src/." "$skill_dir/" 2>/dev/null || true
        cp repo/README.md "$skill_dir/" 2>/dev/null || true
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        # frontmatter name 對齊獨立目錄名，避免與既有 security-audit 撞名
        sed -i '' 's/^name: security-audit$/name: cloudflare-security-audit/' "$skill_dir/SKILL.md"
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗（上游結構改變，找不到 $src/SKILL.md，需更新同步函數）"
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

    # 2026-10 上游把 skills 從 plugins/sentry-skills/skills/ 移到根目錄 skills/。
    local src="repo/skills"
    if [ -d "$src" ] && [ -n "$(ls -A "$src" 2>/dev/null)" ]; then
        rm -rf "$skill_dir"
        mkdir -p "$skill_dir"
        cp -RP "$src/." "$skill_dir/"
        cp repo/LICENSE "$skill_dir/" 2>/dev/null || true
        echo "  狀態: 已更新"
    else
        echo "  狀態: 失敗（上游結構改變，找不到 $src/，需更新同步函數）"
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
    echo "  - claude-api              (Anthropic 官方, Claude API/SDK 7 語言範例)"
    echo "  - brand-guidelines        (Anthropic 官方, 品牌指引)"
    echo "  - web-artifacts-builder   (Anthropic 官方, 單檔互動 demo)"
    echo "  - algorithmic-art         (Anthropic 官方, p5.js 演算法藝術)"
    echo "  - internal-comms          (Anthropic 官方, 內部溝通文件)"
    echo "  - slack-gif-creator       (Anthropic 官方, Slack 動畫 GIF)"
    echo "  - deploy-to-vercel        (Vercel Labs, Vercel 部署)"
    echo "  - vercel-optimize         (Vercel Labs, 成本與效能優化審查)"
    echo ""
    echo "  安全 / 資安類:"
    echo "  - trailofbits-security       (Trail of Bits, 35+ security plugins)"
    echo "  - cloudflare-security-audit  (Cloudflare, 多 agent 編排式滲透審計)"
    echo "  - sentry-security-review     (Sentry 官方, security code review)"
    echo ""
    echo "  影片製作類:"
    echo ""
    echo "  寫作 / 敘事類:"
    echo "  - doc-coauthoring         (Anthropic 官方, 文件共筆)"
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
        update_neon_skills
        update_frontend_design
        update_doc_coauthoring
        update_trailofbits_security
        update_cloudflare_security_audit
        update_sentry_security_review
        update_canvas_design
        update_pdf
        update_docx
        update_xlsx
        update_pptx
        update_mcp_builder
        update_skill_creator
        update_webapp_testing
        update_theme_factory
        update_claude_api
        update_brand_guidelines
        update_web_artifacts_builder
        update_deploy_to_vercel
        update_vercel_optimize
        update_algorithmic_art
        update_internal_comms
        update_slack_gif_creator
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

    # 統計結果
    ok=0 fail=0 timeout_count=0
    failed_names=()
    for fn in "${all_updates[@]}"; do
        if grep -q '狀態: 已更新' "$LOG_DIR/$fn.log" 2>/dev/null; then
            ok=$((ok + 1))
        elif grep -q '狀態: 逾時' "$LOG_DIR/$fn.log" 2>/dev/null; then
            timeout_count=$((timeout_count + 1))
            failed_names+=("${fn#update_}（逾時）")
        else
            fail=$((fail + 1))
            failed_names+=("${fn#update_}")
        fi
    done
    echo ""
    echo "  結果: $ok 成功 / $fail 失敗 / $timeout_count 逾時 (共 $total)"
    echo ""

    # 失敗清單寫進狀態檔，讓 auto-update.sh 與每日巡檢讀得到。
    # 2026-10-25 事故：cloudflare-security-audit、sentry-security-review 因上游改結構連續失敗
    # 4 到 6 個月，失敗只印在被 auto-update 丟進 /dev/null 的輸出裡，沒有人發現。
    status_file="$REPO_DIR/.last-sync-failures"
    if [ ${#failed_names[@]} -gt 0 ]; then
        {
            echo "$(date '+%Y-%m-%d %H:%M') 失敗 ${#failed_names[@]} 個"
            printf '%s\n' "${failed_names[@]//_/-}"
        } > "$status_file"
    else
        : > "$status_file"
    fi

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
            "neon-skills"|"neon")
                update_neon_skills
                ;;
            "doc-coauthoring"|"doc")
                update_doc_coauthoring
                ;;
            "trailofbits-security"|"trailofbits"|"tob")
                update_trailofbits_security
                ;;
            "cloudflare-security-audit"|"cf-audit"|"cloudflare-audit")
                update_cloudflare_security_audit
                ;;
            "sentry-security-review"|"sentry-review")
                update_sentry_security_review
                ;;
            "frontend-design"|"frontend")
                update_frontend_design
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
            "claude-api"|"api")
                update_claude_api
                ;;
            "brand-guidelines"|"brand")
                update_brand_guidelines
                ;;
            "web-artifacts-builder"|"artifacts")
                update_web_artifacts_builder
                ;;
            "deploy-to-vercel"|"deploy")
                update_deploy_to_vercel
                ;;
            "vercel-optimize"|"optimize")
                update_vercel_optimize
                ;;
            "algorithmic-art"|"algo-art")
                update_algorithmic_art
                ;;
            "internal-comms"|"comms")
                update_internal_comms
                ;;
            "slack-gif-creator"|"slack-gif"|"gif")
                update_slack_gif_creator
                ;;
            *)
                echo "警告: 未知的 skill: $skill"
                show_available
                ;;
        esac
        echo ""
    done
fi

# agent-browser CLI 不在這裡自動升級（2026-11-10 移除 npm install -g agent-browser@latest）：
# 它的 SKILL.md 只是空殼，實際指令由 CLI 提供，自動裝最新版等於讓未經檢查的執行碼與 agent 指令
# 每天繞過閘門進來。升級改為手動並指定版本，做法見 README「自動同步」一節。

echo ""
echo "同步完成!"

# === 自動 commit + push ===
# 從 auto-update.sh 呼叫時跳過（由呼叫端統一 redact + commit + push）
if [ -z "$DASH_SKILLS_NO_PUSH" ]; then
    cd "$REPO_DIR"
    if [ -n "$(git status --porcelain)" ]; then
        TODAY=$(date +%Y-%m-%d)
        # 指名 stage（2026-07-25）：public repo 禁 git add -A
        git add external openspec pi-agent scripts skills *.md 2>/dev/null || true
        git commit -m "chore: daily external skills sync ($TODAY)"
        git push
        echo ""
        echo "已自動 commit 並推送 ($TODAY)"
    else
        echo "無變更，跳過 commit"
    fi
else
    echo "跳過 commit（由呼叫端處理）"
fi
