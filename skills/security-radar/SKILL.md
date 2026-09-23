---
name: security-radar
description: 資安套件情報雷達。每日掃描並精選「有效、熱門、自身安全」的資安套件/工具，聚焦 Nuxt 3 / Vue 3 / TypeScript（npm）、Go、Python (FastAPI) 技術棧，以及 AI agent / LLM 應用安全（OWASP Agentic 2026、LLM Top 10 2026）。查詢已收錄套件的評估結論、安全狀態與選型建議時使用。
updated: 2026-09-23
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
    （**例外**：該用途查無任何合格替代時，可保留 ⚠️ 並在備註寫明理由與替代做法，
    同時列入觀察名單；一旦出現合格替代品即改標淘汰。目前僅 bluemonday 適用。）
  - 已修補 → 更新為 ✅ 並註記修補版本
- **每日：複查輪替**（2026-09-23 起，OWASP Top 10:2025 十項皆已有對應工具後改採此節奏）
  1. `packages.md` 觀察名單全部查一次。
  2. 當日輪值組：表格列序（第 1 列起算）除以 7 的餘數 = 觸發當下 UTC 星期
     （`date -u +%u`，週日取 0）。每組約 7 筆，一週輪完全表，新增的列自動分組。
     取當日輪值組：
     `awk -F'|' -v d=$(( $(date -u +%u) % 7 )) '/^\| \[/{n++; if(n%7==d) print n, $2}' skills/security-radar/packages.md`
  3. 每筆查兩件事：最後 commit / release 日期（活躍度）、GitHub Advisory 有無新的自身公告。
     星數、版本號的自然漂移**不算**狀態變化，不為此改表。
  4. 發現需淘汰的項目時，當天就找替代品，不等每週新候選。
- **每週一：新候選**（3–5 個），只看三個來源：涵蓋矩陣「缺口」欄仍未解的項目、
  觀察名單列出的後繼專案、當週複查淘汰後留下的空位。依 npm/JS、Go、通用、AI/agent 四類輪替。
- **AI 矩陣建置期**：2026-09-23 當天已把 Agentic 2026 與 LLM Top 10 2026 兩張矩陣的缺口全部補齊，
  或查證為「非套件可解 / 不適用」並寫明結論，建置期結束，新候選回到只在每週一找。
  日後這兩份清單改版、或技術棧變動讓某格從「不適用」變成適用時，才重開該格。
- **觀察名單**（`packages.md` 文末）：有具體觀察點的項目（逼近淘汰線、後繼專案、
  已知不穩定因素）。狀態變化時連同名單一併更新；觀察點解除就移出名單。
- **OWASP 對應**：每筆收錄必填「OWASP」欄，可混用三份清單的代碼（可多個），各對應 `packages.md` 文末一張涵蓋矩陣：
  - [OWASP Top 10:2025](https://owasp.org/Top10/2025/)（Web 應用）：A01 Broken Access Control（含 SSRF）｜
    A02 Security Misconfiguration｜A03 Software Supply Chain Failures｜A04 Cryptographic Failures｜
    A05 Injection｜A06 Insecure Design｜A07 Authentication Failures｜
    A08 Software or Data Integrity Failures｜A09 Security Logging and Alerting Failures｜
    A10 Mishandling of Exceptional Conditions。
  - OWASP Top 10 for Agentic Applications 2026（agent / MCP / skill）：ASI01 Agent Goal Hijack｜
    ASI02 Tool Misuse & Exploitation｜ASI03 Identity & Privilege Abuse｜
    ASI04 Agentic Supply Chain Vulnerabilities｜ASI05 Unexpected Code Execution｜
    ASI06 Memory & Context Poisoning｜ASI07 Insecure Inter-Agent Communication｜
    ASI08 Cascading Failures｜ASI09 Human-Agent Trust Exploitation｜ASI10 Rogue Agents。
  - OWASP GenAI LLM Top 10 2026（直接呼叫模型的程式碼）：LLM01 Prompt Injection｜
    LLM02 Sensitive Information Disclosure｜LLM03 Excessive Agency｜LLM04 Supply Chain｜
    LLM05 Data and Model Poisoning｜LLM06 Unbounded Consumption｜LLM07 Misinformation｜
    LLM08 Hidden Context Exposure｜LLM09 Vector and Embedding Weaknesses｜
    LLM10 Improper Output Handling。
  - 三份清單各項的檢查重點見 `skills/security-reviewer/SKILL.md` 的「OWASP 對照」。
  新增後同步更新對應的涵蓋矩陣，矩陣「缺口」欄是新候選的首要來源。
  既有工具若也適用 AI 矩陣（例如 rate limiter 可套在 LLM 端點），在矩陣中交叉引用即可，
  不必回頭改該列的 OWASP 欄。任一清單發布新版，先更新此對照與矩陣標題，再依新版重標。
- 有新收錄或狀態更新才 commit / 開 PR；當天無變化則不動 repo。
- **自動 merge**（使用者已於 2026-08-31 授權）：PR 開**正式**（非 draft）；
  確認無 merge conflict 且 CI（若有）全綠後，直接以 squash 合併並附合併說明，
  不等人工審核。若 CI 紅燈或有衝突，先修到綠再合併；修不了才留著 PR 並說明原因。

## 安全狀態圖例

| 標記 | 意義 |
|------|------|
| ✅ | 查證時無未修補 CVE |
| ⚠️ | 有未修補 CVE 或重大疑慮（附連結） |
| 淘汰 | 停止維護或有未修高危漏洞，不建議使用 |
