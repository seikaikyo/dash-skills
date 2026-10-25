# 修復 cloudflare 與 sentry 同步，個別 skill 失敗改為會被看見

- **type**: fix
- **建立日期**: 2026-10-25

## 背景

2026-10-25 手動跑每日同步：29 個原廠 skill 中 27 個成功，cloudflare-security-audit 與 sentry-security-review 失敗。查 git 紀錄，cloudflare 從 2026-06-29、sentry 從 2026-04-18 起就沒有成功同步過，失敗了 4 到 6 個月。

原因有兩層：

1. 上游改了目錄結構。cloudflare/security-audit-skill 把檔案從 repo 根目錄移到 `skills/security-audit/`；getsentry/skills 把 skill 從 `plugins/sentry-skills/skills/` 移到根目錄 `skills/`。同步函數的路徑判斷變成 false，落到「狀態: 失敗」。
2. 失敗被吞掉。auto-update.sh 把 update-external.sh 的輸出導到 /dev/null，只看整支有沒有逾時；個別 skill 失敗不影響結束碼，只是一行字，沒有人看得到。

## 變更內容

1. update_cloudflare_security_audit：來源改為 `repo/skills/security-audit/`，整個目錄複製，不再逐檔列舉（上游持續新增 .md 與 .cjs）。README 與 LICENSE 仍從根目錄取。
2. update_sentry_security_review：來源改為 `repo/skills/`。
3. 兩個函數失敗時改印「上游結構改變，找不到 <路徑>」，下次看到就知道要改哪裡。
4. update-external.sh 平行統計後，把失敗與逾時的 skill 名稱寫進 `.last-sync-failures`（附時間）；全部成功時清空。
5. auto-update.sh 在同步步驟後讀 `.last-sync-failures`，非空就印出警告與清單。
6. `.gitignore` 加入 `.last-sync-failures`（本機狀態）。

另案：把 `.last-sync-failures` 接進 ~/.claude/hooks/daily-audit.sh 的每日巡檢報告（使用者每天讀的地方），屬 repo 外的 hook 變更，另行處理。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| scripts/update-external.sh | 兩個同步函數改路徑；新增失敗清單輸出。 |
| scripts/auto-update.sh | 同步後顯示失敗清單。 |
| .gitignore | 新增一行。 |
| external/ | 下次同步會重新取得 cloudflare-security-audit 與 sentry-security-review 的最新內容。 |

## 剩餘風險

sentry-security-review 的上游現在是 30 個 skill 的集合（含 commit、security-review、find-bugs 等），同步後內容會比以前多；它沒有頂層 SKILL.md，屬未載入的集合，不影響 Claude Code 載入的 skill。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh`、`bash -n scripts/auto-update.sh` 通過。
2. 在沙箱外跑 `DASH_SKILLS_NO_PUSH=1 bash scripts/update-external.sh`，cloudflare-security-audit 與 sentry-security-review 顯示「狀態: 已更新」，結果 29 成功。
3. 全部成功時 `.last-sync-failures` 為空；人為讓一個失敗時檔案列出該 skill。
