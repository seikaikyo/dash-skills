# Dash Skills

**Claude Code Skills Collection**

[English](./README.en.md) | [日本語](./README.ja.md) | 正體中文

## 概述

集中管理 Claude Code 的 Skills -- 自建的技術棧規範 + 收錄的外部 Skills，搭配每日自動同步機制。

## 包含的 Skills

> 自建 12 個 (`skills/`) + 外部收錄 48 個 (`external/`)。外部 skill 每日從上游自動同步。

### 自建 Skills (`skills/`)

| Skill | 描述 |
|-------|------|
| **angular-primeng** | Angular 21 + PrimeNG 企業應用開發規範 (MES / ERP / 後台) |
| **fastapi-patterns** | FastAPI + SQLModel + Neon 後端開發規範 |
| **openspec** | 規格驅動開發 (SDD) 工作流程 |
| **security-reviewer** | 安全漏洞檢測與修復 (OWASP Top 10) |
| **build-error-resolver** | 建構與 TypeScript 錯誤快速修復 |
| **refactor-cleaner** | 死代碼清理與重構整合 |
| **architecture-audit** | 架構文件稽核，比對 CLAUDE.md 與實際程式碼結構 |
| **cis-design-system** | CIS 企業識別設計規範建立與維護 |
| **quality-gate** | 前端品質閘門 (SEO / 無障礙 / 效能 / UI-UX) |
| **doubt-driven-development** | 非平凡決策的新鮮 context 對抗審查 (改寫自 tGD, Apache-2.0) |
| **interview-me** | 需求不明時的意圖萃取訪談 (改寫自 tGD, Apache-2.0) |
| **sketch** | 拋棄式 HTML mockup 比稿，2 到 3 個設計立場變體 (改寫自 tGD, Apache-2.0) |

### 開發與部署

| Skill | 描述 | 來源 |
|-------|------|------|
| **react-best-practices** | React / Next.js 效能優化指南 | vercel-labs/agent-skills |
| **vercel-react-best-practices** | React / Next.js 效能優化 (TSX 審查版) | vercel-labs/agent-skills |
| **vercel-python** | Python 專案 Vercel 部署診斷與修復 | vercel-labs/agent-skills |
| **vercel-cost-optimization** | Vercel 帳單分析與成本優化 | vercel-labs/agent-skills |
| **deploy-to-vercel** | 部署應用到 Vercel | vercel-labs/agent-skills |
| **agent-browser** | 瀏覽器自動化 CLI (200+ 指令) | vercel-labs/agent-browser |
| **mcp-builder** | 建立高品質 MCP server | anthropics/skills |
| **skill-creator** | 建立 / 改進 / 評測 skill | anthropics/skills |
| **claude-api** | Claude API 使用指南 | anthropics/skills |

### UI/UX 與設計

| Skill | 描述 | 來源 |
|-------|------|------|
| **frontend-design** | 反 AI 罐頭風格的前端設計 | anthropics/skills |
| **interface-design** | 設計記憶系統，確保元件風格一致 | Dammyjay93/interface-design |
| **ui-ux-pro-max** | 50+ UI 風格 / 161 色彩 / 57 字型配對 | nextlevelbuilder/ui-ux-pro-max-skill |
| **bencium-marketplace** | UX 審查 + typography + 創新 UX | bencium/bencium-marketplace |
| **web-design-guidelines** | UI 程式碼審查 (a11y / UX / 效能) | vercel-labs/agent-skills |
| **canvas-design** | 用設計哲學做 PNG / PDF 視覺作品 | anthropics/skills |
| **brand-guidelines** | 套用 Anthropic 官方品牌色彩與字型 | anthropics/skills |
| **theme-factory** | 用主題為 artifact 上樣式 (10 種預設) | anthropics/skills |
| **web-artifacts-builder** | 建立多元件 claude.ai HTML artifact | anthropics/skills |
| **algorithmic-art** | 用 p5.js 做演算法藝術 | anthropics/skills |

### 無障礙

