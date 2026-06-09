# Dash Skills

**Claude Code スキル集**

[English](./README.en.md) | **日本語** | [正體中文](./README.md)

## 概要

Claude Code のスキルを一元管理 -- 自作の技術スタック規範 + 厳選された外部スキル、毎日自動同期。

## 収録スキル

> 自作 9 個 (`skills/`) + 外部収録 45 個 (`external/`)。外部スキルは毎日上流から自動同期。

### 自作 (`skills/`)

| スキル | 説明 |
|--------|------|
| **angular-primeng** | Angular 21 + PrimeNG 企業アプリ開発規範 (MES / ERP / 管理画面) |
| **fastapi-patterns** | FastAPI + SQLModel + Neon バックエンド規範 |
| **openspec** | 仕様駆動開発 (SDD) ワークフロー |
| **security-reviewer** | 脆弱性検出と修復 (OWASP Top 10) |
| **build-error-resolver** | ビルド・TypeScript エラー即修復 |
| **refactor-cleaner** | 不使用コード整理とリファクタ統合 |
| **architecture-audit** | ドキュメントと実コード構造の差分監査 (CLAUDE.md) |
| **cis-design-system** | CIS 企業アイデンティティ設計規範 |
| **quality-gate** | フロントエンド品質ゲート (SEO / a11y / 性能 / UI-UX) |

### 開発・デプロイ

| スキル | 説明 | ソース |
|--------|------|--------|
| **react-best-practices** | React / Next.js パフォーマンス最適化 | vercel-labs/agent-skills |
| **vercel-react-best-practices** | React / Next.js 最適化 (TSX レビュー版) | vercel-labs/agent-skills |
| **vercel-python** | Python プロジェクトの Vercel デプロイ診断・修復 | vercel-labs/agent-skills |
| **vercel-cost-optimization** | Vercel 請求分析とコスト最適化 | vercel-labs/agent-skills |
| **deploy-to-vercel** | アプリを Vercel にデプロイ | vercel-labs/agent-skills |
| **agent-browser** | ブラウザ自動化 CLI (200以上のコマンド) | vercel-labs/agent-browser |
| **mcp-builder** | 高品質な MCP サーバー構築 | anthropics/skills |
| **skill-creator** | skill の作成 / 改善 / 評価 | anthropics/skills |
| **claude-api** | Claude API 利用ガイド | anthropics/skills |

### UI/UX・デザイン

| スキル | 説明 | ソース |
|--------|------|--------|
| **frontend-design** | AI っぽさを排除したフロントエンドデザイン | anthropics/skills |
| **interface-design** | コンポーネント一貫性のデザイン記憶システム | Dammyjay93/interface-design |
| **ui-ux-pro-max** | 50以上の UI スタイル / 161 パレット / 57 フォントペア | nextlevelbuilder/ui-ux-pro-max-skill |
| **bencium-marketplace** | UX 監査 + タイポグラフィ + 革新的 UX | bencium/bencium-marketplace |
| **web-design-guidelines** | UI コードレビュー (a11y / UX / 性能) | vercel-labs/agent-skills |
| **canvas-design** | デザイン哲学で PNG / PDF ビジュアル作成 | anthropics/skills |
| **brand-guidelines** | Anthropic 公式ブランドカラーとフォント適用 | anthropics/skills |
| **theme-factory** | テーマで artifact をスタイリング (10 プリセット) | anthropics/skills |
| **web-artifacts-builder** | 複数コンポーネントの claude.ai HTML artifact 構築 | anthropics/skills |
| **algorithmic-art** | p5.js でアルゴリズムアート | anthropics/skills |

### アクセシビリティ

| スキル | 説明 | ソース |
|--------|------|--------|
| **accessibility-agents** | WCAG AA 強制 (80 エージェント + 25 コマンド) | Community-Access/accessibility-agents |

### テスト

| スキル | 説明 | ソース |
|--------|------|--------|
| **webapp-testing** | Playwright でローカル web アプリをテスト | anthropics/skills |
| **webapp-uat** | ブラウザ全体 UAT (console / network / a11y / i18n) | tsilverberg/webapp-uat |

### セキュリティ / コンプライアンス

| スキル | 説明 | ソース |
|--------|------|--------|
| **security-audit** | ホワイト / グレーボックスセキュリティ監査 (ISO 27001 対応) | afiqiqmal/claude-security-audit |
| **security-skills** | セキュリティ自動化 skill マーケットプレイス | eth0izzle/security-skills |
| **claude-code-owasp** | OWASP Top 10 コードセキュリティレビュー | agamm/claude-code-owasp |
| **ot-security-mcp** | IEC 62443 / NIST 800-82 OT セキュリティ MCP | Ansvar-Systems/ot-security-mcp |
| **trailofbits-security** | セキュリティ分析プラグイン (CodeQL / Semgrep) | trailofbits/skills |
| **trailofbits-skills-curated** | Trail of Bits 審査済みプラグイン | trailofbits/skills-curated |
| **sentry-security-review** | Sentry 規約コミット + セキュリティレビュー | getsentry/skills |
| **anthropic-cybersecurity-skills** | サイバーセキュリティ skill 集 | mukul975/Anthropic-Cybersecurity-Skills |

