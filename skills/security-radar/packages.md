# Security Radar — 收錄套件清單

評估標準見 [SKILL.md](./SKILL.md)。狀態圖例：✅ 無未修 CVE｜⚠️ 有疑慮｜淘汰 不建議使用。

| 套件 | 生態 | 用途 | 熱門度 | 安全狀態 | 收錄日期 | 備註 |
|------|------|------|--------|----------|----------|------|
| [osv-scanner](https://github.com/google/osv-scanner) | Go（CLI，跨生態） | 依賴漏洞掃描：以 osv.dev 資料庫掃 `package-lock.json` / `go.mod` / `requirements.txt` 等 11+ 生態 lockfile，一支工具覆蓋 npm+Go+Python 全棧 | 10.9k ★；v2.5.1（2026-08-17），活躍 | ✅ GitHub Advisory 無自身公告 | 2026-08-31 | Google 維護；支援容器映像掃描與 CI action，適合接進 Vercel/Render 前置 CI |
| [trivy](https://github.com/aquasecurity/trivy) | Go（CLI，跨生態） | 綜合掃描：依賴 CVE、容器映像、IaC 錯誤設定、secrets、license，一站式 CI 安全閘門 | 37.7k ★；v0.74.0（2026-08-14），高度活躍 | ✅ 歷史 CVE 均已修補（含 [CVE-2026-55092](https://github.com/advisories/GHSA-mcj4-mphf-j9ff) 高危路徑遍歷，0.71.1 已修；使用 ≥0.71.1） | 2026-08-31 | Aqua Security 維護；功能比 osv-scanner 廣但較重，適合完整 pipeline |
| [scorecard](https://github.com/ossf/scorecard) | Go（CLI / GitHub Action） | 供應鏈健康評分：對依賴的上游 repo 跑 24+ 項安全檢查（branch protection、code review、pinned deps），選型前評估依賴可信度 | 5.7k ★；OpenSSF 官方，持續開發（3.1k commits） | ✅ GitHub Advisory 無自身公告；release 具 SLSA L3 provenance | 2026-08-31 | 用於評估第三方依賴與本 radar 自身查證流程 |
| [lockfile-lint](https://github.com/lirantal/lockfile-lint) | npm | Lockfile 供應鏈防護：驗證 `package-lock.json` / `yarn.lock` 的 resolved URL 只指向可信 registry，阻擋 lockfile 注入攻擊 | 868 ★；週下載約 29.9 萬（[Snyk](https://snyk.io/advisor/npm-package/lockfile-lint)），維護中 | ✅ [CVE-2025-4759](https://github.com/advisories/GHSA-7cfr-5cjf-32p4)（中危，URL 驗證繞過）已於 lockfile-lint-api 5.9.2 修補；使用 ≥5.9.2 | 2026-08-31 | Liran Tal（Snyk）維護；輕量，適合 Nuxt 專案 pre-commit / CI 一行接入 |
