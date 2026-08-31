---
name: security-scan
description: 用外部掃描工具對 repo 做相依漏洞、機密外洩、SAST 三層檢查，並把結果對回 OWASP Top 10:2025 分類。適用：面試或對外發布前的作品體檢、接手不熟的 repo、想確認自己的修正經得起獨立工具驗證。不適用：判斷認證邏輯對不對、權限有沒有寫錯這類要讀懂程式意圖的問題，那要人或 agent 讀碼。
source: 自建，2026-08-31 對照 OWASP Top 10:2025 與當前開源掃描工具現況建立
updated: 2026-08-31
---

# Security Scan（外部工具掃描）

## 這個 skill 解決什麼，不解決什麼

掃描器負責「窮舉比對」，人負責「讀懂意圖」。兩者抓到的東西不重疊，不要拿其中一個當另一個的替代品。

掃描器擅長：已知 CVE 的相依套件、金鑰字串、已知的危險 API 用法。逐 commit 逐 blob 窮舉這種事，人做不到同樣覆蓋率。

掃描器抓不到：端點忘了掛認證、認證中介層寫好但參數從沒傳進去所以是死碼、狀態機少了前置條件、RBAC 實作完整但零呼叫點、README 宣稱與實作不符。這些要讀懂程式在做什麼才看得見。

## 三層工具

| 層 | 工具 | 涵蓋 | 指令 |
|---|---|---|---|
| 相依（SCA） | osv-scanner | npm / Go modules / Python / 多生態，自動找子目錄 manifest | `osv-scanner scan source <dir>` |
| 相依（Python） | pip-audit | requirements.txt 精確比對 | `pip-audit -r requirements.txt` |
| 機密 | gitleaks | 完整 git 歷史逐 blob | `gitleaks git <dir> --report-path <out>.json` |
| SAST | semgrep | 危險 API 用法、OWASP 規則集 | `semgrep --config=p/owasp-top-ten <dir>` |

安裝：`brew install osv-scanner semgrep gitleaks`、`pip install pip-audit`。

Go 專案另可加 `govulncheck ./...`（比 osv-scanner 精確，只報實際可達的呼叫路徑）。

## 執行順序

1. **gitleaks 全歷史**先跑，因為機密外洩是唯一需要「立刻撤銷憑證」的類別，其他都可以排程修。
2. **osv-scanner** 掃相依。注意判讀：多數命中落在建置工具鏈（vite、postcss、esbuild、remotion），不是執行期程式碼，帳面數字難看但實際風險低。要區分就看該套件會不會進 bundle 或上線。
3. **semgrep** 跑 OWASP 規則集。零命中不代表沒問題，只代表沒有模式比對得出來的問題。

## 判讀紀律

- 掃描器回報乾淨，只代表它負責的那一類乾淨，不代表 repo 沒問題。報告要寫清楚覆蓋了什麼、沒覆蓋什麼。
- 命中要分「真實可利用」與「工具鏈噪音」，不要把總數當結論。範例值（`AKIAIOSFODNN7EXAMPLE`）與明確標示的 placeholder 不算。
- 相依漏洞的嚴重度看可達性：只在本機建置時用到的套件，跟跑在 production 執行期的套件不同級。

## 對回 OWASP Top 10:2025

2025 版（2026 年 1 月正式發布）有兩個新類別：軟體供應鏈失效、例外狀況處理不當；SSRF 併進 A01 權限控制失效。

| 類別 | 掃描器抓得到嗎 |
|---|---|
| A01 權限控制失效（含 SSRF） | 抓不到，要讀碼 |
| A02 加密失效 | 部分（semgrep 抓得到關閉 TLS 驗證這類寫法） |
| A03 注入 | 抓得到 |
| A04 不安全設計 | 抓不到 |
| A05 安全設定錯誤 | 部分 |
| A06 元件有已知漏洞 | osv-scanner 正面涵蓋 |
| A07 認證失效 | 抓不到 |
| A08 軟體與資料完整性 | 部分（供應鏈由 osv-scanner 涵蓋） |
| A09 記錄與監控失效 | 抓不到 |
| A10 例外狀況處理不當 | 部分 |

一半的類別掃描器碰不到，那半邊要派 agent 讀碼稽核。

## ISO 27001 與 SEMI E187 說明

兩者都**不是**程式碼掃描的對象，不要宣稱用工具「掃過合規」。

ISO 27001 是組織層的資訊安全管理系統標準，稽核對象是流程與文件，不是 repo。

SEMI E187 是晶圓廠設備的資安規範，涵蓋作業系統支援、網路安全、端點防護、資安監控四塊，稽核對象是實體設備。市面上的評估方案（CyCraft、PEER Group、Intertek）都是商業服務，沒有開源工具能對一個 git repo 判定 E187 合規。

寫對外文件時，正確的措辭是「參照 IEC 62443 / SEMI E187 設計」加上「未經認證或第三方評估」，不要寫 compliant 或 certified。合規用語見 skill `compliance-check`。

## 每日自動掃描

`~/.claude/hooks/daily-audit.sh` 的 OSV 區段每天掃全部 repo，基準線存 `~/.claude/osv-baseline.txt`，只有某個 repo 的數字比前一天多才示警，結果由 session-start 顯示。不需要手動跑這一層。

本 skill 用在需要深掃或需要判讀的時候。
