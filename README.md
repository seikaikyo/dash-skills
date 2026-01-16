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

| Skill | 來源 | 描述 |
|-------|------|------|
| **react-best-practices** | [Vercel Labs](https://github.com/vercel-labs/agent-skills) | React/Next.js 效能優化指南 (40+ 規則) |
| **agent-browser** | [Vercel Labs](https://github.com/vercel-labs/agent-browser) | 瀏覽器自動化 (200+ 操作指令) |

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
# 建立符號連結，方便同步更新
./scripts/link.sh
```

## 使用方式

安裝後，在 Claude Code 中可以透過指令觸發：

```
# 自建 Skills
/angular-primeng  - 載入 Angular + PrimeNG 開發規範
/vue-daisyui      - 載入 Vue + DaisyUI 快速原型規範
/fastapi-patterns - 載入 FastAPI 後端開發規範

# 外部 Skills
/react-best-practices - 載入 React/Next.js 效能優化指南
/agent-browser        - 載入瀏覽器自動化工具
```

## 目錄結構

```
dash-skills/
├── README.md              # 說明文件（正體中文）
├── README.en.md           # 說明文件（英文）
├── README.ja.md           # 說明文件（日文）
├── scripts/
│   ├── install.sh         # 安裝腳本
│   ├── link.sh            # Symlink 腳本
│   ├── sync.sh            # 同步腳本（自建）
│   └── update-external.sh # 同步腳本（外部）
├── skills/                # 自建 Skills
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
└── external/              # 外部收錄 Skills
    ├── react-best-practices/
    └── agent-browser/
```

## 同步外部 Skills

外部 Skills 可以從官方來源更新：

```bash
# 更新全部外部 skills
./scripts/update-external.sh

# 更新指定的 skill
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh agent-browser
```

## Skill 規格

每個 Skill 包含一個 `SKILL.md` 檔案，格式如下：

```yaml
---
name: skill-name
description: Skill 的簡短描述
source: custom | URL
updated: YYYY-MM-DD
---

# Skill 標題
...
```

## 新增 Skill

### 新增自建 Skill

1. 在 `skills/` 下建立新目錄
2. 建立 `SKILL.md` 檔案
3. 執行 `./scripts/sync.sh` 同步到 `~/.claude/skills/`

### 收錄外部 Skill

1. 在 `external/` 下建立新目錄
2. 複製 Skill 檔案
3. 在 `scripts/update-external.sh` 新增同步函數
4. 執行安裝腳本

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

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser
