# 每日同步：先在暫存工作目錄同步與檢查，過閘門才套用到 external/

- **type**: fix
- **建立日期**: 2026-11-16
- **status**: completed

## 背景

2026-11-16 的安全審查確認：每日同步直接把上游內容寫進 `external/`，而 `~/.claude/skills` 的連結指向這裡。從同步開始到閘門判定完成的幾分鐘內，還沒檢查過的內容已經可以被 Claude Code 載入。`sync-gate-coverage-2026-11-16` 只補了「中斷時退回」，這段空檔還在。

## 變更內容

1. `scripts/auto-update.sh`
   - 同步、釘版、遮蔽、閘門都改在 repo 的第二個工作目錄（git worktree，放在 `~/Library/Caches/dash-skills-staging`，不在專案目錄內）進行。每次執行前把它重設成主目錄目前的 HEAD 並清空；不存在就建立。路徑上已有東西但不是這個 repo 的工作目錄時停止，不刪除。
   - 同步程序放在獨立的程序群組裡執行，結束或逾時後整個群組一起停掉，避免殘留的複製程序在閘門檢查期間繼續寫檔。
   - 閘門通過後，把暫存目錄的 `external/` 記成 git 物件，再用 `git restore` 從這個物件套用到主目錄的 `external/`（含刪除、權限與已放行的連結），不直接複製檔案。
   - 套用前確認主目錄 HEAD 沒有在執行期間改變；變了就停止，主目錄不動，下次重跑。
   - 閘門失敗、暫存目錄準備失敗：主目錄的 `external/` 完全不動。套用失敗或連結保險檢查失敗：主目錄的 `external/` 退回 HEAD。
   - 同步失敗清單 `.last-sync-failures` 從暫存目錄複製回主目錄，每日巡檢照舊讀得到。
   - 拿掉 `sync-gate-coverage-2026-11-16` 加的「結束時退回」：主目錄在套用前不會被寫入，已不需要。
2. `scripts/gate-external.py`、`scripts/scan-skills.sh`、`scripts/scan-split.py`：放行清單、掃描基準、接受清單、隔離區的位置可用環境變數 `DASH_SKILLS_REPORT_DIR` 指定。排程在暫存目錄執行時指向主目錄的 `security-reports/`；沒設定時照舊用腳本所在 repo 的 `security-reports/`。
3. `CLAUDE.md`：每日同步流程的說明改成暫存目錄的做法。

## 影響範圍

- 只動排程與三支閘門相關腳本。
- `~/Library/Caches/` 會多一份 repo 工作目錄（約跟主目錄的 `external/` 一樣大）。macOS 清快取把它刪掉時，下次執行會重建。
- `git worktree list` 會多一筆暫存目錄。
- 直接手動執行 `update-external.sh` 仍會寫進主目錄（這是手動工具，提示文字照舊要求之後跑一次完整流程）；下次排程會用暫存目錄的結果覆蓋。

## UI規格

無畫面變更。

## 測試計畫

1. 新增或改寫測試（假的同步、閘門、連結腳本，實際執行 `auto-update.sh`）：
   - 閘門通過：主目錄 `external/` 更新、產生一個 commit、連結腳本有跑、閘門讀到的是主目錄的 `security-reports/`。
   - 同步期間主目錄 `external/` 一個位元組都沒變。
   - 上游刪掉的檔案在主目錄也被刪除；已放行的連結以連結形式套用。
   - 同步留下的背景程序在閘門期間寫檔：寫入的內容不會出現在主目錄。
   - 閘門失敗、閘門執行中被中斷：主目錄不動、沒有 commit。
   - 執行期間主目錄 HEAD 改變：停止，主目錄 `external/` 不動。
   - 暫存路徑上是別的東西：停止，不刪除那個路徑。
   - 同步失敗清單複製回主目錄。
   - 閘門與 `scan-split.py` 遵守 `DASH_SKILLS_REPORT_DIR`。
2. 既有測試全過；`bash -n` 與 Python 語法檢查通過。

## 結果

- 新增 8 個測試，其中 6 個在改動前的版本（2fe163e）上失敗、改動後通過；另 2 個（既有暫存目錄先重設、主目錄 HEAD 改變後不套用的對照）是防退步的檢查。
- 測試用的假閘門原本在少了 `DASH_SKILLS_REPORT_DIR` 時會崩潰，讓舊版因「閘門失敗」而全部退回、看起來也通過；改成沒有這個變數也照樣通過，比對才量到套用邏輯本身。
- Python 三套共 117 個、pi 11 組測試全過；`bash -n` 與 Python 語法檢查通過。
- 只在暫存的假 repo 驗過；第一次實際執行是快轉後的下一次排程。
