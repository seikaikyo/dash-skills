# pi-agent

個人 pi.dev 工作配置。把 Claude Code 那套工作紀律與攔截搬到 pi。

不含 pi 安裝與內部 model 設定:那兩塊照部署環境既有方式處理,本目錄只提供讀檔即生效的配置。

## 內容

| 檔案 | 放到 | 作用 |
|------|------|------|
| `AGENTS.md` | `~/.pi/agent/AGENTS.md` | 工作風格與工程紀律(append 到 system prompt) |
| `APPEND_SYSTEM.md` | `~/.pi/agent/APPEND_SYSTEM.md` | 核心行為約束:機密邊界 / 對外確認 / 誠實 / 簡潔 |
| `extensions/guardrails.ts` | `~/.pi/agent/extensions/guardrails.ts` | 危險 git / 對外動作 / 刪除 / 機敏檔 / emoji 攔截 |
| `settings.fragment.json` | 併進 `~/.pi/agent/settings.json` | 列出要載入的 skill 與 extensions |

## AGENTS.md vs APPEND_SYSTEM.md vs SYSTEM.md

- `APPEND_SYSTEM.md`:**追加**到 system prompt base 層,不取代預設。放跨專案的核心行為紅線。
- `AGENTS.md`:context files,放工作風格與工程紀律,在專案層注入。
- `SYSTEM.md`(本目錄不提供):**整碗取代**預設 system prompt,會丟掉 pi 預設的工具清單與 guidelines。coding 場景不建議;要把 pi 改成非 coding 用途才考慮。

## 安裝

1. 各檔放到上表位置(`extensions/` 目錄沒有就建)。
2. `settings.fragment.json` 的 `skills` 與 `extensions` 兩個 key **併進**現有 `settings.json`,不要整檔覆蓋(避免蓋掉環境已配好的 model / provider)。把 `CHANGE_ME` 改成 skills repo 的實際 clone 路徑。
3. 進 pi 執行 `/reload`。
4. 驗證:要 agent 跑 `git add -A`,應被擋下。

## guardrails 怎麼判斷

shell 指令先拆成一個個簡單指令再逐詞判斷,結果分三種:直接擋、先問、放行。

| 情況 | 結果 |
|------|------|
| `git add` 帶 `-A` `--all` `-u` `.` `:/` 或萬用字元;`git commit` 帶 `-a`(含 `-am`)或 `--all`;commit message 含 emoji | 擋 |
| `git push`、`git clean`、`git reset --hard`、`gh` 的寫入動作(讀取類 `view` `list` `status` `diff` `checks` 與不帶寫入參數的 `gh api` 除外) | 先問 |
| `rm` 帶 `r` `R` `f` 任一或對應長選項、`find -delete`、`find -exec` | 先問 |
| 寫入、讀取、重新導向、`tee` `cp` `mv` 這類指令碰到機敏路徑(`.env*`、`.envrc`、私鑰、`.pem`、`.key`、`credentials`、`secret`、`.ssh/`、`.aws/` 等) | 先問 |
| 看不出要做什麼:`$(...)`、反引號、變數當指令、`eval`、`sh -c`、`xargs`、管線接 shell 或直譯器、`git -c alias.` | 先問 |
| `bash`、`write`、`edit`、`powershell` 的欄位格式認不得;判斷過程出錯 | 擋 |
| 需要確認但沒有互動介面(例如非互動模式) | 擋 |

做不到的:執行腳本檔(`bash x.sh`、`python3 x.py`)時看不到腳本內容,照放行。

改了規則後跑 `node --experimental-strip-types --test scripts/tests/test_pi_guardrails.mjs`(不需要安裝 pi)。

## skill 清單

`settings.fragment.json` 逐一列出要給 pi 載入的目錄,不指向整個 `external/`。pi 會在列出的目錄裡遞迴找 `SKILL.md`,整個 `external/` 會把集合裡所有巢狀 skill 一起載入,包括會自動改寫並 push 的 skill 與跟其他集合同名的 skill。

- sentry 集合只列 `security-review`。
- `external/` 新增的集合不會自動給 pi,要用就自己加一行。

## 注意

- 在沒裝 pi 的機器上用編輯器開 `guardrails.ts`,會看到 `Cannot find module '@earendil-works/pi-coding-agent'` 的型別提示,屬正常:它只從 pi 套件引入型別,執行與測試都不需要 pi。
- extension API 基於 @earendil-works 公開版。若是改過的 fork,`event.input` 欄位名可能不同;對不上時會擋下並在原因裡寫出缺哪個欄位,照內部文件改 `decide()` 讀的欄位名即可。

## 安全(repo 當內外網橋樑時)

這是 public repo。在受限環境 clone 回去後,移除 remote 避免任何內部內容被推回公開:

```
git remote remove origin
```

只進不出。
