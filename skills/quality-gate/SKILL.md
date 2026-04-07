---
name: quality-gate
description: 前端品質閘門。自動檢查 SEO、無障礙、效能模式、UI/UX 基線。編輯 .tsx/.css 後自動觸發，push 前強制執行。修復找到的問題，不做架構變更。
source: self
updated: 2026-04-07
---

# Quality Gate (前端品質閘門)

## When to Use

在以下情況**自動觸發**（hook 驅動，不需手動）：
- 編輯 `.tsx` / `.css` / `.html` 檔案後（PostToolUse hook）
- `git push` 前（PreToolUse hook，blocking）

也可以手動執行 `/quality-gate` 做完整檢查。

## 檢查清單

### 1. SEO (Search Engine Optimization)

```bash
# 在 layout.tsx 或 page.tsx 中檢查
grep -r "metadataBase" src/app/layout.tsx    # 必須存在
grep -r "openGraph" src/app/layout.tsx       # 必須有 OG tags
grep -r "robots" src/app/layout.tsx          # 必須有 robots 設定
ls public/robots.txt                          # 必須存在
ls public/sitemap.xml                         # 必須存在
ls public/favicon.svg public/favicon.ico      # 至少一個
```

**修復規則：**
- `metadataBase` 必須設定為正式網域（不能是 localhost）
- OG image 路徑必須存在於 public/
- description 不超過 160 字元

### 2. Accessibility (無障礙)

**Semantic HTML 檢查：**
```bash
# 必須存在的語意標籤
grep -rn "<header" src/components/     # 頁首區域
grep -rn "<main" src/                   # 主內容區
grep -rn "<nav " src/components/        # 導覽區域
grep -rn "<footer" src/components/      # 頁尾
```

**ARIA 檢查：**
```bash
# 所有 <button> 必須有可辨識文字或 aria-label
grep -rn "<button" src/components/ | grep -v "aria-label\|>{.*}<"

# 所有 <input> 必須有 label 或 aria-label
grep -rn "<Input\|<input" src/components/ | grep -v "aria-label\|<label"

# 語言切換按鈕必須有 aria-pressed
grep -rn "setLocale\|locale" src/components/ | grep "button" | grep -v "aria-pressed"
```

**Focus 檢查：**
```bash
# 互動元素必須有 focus-visible 樣式
grep -rn "focus-visible" src/components/   # 應該有結果
```

**修復規則：**
- 每個互動元素必須可用鍵盤操作
- touch target >= 28px (7 * 4px grid)
- 色彩對比 WCAG AA (4.5:1 一般文字, 3:1 大文字)

### 3. Performance (效能)

```bash
# 圖片必須用 next/image（Next.js 專案）
grep -rn "<img " src/          # 不應該出現原生 img（除了 SVG inline）
grep -rn "next/image" src/     # 應該有結果（如果有圖片）

# CSS 動畫不應阻塞主執行緒
grep -rn "will-change" src/app/globals.css   # 固定背景/紋理需要
grep -rn "contain:" src/app/globals.css      # 獨立圖層需要 contain

# 字型必須用 next/font（Next.js）或 font-display: swap
grep -rn "font-display\|next/font" src/

# 不應有未使用的大型依賴
# (由 dash deps check 處理)
```

**修復規則：**
- 靜態圖片用 `next/image` + width/height + alt
- CSS 動畫用 `transform` / `opacity`，不用 `top`/`left`
- 紋理/背景固定層加 `contain: strict`

### 4. UI/UX 基線

```bash
# 必須有 Back to Top（長頁面）
grep -rn "back-to-top\|BackToTop\|scrollTo.*top" src/

# 必須有空狀態處理
grep -rn "noResults\|no.*found\|empty" src/components/

# 必須有 loading 或 skeleton（如果有非同步資料）
grep -rn "loading\|skeleton\|Suspense" src/

# 三語 i18n 完整性（如果是多語專案）
# 檢查所有 t('key') 在三個 locale 都有對應
```

**修復規則：**
- 可滾動頁面 > 2 個 viewport 高度 → 必須有 Back to Top
- 所有篩選/搜尋必須有空狀態提示
- 外部連結必須有 `target="_blank" rel="noopener noreferrer"`

### 5. Reliability (穩定度)

