# 內化 ui-ux-pro-max（MIT），脫離每日自動同步

- **type**: chore
- **建立日期**: 2026-10-25

## 背景

ui-ux-pro-max（nextlevelbuilder，MIT 授權）是 5 個在用的非原廠 skill 裡唯一有授權、且價值在大型資料集（50+ 風格、161 色盤、57 字型配對、119 條 UX 準則）而非可重寫流程的。與 humanizer、interface-design、webapp-uat 不同，它不適合「照自家流程重寫」。MIT 允許散布，使用者決定把現有 MIT 版本內化到 skills/，保留 LICENSE 與出處標註，並從每日自動同步移除，解除供應鏈風險。drop-non-vendor-external-skills-2026-10-25 第二階段最後一步。

## 變更內容

1. `git mv external/ui-ux-pro-max skills/ui-ux-pro-max`：整包（264 檔、含 LICENSE）移入自建區，不再每日覆蓋。
2. update-external.sh：刪除 update_ui_ux_pro_max 函數與其主流程、case、show_available 項目。
3. link.sh：巢狀覆寫改成通用的 resolve_nested_path(name, base)，自建與外部兩個來源都適用，讓 skills/ui-ux-pro-max 的連結指向內層 ui-ux-pro-max/ui-ux-pro-max（真正有 SKILL.md 的那層）。NESTED_OVERRIDES 值不變。
4. 三份 README：ui-ux-pro-max 列從外部表（UI/UX 區）移到自建表，標註「內化自 nextlevelbuilder/ui-ux-pro-max-skill, MIT」，自建 18 → 19，外部 30 → 29。

skill 名稱沿用，CLAUDE.md 的 `/ui-ux-pro-max` 參照不需更動。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| skills/ | 新增 ui-ux-pro-max（內化的 MIT 套件，附 LICENSE 與出處）。 |
| external/ | 移除 1 個目錄與同步函數，不再自動同步。 |
| link.sh | 巢狀覆寫對自建來源生效。 |
| README × 3 | 自建 19、外部 29。 |

## 剩餘風險

ui-ux-pro-max 不再隨上游更新，資料集凍結於內化當下的版本。日後要更新需手動從上游取並重新確認授權與內容。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh`、`bash -n scripts/link.sh` 通過。
2. update-external.sh 無殘留 update_ui_ux_pro_max。
3. skills/ui-ux-pro-max/LICENSE 與 skills/ui-ux-pro-max/ui-ux-pro-max/SKILL.md 存在。
4. 三份 README 自建 19、外部 29，ui-ux-pro-max 在自建表且標 MIT 出處。
5. 使用者重跑 link.sh 後 ~/.claude/skills/ui-ux-pro-max 指向 skills/ui-ux-pro-max/ui-ux-pro-max。
