# Dash Skills

**Claude Code スキル集**

[English](./README.en.md) | **日本語** | [正體中文](./README.md)

## 概要

Claude Code のスキルを一元管理 -- 自作の技術スタック規範 + 厳選された外部スキル、毎日自動同期。

## 収録スキル

### 自作 (`skills/`)

| スキル | 説明 | 用途 |
|--------|------|------|
| **angular-primeng** | Angular 21 + PrimeNG 企業アプリ規範 | MES、ERP、管理画面 |
| **fastapi-patterns** | FastAPI + SQLModel + Neon バックエンド | Render デプロイの API |
| **openspec** | 仕様駆動開発 (SDD) ワークフロー | 機能企画、変更管理 |
| **security-reviewer** | OWASP Top 10 脆弱性検出 | 認証、ユーザー入力、API |
| **build-error-resolver** | ビルド/TypeScript エラー修復 | ビルド失敗、型エラー |
| **refactor-cleaner** | 不使用コード検出・削除 | コード品質、依存関係整理 |

### 外部収録 (`external/`)

#### Vercel Labs
| スキル | 説明 |
|--------|------|
| **react-best-practices** | React/Next.js パフォーマンス最適化（40以上のルール） |
| **agent-browser** | ブラウザ自動化（200以上のコマンド）+ CLI 自動更新 |
| **web-design-guidelines** | UI 審査（a11y、UX、パフォーマンス、80以上のルール） |

#### UI/UX デザイン
| スキル | 説明 | ソース |
|--------|------|--------|
| **frontend-design** | AI っぽさを排除したフロントエンドデザイン | Anthropic 公式 |
| **interface-design** | デザイン記憶システム（コンポーネント一貫性） | Dammyjay93 |
| **ui-ux-pro-max** | 67 UI スタイル、96 カラーパレット、56 フォントペア | nextlevelbuilder |
| **bencium-marketplace** | UX 監査 + タイポグラフィ + 革新的 UX | bencium |

#### アクセシビリティ
| スキル | 説明 | ソース |
|--------|------|--------|
| **accessibility-agents** | 57 の WCAG 2.2 AA 監査エージェント | Community-Access |

#### セキュリティ / コンプライアンス
| スキル | 説明 | ソース |
|--------|------|--------|
| **security-audit** | ISO 27001:2022 対応、850以上のチェック項目 | afiqiqmal |
| **ot-security-mcp** | IEC 62443 / NIST 800-82 OT セキュリティ MCP | Ansvar-Systems |
| **trailofbits-security** | 35 プラグイン（CodeQL/Semgrep/変異分析） | Trail of Bits |
| **sentry-security-review** | 低誤検出率のセキュリティコードレビュー | Sentry |
| **cisco-skill-scanner** | スキルサプライチェーンセキュリティスキャナー | Cisco AI Defense |

#### 文章スタイル
| スキル | 説明 | ソース |
|--------|------|--------|
| **humanizer-zh-tw** | AI 文体の痕跡を除去（強制適用） | kevintsai1202 |

#### Neon Database
| スキル | 説明 |
|--------|------|
| **neon-ai-rules** | Neon 完全ルール + .mdc ファイル |
| **neon-skills/** | 6 スキル（drizzle, serverless, toolkit, auth, js, docs） |

## インストール

```bash
git clone https://github.com/seikaikyo/dash-skills.git
cd dash-skills
./scripts/install.sh
```

## 自動同期

`~/.zshrc` に追加：

```bash
source ~/Documents/github/dash-skills/scripts/auto-update.sh
```

毎日自動：SKILL.md 更新、agent-browser CLI バージョン確認、自動 commit + push。

## 更新履歴

### 2026-03-14
- セキュリティスキル 5 個追加（security-audit, ot-security-mcp, trailofbits, sentry, cisco）
- UI/UX スキル 3 個追加（frontend-design, accessibility-agents, bencium-marketplace）
- 消滅したリポジトリを削除（ux-designer, ui-agents, claude-designer）
- update-external.sh の git clone 失敗時クラッシュを修正
- agent-browser CLI npm 自動更新を追加

### 2026-01-16
- 初回リリース

## ライセンス

- 自作スキル：MIT License
- 外部スキル：各ソースのライセンスに準拠

## 作者

SeiKai Kyo