```bash
# 不應有 non-null assertion (!)
grep -rn "\\b!\\." src/ --include="*.tsx" --include="*.ts" | grep -v "node_modules\|!="

# Client component 的 localStorage 必須有 typeof window 防護
grep -rn "localStorage\|sessionStorage" src/ | grep -v "typeof window"

# Error boundary 檢查（React 專案）
grep -rn "ErrorBoundary\|error\\.tsx" src/
```

**修復規則：**
- 用 optional chaining (`?.`) 取代 `!.`
- `localStorage` 存取包在 `typeof window !== 'undefined'` 裡
- 根層級應有 error.tsx（Next.js App Router）

## 執行流程

1. 跑上述所有 grep 檢查
2. 列出問題清單（檔案:行號 + 問題描述）
3. 按嚴重度排序：blocking > warning > info
4. 逐一修復 blocking 問題
5. 報告 warning（不自動修）

## Blocking vs Warning

| 嚴重度 | 問題 | 動作 |
|--------|------|------|
| **Blocking** | 缺 metadataBase、缺 aria-label on button/input、非 null assertion | 自動修復 |
| **Warning** | 缺 sitemap、缺 error.tsx、原生 img 標籤 | 報告，不擋 push |
| **Info** | 缺 JSON-LD、缺 canonical per page | 報告 |

### 6. Security (安全性)

```bash
# 硬編碼機敏資料
grep -rn "sk-\|AKIA\|ghp_\|password\s*=\s*['\"]" src/ --include="*.tsx" --include="*.ts"

# dangerouslySetInnerHTML 未 sanitize
grep -rn "dangerouslySetInnerHTML" src/ --include="*.tsx" | grep -v "DOMPurify\|sanitize"

# target="_blank" 缺少 rel="noopener noreferrer"
grep -rn 'target="_blank"' src/ --include="*.tsx" | grep -v "noopener"

# 表單提交缺少 CSRF 防護（如果有表單）
grep -rn "<form" src/ --include="*.tsx" | grep -v "csrf\|token"

# eval / Function() 使用
grep -rn "eval(\|new Function(" src/ --include="*.tsx" --include="*.ts"
```

**修復規則：**
- 機敏資料一律走環境變數（`.env.local`），不硬編碼
- `dangerouslySetInnerHTML` 必須搭配 DOMPurify
- 所有 `target="_blank"` 加 `rel="noopener noreferrer"`
- 禁止 `eval()` 和 `new Function()`

### 7. Architecture Documentation (SA/SD 同步)

每個專案必須有以下文件，且內容與程式碼一致：

| 文件 | 適用 | 必要內容 |
|------|------|---------|
| `CLAUDE.md` | 所有專案 | 專案概述、技術架構表、目錄結構、開發注意事項、後端位置（如分離） |
| `.interface-design/system.md` | 前端專案 | 色彩 token、字型、間距、圓角、元件模式、手刻元件清單、禁止事項 |
| `openspec/` | 所有專案 | 變更管理（非架構文件，但必須存在） |

```bash
# CLAUDE.md 存在
test -f CLAUDE.md

# 前端：design system 存在
test -f .interface-design/system.md || test -f wireframes/cis-design-tokens.html

# CLAUDE.md 目錄結構 vs 實際
# 抽取 CLAUDE.md 中提到的路徑，比對實際檔案系統
grep -oE 'src/[a-zA-Z0-9_/-]+' CLAUDE.md | sort -u | while read dir; do
  [ -d "$dir" ] || [ -f "$dir" ] || echo "MISSING: $dir"
done

# 新增/刪除檔案後，CLAUDE.md 是否也更新
git diff --cached --diff-filter=ADR --name-only | head -10
git diff --cached --name-only | grep CLAUDE.md
```

**修復規則：**
- 新增元件/模組 → 更新 CLAUDE.md 目錄結構 + system.md 元件清單
- 刪除元件/模組 → 同步移除文件中的描述
- 改 API 端點 → 更新 CLAUDE.md API 段落
- 改設計 token → 更新 system.md 色彩/字型表
- 後端 router 數量變更 → 更新 CLAUDE.md API 說明

## 不做的事

- 不改架構
- 不改視覺設計
- 不加新功能
- 不重構程式碼
- 只修品質問題
