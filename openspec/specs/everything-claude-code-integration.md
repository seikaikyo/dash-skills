---
title: Everything Claude Code 整合規格
status: active
created: 2026-01-22
source: https://github.com/affaan-m/everything-claude-code
---

# Everything Claude Code 整合規格

## 概述

將 `everything-claude-code` repo 的最佳實踐整合到 dash-skills 生態系統，包括：
- 新增有價值的 Skills
- 優化 CLAUDE.md
- 整合 Hooks 系統
- 改進 MCP 配置

## 來源分析

### 來源 Repo 結構

| 目錄 | 內容 | 價值評估 |
|------|------|---------|
| agents/ | 9 個專業代理 | 高 - 多數可直接採用 |
| skills/ | 7 個技能定義 | 中 - 部分與現有重複 |
| commands/ | 10 個斜線指令 | 高 - 提升操作效率 |
| rules/ | 8 個規則檔案 | 中 - 需與 CLAUDE.md 合併 |
| hooks/ | 完整 Hook 系統 | 高 - 記憶持久化很有價值 |
| contexts/ | 3 種工作模式 | 中 - 可作為 skill 參考 |

### 與現有 Skills 的重複性

| 來源 | 現有對應 | 處理方式 |
|------|---------|---------|
| tdd-guide | superpowers/test-driven-development | 合併增強 |
| code-reviewer | superpowers/verification-before-completion | 合併增強 |
| planner | superpowers/writing-plans | 合併增強 |
| security-reviewer | (無) | 新增 |
| build-error-resolver | (無) | 新增 |
| e2e-runner | agent-browser | 補充增強 |
| refactor-cleaner | (無) | 新增 |

## 整合計畫

### Phase 1: 新增高價值 Skills (優先)

#### 1.1 security-reviewer (安全審查)
- 來源: agents/security-reviewer.md + skills/security-review/
- 功能: OWASP Top 10 漏洞檢測、機密資料掃描
- 整合: 建立 `skills/security-reviewer/`

#### 1.2 build-error-resolver (構建錯誤修復)
- 來源: agents/build-error-resolver.md
- 功能: TypeScript/編譯錯誤快速修復
- 整合: 建立 `skills/build-error-resolver/`

#### 1.3 refactor-cleaner (重構清理)
- 來源: agents/refactor-cleaner.md
- 功能: 死代碼檢測、依賴清理
- 整合: 建立 `skills/refactor-cleaner/`

### Phase 2: 整合 Hooks 系統

#### 2.1 記憶持久化 Hooks
- session-start.sh: 載入先前上下文
- session-end.sh: 保存工作階段狀態
- pre-compact.sh: 壓縮前保存狀態

#### 2.2 程式碼品質 Hooks
- console.log 檢測
- TypeScript 類型檢查
- Prettier 自動格式化

### Phase 3: CLAUDE.md 優化

#### 3.1 新增內容
- Agent 協調系統說明
- Context 視窗管理策略
- 工作模式切換 (dev/research/review)

#### 3.2 合併 Rules
- 合併 coding-style.md 精華
- 合併 performance.md 策略
- 合併 agents.md 協調規則

### Phase 4: MCP 配置優化

- 評估 mcp-servers.json 中的新服務
- 更新視窗管理建議 (70k 限制)

## 檔案結構規劃

```
dash-skills/
├── skills/
│   ├── security-reviewer/      # 新增
│   │   └── SKILL.md
│   ├── build-error-resolver/   # 新增
│   │   └── SKILL.md
│   └── refactor-cleaner/       # 新增
│       └── SKILL.md
├── external/
│   └── everything-claude-code/ # 參考來源 (symlink)
└── scripts/
    └── hooks/                  # Hook 腳本
        ├── session-start.sh
        ├── session-end.sh
        └── pre-compact.sh
```

## 成功標準

1. 新增 3 個高價值 Skills
2. Hooks 系統正常運作
3. CLAUDE.md 涵蓋 Agent 協調
4. 無重複功能衝突
5. 所有 Skill 格式符合 Claude Code 標準

## 風險評估

| 風險 | 影響 | 緩解措施 |
|------|------|---------|
| Skills 功能重複 | 混淆 | 明確標示差異和適用場景 |
| Hooks 與現有工作流衝突 | 干擾 | 漸進式啟用，可選關閉 |
| Context 視窗超載 | 效能下降 | 實施 70k 限制策略 |

## 相關變更

- [[integrate-everything-claude-code]]
