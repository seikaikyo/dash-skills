---
name: security-radar
description: 資安套件情報雷達。每日掃描並精選「有效、熱門、自身安全」的資安套件/工具，聚焦 Nuxt 3 / Vue 3 / TypeScript（npm）、Go、Python (FastAPI) 技術棧。查詢已收錄套件的評估結論、安全狀態與選型建議時使用。
updated: 2026-08-31
---

# Security Radar（資安套件情報雷達）

## 用途

每日自動掃描資安生態，把通過查證的套件/工具沉澱到 `packages.md`，
作為技術棧（Nuxt 3 / Vue 3 / TypeScript、Go、Python FastAPI、Neon PostgreSQL、
Vercel / Render、Logto JWT/JWKS）的資安選型依據。

## 評估標準（三維度，逐項查證）

收錄前必須通過全部三項，**不可憑印象**：

1. **有效**：解決明確的安全問題；與現有技術棧整合成本合理
   （npm / Go module / pip 可直接安裝，或 CI 一鍵接入）。
2. **熱門**：GitHub stars、近 90 天 commit/release 活躍度、下載量。
   已停止維護（>12 個月無活動）的不收錄；已收錄者標「淘汰」。
3. **安全**：查 osv.dev / GitHub Advisory Database 確認無未修補 CVE；
   參考 OpenSSF Scorecard 與 release provenance（SLSA / sigstore）。
   **自身有未修補高危漏洞者一律淘汰。**

## 維護規則

- 資料表在 `packages.md`，一列一套件。
- 已收錄的套件不重複新增；只在狀態變化時更新該列：
  - 爆出未修 CVE → 安全狀態標 ⚠️ 並附公告連結
  - 停止維護 → 標「淘汰」
  - 已修補 → 更新為 ✅ 並註記修補版本
- 每日主題輪替：npm/JS（依賴稽核、XSS/CSP、JWT、rate limiting）、
  Go（安全 middleware、secrets 掃描、fuzzing）、
  通用（SAST、supply chain、secrets 偵測、容器/CI 安全）。
- 有新收錄或狀態更新才 commit / 開 PR；當天無變化則不動 repo。

## 安全狀態圖例

| 標記 | 意義 |
|------|------|
| ✅ | 查證時無未修補 CVE |
| ⚠️ | 有未修補 CVE 或重大疑慮（附連結） |
| 淘汰 | 停止維護或有未修高危漏洞，不建議使用 |
