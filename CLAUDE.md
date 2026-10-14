# dash-skills

Claude Code skills 集合：自建 skill 加上收錄的外部 skill，外部 skill 每日從上游自動同步。這是公開 repo，任何檔案都不放本機路徑、帳號、金鑰或個人資料。

## 目錄結構

| 路徑 | 內容 | 怎麼改 |
|------|------|--------|
| `skills/` | 自建 skill，14 個，每個一個目錄，入口是 `SKILL.md` | 直接編輯 |
| `external/` | 收錄的外部 skill，51 個，每日從上游覆蓋 | 不手改，改了隔天會被蓋掉；要調整就改同步腳本或 `scripts/pin-refs.py` |
| `scripts/` | 安裝、連結、同步、安檢腳本 | 直接編輯 |
| `scripts/hooks/` | 給新專案用的 hook 範本與 session 腳本 | 直接編輯 |
| `scripts/launchd/` | 每日自動更新的 launchd 設定 | 直接編輯 |
| `pi-agent/` | pi 的工作配置，說明見 `pi-agent/README.md` | 直接編輯 |
| `openspec/` | 變更提案（`changes/`）、已完成提案（`archive/`）、規格（`specs/`） | 改動 20 行以上先在 `changes/` 建提案 |
| `security-reports/` | 外部 skill 安檢報告，只留本機 | 已列在 `.gitignore`，不進 repo |

## 每日同步流程

`scripts/auto-update.sh` 由 launchd 每天早上 6 點執行，分五步：

1. 同步：`scripts/update-external.sh` 從上游拉外部 skill，再由 `scripts/pin-refs.py` 把曾遭入侵或會被改指向的引用釘死
2. 清理與遮蔽：刪掉 iCloud 衝突產生的重複檔，把外部 skill 裡金鑰格式的範例值遮蔽掉（GitHub 推送保護連範例值都會擋）
3. 裝載前閘門：`scripts/gate-external.py` 檢查有變更的外部 skill，並呼叫 `scripts/scan-skills.sh` 做靜態安檢；不合格的退回上一個已提交版本。之後 `scripts/link.sh` 重建 `~/.claude/skills` 的符號連結
4. 提交並推送，訊息固定為 `chore: daily external skills sync (日期)`
5. 順帶備份另一個私人設定 repo

## 修改規則

- 新增或移除 skill 時，三份 README（`README.md`、`README.en.md`、`README.ja.md`）的清單與數量一起改。
- 外部 skill 的授權照上游，收錄前確認授權允許再散布。
- Python 快取（`__pycache__/`、`*.pyc`）已列在 `.gitignore`，不要強制加入。
- commit 訊息用英文。
