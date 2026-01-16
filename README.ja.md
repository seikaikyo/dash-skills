# Dash Skills

**Claude Code カスタムスキル集**

[English](./README.en.md) | 日本語 | [正體中文](./README.md)

## 概要

このリポジトリは、Claude Code 用に作成したカスタムスキルを一元管理しています。スキルは Claude Code の拡張機能で、AI アシスタントが特定の技術分野でより正確なガイダンスを提供できるようにします。

## 含まれるスキル

| スキル | 説明 | 用途 |
|--------|------|------|
| **angular-primeng** | Angular 21 + PrimeNG エンタープライズアプリ開発ガイドライン | MES、ERP、管理画面 |
| **vue-daisyui** | Vue 3 CDN + DaisyUI 高速プロトタイピング | POC、デモ、社内ツール |
| **fastapi-patterns** | FastAPI + SQLModel + Neon バックエンド開発 | Render にデプロイする API サービス |

## インストール方法

### 方法1：インストールスクリプト（推奨）

```bash
git clone https://github.com/anthropics/dash-skills.git
cd dash-skills
./scripts/install.sh
```

### 方法2：手動コピー

```bash
# Claude Code スキルディレクトリにコピー
cp -r skills/* ~/.claude/skills/
```

### 方法3：シンボリックリンク（開発用）

```bash
# 同期しやすいようにシンボリックリンクを作成
./scripts/link.sh
```

## 使い方

インストール後、Claude Code でコマンドを使ってスキルを呼び出せます：

```
/angular-primeng  - Angular + PrimeNG 開発ガイドラインを読み込む
/vue-daisyui      - Vue + DaisyUI 高速プロトタイピングガイドラインを読み込む
/fastapi-patterns - FastAPI バックエンド開発ガイドラインを読み込む
```

Claude Code は、プロジェクトタイプに基づいて適切なスキルを自動的に提案することもあります。

## ディレクトリ構造

```
dash-skills/
├── README.md              # ドキュメント（繁体字中国語）
├── README.en.md           # ドキュメント（英語）
├── README.ja.md           # ドキュメント（日本語）
├── scripts/
│   ├── install.sh         # インストールスクリプト
│   ├── link.sh            # シンボリックリンクスクリプト
│   └── sync.sh            # 同期スクリプト
└── skills/
    ├── angular-primeng/
    │   └── SKILL.md
    ├── vue-daisyui/
    │   └── SKILL.md
    └── fastapi-patterns/
        └── SKILL.md
```

## スキルフォーマット

各スキルには以下の形式の `SKILL.md` ファイルが含まれています：

```yaml
---
name: skill-name
description: スキルの簡単な説明
source: custom
updated: YYYY-MM-DD
---

# スキルタイトル

## 用途
...

## 核心原則
...
```

## 新しいスキルの追加

1. `skills/` 配下に新しいディレクトリを作成
2. `SKILL.md` ファイルを作成
3. `./scripts/sync.sh` を実行して `~/.claude/skills/` に同期

## 更新の同期

リポジトリ内のスキルを更新した後：

```bash
git pull
./scripts/sync.sh
```

## 技術スタック概要

これらのスキルは、私の技術スタックに基づいて設計されています：

| レイヤー | 技術 |
|----------|------|
| フロントエンド（エンタープライズ） | Angular 21 + PrimeNG |
| フロントエンド（プロトタイプ） | Vue 3 CDN + DaisyUI |
| バックエンド | FastAPI + SQLModel |
| データベース | Neon PostgreSQL |
| フロントエンドデプロイ | Vercel |
| バックエンドデプロイ | Render |

## ライセンス

MIT License

## 作者

Dash
