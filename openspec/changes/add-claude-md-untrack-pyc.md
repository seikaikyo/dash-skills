---
title: 新增 CLAUDE.md 並移除追蹤中的 Python 快取檔
type: docs
status: in-progress
created: 2026-10-14
---

# 新增 CLAUDE.md 並移除追蹤中的 Python 快取檔

## 變更內容

1. 新增根目錄 `CLAUDE.md`，說明目錄結構、每日同步流程與修改規則。push 前的架構檢查要求根目錄有這個檔案，repo 之前沒有。
2. `scripts/__pycache__/gate-external.cpython-312.pyc` 在 2026-10-04 隨每日同步被 commit 進來，內含本機絕對路徑。從 git 移除追蹤，`.gitignore` 加上 `__pycache__/` 與 `*.pyc`，避免每日同步的 `git add scripts` 再把它帶進來。
3. `scripts/hooks/hooks-template.json` 的 PR 記錄 hook 改讀 `tool_response.stdout`（已在 8f538689 完成，與本提案一起推）。

## 影響範圍

- `CLAUDE.md`（新增）
- `.gitignore`
- `scripts/__pycache__/`（移除追蹤，本機檔案保留）
- `scripts/hooks/hooks-template.json`

## UI 規格

無 UI 變更。

## 測試計畫

- `git ls-files | grep -c pyc` 結果為 0
- 重跑 `python3 scripts/gate-external.py --help` 等會產生快取的指令後，`git status` 不出現 `__pycache__`
- `CLAUDE.md` 不含本機絕對路徑：`grep -c '/Users/' CLAUDE.md` 為 0
- push 通過架構檢查與 OpenSpec 檢查
