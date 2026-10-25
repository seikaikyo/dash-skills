---
name: interface-design
description: Craft-first 介面設計基礎，用於儀表板、後台、管理介面、工具與資料密集型產品 UI。設計或檢視這類介面的版面層級、間距節奏、深度策略、色彩角色、狀態覆蓋、設計系統一致性時使用。搭配 init / extract / audit / status 指令與 .interface-design/system.md token 檔運作。不處理行銷頁、landing page、品牌視覺，那些另找設計工具。
---

# interface-design

儀表板、後台、工具這類介面的設計基礎。這份是 init、extract、audit、status 四個指令共用的原則與檢查，也是 quality-gate-push.sh 對 UI 改動做設計稽核時的對照依據。

對象是資料密集、長期使用、操作導向的產品介面，不是行銷頁或 landing page。那兩類重氣氛與轉換，這裡重的是可讀、可掃描、可長時間操作不累。

## 設計系統檔：.interface-design/system.md

每個前端專案把設計決策寫進 `.interface-design/system.md`，當作這個專案的單一真相來源。`extract` 從既有程式碼抽出目前的樣子寫成這份檔，`init` 從頭建立，`audit` 拿程式碼對照這份檔找違規，`status` 回報目前狀態。

system.md 至少要涵蓋：

- 色彩角色：不是列一堆色票，而是講每個角色（背景、表面、前景、次要前景、邊框、primary、destructive、success、warning）對應哪個 token、Light 與 Dark 各是什麼值。
- 字型與字級：字型家族，加上一張字級表（名稱、大小、字重、行高、用途）。
- 間距尺階：基數（通常 4px）與允許的間距階梯。只用階梯上的值。
- 圓角尺階：radius 的幾個級距，哪種元件用哪級。
- 深度策略：陰影或邊框的層級怎麼表達高低，一個介面只用一套。
- 元件模式：卡片、表格、表單、badge、按鈕各自的結構與狀態規則。

這份檔與 cis-design-system 產生的 `wireframes/cis-design-tokens.html`（C1 到 C7 區塊）是同一套 token 的兩個視角：system.md 給設計與稽核讀，cis-design-tokens.html 給人看。兩者的 token 值要一致。

## 設計原則

### 間距用節奏，不用隨手填
間距從固定尺階來（4 的倍數），同一層級的元素用同一個值。版面的呼吸感來自一致的節奏，不是每處微調。看到 `13px`、`7px` 這種落在尺階外的值就是警訊。

### 深度策略一套到底
表達「這塊浮在上面」只用一種手法：全站用陰影，或全站用邊框，不混用。陰影就定義好幾個固定級距（卡片、浮層、對話框各一級），不要每個元件自己調一組 rgba。

### 色彩講角色，不講顏色
程式碼裡不出現 hardcode 的 hex 或 rgb，一律走語意 token。改配色時改 token 一處，不是全站搜字串。badge 這類用「半透明底加實色字」的規則統一處理，不每個顏色各寫一套。

### 層級靠對比，不靠裝飾
重要的東西用大小、字重、留白拉出來，不靠加框加色加陰影堆疊。一個畫面裡最多一個主要行動（primary），其餘降級。

### 狀態要蓋滿
每個互動元件都要想過這些狀態，缺一個就是半成品：預設、hover、focus（鍵盤可見）、active、disabled。每個資料區塊都要想過：載入中、空資料、錯誤、正常。空狀態不是空白，要講為什麼空、下一步做什麼。

### 密度配場景
資料密集的後台可以緊，但要靠對齊與分組維持可掃描；對外或低頻的頁面可以鬆。密度是刻意選的，不是放著不管的結果。

## audit 檢查項

`audit` 拿程式碼對照 system.md，找這些違規，照嚴重度排序：

1. hardcode 的色值（hex / rgb / hsl 字面值），該走 token。
2. 落在間距尺階外的 margin / padding / gap。
3. 圓角、陰影不在定義的級距內，或深度手法混用。
4. 互動元件缺狀態：沒有 focus 樣式（鍵盤無法定位）、沒有 disabled、沒有 hover 回饋。
5. 資料區塊缺載入、空、錯誤狀態。
6. 同一種元件在不同頁面長得不一樣（卡片內距、按鈕高度不一致）。
7. 一個畫面出現多個 primary 行動，層級不清。
8. 字級不在字級表內，或用 inline style 硬寫大小。

找到就回報位置、違反哪一條、對應 system.md 哪個 token 或規則，不要只說「不一致」。

## 與其他機制的關係

- cis-design-system 負責把 token 寫成 `wireframes/cis-design-tokens.html`（C1 到 C7），是給人讀的設計規範。interface-design 負責設計方法與程式碼稽核，讀 `.interface-design/system.md`。兩邊 token 一致。
- quality-gate-push.sh 在 UI 改動時要求跑 audit，並檢查 `.interface-design/system.md` 是否存在。新專案或既有專案首次改 UI 時用 extract 或 init 補上。
- 新頁上線前的使用者導覽元素（PageHero、NextStepGuide、InfoTooltip、麵包屑、BackToTop）見 design-system.md，屬內容層導覽，與本 skill 的視覺層檢查互補。

## 輸出

設計或改 UI 時，先確認 system.md 存在且讀過，照上面原則實作。被要求 audit 時，回傳照嚴重度排序的違規清單，每項附位置與對應規則。不改設計決策本身，那是 system.md 的事。
