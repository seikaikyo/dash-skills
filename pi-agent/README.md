# pi-agent

個人 pi.dev 工作配置。把 Claude Code 那套工作紀律與攔截搬到 pi。

不含 pi 安裝與內部 model 設定:那兩塊照部署環境既有方式處理,本目錄只提供讀檔即生效的配置。

## 內容

| 檔案 | 放到 | 作用 |
|------|------|------|
| `AGENTS.md` | `~/.pi/agent/AGENTS.md` | 工作風格與工程紀律(append 到 system prompt) |
| `APPEND_SYSTEM.md` | `~/.pi/agent/APPEND_SYSTEM.md` | 核心行為約束:機密邊界 / 對外確認 / 誠實 / 簡潔 |
| `extensions/guardrails.ts` | `~/.pi/agent/extensions/guardrails.ts` | 危險 git / 機敏檔 / emoji 攔截 |
| `settings.fragment.json` | 併進 `~/.pi/agent/settings.json` | 指向 skills 與 extensions |

## AGENTS.md vs APPEND_SYSTEM.md vs SYSTEM.md

- `APPEND_SYSTEM.md`:**追加**到 system prompt base 層,不取代預設。放跨專案的核心行為紅線。
- `AGENTS.md`:context files,放工作風格與工程紀律,在專案層注入。
- `SYSTEM.md`(本目錄不提供):**整碗取代**預設 system prompt,會丟掉 pi 預設的工具清單與 guidelines。coding 場景不建議;要把 pi 改成非 coding 用途才考慮。

## 安裝

1. 各檔放到上表位置(`extensions/` 目錄沒有就建)。
2. `settings.fragment.json` 的 `skills` 與 `extensions` 兩個 key **併進**現有 `settings.json`,不要整檔覆蓋(避免蓋掉環境已配好的 model / provider)。把 `CHANGE_ME` 改成 skills repo 的實際 clone 路徑。
3. 進 pi 執行 `/reload`。
4. 驗證:要 agent 跑 `git add -A`,應被擋下。

## 注意

- `guardrails.ts` 在沒裝 pi 的機器上會報 `Cannot find module '@earendil-works/pi-coding-agent'`,屬正常。裝了 pi 的機器才解析得到型別。
- extension API 基於 @earendil-works 公開版。若是改過的 fork,`event.input` 欄位名可能要對照內部文件微調。

## 安全(repo 當內外網橋樑時)

這是 public repo。在受限環境 clone 回去後,移除 remote 避免任何內部內容被推回公開:

```
git remote remove origin
```

只進不出。