| Skill | 描述 | 來源 |
|-------|------|------|
| **accessibility-agents** | WCAG AA 無障礙強制 (80 專家 agent + 25 指令) | Community-Access/accessibility-agents |

### 測試

| Skill | 描述 | 來源 |
|-------|------|------|
| **webapp-testing** | 用 Playwright 測試本地 web app | anthropics/skills |
| **webapp-uat** | 瀏覽器全流程 UAT (console / network / a11y / i18n) | tsilverberg/webapp-uat |

### 資安 / 合規

| Skill | 描述 | 來源 |
|-------|------|------|
| **security-audit** | 白箱 / 灰箱安全稽核 (ISO 27001 對映) | afiqiqmal/claude-security-audit |
| **security-skills** | 安全自動化 skill marketplace | eth0izzle/security-skills |
| **claude-code-owasp** | OWASP Top 10 程式碼安全審查 | agamm/claude-code-owasp |
| **ot-security-mcp** | IEC 62443 / NIST 800-82 OT 安全 MCP | Ansvar-Systems/ot-security-mcp |
| **trailofbits-security** | 安全分析 plugin (CodeQL / Semgrep) | trailofbits/skills |
| **trailofbits-skills-curated** | Trail of Bits 審核過的 plugin 精選 | trailofbits/skills-curated |
| **sentry-security-review** | Sentry 慣例 commit + 安全審查 | getsentry/skills |
| **anthropic-cybersecurity-skills** | 網路安全 skill 集 | mukul975/Anthropic-Cybersecurity-Skills |

### 文件處理

| Skill | 描述 | 來源 |
|-------|------|------|
| **docx** | 建立 / 讀取 / 編輯 Word 文件 | anthropics/skills |
| **pdf** | 處理 PDF (讀取 / 合併 / 提取) | anthropics/skills |
| **pptx** | 建立 / 編輯簡報 | anthropics/skills |
| **xlsx** | 建立 / 編輯試算表 | anthropics/skills |

### 寫作與內容

| Skill | 描述 | 來源 |
|-------|------|------|
| **humanizer-zh-tw** | 去除中文 AI 寫作痕跡 (強制套用) | kevintsai1202/Humanizer-zh-TW |
| **humanizer-en** | 去除英文 AI 寫作痕跡 | blader/humanizer |
| **content-research-writer** | 研究 + 引用輔助的內容寫作 | ComposioHQ/awesome-claude-skills |
| **creative-writing-skills** | 虛構世界觀 / 角色 wiki 寫作 | haowjy/creative-writing-skills |
| **paper-writer-skill** | 醫學 / 科學論文寫作流程 | kgraph57/paper-writer-skill |
| **storytelling** | 產品價值與痛點的敘事建構 | gtmagents/gtm-agents |
| **doc-coauthoring** | 結構化文件協作流程 | anthropics/skills |
| **internal-comms** | 內部溝通文件 (狀態報告 / 領導層更新) | anthropics/skills |

### 影片 / 動畫

| Skill | 描述 | 來源 |
|-------|------|------|
| **remotion-video-skill** | 用 Remotion 以程式碼產生影片 | wshuyi/remotion-video-skill |
| **slack-gif-creator** | 製作 Slack 最佳化的動態 GIF | anthropics/skills |

### 資料庫

| Skill | 描述 | 來源 |
|-------|------|------|
| **neon-skills** | Neon serverless 驅動配置 (6 個子 skill) | neondatabase/ai-rules |

### 已移除

| Skill | 原因 |
|-------|------|
| ~~cisco-skill-scanner~~ | 不再同步 |
| ~~neon-ai-rules~~ | 併入 neon-skills |
| ~~ux-designer~~ | bencium/design-skill repo 已不存在 |
| ~~ui-agents~~ | JakobStadler/claude-code-ui-agents repo 已不存在 |
| ~~claude-designer~~ | joeseesun/claude-designer-skill repo 已不存在 |

## pi.dev 配置 (`pi-agent/`)

