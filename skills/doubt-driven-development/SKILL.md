---
name: doubt-driven-development
description: 對非平凡決策啟動新鮮 context 對抗審查（找碴不背書），在修正還便宜的時候抓出錯誤方向。適用：高風險改動（production、資安敏感邏輯、不可逆操作）、不熟的程式碼、要宣稱「這樣是安全的 / 可行的」之前。機械性操作與一行修改不適用。
source: adapted from openclawyhwang-hub/tGD tgd-doubt-driven-development (Apache-2.0)
updated: 2026-07-13
---

# Doubt-Driven Development（決策對抗審查）

## 核心

有信心不等於正確。長 session 累積的 context 會讓假設悄悄變成「事實」。本 skill 的紀律：非平凡決策在定案前，交給一個沒有包袱的新鮮 context reviewer 專門找碴。

跟 /code-review 的差別：/code-review 是完成品的事後判決；這是進行中的姿勢，在決策還便宜的時候交叉檢驗。

## 何時使用

決策符合任一條即為非平凡：

- 新增或修改分支邏輯
- 跨 module 或 service 邊界
- 宣稱型別系統驗不了的性質（thread safety、冪等、順序、不變量）
- 正確性依賴未來讀者看不到的 context
- 影響不可逆（production 部署、資料遷移、公開 API 變更）

不適用：機械性操作（改名、格式化、搬檔）、明確無歧義的指示、讀碼與摘要、一行修改、純工具操作。每個 keystroke 都懷疑就什麼都出不了貨，本 skill 只管上面定義的非平凡決策。

## 流程（五步）

```
Doubt cycle:
- [ ] Step 1 CLAIM：寫下主張與其重要性
- [ ] Step 2 EXTRACT：抽出 artifact + contract，剝掉自己的推理
- [ ] Step 3 DOUBT：派新鮮 context reviewer 對抗審查
- [ ] Step 4 RECONCILE：逐條 findings 對照 artifact 分類
- [ ] Step 5 STOP：滿足停止條件才停
```

### Step 1 CLAIM：講清楚什麼要定案

兩三行寫出決策：

```
CLAIM：「新的快取層在 spec 描述的讀重負載下 thread-safe」
重要性：race 會弄壞使用者資料，QA 很難抓到
```

寫不出精簡版就代表只有感覺、沒有決策。先寫出來再檢驗。

### Step 2 EXTRACT：最小可審單位

reviewer 需要 artifact 跟 contract，不需要你的心路歷程：

- 程式碼：diff 或函式，不是整個檔案
- 決策：3 到 5 句提案加上要滿足的約束
- 主張：主張本身加上據稱支持它的證據

剝掉自己的推理：交出結論會換回對結論的背書。單位要小到一次讀完能掌握，500 行的 PR 先拆再審。

### Step 3 DOUBT：派新鮮 context reviewer

用 Agent tool 派一個新鮮 subagent（sora），prompt 必須是對抗式，措辭決定答案：

```
對抗審查。找出這個 artifact 的問題。假設作者過度自信。找：
- 未言明的假設
- 沒處理的邊界情況
- 隱藏耦合或共享狀態
- 違反 contract 的可能方式
- 打破既有慣例之處
- 意外輸入下的失敗模式
禁止背書、禁止摘要。找不到問題就明講「徹底檢查後找不到」。
ARTIFACT: <貼上>
CONTRACT: <貼上>
```

只傳 ARTIFACT + CONTRACT，禁傳 CLAIM：把結論交給 reviewer 會誘導它同意。

跨模型第二意見（Gemini / Codex CLI）流程本環境沒有常備工具，不搬進來；需要時看原文 `external/tgd-skills/tgd-doubt-driven-development/SKILL.md`，並遵守其安全守則（唯讀 sandbox、每次調用都要使用者授權）。

### Step 4 RECONCILE：findings 分類回收

reviewer 的輸出是資料不是判決，你還是 orchestrator。每條 finding 對照 artifact 原文再分類（先中先贏）：

1. contract 誤讀：contract 寫得不清才被誤標，先修 contract，下一輪重分類
2. 有效且可行動：真問題，改 artifact 再迴圈
3. 有效但取捨：修的成本高於接受的成本，明文記下取捨給使用者看
4. 雜訊：reviewer 缺 context 造成誤報，記下並自問補什麼 context 可預防

新鮮 reviewer 也會因缺 context 而錯，不因為它「新鮮」就照單全收。橡皮圖章跟無視是同一種失敗。

### Step 5 STOP：有界迴圈，不遞迴

滿足任一即停：

- 下一輪只剩瑣碎或已考慮過的 findings
- 跑滿 3 輪（升級給使用者，不自己磨第四輪）
- 使用者明說出貨

3 輪之後還有實質問題，代表 artifact 可能沒準備好。這是關於 artifact 的資訊，不是繼續迴圈的理由。若因 artifact 太大導致 3 輪不夠：回 Step 2 拆解，不放寬上限。

## 常見合理化

| 合理化 | 現實 |
|---|---|
| 「我很有信心，跳過懷疑」 | 新問題上信心與正確性相關性很差，最篤定的時刻正是盲點藏身處 |
| 「派 reviewer 很貴」 | production 除錯更貴。檢查有上限，bug 沒有 |
| 「reviewer 只會挑毛病」 | 沒約束才會。prompt 限定「會讓 contract 失敗的問題」 |
| 「最後用 /code-review 就好」 | 那是終點閘門。本 skill 在方向還便宜時抓錯，到 PR 已太晚 |
| 「reviewer 不同意所以我錯了」 | reviewer 缺你的 context，不同意是資訊不是判決。重讀 artifact 再分類 |

## 紅旗

- 對一行改名派 reviewer
- 不重讀 artifact 就把 reviewer 輸出當權威
- 超過 3 輪不升級給使用者
- 用「這樣好嗎」代替「找出問題」
- 高風險決策因趕時間跳過懷疑
- artifact 沒變就重派（只會拿到同樣 findings，你在拖延）
- 懷疑作秀（可檢核訊號）：連續 2 輪以上 reviewer 有實質 findings，卻零條被分類為可行動。你在找背書不是在懷疑，停下升級
- commit 之後才懷疑：那是 /code-review，不是本 skill

## 與現有流程的關係

- superpowers test-driven-development：RED 步驟的失敗測試就是行為主張的具體化懷疑。TDD 適用時，那個失敗測試即可抵本 skill 對行為主張的 doubt 步
- /code-review 與 pr-review-toolkit：互補。事後 PR 層 vs 進行中決策層，兩個都要
- 完整原文（含跨模型流程與 orchestration 反模式）：`external/tgd-skills/tgd-doubt-driven-development/`

## 驗證

- [ ] 每個非平凡決策定案前都有明文 CLAIM
- [ ] 每個非平凡 artifact 至少一次新鮮 context 審查（TDD RED 的失敗測試可抵行為主張）
- [ ] reviewer 只拿到 ARTIFACT + CONTRACT，沒拿到 CLAIM 與推理
- [ ] prompt 是對抗式（找問題），不是背書式（好不好）
- [ ] findings 逐條對照 artifact 分類，沒有橡皮圖章
- [ ] 滿足停止條件（瑣碎 findings、3 輪、或使用者放行）
