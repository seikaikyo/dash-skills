---
name: architecture-audit
description: 架構文件稽核。比對 CLAUDE.md 記錄與實際程式碼結構，找出差異並建議更新。大型 refactor 完成後或 OpenSpec 歸檔時手動執行。
source: dashai (自建)
updated: 2026-03-28
---

# Architecture Audit (架構文件稽核)

## When to Use

在以下情況使用此 Skill：
- 大型 refactor 完成後
- OpenSpec 歸檔時
- 新增/刪除多個檔案後
- 手動執行 `/architecture-audit`

## 稽核流程

### Step 1: 讀取 CLAUDE.md

```bash
cat CLAUDE.md
```

確認文件存在。若不存在，建議先建立。

### Step 2: 掃描實際結構

```bash
# 前端
ls -R src/ | head -100

# 後端
ls -R *.py **/*.py | head -100

# 路由數量
grep -c "path:" src/router/index.ts 2>/dev/null || true
```

### Step 3: 比對差異

檢查以下項目：

| 項目 | 方法 |
|------|------|
| 新增的目錄/檔案 | 實際有但 CLAUDE.md 未記錄 |
| 刪除的目錄/檔案 | CLAUDE.md 記錄但實際已不存在 |
| 路由數量 | CLAUDE.md 記錄數 vs 實際數 |
| 依賴版本 | package.json/requirements.txt vs CLAUDE.md |
| 元件數量 | 實際元件數 vs CLAUDE.md 記錄 |

### Step 4: 輸出報告

```
架構稽核報告
===========
專案: {project_name}
日期: {date}

差異:
+ src/views/NewPage.vue (未記錄)
- src/views/OldPage.vue (已刪除)
~ 路由數量: 文件記 22, 實際 25

建議更新:
1. CLAUDE.md 目錄結構段落加入 NewPage
2. 移除已刪除的 OldPage 記錄
3. 更新路由數量為 25
```

### Step 5: 使用者確認後更新

- 使用者確認 → 直接更新 CLAUDE.md
- 使用者拒絕 → 跳過

## CLI 指令

```bash
# 快速檢查
dash architecture check .

# 詳細差異
dash architecture diff .

# 全專案掃描
dash architecture check --all
```

## 注意事項

- 此 skill 不修改程式碼，只更新文件
- CLAUDE.md 的目錄結構是參考，不需要列出每個檔案
- 重點放在結構性變化（新增/刪除目錄、路由數量、依賴版本）
