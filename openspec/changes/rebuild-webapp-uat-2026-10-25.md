# 自建 webapp-uat，取代非原廠版本

- **type**: feat
- **建立日期**: 2026-10-25

## 背景

external/webapp-uat（tsilverberg，無授權檔）是瀏覽器全流程 UAT skill。本機只在 CLAUDE.md 以手動 skill `/webapp-uat` 引用，沒有 hook 或路徑契約。它的用途（逐畫面 UAT、console 與 network 錯誤擷取、a11y、i18n、bug 分級）可以用我們既有的 agent-browser（vercel-labs，保留）與三語、三尺寸 RWD、Sentry 規範原創重寫。

drop-non-vendor-external-skills-2026-10-25 第二階段第三步。

## 變更內容

1. 新增 skills/webapp-uat/SKILL.md：以 agent-browser CLI 為主的全流程 UAT 方法，內容依本機 browser-tools.md、observability 與三語規範原創。
2. update-external.sh：刪除 update_webapp_uat 函數與其主流程、case、show_available 項目。
3. git rm external/webapp-uat。
4. 三份 README：webapp-uat 列從外部表（測試區）移到自建表，自建 17 → 18，外部 31 → 30。

skill 名稱沿用，CLAUDE.md 的 `/webapp-uat` 參照不需更動。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| skills/ | 新增 1 個自建 skill。 |
| external/ | 移除 1 個目錄與同步函數。測試分類表 webapp-testing（anthropic）保留。 |
| README × 3 | 自建 18、外部 30。 |

## 剩餘風險

無。webapp-testing（anthropic 官方）仍在，涵蓋本地 Playwright 測試；webapp-uat 專注對部署站的逐畫面驗收。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh` 通過，無殘留 update_webapp_uat。
2. SKILL.md 通過 writing-rules-file-gate.py。
3. 三份 README 自建 18、外部 30，webapp-uat 在自建表。
4. 使用者重跑 link.sh 後 ~/.claude/skills/webapp-uat 指向 skills/ 版本。
