# Security Radar — 收錄套件清單

評估標準見 [SKILL.md](./SKILL.md)。狀態圖例：✅ 無未修 CVE｜⚠️ 有疑慮｜淘汰 不建議使用。OWASP 欄為 [OWASP Top 10:2025](https://owasp.org/Top10/2025/) 代碼，對照表與涵蓋矩陣見文末。

| 套件 | 生態 | 用途 | OWASP 2025 | 熱門度 | 安全狀態 | 收錄日期 | 備註 |
|------|------|------|------------|--------|----------|----------|------|
| [osv-scanner](https://github.com/google/osv-scanner) | Go（CLI，跨生態） | 依賴漏洞掃描：以 osv.dev 資料庫掃 `package-lock.json` / `go.mod` / `requirements.txt` 等 11+ 生態 lockfile，一支工具覆蓋 npm+Go+Python 全棧 | A03 | 10.9k ★；v2.5.1（2026-08-17），活躍 | ✅ GitHub Advisory 無自身公告 | 2026-08-31 | Google 維護；支援容器映像掃描與 CI action，適合接進 Vercel/Render 前置 CI |
| [trivy](https://github.com/aquasecurity/trivy) | Go（CLI，跨生態） | 綜合掃描：依賴 CVE、容器映像、IaC 錯誤設定、secrets、license，一站式 CI 安全閘門 | A02、A03 | 37.7k ★；v0.74.0（2026-08-14），高度活躍 | ✅ 歷史 CVE 均已修補（含 [CVE-2026-55092](https://github.com/advisories/GHSA-mcj4-mphf-j9ff) 高危路徑遍歷，0.71.1 已修；使用 ≥0.71.1） | 2026-08-31 | Aqua Security 維護；功能比 osv-scanner 廣但較重，適合完整 pipeline |
| [scorecard](https://github.com/ossf/scorecard) | Go（CLI / GitHub Action） | 供應鏈健康評分：對依賴的上游 repo 跑 24+ 項安全檢查（branch protection、code review、pinned deps），選型前評估依賴可信度 | A03、A08 | 5.7k ★；OpenSSF 官方，持續開發（3.1k commits） | ✅ GitHub Advisory 無自身公告；release 具 SLSA L3 provenance | 2026-08-31 | 用於評估第三方依賴與本 radar 自身查證流程 |
| [lockfile-lint](https://github.com/lirantal/lockfile-lint) | npm | Lockfile 供應鏈防護：驗證 `package-lock.json` / `yarn.lock` 的 resolved URL 只指向可信 registry，阻擋 lockfile 注入攻擊 | A03、A08 | 868 ★；週下載約 29.9 萬（[Snyk](https://snyk.io/advisor/npm-package/lockfile-lint)），維護中 | ✅ [CVE-2025-4759](https://github.com/advisories/GHSA-7cfr-5cjf-32p4)（中危，URL 驗證繞過）已於 lockfile-lint-api 5.9.2 修補；使用 ≥5.9.2 | 2026-08-31 | Liran Tal（Snyk）維護；輕量，適合 Nuxt 專案 pre-commit / CI 一行接入 |
| [nuxt-security](https://github.com/Baroshem/nuxt-security) | npm（Nuxt module） | 應用層防護：一個 module 帶入 OWASP 安全 headers、CSP（含 SSG）、rate limiting、請求大小限制、XSS 驗證、CSRF | A01、A02、A05 | 979 ★；週下載約 11.1 萬，v2.5.1，支援 Nuxt 3/4 | ✅ GitHub Advisory 無自身公告 | 2026-09-06 | Nuxt 官方 modules 目錄收錄；對本技術棧是最低成本的整段防護，建議直接裝 |
| [jose](https://github.com/panva/jose) | npm | JWT/JWS/JWE/JWKS 標準實作：驗 Logto JWT 與 JWKS 拉取的底層庫，零依賴、支援 Node/Edge/Workers | A04、A07 | 7.8k ★；v6.2.12，高度活躍 | ✅ 歷史公告（2021/2022/2024，中危）均已修補；[CVE-2025-45767](https://github.com/advisories/GHSA-m523-xm42-q7ff) 為未評審且有爭議的批量報告，維護者已於 [discussion #813](https://github.com/panva/jose/discussions/813) 反駁，無受影響版本 | 2026-09-06 | panva 維護（同時是 oauth4webapi 作者）；Nuxt server 端驗 Logto token 首選 |
| [golang-jwt/jwt](https://github.com/golang-jwt/jwt) | Go | Go 的 JWT 解析/驗證/簽發標準庫（RFC 7519），社群接手 dgrijalva/jwt-go 的官方後繼 | A04、A07 | 9.2k ★；v5.3.1，活躍 | ✅ [CVE-2025-30204](https://github.com/advisories/GHSA-mh63-6h87-95cp)（高危，ParseUnverified 記憶體放大）已於 5.2.2 修補；使用 v5 ≥5.2.2，勿用無修補的 v3 | 2026-09-06 | Go 後端驗 Logto JWT 用；搭配官方 JWKS extension |
| [PyJWT](https://github.com/jpadilla/pyjwt) | Python (pip) | Python 的 JWT 編解碼標準庫（RFC 7519），FastAPI 生態最常用的 token 驗證底層 | A04、A07 | 5.7k ★；v2.13.0，活躍 | ✅ 2026-06 批次 5 筆公告（含高危 [GHSA-752w-5fwx-jx9f](https://github.com/jpadilla/pyjwt/security/advisories/GHSA-752w-5fwx-jx9f) crit header 未驗證）已於 2.12.0–2.13.0 修補；使用 ≥2.13.0 | 2026-09-06 | FastAPI 驗 Logto JWT 用；PyJWKClient 的 SSRF/DoS 修補也在此批，舊版務必升級 |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Go（CLI，跨生態） | Secrets 偵測：以 regex + entropy 掃 git 歷史與工作目錄中的金鑰/token，支援 pre-commit、GitHub Action、SARIF 輸出 | A02、A07 | 29.1k ★；v8.30.1，secrets 掃描最高人氣 | ✅ [CVE-2026-63728](https://github.com/advisories/GHSA-mmh4-9cvr-w4cj)（高危，範本注入，未評審）已於 8.30.1 修補，即最新版；使用 ≥8.30.1 | 2026-09-07 | 維護者宣告 feature complete，後續僅安全修補並轉向後繼專案 Betterleaks，選用時留意後繼動向 |
| [trufflehog](https://github.com/trufflesecurity/trufflehog) | Go（CLI，跨生態） | Secrets 偵測 + 驗證：800+ 種金鑰型別可主動打 API 驗證是否仍有效，支援 git/GitHub/S3/Docker 等來源 | A02、A07 | 27.7k ★；v3.97.4，高度活躍（幾乎每週出版） | ✅ [CVE-2025-41390](https://github.com/advisories/GHSA-px2j-m3gx-wpq5)（高危，惡意 repo 的 fsmonitor 設定致任意程式碼執行，[TALOS-2025-2243](https://talosintelligence.com/vulnerability_reports/TALOS-2025-2243)）影響 ≤3.90.2，升級最新版即修補 | 2026-09-07 | 「驗證金鑰是否還活著」是它相對 gitleaks 的獨特價值；注意授權為 AGPL-3.0（CLI 掃描使用不受影響，勿嵌入產品） |
| [secretlint](https://github.com/secretlint/secretlint) | npm | Secrets 偵測（npm 原生）：pluggable lint 架構，30+ 平台規則包，錯誤訊息預設遮蔽金鑰，適合 husky/lint-staged 流程 | A02、A07 | 1.4k ★；1.9k commits，持續維護 | ✅ GitHub Advisory 無自身公告 | 2026-09-07 | 對 Nuxt 專案整合成本最低（npm 裝了就進 lint pipeline）；規模較小，適合與 gitleaks 在 CI 雙保險 |
| [semgrep](https://github.com/semgrep/semgrep) | Python (pip)（CLI，跨語言） | SAST：語意層級的規則式靜態分析，支援 30+ 語言（TS/Go/Python 皆涵蓋），可用社群規則庫或自寫規則，程式碼預設不上傳 | A01、A04、A05、A10 | 16.5k ★；10k+ commits，高度活躍 | ✅ GitHub Advisory 無核心套件公告（僅第三方包裝 mcp-server-semgrep 有一筆中危，與本體無關） | 2026-09-08 | 一支工具覆蓋全技術棧的 SAST 首選；注意 LGPL-2.1 授權與商業平台分層，CLI 掃描使用不受影響 |
| [gosec](https://github.com/securego/gosec) | Go（CLI / GitHub Action） | Go 專用 SAST：掃 AST/SSA 找硬編碼憑證、SQL 注入、弱加密等，內建 taint 分析，輸出 SARIF 進 GitHub code scanning | A04、A05、A10 | 8.9k ★；v2.29.0（2026-08-26），活躍 | ✅ GitHub Advisory 無自身公告 | 2026-09-08 | Go 後端 CI 標配，與 semgrep 互補（gosec 規則更貼 Go 慣用漏洞型態） |
| [bandit](https://github.com/PyCQA/bandit) | Python (pip) | Python 專用 SAST：AST 掃描常見安全問題（assert、eval、subprocess shell、弱雜湊等），PyCQA 官方維護 | A04、A05 | 8.3k ★；持續維護（1.5k commits） | ✅ GitHub Advisory 無自身公告（同名 Erlang 套件的公告勿混淆） | 2026-09-08 | FastAPI 專案 CI 輕量首選；誤報需人工分流，建議搭 baseline |
| [eslint-plugin-security](https://github.com/eslint-community/eslint-plugin-security) | npm | JS/TS SAST（lint 層）：15 條規則抓 eval 注入、非常值 fs 路徑、ReDoS、timing attack 等 Node 端安全熱點 | A01、A05 | 2.4k ★；v4.0.1（2026-06-12），eslint-community 維護 | ✅ GitHub Advisory 無自身公告 | 2026-09-08 | Nuxt server 端（nitro）適用；官方自述誤報偏多，當提示器用、勿當閘門 |

## OWASP Top 10:2025 涵蓋矩陣

最新正式版為 2025 版（2026-01 定稿）。相對 2021 版：SSRF 併入 A01；新增 A03 軟體供應鏈失效與 A10 例外狀況處理不當。

| 代碼 | 分類 | 已收錄工具 | 缺口 |
|------|------|------------|------|
| A01 | Broken Access Control（含 SSRF） | nuxt-security（CSRF/rate limit）、semgrep、eslint-plugin-security | 缺授權邏輯測試工具（DAST / 授權矩陣檢查） |
| A02 | Security Misconfiguration | nuxt-security、trivy（IaC）、gitleaks / trufflehog / secretlint | — |
| A03 | Software Supply Chain Failures | osv-scanner、trivy、scorecard、lockfile-lint | 缺 SBOM 產生與簽章驗證（syft / cosign 類） |
| A04 | Cryptographic Failures | jose、golang-jwt、PyJWT、semgrep、gosec、bandit | — |
| A05 | Injection | nuxt-security（CSP/XSS）、semgrep、gosec、bandit、eslint-plugin-security | 缺前端 HTML 淨化庫（DOMPurify 類）與 DAST |
| A06 | Insecure Design | — | 屬設計流程（威脅建模），非套件可解；可考慮收 threat-modeling 工具 |
| A07 | Authentication Failures | jose、golang-jwt、PyJWT、gitleaks / trufflehog / secretlint（硬編碼憑證） | 缺 rate limiting / 暴力破解防護（後端層） |
| A08 | Software or Data Integrity Failures | scorecard（SLSA）、lockfile-lint | 缺 artifact 簽章驗證（sigstore / cosign）與 CI 動作 pinning 檢查 |
| A09 | Security Logging and Alerting Failures | — | 非套件雷達範圍，由 daily-security-watch 與 Sentry 巡檢覆蓋 |
| A10 | Mishandling of Exceptional Conditions | semgrep、gosec（G104 錯誤未處理） | 缺 fuzzing（go-fuzz / atheris 類） |

缺口欄用來指引後續主題輪替：優先補 A08 簽章驗證、A05 前端淨化、A07 rate limiting、A10 fuzzing。
