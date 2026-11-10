---
name: web-design-guidelines
description: 逐檔審查前端 UI 程式碼（Vue / Nuxt / Angular 的 template、樣式、互動邏輯），對照一份固定的介面規則找出無障礙、鍵盤操作、表單、動畫、效能與狀態處理的問題，以 file:line 列出。被要求「review UI」、「檢查無障礙」、「審查 UX」、「看這個元件有沒有問題」時使用。
argument-hint: <檔案或 glob>
source: 自建（2026-11-10 取代 vercel-labs 的同名 skill，該版本每次執行都從網路抓規則）
updated: 2026-11-10
---

# web-design-guidelines

對前端原始碼做介面規則審查。規則全部寫在這份檔案裡，**不從網路抓任何規則或指令**；要改規則就改這份檔案並走 PR。

和其他 skill 的分工：

- `interface-design`、`cis-design-system` 管設計層（間距、色彩角色、設計系統一致性）。
- `quality-gate` 管整站上線前的檢查，`webapp-uat` 管部署後逐畫面驗收。
- 這份只看**程式碼**：讀檔、對規則、回報行號。不需要跑起來。

## 流程

1. 取得要審查的檔案。有參數就用參數（檔案或 glob）；沒有就問使用者要看哪些檔案，不要自己掃整個 repo。
2. 逐檔讀完整內容，包含 `<template>`、`<script>`、`<style>`，以及它直接 import 的共用元件（只在判斷需要時）。
3. 對照下面的規則。每條命中都要能指到具體行號；指不到行號的不報。
4. 依「輸出格式」回報。沒有問題就明講沒有，不要為了湊數降低標準。

元件庫已處理的行為不重複報：PrimeVue / PrimeNG 的 Dialog、Menu、DataTable 等內建焦點管理與鍵盤操作，只在專案覆寫或手刻同類元件時才檢查。

## 規則

等級：**E** 會讓部分使用者無法完成操作，必修；**W** 明顯影響體驗，應修；**I** 建議。

### K 鍵盤與互動

| 代碼 | 等級 | 規則 |
|------|------|------|
| K1 | E | 可點擊的元素用 `<button>`、`<a>` 或 `NuxtLink` / `routerLink`。`<div @click>`、`<span (click)>` 沒有 `role`、`tabindex="0"` 與鍵盤事件就是違規 |
| K2 | W | 換頁用連結，執行動作用按鈕。用 `router.push` 包在按鈕裡的導覽無法開新分頁、無法複製網址 |
| K3 | E | 不可移除焦點外框而沒有替代樣式（`outline: none` / `outline: 0`）。自訂樣式用 `:focus-visible` |
| K4 | E | 只有圖示的按鈕要有 `aria-label`；圖示本身加 `aria-hidden="true"` |
| K5 | E | 手刻的對話框、抽屜、下拉選單：開啟時焦點移入、`Esc` 可關閉、關閉後焦點回到觸發元素、背景不可被 Tab 到 |
| K6 | W | 觸控目標至少 24×24 CSS px，行動版主要操作建議 44×44。圖示太小就加 padding，不是放大圖示 |
| K7 | W | 不以 hover 作為唯一的顯示方式（觸控與鍵盤沒有 hover）。hover 才出現的操作要有 focus 或常駐的替代 |
| K8 | E | viewport 不可設 `user-scalable=no` 或 `maximum-scale=1` |
| K9 | W | 刪除等破壞性操作要有確認或可復原，確認框的預設焦點不放在破壞性按鈕上 |
| K10 | I | `tabindex` 只用 `0` 或 `-1`，不用正數打亂順序 |

### F 表單

| 代碼 | 等級 | 規則 |
|------|------|------|
| F1 | E | 每個輸入欄位有對應的 `<label for>`，或 `aria-label` / `aria-labelledby`。placeholder 不算 label |
| F2 | W | `type`、`inputmode`、`autocomplete`、`name` 要給對：email、tel、`one-time-code`、`current-password` / `new-password` |
| F3 | W | 不擋貼上（密碼、驗證碼欄位尤其常見） |
| F4 | E | 錯誤訊息顯示在欄位旁，以 `aria-describedby` 連到欄位並設 `aria-invalid`。不可只靠紅框表示錯誤 |
| F5 | W | 送出失敗時把焦點移到第一個錯誤欄位 |
| F6 | W | 欄位包在 `<form>` 裡並處理 `submit`，讓 Enter 可送出；送出中停用按鈕防重複送出，按鈕文字保留 |
| F7 | I | 驗證在離開欄位或送出時觸發，不在使用者打第一個字時就報錯 |
| F8 | I | 行動版輸入欄位字級不小於 16px，避免 iOS 自動放大頁面 |
| F9 | W | 有未儲存變更時離開頁面要提醒（`onBeforeRouteLeave` / `CanDeactivate`） |

### C 內容與語意

