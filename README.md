# Dash Skills

**Claude Code 自定義 Skills 集合**

[English](./README.en.md) | [日本語](./README.ja.md) | 正體中文

## 概述

這個 repo 集中管理 Claude Code 的 Skills。包含自建的技術棧規範，以及收錄的優質外部 Skills。

## 包含的 Skills

### 自建 Skills (`skills/`)

| Skill | 描述 | 適用場景 |
|-------|------|---------|
| **angular-primeng** | Angular 21 + PrimeNG 企業應用開發規範 | MES、ERP、後台管理系統 |
| **fastapi-patterns** | FastAPI + SQLModel + Neon 後端開發 | Render 部署的 API 服務 |
| **openspec** | OpenSpec 規格驅動開發 (SDD) 工作流程 | 功能規劃、變更管理 |
| **security-reviewer** | 安全漏洞檢測 (OWASP Top 10) | 認證、用戶輸入、API、敏感資料處理 |
| **build-error-resolver** | 建構/TypeScript 錯誤快速修復 | 建構失敗、類型錯誤 |
| **refactor-cleaner** | 死代碼檢測與清理 | 程式碼健康檢查、依賴清理 |

### 外部收錄 (`external/`)

#### Vercel Labs

| Skill | 描述 | 規則數 |
|-------|------|--------|
| **react-best-practices** | React/Next.js 效能優化指南 | 40+ |
| **agent-browser** | 瀏覽器自動化工具 | 200+ 指令 |
| **web-design-guidelines** | UI 審查規則 (a11y, UX, 效能) | 80+ |

#### UI/UX 設計

| Skill | 描述 | 來源 |
|-------|------|------|
| **ux-designer** | 專業 UI/UX 設計指導 (WCAG、響應式、動效) | bencium |
| **ui-agents** | UI/UX 提示詞模板集 (7 大類別) | JakobStadler |
| **interface-design** | 設計記憶系統，確保元件風格一致 | Dammyjay93 |
| **ui-ux-pro-max** | 67 種 UI 風格、96 色彩方案、56 字型配對 | nextlevelbuilder |
| **claude-designer** | Jobs + Rams 設計理念，三階段工作流 | joeseesun |

#### 寫作風格

| Skill | 描述 | 來源 |
|-------|------|------|
| **humanizer-zh-tw** | 去除 AI 寫作痕跡 (強制) | kevintsai1202 |

#### Neon Database

