---
title: 每日同步改由 launchd 執行
type: fix
status: in-progress
created: 2026-10-03
---

# 每日同步改由 launchd 執行

## 問題

`scripts/auto-update.sh` 由 `~/.zshrc` source，在開殼層的前景跑完整趟（外部同步、閘門掃描每個集合最多 240 秒、commit、push）。
殼層被關掉或中斷時整趟就斷，而 `.last-update` 在腳本開頭就寫入，當天不會重跑。

2026-09-26 到 2026-10-03 每天都斷在閘門掃描，security-reports/ 沒有任何新報告，8 天沒有 commit；
被閘門擋下的集合每天重新下載完整新版，工作區累積到 386 個檔案、+45,610 / -28,787 行。

## 變更內容

1. 新增 `scripts/launchd/com.dash.skills-auto-update.plist`：每天 06:00 由 launchd 在背景執行，輸出寫入 `~/Library/Logs/dash-skills-auto-update.log`，與殼層生命週期脫鉤。
2. `scripts/auto-update.sh`：
   - 開頭只建鎖（`.auto-update.lock`，記 PID，程序不在就視為殘留鎖清掉），防止同時兩個實例。
   - `.last-update` 改在整趟跑完才寫入；中途中斷不寫，下次觸發會補跑。
3. `~/.zshrc` 改為：當天還沒跑完且沒有在跑時，`launchctl kickstart` 觸發同一個 launchd job（立即返回，不佔前景），取代直接 source。
4. README 三語的自動同步段落同步更新。

## 影響範圍

- `scripts/auto-update.sh`
- `scripts/launchd/com.dash.skills-auto-update.plist`（新增）
- `README.md` `README.en.md` `README.ja.md`
- 本機：`~/Library/LaunchAgents/`、`~/.zshrc`（不在 repo 內）

## UI 規格

無 UI。

## 測試計畫

- `plutil -lint` 驗證 plist。
- `bash -n scripts/auto-update.sh` 語法檢查。
- `launchctl print gui/$UID/com.dash.skills-auto-update` 確認已載入且排程正確。
- 當天已完成時 kickstart：腳本立即結束，log 無同步輸出。
- 刪除 `.last-update` 後 kickstart：整趟跑完、log 有「完成」、`.last-update` 為當天、git 工作區乾淨。
- 跑到一半 `launchctl kill TERM`：`.last-update` 不更新、鎖被清掉，下一次觸發會重跑。
