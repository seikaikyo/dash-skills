# 外部 skill 同步：不跟隨符號連結、閘門不受 .gitattributes 影響

- **type**: fix
- **建立日期**: 2026-11-16
- **status**: completed

## 背景

2026-11-16 檢查同步流程時找到兩個閘門沒擋到的情況，都在本機重現過：

1. `scripts/update-external.sh` 用 `cp -r` 複製上游目錄。macOS 的 `cp -r` 會跟隨符號連結並複製目標內容，上游目錄裡的連結若指到 repo 以外的本機檔案，該檔內容會變成 `external/` 底下的一般檔案，之後被提交並推送。
2. `scripts/gate-external.py` 的 `added_lines()` 靠 `git diff` 的新增行跑規則。上游目錄裡放一個 `.gitattributes`（例如 `* -diff`），diff 只印「Binary files differ」，新增行清單是空的，所有差異規則都不會命中。

## 變更內容

1. `scripts/update-external.sh`：8 處 `cp -r` 改成 `cp -RP`，符號連結照原樣複製、不跟隨。來源結尾帶斜線與 `/.` 的語義不變。
2. `scripts/gate-external.py`：
   - 新增 `structure_blocks()`：`external/<name>` 底下有符號連結或 `.gitattributes` 就隔離，不走 allowlist。
   - `added_lines()` 的 diff 加 `--text --no-ext-diff --no-textconv`，強制逐行比對。
3. `scripts/auto-update.sh`：提交前檢查 `external/` 底下有沒有符號連結，有就停止提交與推送。
4. `scripts/tests/test_gate_structure.py`（新增）：沿用 `test_gate.py` 的暫存 repo，新增 5 項。

## 影響範圍

- 只動同步與閘門腳本，不動 `external/` 與 `skills/` 的內容。
- 目前 `external/` 底下沒有被追蹤的符號連結，也沒有 `.gitattributes`，既有集合不會因此被隔離。
- 上游之後若真的需要這兩種檔案，該次更新會被隔離，由人看過再決定。

## UI規格

無畫面變更。

## 測試計畫

1. `python3 scripts/tests/test_gate_structure.py`：新增 5 項加上沿用 `test_gate.py` 的項目全過。改動前的腳本跑同一份，新增的 5 項有 4 項失敗。
2. 複製語義：同一棵沒有連結的目錄樹，用腳本裡出現的四種寫法（來源帶斜線、`/.`、目標不存在、`*` 展開）各以 `cp -r` 與 `cp -RP` 複製，產出的檔案清單逐行相同。
3. 連結行為：目錄裡放一個指到外部檔案的連結，`cp -r` 產出含目標內容的一般檔案，`cp -RP` 產出連結。
4. `bash -n` 與 `py_compile` 通過。

## 後續（不在這次範圍）

- 七個上游來源目前都跟分支最新版，沒有釘 commit。
- 排程執行前會載入整份環境變數檔，同步流程用不到其中大部分。
