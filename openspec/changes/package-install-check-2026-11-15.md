# security-scan：新裝套件檢查

- **type**: feat
- **建立日期**: 2026-11-15
- **status**: completed

## 背景

使用者的本機設定裡有一支安裝套件後觸發的檢查，原本要求照 trailofbits-security 的 supply-chain-risk-auditor 做依賴審查。這個集合 2026-11-15 已從 `external/` 移除，檢查指向的 skill 不存在了。

`security-scan` 現有內容是整個 repo 的三層體檢（金鑰歷史、相依漏洞、程式碼規則），每裝一個套件就跑一次太重，也不涵蓋發布時間、撤回、棄用、維護者這幾項。

## 變更內容

`skills/security-scan/SKILL.md` 新增「新裝套件檢查」一節，只查剛裝的那一個套件，資料源只用官方：

- OSV 查詢 API：該版本有沒有已知漏洞。
- PyPI JSON API：版本發布時間、是否撤回、發布歷史。
- npm registry：版本發布時間、是否標為棄用、維護者人數、套件最後更新時間。

依結果分成「可以裝」「先問使用者」「不要裝」三種，並說明怎麼回報。

不納入下載量：PyPI 沒有官方下載量來源，npm 的下載量端點在沙箱裡驗不到；下載量本身也容易被刷，訊號弱。

描述欄與 `updated` 一併更新。

## 影響範圍

- 只動 `skills/security-scan/SKILL.md`。
- 本機設定那句指示由使用者改成指向這一節（設定檔不由 agent 修改）。

## UI規格

無畫面變更。

## 測試計畫

1. 節內每個 API 網址與欄位名，用 curl 實際打一次確認存在（2026-11-15：soupsieve 4.0.1、jinja2 3.1.2 的 OSV 查詢、left-pad 的 npm 資料）。
2. 用三個已知答案的套件走一遍判定：
   - jinja2 3.1.2：OSV 有漏洞 → 不要裝。
   - left-pad 1.3.0：npm 標為棄用 → 先問使用者。
   - soupsieve 4.0.1：無漏洞、未撤回、發布超過 7 天 → 可以裝。
3. 寫作規則檢查（禁用符號與填充詞）通過。
