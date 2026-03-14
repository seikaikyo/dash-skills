# Dash Skills

**Claude Code Skills Collection**

[English](./README.en.md) | [日本語](./README.ja.md) | 正體中文

## 概述

集中管理 Claude Code 的 Skills -- 自建的技術棧規範 + 收錄的外部 Skills，搭配每日自動同步機制。

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

| Skill | 描述 |
|-------|------|
| **react-best-practices** | React/Next.js 效能優化指南 (40+ 規則) |
| **agent-browser** | 瀏覽器自動化 (200+ 指令) + CLI 工具自動更新 |
| **web-design-guidelines** | UI 審查規則 (a11y, UX, 效能, 80+ 規則) |

#### UI/UX 設計

| Skill | 描述 | 來源 | 狀態 |
|-------|------|------|------|
| **frontend-design** | 反 AI 罐頭風格的前端設計 (277K+ 安裝) | Anthropic 官方 | 活躍 |
| **interface-design** | 設計記憶系統，確保元件風格一致 | Dammyjay93 | 活躍 (3,973 stars) |
| **ui-ux-pro-max** | 67 種 UI 風格、96 色彩方案、56 字型配對 | nextlevelbuilder | 活躍 (41,258 stars) |
| **bencium-marketplace** | UX audit + typography + innovative UX | bencium | 活躍 |

#### Accessibility

| Skill | 描述 | 來源 | 狀態 |
|-------|------|------|------|
| **accessibility-agents** | 57 個 WCAG 2.2 AA 審查代理 | Community-Access | 活躍 (185 stars) |

#### 寫作風格

| Skill | 描述 | 來源 |
|-------|------|------|
| **humanizer-zh-tw** | 去除 AI 寫作痕跡 (強制套用) | kevintsai1202 |

#### Neon Database

| Skill | 描述 |
|-------|------|
| **neon-ai-rules** | 完整 Neon 規則 + .mdc 文件 |
| **neon-skills/** | 6 個獨立 skills (drizzle, serverless, toolkit, auth, js, docs) |

### 已移除

| Skill | 原因 |
|-------|------|
| ~~ux-designer~~ | bencium/design-skill repo 已不存在 |
| ~~ui-agents~~ | JakobStadler/claude-code-ui-agents repo 已不存在 |
| ~~claude-designer~~ | joeseesun/claude-designer-skill repo 已不存在 |

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

## 使用

安裝後在 Claude Code 中直接觸發：

```bash
# 自建
/angular-primeng       # Angular + PrimeNG
/fastapi-patterns      # FastAPI 後端
/openspec              # 規格驅動開發

# 程式碼品質
/security-reviewer     # 安全漏洞檢測
/build-error-resolver  # 建構錯誤修復
/refactor-cleaner      # 死代碼清理

# Vercel Labs
/agent-browser         # 瀏覽器自動化
/web-design-guidelines # UI 審查

# UI/UX 設計
/interface-design      # 設計記憶系統
/ui-ux-pro-max         # 67 種 UI 風格
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

### 2026-03-14
- 新增 frontend-design (Anthropic 官方)
- 新增 accessibility-agents (57 個 WCAG 2.2 agents)
- 新增 bencium-marketplace (UX audit + typography)
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

- [Vercel Labs](https://github.com/vercel-labs) -- react-best-practices, agent-browser, web-design-guidelines
- [Neon Database](https://github.com/neondatabase) -- neon-skills
- [affaan-m](https://github.com/affaan-m) -- everything-claude-code (security-reviewer, build-error-resolver, refactor-cleaner)
- [Dammyjay93](https://github.com/Dammyjay93) -- interface-design
- [nextlevelbuilder](https://github.com/nextlevelbuilder) -- ui-ux-pro-max
- [kevintsai1202](https://github.com/kevintsai1202) -- humanizer-zh-tw