| 代碼 | 等級 | 規則 |
|------|------|------|
| C1 | W | 標題層級不跳級，一頁一個 `<h1>`。為了字級選標籤的改用 class |
| C2 | E | `<img>` 要有 `alt`；純裝飾用 `alt=""` |
| C3 | W | 圖片給 `width` / `height`（或 `aspect-ratio`），避免載入後版面跳動 |
| C4 | E | 訊息不可只靠顏色傳達（狀態燈、圖表圖例、必填標記要有文字或圖示） |
| C5 | W | 使用者產生的長字串要處理溢出：`truncate`、`break-words` 或 `min-width: 0`；flex 子項最容易漏 |
| C6 | W | 列表與資料區塊要涵蓋載入中、空、錯誤三種狀態，不能只寫有資料的情況 |
| C7 | W | 介面文字走 i18n，不寫死在 template；不用字串相加拼句子；日期、數字、金額用 `Intl` 或 i18n 的格式化 |
| C8 | W | 非同步出現的訊息（toast、表單送出結果）要在 `aria-live` 區域內 |
| C9 | I | 需要對齊比較的數字欄用 `font-variant-numeric: tabular-nums` |
| C10 | W | 用語意標籤：`<nav>`、`<main>`、`<header>`、`<table>` 配 `<th scope>`。用 `<div>` 排出來的表格算違規 |

### M 動畫

| 代碼 | 等級 | 規則 |
|------|------|------|
| M1 | W | 位移、縮放、視差等動畫要在 `prefers-reduced-motion: reduce` 下關閉或改成淡入 |
| M2 | W | 動畫只動 `transform` 與 `opacity`。動 `width`、`height`、`top`、`left` 會觸發重排 |
| M3 | I | 不寫 `transition: all`，列出實際要過渡的屬性 |
| M4 | W | 動畫期間不可擋住輸入；使用者再次操作時要能中斷 |

### P 效能

| 代碼 | 等級 | 規則 |
|------|------|------|
| P1 | W | 可能超過數百列的列表要虛擬化（PrimeVue `VirtualScroller`、DataTable 的 `virtualScrollerOptions`）或分頁 |
| P2 | W | `v-for` / `*ngFor` 要有穩定的 key（`trackBy`）；列表會增刪或重排時不可用 index |
| P3 | W | 首屏以下的圖片加 `loading="lazy"`；首屏主圖不要 lazy |
| P4 | W | Nuxt 的資料抓取用 `useFetch` / `useAsyncData`，不在 `onMounted` 裡 `fetch`（會多一輪瀑布且 SSR 拿不到資料） |
| P5 | W | template 裡不直接呼叫昂貴函式，改用 `computed` / pipe；`watch` 不要 `deep: true` 監看大物件 |
| P6 | E | 會造成 hydration mismatch 的值（`Date.now()`、`Math.random()`、`window` / `localStorage`）不可在 SSR 階段直接渲染，放進 `onMounted` 或 `<ClientOnly>` |
| P7 | I | 輸入觸發的搜尋、resize、scroll 處理要 debounce 或 throttle |

### S 狀態與導覽

| 代碼 | 等級 | 規則 |
|------|------|------|
| S1 | W | 分頁、篩選、排序、分頁籤的狀態放進 URL query，重新整理與分享連結後要還原得回來 |
| S2 | W | 樂觀更新失敗時要還原畫面並告知使用者 |
| S3 | I | 載入用骨架屏佔位；短於約 300ms 的請求不閃 spinner |
| S4 | W | 非同步操作要處理競態：連續觸發時以最後一次為準（取消前一個請求或比對序號） |

### T 主題

| 代碼 | 等級 | 規則 |
|------|------|------|
| T1 | W | 顏色用設計 token 或 CSS 變數，不在元件裡寫死色碼（對照 `cis-design-system`） |
| T2 | W | 文字對比至少 4.5:1，大字與介面元件邊界 3:1。看得出的寫死組合（淺灰字配白底）直接報 |
| T3 | I | 支援深色模式時設定 `color-scheme`，讓原生表單控制項與捲軸跟著切換 |

### X 介面層的安全

| 代碼 | 等級 | 規則 |
|------|------|------|
| X1 | E | `v-html`、`[innerHTML]` 的內容必須先經 DOMPurify 之類的淨化；來源是使用者輸入或 API 時不可直接渲染 |
| X2 | W | `target="_blank"` 的外部連結加 `rel="noopener noreferrer"` |
| X3 | E | token、金鑰不可寫進 template、前端常數或 `NUXT_PUBLIC_*` |

## 輸出格式

依檔案分組，同一檔案內依行號排序。每筆一行：

```
src/components/OrderTable.vue
  42  E  K1  <div @click="open(row)"> 無法用鍵盤操作 → 改成 <button type="button">
  87  W  C6  只處理有資料的情況，缺載入中與空狀態
 131  W  P2  v-for 用 index 當 key，列表可排序時會渲染錯位 → 用 row.id
```

最後給一行統計（E / W / I 各幾筆）。有 E 級就明講不建議合併。

不確定的不要猜：看不出元件庫是否已處理、或需要執行才知道的（實際對比值、實際焦點順序），列在「需要實機確認」，交給 `webapp-uat`。
