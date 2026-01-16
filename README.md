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
| **vue-daisyui** | Vue 3 CDN + DaisyUI 快速原型開發 | POC、Demo、內部工具 |
| **fastapi-patterns** | FastAPI + SQLModel + Neon 後端開發 | Render 部署的 API 服務 |

### 外部收錄 (`external/`)

#### Vercel Labs

| Skill | 描述 | 規則數 |
|-------|------|--------|
| **react-best-practices** | React/Next.js 效能優化指南 | 40+ |
| **agent-browser** | 瀏覽器自動化工具 | 200+ 指令 |
| **web-design-guidelines** | UI 審查規則 (a11y, UX, 效能) | 80+ |

#### Neon Database (`neon-skills/`)

| Skill | 描述 |
|-------|------|
| **neon-drizzle** | Drizzle ORM 整合設定 |
| **neon-serverless** | 無伺服器連線設定 |
| **neon-toolkit** | 暫時 DB 管理 (測試/CI) |
| **neon-auth** | 驗證整合 |
| **neon-js** | JS SDK 設定 |
| **add-neon-docs** | 文檔安裝 |

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
/vue-daisyui           # Vue + DaisyUI 快速原型規範
/fastapi-patterns      # FastAPI 後端開發規範

# Vercel Labs
/react-best-practices  # React/Next.js 效能優化
/agent-browser         # 瀏覽器自動化
/web-design-guidelines # UI 審查

# Neon Database
/neon-drizzle          # Drizzle ORM 設定
/neon-serverless       # 無伺服器連線
/neon-auth             # 驗證整合
```

## 目錄結構

```
dash-skills/
├── skills/                      # 自建 Skills (3)
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
├── external/                    # 外部收錄 (4 來源, 9 skills)
│   ├── react-best-practices/    # Vercel Labs
│   ├── agent-browser/           # Vercel Labs
│   ├── web-design-guidelines/   # Vercel Labs
│   └── neon-skills/             # Neon Database (6 skills)
│       ├── neon-drizzle/
│       ├── neon-serverless/
│       ├── neon-toolkit/
│       ├── neon-auth/
│       ├── neon-js/
│       └── add-neon-docs/
└── scripts/
    ├── install.sh               # 安裝全部
    ├── link.sh                  # Symlink
    ├── sync.sh                  # 同步自建
    └── update-external.sh       # 同步外部
```

## 同步外部 Skills

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
| 前端（原型） | Vue 3 CDN + DaisyUI |
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