| Skill | 描述 |
|-------|------|
| **neon-ai-rules** | 完整 Neon 規則 + .mdc 文件 (CLAUDE.md) |
| **neon-skills/** | 6 個獨立 skills (drizzle, serverless, toolkit, auth, js, docs) |

## 安裝方式

### 方法一：使用安裝腳本（推薦）

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法二：手動複製

```bash
# 複製到 Claude Code skills 目錄
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### 方法三：Symlink（開發用）

```bash
./scripts/link.sh
```

## 使用方式

安裝後，在 Claude Code 中可以透過指令觸發：

```bash
# 自建 Skills
/angular-primeng       # Angular + PrimeNG 開發規範
/fastapi-patterns      # FastAPI 後端開發規範
/openspec              # OpenSpec 規格驅動開發

# 程式碼品質 (everything-claude-code)
/security-reviewer     # 安全漏洞檢測
/build-error-resolver  # 建構錯誤修復
/refactor-cleaner      # 死代碼清理

# Vercel Labs
/react-best-practices  # React/Next.js 效能優化
/agent-browser         # 瀏覽器自動化
/web-design-guidelines # UI 審查

# UI/UX 設計
/ux-designer           # 專業 UI/UX 設計指導
/interface-design      # 設計記憶系統
/ui-ux-pro-max         # 67 種 UI 風格 + 96 色彩方案
/claude-designer       # Jobs + Rams 設計理念
# ui-agents            # 提示詞模板集（參考用）

# Neon Database
/neon-drizzle          # Drizzle ORM 設定
/neon-serverless       # 無伺服器連線
/neon-auth             # 驗證整合
```

## 目錄結構

```
dash-skills/
├── skills/                      # 自建 Skills (6)
│   ├── angular-primeng/
│   ├── fastapi-patterns/
│   ├── openspec/
│   ├── security-reviewer/       # 安全審查 (everything-claude-code)
│   ├── build-error-resolver/    # 建構錯誤修復 (everything-claude-code)
│   └── refactor-cleaner/        # 重構清理 (everything-claude-code)
├── external/                    # 外部收錄 (10 來源, 17 skills)
│   ├── react-best-practices/    # Vercel Labs
│   ├── agent-browser/           # Vercel Labs
│   ├── web-design-guidelines/   # Vercel Labs
│   ├── ux-designer/             # bencium (UI/UX 設計)
│   ├── ui-agents/               # JakobStadler (提示詞模板)
│   ├── interface-design/        # Dammyjay93 (設計記憶系統)
│   ├── ui-ux-pro-max/           # nextlevelbuilder (67 風格)
│   ├── claude-designer/         # joeseesun (Jobs 設計)
│   ├── humanizer-zh-tw/         # kevintsai1202 (去除 AI 痕跡) [強制]
│   ├── neon-ai-rules/           # Neon Database (完整規則 + .mdc)
│   └── neon-skills/             # Neon Database (6 skills)
│       ├── neon-drizzle/
│       ├── neon-serverless/
│       ├── neon-toolkit/
│       ├── neon-auth/
│       ├── neon-js/
│       └── add-neon-docs/
├── scripts/
│   ├── install.sh               # 安裝全部
│   ├── link.sh                  # Symlink
│   ├── sync.sh                  # 同步自建
│   ├── update-external.sh       # 同步外部
│   └── hooks/                   # Hook 腳本 (everything-claude-code)
│       ├── hooks-template.json  # Hooks 設定範本
│       ├── session-start.sh     # 載入先前工作階段
│       ├── session-end.sh       # 保存工作階段狀態
│       └── pre-compact.sh       # 壓縮前保存狀態
└── openspec/                    # OpenSpec 規格文件
    ├── specs/
    └── changes/
```

## 同步外部 Skills

### 自動同步（推薦）

將以下內容加入 `~/.zshrc`，每天第一次開啟 terminal 時自動同步：

```bash
source ~/Documents/github/dash-skills/scripts/auto-update.sh
```

自動同步功能：
- 每日自動從官方來源更新外部 skills
- 偵測到變更時自動 commit 並 push 到 GitHub
- 透過 `.last-update` 檔案確保每天只執行一次

### 手動同步

```bash
# 更新全部
./scripts/update-external.sh

# 列出可用的
./scripts/update-external.sh --list

# 更新指定的
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh neon-skills
```

## 技術棧總覽

| 層級 | 技術選擇 |
|------|---------|
| 前端（企業） | Angular 21 + PrimeNG |
| 前端（一般） | Vite + Vue 3 + Shoelace |
| 後端 | FastAPI + SQLModel |
| 資料庫 | Neon PostgreSQL |
| 前端部署 | Vercel |
| 後端部署 | Render |

## 授權

- 自建 Skills：MIT License
- 外部 Skills：依各來源授權

## 作者

Dash

## 致謝

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser, web-design-guidelines
- [Neon Database](https://github.com/neondatabase) - neon-skills
- [bencium](https://github.com/bencium) - ux-designer (design-skill)
- [JakobStadler](https://github.com/JakobStadler) - ui-agents (claude-code-ui-agents)
- [affaan-m](https://github.com/affaan-m) - everything-claude-code (security-reviewer, build-error-resolver, refactor-cleaner, hooks)
- [Dammyjay93](https://github.com/Dammyjay93) - interface-design (設計記憶系統)
- [nextlevelbuilder](https://github.com/nextlevelbuilder) - ui-ux-pro-max (67 種 UI 風格)
- [joeseesun](https://github.com/joeseesun) - claude-designer (Jobs + Rams 設計理念)
- [kevintsai1202](https://github.com/kevintsai1202) - humanizer-zh-tw (去除 AI 寫作痕跡)