### ドキュメント処理

| スキル | 説明 | ソース |
|--------|------|--------|
| **docx** | Word 文書の作成 / 読取 / 編集 | anthropics/skills |
| **pdf** | PDF 処理 (読取 / 結合 / 抽出) | anthropics/skills |
| **pptx** | プレゼンの作成 / 編集 | anthropics/skills |
| **xlsx** | スプレッドシートの作成 / 編集 | anthropics/skills |

### ライティング・コンテンツ

| スキル | 説明 | ソース |
|--------|------|--------|
| **humanizer-zh-tw** | 中国語 AI 文体の痕跡除去 (強制適用) | kevintsai1202/Humanizer-zh-TW |
| **humanizer-en** | 英語 AI 文体の痕跡除去 | blader/humanizer |
| **content-research-writer** | リサーチ + 引用補助のコンテンツ作成 | ComposioHQ/awesome-claude-skills |
| **creative-writing-skills** | 架空世界観 / キャラ wiki 作成 | haowjy/creative-writing-skills |
| **paper-writer-skill** | 医学 / 科学論文の執筆ワークフロー | kgraph57/paper-writer-skill |
| **storytelling** | 製品価値と課題を繋ぐ物語構築 | gtmagents/gtm-agents |
| **doc-coauthoring** | 構造化ドキュメント共同執筆 | anthropics/skills |
| **internal-comms** | 社内コミュニケーション文書 (状況報告 / 経営層向け) | anthropics/skills |

### 動画 / アニメーション

| スキル | 説明 | ソース |
|--------|------|--------|
| **remotion-video-skill** | Remotion でプログラム的に動画生成 | wshuyi/remotion-video-skill |
| **slack-gif-creator** | Slack 最適化アニメ GIF | anthropics/skills |

### データベース

| スキル | 説明 | ソース |
|--------|------|--------|
| **neon-skills** | Neon serverless ドライバ設定 (6 サブ skill) | neondatabase/ai-rules |

### 削除済み

| スキル | 理由 |
|--------|------|
| ~~cisco-skill-scanner~~ | 同期停止 |
| ~~neon-ai-rules~~ | neon-skills に統合 |
| ~~ux-designer~~ | bencium/design-skill repo が消滅 |
| ~~ui-agents~~ | JakobStadler/claude-code-ui-agents repo が消滅 |
| ~~claude-designer~~ | joeseesun/claude-designer-skill repo が消滅 |

## pi.dev 設定 (`pi-agent/`)

Claude Code スキルに加え、本リポジトリは pi.dev コーディングエージェントの個人設定も収録(読み込みで即適用)。

| ファイル | 役割 |
|----------|------|
| `AGENTS.md` | 作業スタイルとエンジニアリング規範 |
| `APPEND_SYSTEM.md` | 中核の行動制約(機密境界 / 外部操作の確認 / 誠実 / 簡潔) |
| `extensions/guardrails.ts` | 危険な git / 機密ファイル / emoji のガード |
| `settings.fragment.json` | skills と extensions を指定 |

インストールと配置は [`pi-agent/README.md`](./pi-agent/README.md) を参照。

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

### 2026-06-09

- README 全面同期：skill 一覧を 22 から 54 に拡充（自作 9 + 外部 45）、外部 skill ごとに上流ソースを記載
- 消滅した項目を削除：cisco-skill-scanner、neon-ai-rules（neon-skills に統合）
- `pi-agent/` を追加：pi.dev コーディングエージェントの個人設定(AGENTS.md / APPEND_SYSTEM.md / guardrails extension / settings フラグメント)

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

## ソース

外部スキルは各オープンソースコミュニティ由来、ライセンスは各ソースに準拠。主なソース：

- [Anthropic](https://github.com/anthropics/skills) -- 公式 skills（ドキュメント処理 / デザイン / mcp-builder など）
- [Vercel Labs](https://github.com/vercel-labs) -- react-best-practices, agent-browser, web-design-guidelines, vercel シリーズ
- [Neon](https://github.com/neondatabase) -- neon-skills
- [Trail of Bits](https://github.com/trailofbits) -- セキュリティプラグイン
- ほか Dammyjay93, nextlevelbuilder, bencium, Community-Access, kevintsai1202, blader, haowjy, kgraph57, ComposioHQ, gtmagents, agamm, mukul975, eth0izzle, afiqiqmal, getsentry, Ansvar-Systems, tsilverberg, wshuyi など
