# Dash Skills

**Claude Code スキル集**

[English](./README.en.md) | **日本語** | [正體中文](./README.md)

## 概要

Claude Code のスキルを一元管理 -- 自作の技術スタック規範 + 厳選された外部スキル、毎日自動同期。

## 収録スキル

> 自作 16 個 (`skills/`) + 外部収録 32 個 (`external/`)。外部スキルは毎日上流から自動同期。

### 自作 (`skills/`)

| スキル | 説明 |
|--------|------|
| **angular-primeng** | Angular 21 + PrimeNG 企業アプリ開発規範 (MES / ERP / 管理画面) |
| **fastapi-patterns** | FastAPI + SQLModel + Neon バックエンド規範 |
| **openspec** | 仕様駆動開発 (SDD) ワークフロー |
| **security-reviewer** | 脆弱性検出と修復、OWASP Top 10:2025・Agentic Applications 2026・GenAI LLM Top 10 2026 に対応付け |
| **build-error-resolver** | ビルド・TypeScript エラー即修復 |
| **refactor-cleaner** | 不使用コード整理とリファクタ統合 |
| **architecture-audit** | ドキュメントと実コード構造の差分監査 (CLAUDE.md) |
| **cis-design-system** | CIS 企業アイデンティティ設計規範 |
| **quality-gate** | フロントエンド品質ゲート (SEO / a11y / 性能 / UI-UX) |
| **doubt-driven-development** | 非自明な意思決定への新規コンテキスト敵対レビュー (tGD より改作, Apache-2.0) |
| **interview-me** | 要件不明時の意図抽出インタビュー (tGD より改作, Apache-2.0) |
| **sketch** | 使い捨て HTML モックアップ比較、2〜3 のデザイン方針バリアント (tGD より改作, Apache-2.0) |
| **security-scan** | 依存脆弱性・シークレット・SAST の三層スキャン、OWASP Top 10:2025 に対応付け |
| **security-radar** | セキュリティパッケージレーダー：毎日自動スキャンし「有効 / 人気 / 自身が安全」なセキュリティツールを収録、OWASP Top 10:2025・Agentic Applications 2026・LLM Top 10 2026 の 3 つのカバレッジ行列付き |
| **humanizer-zh-tw** | 中国語 AI 文体の痕跡を除去する書き換えツール (強制適用) |
| **humanizer-en** | 英語 AI 文体の痕跡を除去する書き換えツール |

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
| **web-design-guidelines** | UI コードレビュー (a11y / UX / 性能) | vercel-labs/agent-skills |
| **canvas-design** | デザイン哲学で PNG / PDF ビジュアル作成 | anthropics/skills |
| **brand-guidelines** | Anthropic 公式ブランドカラーとフォント適用 | anthropics/skills |
| **theme-factory** | テーマで artifact をスタイリング (10 プリセット) | anthropics/skills |
| **web-artifacts-builder** | 複数コンポーネントの claude.ai HTML artifact 構築 | anthropics/skills |
| **algorithmic-art** | p5.js でアルゴリズムアート | anthropics/skills |

### テスト

| スキル | 説明 | ソース |
|--------|------|--------|
| **webapp-testing** | Playwright でローカル web アプリをテスト | anthropics/skills |
| **webapp-uat** | ブラウザ全体 UAT (console / network / a11y / i18n) | tsilverberg/webapp-uat |

### セキュリティ / コンプライアンス

| スキル | 説明 | ソース |
|--------|------|--------|
| **trailofbits-security** | セキュリティ分析プラグイン (CodeQL / Semgrep) | trailofbits/skills |
| **trailofbits-skills-curated** | Trail of Bits 審査済みプラグイン | trailofbits/skills-curated |
| **sentry-security-review** | Sentry 規約コミット + セキュリティレビュー | getsentry/skills |
| **cloudflare-security-audit** | マルチエージェント編成型ペネトレーション監査 (偵察 / 攻撃クラス / 検証レポート) | cloudflare/security-audit-skill |

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
| **doc-coauthoring** | 構造化ドキュメント共同執筆 | anthropics/skills |
| **internal-comms** | 社内コミュニケーション文書 (状況報告 / 経営層向け) | anthropics/skills |

### 動画 / アニメーション

| スキル | 説明 | ソース |
|--------|------|--------|
| **slack-gif-creator** | Slack 最適化アニメ GIF | anthropics/skills |

### データベース

| スキル | 説明 | ソース |
|--------|------|--------|
| **neon-skills** | Neon serverless ドライバ設定 (6 サブ skill) | neondatabase/ai-rules |

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

launchd で毎日 06:00 にバックグラウンド実行、ログは `~/Library/Logs/dash-skills-auto-update.log`：

```bash
cp scripts/launchd/com.dash.skills-auto-update.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.dash.skills-auto-update.plist
```

当日の実行が未完了なら terminal を開いた時に再実行させるため、`~/.zshrc` に追加（すぐ戻る）：

```bash
[ "$(cat ~/Documents/github/dash-skills/.last-update 2>/dev/null)" = "$(date +%Y-%m-%d)" ] || launchctl kickstart gui/$(id -u)/com.dash.skills-auto-update 2>/dev/null
```

毎日自動：SKILL.md 更新、agent-browser CLI バージョン確認、自動 commit + push。

## 更新履歴

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
