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

| スキル | ソース | 説明 |
|--------|--------|------|
| **react-best-practices** | [Vercel Labs](https://github.com/vercel-labs/agent-skills) | React/Next.js パフォーマンスガイド (40+ ルール) |
| **agent-browser** | [Vercel Labs](https://github.com/vercel-labs/agent-browser) | ブラウザ自動化 (200+ コマンド) |

## インストール方法

### 方法1：インストールスクリプト（推奨）

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法2：手動コピー

```bash
# Claude Code スキルディレクトリにコピー
cp -r skills/* ~/.claude/skills/
cp -r external/* ~/.claude/skills/
```

### 方法3：シンボリックリンク（開発用）

```bash
# 同期しやすいようにシンボリックリンクを作成
./scripts/link.sh
```

## 使い方

インストール後、Claude Code でコマンドを使ってスキルを呼び出せます：

```
# 自作スキル
/angular-primeng  - Angular + PrimeNG ガイドラインを読み込む
/vue-daisyui      - Vue + DaisyUI プロトタイピングガイドラインを読み込む
/fastapi-patterns - FastAPI バックエンドガイドラインを読み込む

# 外部スキル
/react-best-practices - React/Next.js パフォーマンスガイドを読み込む
/agent-browser        - ブラウザ自動化ツールを読み込む
```

## ディレクトリ構造

```
dash-skills/
├── README.md              # ドキュメント（繁体字中国語）
├── README.en.md           # ドキュメント（英語）
├── README.ja.md           # ドキュメント（日本語）
├── scripts/
│   ├── install.sh         # インストールスクリプト
│   ├── link.sh            # シンボリックリンクスクリプト
│   ├── sync.sh            # 同期スクリプト（自作）
│   └── update-external.sh # 同期スクリプト（外部）
├── skills/                # 自作スキル
│   ├── angular-primeng/
│   ├── vue-daisyui/
│   └── fastapi-patterns/
└── external/              # 外部スキル
    ├── react-best-practices/
    └── agent-browser/
```

## 外部スキルの同期

外部スキルは公式ソースから更新できます：

```bash
# すべての外部スキルを更新
./scripts/update-external.sh

# 特定のスキルを更新
./scripts/update-external.sh react-best-practices
./scripts/update-external.sh agent-browser
```

## スキルフォーマット

各スキルには `SKILL.md` ファイルが含まれています：

```yaml
---
name: skill-name
description: 簡単な説明
source: custom | URL
updated: YYYY-MM-DD
---

# スキルタイトル
...
```

## スキルの追加

### 自作スキルの追加

1. `skills/` 配下に新しいディレクトリを作成
2. `SKILL.md` ファイルを作成
3. `./scripts/sync.sh` を実行して `~/.claude/skills/` に同期

### 外部スキルの追加

1. `external/` 配下に新しいディレクトリを作成
2. スキルファイルをコピー
3. `scripts/update-external.sh` に同期関数を追加
4. インストールスクリプトを実行

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

- [Vercel Labs](https://github.com/vercel-labs) - react-best-practices, agent-browser
