# pi 設定範本：防護改成逐詞判斷、對外動作要確認、只載入列出的 skill

- **type**: fix
- **建立日期**: 2026-11-16
- **status**: in-progress

## 背景

2026-11-16 的安全審查確認 `pi-agent/extensions/guardrails.ts` 的攔截可以用常見的其他寫法繞過，例如 `git commit -am`、`git add -u`、`rm -Rf`、`rm --recursive --force`、寫入 `.envrc` 或 `id_ed25519`。原因是它對整串指令做幾條固定的正規表示式比對，只看 `bash` 與 `write` 兩種工具，欄位名稱對不上時直接放行。

另外兩點：

1. `APPEND_SYSTEM.md` 要求 push 與對外寫入前先確認，但只寫在提示文字裡，沒有程式強制。
2. `settings.fragment.json` 讓 pi 讀整個 `external/`。pi 會遞迴找出所有 `SKILL.md`，連同 sentry 集合裡會自動改寫並 push 的 `iterate-pr` 與兩個跟其他集合同名的 skill 一起載入。

這台機器沒有安裝 pi，這些問題影響的是照這份公開範本安裝的人。

## 變更內容

1. `pi-agent/extensions/guardrails.ts` 重寫判斷方式：
   - 把 shell 指令拆成一個個簡單指令再逐詞判斷，不對整串字做比對。
   - 指令內容沒辦法靜態看出要做什麼時一律先問：指令替換 `$(...)` 與反引號、變數放在指令位置、`eval`、`sh -c` 這類巢狀 shell、`xargs`、管線接到 shell 或直譯器。
   - `git add`：`-A`、`--all`、`-u`、`--update`、`.`、`:/`、萬用字元直接擋；其他選項先問；指名路徑放行。git 的全域選項（`-C`、`-c`）之後的子指令也看得到。
   - `git commit`：短選項群組含 `a`（`-a`、`-am`）或 `--all` 直接擋；提交訊息含 emoji 擋。
   - `git push`、`git clean`、`git reset --hard` 先問。
   - `gh`：只有讀取類（`view`、`list`、`status`、`diff`、`checks`，與不帶寫入參數的 `gh api`）直接放行，其餘先問。
   - 刪除：`rm` 帶 `r`、`R`、`f` 任一或對應長選項、`find -delete`、`find -exec rm` 先問。
   - 機敏路徑（`.env*`、`.envrc`、私鑰、`.pem`、`.key`、`credentials`、`secret`、`.ssh/`、`.aws/`、`.netrc`、`.npmrc` 等）：寫入類工具、重新導向、`tee`、`cp`、`mv` 這類指令碰到就先問。
   - 檢查範圍擴大到 `write`、`edit`、`bash`、`powershell`；讀取類工具放行。已知工具的欄位格式認不得時直接擋；其他工具帶了指令或路徑欄位時先問。
   - 需要確認但目前沒有互動介面時擋下。判斷過程出錯也擋下。
   - 只從 pi 套件引入型別，判斷邏輯不依賴 pi 執行環境，沒裝 pi 也能測。
2. `pi-agent/settings.fragment.json`：`skills` 從整個 `external/` 改成逐一列出集合；sentry 集合只列 `security-review`。之後新增的外部集合不會自動給 pi 載入。
3. `pi-agent/README.md`：說明防護的判斷方式與 skill 清單怎麼維護。
4. `scripts/tests/test_pi_guardrails.mjs`：用 Node 的 TypeScript 型別去除直接載入 `guardrails.ts` 測判斷結果。

## 影響範圍

- 只動 `pi-agent/` 範本與一支測試，不影響 Claude Code 與每日同步。
- 照新範本安裝的 pi 會比以前多問幾次（push、gh 寫入、看不懂的指令）。

## UI規格

無畫面變更。

## 測試計畫

1. 新增 `node --experimental-strip-types --test scripts/tests/test_pi_guardrails.mjs`：
   - 審查列出的繞過寫法都被擋或先問。
   - 一般指令（`git status`、`git add 指名檔案`、`git commit -m`、`ls`、`gh pr view`）直接放行。
   - 無法靜態判讀的指令先問。
   - 欄位格式不對的已知工具被擋；確認時沒有互動介面被擋；使用者拒絕時被擋。
2. 改動前的 `guardrails.ts` 跑同一份測試，繞過寫法的項目要失敗（舊版需要 pi 套件才能載入，改用同樣規則的副本比對）。
3. `settings.fragment.json` 列出的每個路徑在 repo 裡都存在且含 `SKILL.md`，沒有列到 `iterate-pr`。
