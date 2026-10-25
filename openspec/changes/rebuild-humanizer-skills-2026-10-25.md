# 自建 humanizer-zh-tw 與 humanizer-en，取代非原廠版本

- **type**: feat
- **建立日期**: 2026-10-25

## 背景

external/humanizer-zh-tw（kevintsai1202）與 external/humanizer-en（blader）是個人帳號來源，兩者上游都沒有授權檔，不宜以本專案名義散布。它們的用途（把已寫好的文字改寫得去除 AI 痕跡）在本機的 writing-style.md 與 global-behavior.md 已有完整規則。改以我們自己的規則原創撰寫兩個自建 skill 取代，脫離第三方。

這是 drop-non-vendor-external-skills-2026-10-25 第二階段的第一步。

## 變更內容

1. 新增 skills/humanizer-zh-tw/SKILL.md：手動呼叫的 zh-TW 改寫工具，內容依本機寫作規則原創。
2. 新增 skills/humanizer-en/SKILL.md：英文版，同結構。
3. update-external.sh：刪除 update_humanizer_zh_tw、update_humanizer_en 函數與其主流程、case、show_available 項目。
4. git rm external/humanizer-zh-tw、external/humanizer-en。
5. 三份 README：兩列從外部表移到自建表，自建 14 → 16，外部 34 → 32。

skill 名稱沿用 humanizer-zh-tw、humanizer-en，CLAUDE.md 與 global-behavior.md 的 /humanizer-zh-tw、/humanizer-en 引用不需更動。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| skills/ | 新增 2 個自建 skill。 |
| external/ | 移除 2 個目錄與同步函數。 |
| README × 3 | 自建與外部數量、分類表更新。 |
| ~/.claude/skills | 名稱不變，link.sh 重建後指向自建版本（使用者執行）。 |
| 引用 | CLAUDE.md、global-behavior.md 不需改，名稱沿用。 |

## 剩餘風險

link.sh 需由使用者在沙箱外重跑才會把符號連結改指自建版本；重跑前連結仍指向已刪的 external 路徑，會是死連結。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh` 通過，無殘留 update_humanizer_* 參照。
2. 兩個 SKILL.md 通過 writing-rules-file-gate.py（無破折號、無黑名單詞）。
3. 三份 README 自建 16、外部 32，humanizer 兩列在自建表、不在外部表。
4. 使用者重跑 link.sh 後 ~/.claude/skills/humanizer-zh-tw、humanizer-en 指向 skills/ 版本。
