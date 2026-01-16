# Dash Skills

**Claude Code カスタムスキル集**

[English](./README.en.md) | 日本語 | [正體中文](./README.md)

## 概要

このリポジトリは Claude Code のスキルを一元管理しています。自作の技術スタックガイドラインと、厳選された外部スキルが含まれています。

## 含まれるスキル

### 自作スキル (`skills/`)

| スキル | 説明 | 用途 |
|--------|------|------|
| **angular-primeng** | Angular 21 + PrimeNG エンタープライズアプリガイドライン | MES、ERP、管理画面 |
| **vue-daisyui** | Vue 3 CDN + DaisyUI 高速プロトタイピング | POC、デモ、社内ツール |
| **fastapi-patterns** | FastAPI + SQLModel + Neon バックエンド開発 | Render 上の API サービス |

### 外部スキル (`external/`)

#### Vercel Labs

| スキル | 説明 | ルール数 |
|--------|------|----------|
| **react-best-practices** | React/Next.js パフォーマンスガイド | 40+ |
| **agent-browser** | ブラウザ自動化 CLI | 200+ コマンド |
| **web-design-guidelines** | UI レビュールール (a11y, UX, パフォーマンス) | 80+ |

#### Neon Database (`neon-skills/`)

| スキル | 説明 |
|--------|------|
| **neon-drizzle** | Drizzle ORM 統合 |
| **neon-serverless** | サーバーレス接続設定 |
| **neon-toolkit** | 一時 DB 管理 (テスト/CI) |
| **neon-auth** | 認証統合 |
| **neon-js** | JS SDK 設定 |
| **add-neon-docs** | ドキュメントインストール |

## インストール方法

### 方法1：インストールスクリプト（推奨）

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法2：手動コピー

```bash
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### 方法3：シンボリックリンク（開発用）

```bash
./scripts/link.sh
```

## 使い方

インストール後、Claude Code でスキルを呼び出せます：

```bash
# 自作スキル
/angular-primeng       # Angular + PrimeNG ガイドライン
/vue-daisyui           # Vue + DaisyUI プロトタイピング
/fastapi-patterns      # FastAPI バックエンドガイドライン

# Vercel Labs
/react-best-practices  # React/Next.js パフォーマンス
/agent-browser         # ブラウザ自動化
/web-design-guidelines # UI レビュー

# Neon Database
/neon-drizzle          # Drizzle ORM 設定
/neon-serverless       # サーバーレス接続
/neon-auth             # 認証統合
```

## ディレクトリ構造

```
dash-skills/
├── skills/                      # 自作スキル (3)
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
├── external/                    # 外部スキル (4 ソース, 9 スキル)
│   ├── react-best-practices/    # Vercel Labs
│   ├── agent-browser/           # Vercel Labs
│   ├── web-design-guidelines/   # Vercel Labs
│   └── neon-skills/             # Neon Database (6 スキル)
│       ├── neon-drizzle/
│       ├── neon-serverless/
│       ├── neon-toolkit/
│       ├── neon-auth/
│       ├── neon-js/
│       └── add-neon-docs/
└── scripts/
    ├── install.sh
    ├── link.sh
    ├── sync.sh
    └── update-external.sh
```

## 外部スキルの同期

```bash
# すべて更新
./scripts/update-external.sh

# 利用可能なスキルを表示
./scripts/update-external.sh --list

# 特定のスキルを更新
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh neon-skills
```

## 技術スタック

| レイヤー | 技術 |
|----------|------|
| フロントエンド（エンタープライズ） | Angular 21 + PrimeNG |
| フロントエンド（プロトタイプ） | Vue 3 CDN + DaisyUI |
| バックエンド | FastAPI + SQLModel |
| データベース | Neon PostgreSQL |
| フロントエンドデプロイ | Vercel |
| バックエンドデプロイ | Render |

## ライセンス

- 自作スキル：MIT License
- 外部スキル：各ソースのライセンスに従う

## 作者

Dash

## 謝辞

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser, web-design-guidelines
- [Neon Database](https://github.com/neondatabase) - neon-skills
