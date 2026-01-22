---
title: 整合 Everything Claude Code
type: feature
status: in-progress
spec: everything-claude-code-integration
created: 2026-01-22
---

# 整合 Everything Claude Code

## 變更內容

從 `https://github.com/affaan-m/everything-claude-code` 整合：
1. 高價值 Skills (security-reviewer, build-error-resolver, refactor-cleaner)
2. 記憶持久化 Hooks
3. CLAUDE.md 優化建議

## 影響範圍

- `skills/` - 新增 3 個 skill 目錄
- `external/` - 新增參考連結
- `scripts/hooks/` - 新增 hook 腳本
- `~/.claude/CLAUDE.md` - 更新全域配置

## 實作步驟

### Step 1: 建立新 Skills

- [x] 分析來源 repo 結構
- [x] 識別無重複的高價值 Skills
- [ ] 建立 security-reviewer/SKILL.md
- [ ] 建立 build-error-resolver/SKILL.md
- [ ] 建立 refactor-cleaner/SKILL.md

### Step 2: 整合 Hooks

- [ ] 複製並調整 hook 腳本
- [ ] 建立 hooks 配置範本
- [ ] 測試 hooks 功能

### Step 3: 優化 CLAUDE.md

- [ ] 新增 Agent 協調章節
- [ ] 新增 Context 管理策略
- [ ] 新增工作模式切換指南
- [ ] 新增新 Skills 說明

### Step 4: 驗證與測試

- [ ] 驗證所有 Skills 格式
- [ ] 測試 hooks 執行
- [ ] 確認無功能衝突

## 測試計畫

1. 每個新 Skill 手動觸發測試
2. Hooks 事件觸發驗證
3. CLAUDE.md 語法檢查

## Checklist

- [x] 建立 OpenSpec 規格
- [x] 建立新 Skills (security-reviewer, build-error-resolver, refactor-cleaner)
- [x] 整合 Hooks (hooks-template.json, session-start.sh, session-end.sh, pre-compact.sh)
- [x] 更新 CLAUDE.md
- [x] 更新 README.md
- [ ] 提交變更