除了 Claude Code skills，本 repo 也收錄 pi.dev coding agent 的個人工作配置,讀檔即生效。

| 檔案 | 作用 |
|------|------|
| `AGENTS.md` | 工作風格與工程紀律 |
| `APPEND_SYSTEM.md` | 核心行為約束(機密邊界 / 對外確認 / 誠實 / 簡潔) |
| `extensions/guardrails.ts` | 危險 git / 機敏檔 / emoji 攔截 |
| `settings.fragment.json` | 指向 skills 與 extensions |

安裝與位置說明見 [`pi-agent/README.md`](./pi-agent/README.md)。

## 安裝

### 方法一：安裝腳本

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法二：手動複製

```bash
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### 方法三：Symlink（開發用）

```bash
./scripts/link.sh
```

## 自動同步

將以下加入 `~/.zshrc`，每天第一次開 terminal 自動同步：

```bash
source ~/Documents/github/dash-skills/scripts/auto-update.sh
```

每日自動：

- 從官方來源更新外部 skills SKILL.md
- 檢查 agent-browser CLI npm 版本，有新版自動更新
- 有變更自動 commit + push

### 手動同步

```bash
./scripts/update-external.sh              # 更新全部
./scripts/update-external.sh --list       # 列出可用的
./scripts/update-external.sh agent-browser # 更新指定的
```

## 技術棧總覽

| 層級 | 技術選擇 |
|------|---------|
| 前端（企業） | Angular 21 + PrimeNG |
| 前端（一般） | Vite + Vue 3 + PrimeVue |
| 後端 | FastAPI + SQLModel |
| 資料庫 | Neon PostgreSQL |
| 前端部署 | Vercel |
| 後端部署 | Render |

## 更新紀錄

### 2026-06-09

- README 全面同步：skills 清單從 22 補到 54（自建 9 + 外部 45），每個外部 skill 標上游來源
- 移除已不存在的項目：cisco-skill-scanner、neon-ai-rules（併入 neon-skills）
- 新增 `pi-agent/`：pi.dev coding agent 個人配置(AGENTS.md / APPEND_SYSTEM.md / guardrails extension / settings 片段)

### 2026-03-15

- 移除 accessibility-agents 38 個已刪除的 agent 檔案（上游同步）
- 機敏資料自動 redact 功能加入 auto-update

### 2026-03-14

- 新增 5 個資安 skills（security-audit, ot-security-mcp, trailofbits, sentry, cisco）
- 新增 3 個 UI/UX skills（frontend-design, accessibility-agents, bencium-marketplace）
- 移除已消失的 repo（ux-designer, ui-agents, claude-designer）
- 修復 `update-external.sh` 的 `set -e` 中斷問題
- 新增 agent-browser CLI npm 自動更新
- 技術棧更新：Shoelace 改為 PrimeVue

### 2026-03-01

- 新增 humanizer-zh-tw（強制套用）
- 新增 neon-skills 6 個獨立 skills

### 2026-01-16

- 初始版本：自建 Skills + 外部收錄

## 授權

- 自建 Skills：MIT License
- 外部 Skills：依各來源授權

## 作者

SeiKai Kyo (許正解)

## 致謝

外部 skill 來自各開源社群,授權依各來源。主要來源:

- [Anthropic](https://github.com/anthropics/skills) -- 官方 skills(文件處理 / 設計 / mcp-builder 等)
- [Vercel Labs](https://github.com/vercel-labs) -- react-best-practices, agent-browser, web-design-guidelines, vercel 系列
- [Neon](https://github.com/neondatabase) -- neon-skills
- [Trail of Bits](https://github.com/trailofbits) -- 安全 plugin
- 以及 Dammyjay93, nextlevelbuilder, bencium, Community-Access, kevintsai1202, blader, haowjy, kgraph57, ComposioHQ, gtmagents, agamm, mukul975, eth0izzle, afiqiqmal, getsentry, Ansvar-Systems, tsilverberg, wshuyi 等
