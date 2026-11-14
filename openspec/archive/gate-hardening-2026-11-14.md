# 外部 skill 閘門補強：掃描完整度、被忽略的檔案、私鑰、文件類規則

- **type**: fix
- **建立日期**: 2026-11-14

## 背景

2026-11-14 判讀四個被隔離的更新後，回頭讀 `scripts/auto-update.sh`、`scripts/gate-external.py`、`scripts/scan-skills.sh`，找到四個閘門沒擋到的情況：

1. 掃描沒跑完也算通過。SkillSpector 2.10.0 的時間上限寫死在程式裡，沒有選項可調。trailofbits-security（1639 檔）整包掃描時，完整檢查的檔案是 0 個，23 個分析器有 13 個一個檔都沒跑完，`scan-skills.sh` 只看風險分數，結果仍判「通過」。同一個集合拆成單一子目錄掃描時可以完整檢查（實測最大的子目錄 144 檔、14 秒）。
2. 閘門用 git 的差異與未追蹤清單找檔案，被忽略規則蓋到的檔案不進差異規則、不會被 commit，隔離還原時也不會被清掉。忽略規則包含上游自己帶進來的 `.gitignore`。
3. 同步後發現私鑰只印警告，commit 與 push 照常進行。
4. 「下載後直接執行」與「提到本機憑證位置」兩條規則，寫在腳本檔會擋，寫在文件檔只印注意。skill 的本體是文件。

## 變更內容

1. `scripts/scan-skills.sh`：報告有效後檢查完整度（部分檢查與未檢查的檔案數）。不完整時改呼叫新的 `scripts/scan-split.py` 逐一掃描第一層子目錄並合併成一份報告；合併後仍不完整就回報 `incomplete`。
2. `scripts/scan-split.py`（新增）：
   - 對每個第一層子目錄各跑一次 SkillSpector，頂層散檔另成一組；既有 baseline 依子目錄前綴拆出對應規則；合併報告的檔案路徑補回前綴，`merge-baseline.py` 不需更動。
   - `--complete-check` 判定報告是否涵蓋全部檔案，不完整時列出檔案、原因與可直接貼上的接受指令。
   - 拆開掃也過不了掃描器輸出上限的個別檔案（實測是很長的鎖檔這類），人工看過後在 `security-reports/scan-incomplete-allow.tsv` 加一行接受，可帶 sha256 只接受該版內容。報告沒有逐檔指名的缺口不能接受。
3. `scripts/gate-external.py`：
   - `incomplete` 與 `alert`、`failed`、`timeout` 一樣隔離。
   - 檢查前先刪除 `external/` 底下被忽略規則蓋到的檔案（`--dry-run` 只列不刪）；隔離還原時連被忽略的檔案一起清。
   - 新增 `private-key` 規則（BLOCK，適用所有檔案）。
   - `pipe-to-shell-doc`、`credential-path-doc` 由 WARN 改 BLOCK。
4. `scripts/tests/test_gate.py`（新增）：在暫存 repo 用假的 skillspector 跑閘門，涵蓋上述四項與接受清單，共 9 項。同一份測試拿改動前的腳本跑，原有 7 項裡 5 項失敗。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| 每日同步 | 大型集合的掃描從一次整包改成逐子目錄。trailofbits-security 實測拆成 49 組，1639 檔裡 1637 檔完整檢查，剩 2 檔卡在輸出上限；四個目錄合計 280 秒。 |
| trailofbits-security | 既有 baseline 是從不完整的掃描累積的，改成完整掃描後會出現以前沒看到的告警，下一次上游更新會被隔離，要人工判讀後補 baseline。 |
| 文件類規則 | 同步記錄檔全部歷史裡這兩條共出現 25 次、集中在 3 個檔案。之後同類內容會被隔離，誤報用 `security-reports/gate-allow.tsv` 放行。 |
| external/ 底下被忽略的檔案 | 每次閘門執行時刪除。這些檔案本來就不會被 commit。 |

## 剩餘風險

- 差異規則是逐行比對的固定句型，換說法或拆行的內容比不到，這一層仍要靠掃描器與人工判讀。
- 二進位檔沒有文字差異，只有掃描器會看。
- 同步仍然追上游分支最新版，沒有釘 commit。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/scan-skills.sh`、`python3 -m py_compile scripts/gate-external.py scripts/scan-split.py` 通過。
2. `python3 scripts/tests/test_gate.py` 全過：
   - 被根目錄與巢狀 `.gitignore` 蓋到的檔案在閘門執行後不存在。
   - 文件檔新增下載後執行的指令列會被隔離並還原。
   - 新增內容含私鑰標頭會被隔離。
   - 掃描報告不完整且拆開後仍不完整會被隔離；拆開後完整則通過，合併報告的路徑帶子目錄前綴，baseline 規則有套用到子目錄。
   - 個別檔案要有相符的接受紀錄才算完整，內容變了接受就失效；沒有逐檔指名的缺口不能接受。
3. 對現有 `external/trailofbits-security` 實跑拆分掃描，確認合併報告完整，並回報 baseline 外的告警數。
4. 改動前後對照：對四個今天放行的目錄各跑一次 `scan-skills.sh`，小型集合的判定與改動前相同。

## 後續調整（同日，SkillSpector 升到 2.13.3 之後）

- `scripts/scan-skills.sh`：整包掃描逾時也改走逐子目錄掃描；設定 `SKILLSPECTOR_MAX_WORKFLOW_SECONDS`（預設為外層逾時減 30 秒），讓掃描器先交出部分報告。
- `scripts/scan-split.py`：新增 `--accept`，把報告指名的未完整檔案以目前內容的 sha256 寫進接受清單；`reference_missing` 不算缺口。
- `scripts/tests/test_gate.py`：新增逾時後改走逐子目錄的測試，共 10 項。
