# Dash Skills

**Claude Code 自定義 Skills 集合**

[English](./README.en.md) | [日本語](./README.ja.md) | 正體中文

## 概述

這個 repo 集中管理我為 Claude Code 建立的自定義 Skills。Skills 是 Claude Code 的擴充功能，可以讓 AI 助手在特定技術領域提供更精準的指導。

## 包含的 Skills

| Skill | 描述 | 適用場景 |
|-------|------|---------|
| **angular-primeng** | Angular 21 + PrimeNG 企業應用開發規範 | MES、ERP、後台管理系統 |
| **vue-daisyui** | Vue 3 CDN + DaisyUI 快速原型開發 | POC、Demo、內部工具 |
| **fastapi-patterns** | FastAPI + SQLModel + Neon 後端開發 | Render 部署的 API 服務 |

## 安裝方式

### 方法一：使用安裝腳本（推薦）

```bash
git clone https://github.com/anthropics/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法二：手動複製

```bash
# 複製到 Claude Code skills 目錄
cp -r skills/* ~/.claude/skills/
```

### 方法三：Symlink（開發用）

```bash
# 建立符號連結，方便同步更新
./scripts/link.sh
```

## 使用方式

安裝後，在 Claude Code 中可以透過指令觸發：

```
/angular-primeng  - 載入 Angular + PrimeNG 開發規範
/vue-daisyui      - 載入 Vue + DaisyUI 快速原型規範
/fastapi-patterns - 載入 FastAPI 後端開發規範
```

或者 Claude Code 會根據你的專案類型自動建議適合的 Skill。

## 目錄結構

```
dash-skills/
├── README.md              # 說明文件（正體中文）
├── README.en.md           # 說明文件（英文）
├── README.ja.md           # 說明文件（日文）
├── scripts/
│   ├── install.sh         # 安裝腳本
│   ├── link.sh            # Symlink 腳本
│   └── sync.sh            # 同步腳本
└── skills/
    ├── angular-primeng/
    │   └── SKILL.md
    ├── vue-daisyui/
    │   └── SKILL.md
    └── fastapi-patterns/
        └── SKILL.md
```

## Skill 規格

每個 Skill 包含一個 `SKILL.md` 檔案，格式如下：

```yaml
---
name: skill-name
description: Skill 的簡短描述
source: custom
updated: YYYY-MM-DD
---

# Skill 標題

## 適用場景
...

## 核心原則
...
```

## 新增 Skill

1. 在 `skills/` 下建立新目錄
2. 建立 `SKILL.md` 檔案
3. 執行 `./scripts/sync.sh` 同步到 `~/.claude/skills/`

## 同步更新

當你更新了 repo 中的 skill 後：

```bash
git pull
./scripts/sync.sh
```

## 技術棧總覽

這些 Skills 是根據我的技術棧需求設計的：

| 層級 | 技術選擇 |
|------|---------|
| 前端（企業） | Angular 21 + PrimeNG |
| 前端（原型） | Vue 3 CDN + DaisyUI |
| 後端 | FastAPI + SQLModel |
| 資料庫 | Neon PostgreSQL |
| 前端部署 | Vercel |
| 後端部署 | Render |

## 授權

MIT License

## 作者

Dash
