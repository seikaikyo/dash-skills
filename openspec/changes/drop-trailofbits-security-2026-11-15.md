# 移除 trailofbits-security 外部集合

- **type**: chore
- **建立日期**: 2026-11-15
- **status**: in-progress

## 背景

延續 2026-10-25（只留原廠帳號）與 2026-11-09（只收原廠 main 分支）。使用者決定外部 skill 再收斂：能照官方文件自己寫的就自己寫，平常沒在用的外部集合不再每天同步進來。

trailofbits-security 的狀況：

- 1600 多個檔案，是 `external/` 裡最大的一包，閘門掃一次約 9 分鐘，每次都要拆成 48 段才掃得完。
- 沒有頂層 `SKILL.md`，Claude Code 載入不到，平常沒有被使用。
- 2026-11-15 掃描期間，這個目錄裡有一支 Python 程式被不明程序執行，留下編譯快取，來源還沒查出。

## 變更內容

1. `scripts/update-external.sh`：刪除 `update_trailofbits_security`、平行更新清單裡的那一項、指令分派的 `trailofbits-security|trailofbits|tob`、可用清單裡的說明，改留一行註解記下移除日期與原因。
2. `git rm -r external/trailofbits-security`。
3. 三份 README：刪除資安區那一列與致謝裡的 Trail of Bits，外部數量 25 改 24。
4. `CLAUDE.md`：目錄結構表的外部數量 25 改 24。
5. 本機（不進 repo）：刪除放行清單（2 行）與完整度接受清單（90 行）裡屬於這個集合的項目。掃描基準、歷次報告與隔離複本留作紀錄，集合不存在時不會被讀到。

## 影響範圍

- `external/` 剩 24 個集合。
- 使用者另外安裝的 Trail of Bits 外掛市集不在 dash-skills 裡，不受影響。
- `~/.claude/skills/trailofbits-security` 這個連結會變成死連結，`link.sh` 不會自動移除，由使用者手動刪。
- 目錄裡有兩個檔名受沙箱保護的檔案，自動化刪不掉，由使用者手動刪除整個目錄；沒刪的話下一次同步會把它們當新檔提交。

## UI規格

無畫面變更。

## 測試計畫

1. `bash -n scripts/update-external.sh` 通過。
2. `grep` 確認 `scripts/`、README、`CLAUDE.md` 不再有 trailofbits-security 的同步或清單項目。
3. `bash scripts/update-external.sh list`（或無參數以外的說明輸出）不再列出它。
4. 三份 README 與 `CLAUDE.md` 的外部數量一致為 24，且等於 `ls external | wc -l`。
5. `python3 scripts/tests/test_gate.py` 與 `test_gate_structure.py` 全過。
6. 下一次每日同步不再出現 trailofbits-security。
