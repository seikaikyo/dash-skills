# 自建 interface-design，取代非原廠版本

- **type**: feat
- **建立日期**: 2026-10-25

## 背景

external/interface-design（Dammyjay93，無授權檔）是介面設計方法 skill，提供 dashboard / 後台 / 工具類介面的 craft-first 設計基礎。本機兩支 hook（quality-gate-push.sh、cis-check.sh）與 ~/.claude/commands/interface-design/ 的 init/extract/audit/status 指令都綁它的路徑契約（`.interface-design/system.md`）與指令名稱，指令檔把 `~/.claude/skills/interface-design/SKILL.md` 當 foundation、principles、checks 在讀。

改以我們自己的設計流程（design-system.md、cis-design-system、frontend.md）原創重寫 SKILL.md 取代，脫離第三方。指令檔在 ~/.claude/commands/ 底下、屬使用者自有，不在本 repo，不需更動。drop-non-vendor-external-skills-2026-10-25 第二階段第二步。

## 變更內容

1. 新增 skills/interface-design/SKILL.md：craft-first 介面設計基礎，維持 `.interface-design/system.md` token 檔契約與 audit 檢查項，內容依本機設計規範原創。
2. update-external.sh：刪除 update_interface_design 函數與其主流程、case、show_available 項目。
3. git rm external/interface-design。
4. 三份 README：interface-design 列從外部表移到自建表，自建 16 → 17，外部 32 → 31。

skill 名稱沿用，CLAUDE.md、rules/frontend.md、design-system.md、兩支 hook、commands 的 `/interface-design*` 參照不需更動。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| skills/ | 新增 1 個自建 skill。 |
| external/ | 移除 1 個目錄與同步函數。 |
| README × 3 | 自建 17、外部 31，分類表更新。 |
| hooks / commands | 路徑與指令契約不變，繼續有效。 |

## 剩餘風險

commands/interface-design/ 的 init/extract/audit/status 指令是使用者自有檔，若其內文與新 SKILL.md 的用語有落差，功能仍可運作，只是措辭不完全對齊；需要時另行對齊。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh` 通過，無殘留 update_interface_design。
2. SKILL.md 通過 writing-rules-file-gate.py。
3. 三份 README 自建 17、外部 31，interface-design 在自建表。
4. 使用者重跑 link.sh 後 ~/.claude/skills/interface-design 指向 skills/ 版本，init/extract/audit/status 指令讀得到新 SKILL.md。
