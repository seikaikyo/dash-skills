---
name: cis-design-system
description: CIS (Corporate Identity System) 設計規範建立與維護。前端專案的色彩、字型、間距、元件用途統一定義。新專案建立時或前端修改時自動觸發，確保設計一致性。
source: 自建
updated: 2026-04-04
---

# CIS Design System

## When to Use

**自動觸發（hook 強制）：**
- 編輯 `.css` / `.tsx` / `.vue` / `.scss` / `tailwind` 相關檔案時
- 新增/修改 UI 元件時
- 修改色彩、字型、間距時

**手動觸發：**
- `/cis-design-system` — 建立或更新 CIS 文件
- 新專案初始化時

## CIS 文件位置

每個前端專案必須有：`wireframes/cis-design-tokens.html`

## 核心流程

### 新專案建立

```
1. 讀取 globals.css / tailwind config 萃取所有 CSS 變數
2. 讀取 package.json 確認 UI 框架（shadcn/PrimeVue）
3. 讀取字型設定（layout.tsx / fonts）
4. 生成 cis-design-tokens.html，包含以下區塊：
```

### 前端修改時（hook 觸發）

```
1. 偵測修改了哪些前端檔案
2. 檢查修改內容是否涉及色彩/字型/間距/元件
3. 若涉及 → 比對 CIS 文件是否需更新
4. 若不一致 → block 並提示更新 CIS
```

## CIS 文件必須包含的區塊（附編號）

每個區塊有固定編號，方便討論時引用（如「調整 C1.3 的深色值」）。

### C1 — 色彩系統

| 編號 | 內容 |
|------|------|
| C1.1 | 品牌色（primary / accent，雙主題） |
| C1.2 | 背景色（background / card / muted / input） |
| C1.3 | 文字色（foreground / muted-foreground / dim） |
| C1.4 | 邊框色（border / ring） |
| C1.5 | 語意色（destructive / success / warning） |
| C1.6 | 領域專用色（如運勢等級、特殊日、七曜） |

每個色必須列：Token 名 / Light 值 / Dark 值 / 用途說明

### C2 — 字型系統

| 編號 | 內容 |
|------|------|
| C2.1 | 字型家族定義（serif / sans / mono） |
| C2.2 | 字級表（名稱 / 大小 / 字重 / 用途） |
| C2.3 | 行高規則 |

### C3 — 間距系統

| 編號 | 內容 |
|------|------|
| C3.1 | 基數定義（如 4px） |
| C3.2 | 間距階梯（gap-sm / gap-md / gap-lg） |
| C3.3 | 元件內距（card padding / page padding） |

### C4 — 圓角系統

| 編號 | 內容 |
|------|------|
| C4.1 | 圓角階梯（radius-sm / radius / radius-lg / radius-xl） |
| C4.2 | 特殊圓角（pill / circle） |

### C5 — 元件色彩對照

| 編號 | 內容 |
|------|------|
| C5.1 | 每個 UI 元件該用哪個 token |
| C5.2 | Badge 色彩規則（bg 透明度 + text 實色） |
| C5.3 | 卡片色彩規則 |
| C5.4 | 互動狀態（hover / active / focus） |

### C6 — 禁止事項

| 編號 | 內容 |
|------|------|
| C6.1 | 禁用 hardcode hex/rgb |
| C6.2 | 禁用非原典術語（專案特定） |
| C6.3 | 禁用 emoji |
| C6.4 | 其他專案特定禁止項 |

### C7 — 專案特定定義

| 編號 | 內容 |
|------|------|
| C7.x | 由專案自行定義的領域色彩、術語色彩等 |

## 比對規則

修改前端檔案時，hook 檢查以下項目：

1. **新增顏色** — 是否在 CIS C1 中有定義？
2. **修改 CSS 變數** — CIS 文件是否同步更新？
3. **新增元件** — C5 元件對照是否更新？
4. **修改字型** — C2 是否同步？
5. **修改間距** — C3 是否同步？

## 生成指令

```bash
# 萃取現有專案的設計 token
/cis-design-system

# 步驟：
# 1. 掃描 globals.css → 萃取所有 CSS 變數
# 2. 掃描 components.json → 確認 UI 框架設定
# 3. 掃描 layout.tsx → 確認字型
# 4. 掃描 tailwind config → 確認客製化設定
# 5. 生成 wireframes/cis-design-tokens.html
# 6. 輸出變更摘要
```

## 討論用法範例

```
用戶: 「C1.6 的甘露日金色太亮了，深色模式要暗一點」
Claude: 調整 C1.6 kanro dark 從 #d4af37 → #b8941f，同步更新 globals.css + CIS 文件

用戶: 「C5.2 的 badge 透明度統一改 15%」
Claude: 更新所有 badge bg 從 12% → 15%，影響 C1.5/C1.6 所有 -bg token
```
