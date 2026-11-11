# 全面檢查後的修正：關掉閘門外的更新、移除載入不到與非原廠內容

- **type**: fix
- **建立日期**: 2026-11-10

## 背景

2026-11-10 依「官方為主、其餘自建」的原則對整個 repo 做全面檢查：8 個上游逐檔比對、`gate-external.py` 的規則掃 2,634 個檔案、SkillSpector 2.13.3 掃全部 45 個 skill。沒有發現惡意內容，但找到幾個繞過閘門或不符原則的問題。使用者同意修正下列項目。本提案接在 official-main-only-external-2026-11-09 之後，同一個 PR。

## 變更內容

### 1. 每日同步不再自動安裝 agent-browser

`update-external.sh` 原本每天執行 `npm install -g agent-browser@latest`。`external/agent-browser/SKILL.md` 只是空殼，實際指令由 CLI 的 `agent-browser skills get core` 提供，所以這個套件等於每天自動更新的執行碼加 agent 指令，沒有釘版本、沒有冷卻期，也不經過閘門。移除這段，升級改為手動並指定版本（README「自動同步」一節）。

### 2. web-design-guidelines 改為自建

上游版本每次執行都叫 agent 用 WebFetch 抓 `raw.githubusercontent.com` 上的規則並照做，真正的指令不在 repo、不經過閘門。移除 `external/web-design-guidelines` 與同步函數，新增 `skills/web-design-guidelines/SKILL.md`：規則全部寫在檔案裡（鍵盤與互動、表單、內容語意、動畫、效能、狀態、主題、介面層安全共 8 類），原創撰寫，針對 Vue / Nuxt / Angular 與 PrimeVue / PrimeNG。名稱沿用，`/web-design-guidelines` 不需更動。這取代了 official-main-only-external-2026-11-09 中「web-design-guidelines 改從 main 同步」那一項。`discover-new-skills.sh` 把它列入刻意不收的清單。

### 3. 移除 trailofbits-skills-curated

這包是 Trail of Bits 審過後轉載的第三方作者 skill（598 檔、43 支腳本），不是原廠自己寫的；其中 `wooyun-legacy` 是攻擊手法庫，含 webshell 與反彈 shell 範例，和 2026-10-25 移除的攻擊型 skill 同類。它沒有頂層 `SKILL.md`，Claude Code 本來就載入不到。移除目錄與同步函數。

`trailofbits-security`、`sentry-security-review`、`neon-skills` 同樣是 Claude Code 載入不到的集合型目錄，這次不動，留待使用者決定要保留哪些子 skill。

### 4. ui-ux-pro-max 精簡到實際被載入的部分

內化包原有 7 個子 skill、264 個檔案，只有內層 `ui-ux-pro-max` 被連結。其餘 6 個（banner-design、brand、design、design-system、slides、ui-styling）沒被載入，卻含有會讀 `~/.claude/.env`、把金鑰載入環境並呼叫第三方 AI 服務的腳本，以及 54 個字型檔。刪除這 6 個子 skill 與上游 README，把內層內容攤平到 `skills/ui-ux-pro-max/`，保留 `LICENSE`（MIT）。剩 74 個檔案，腳本只查本機 CSV，沒有連網或子行程。`link.sh` 的 `NESTED_OVERRIDES` 清空（機制保留）；`install.sh` 以前複製整個目錄、頂層沒有 `SKILL.md` 的問題也一併消失。

### 5. fastapi-patterns 的不安全範例

- CORS：`cors_origins` 不再預設 `["*"]`，改為必填並明列來源；`allow_credentials=False`（token 走 Authorization header）；方法與標頭改為明列。
- 認證：原本用 HS256 共用密鑰，與實際的 Logto 認證不符。`jwt.decode` 傳整個 PyJWK 而不是 `.key`，token 標頭的演算法與金鑰型別不符時才會回 401 而不是 500。全域 `HTTPException` handler 補上 `headers=exc.headers`，401 的 `WWW-Authenticate` 才不會被丟掉。改為用 Logto JWKS 公鑰驗證（PyJWT 的 `PyJWKClient`），檢查 issuer、audience、必要欄位，演算法清單只列非對稱演算法（ES384、RS256）。寫法對照 Logto 官方文件的 Python 範例。JWKS 抓不到回 503，其餘驗證失敗回 401。
- 權限：`require_role` 改為 `require_scopes`，Logto 的 RBAC 把權限放在 access token 的 `scope`。
- 相依：`python-jose` 換成 `PyJWT[crypto]>=2.15.0`（程式碼本來就 `import jwt`，版本下限依 security-radar）。
- `render.yaml` 的 `JWT_SECRET` 換成 `LOGTO_ENDPOINT`、`LOGTO_API_RESOURCE`、`CORS_ORIGINS`。
- 「禁止事項」加兩條：禁止 CORS 萬用來源、禁止用共用密鑰驗 token。

### 6. launchd 設定檔不放本機路徑

`scripts/launchd/com.dash.skills-auto-update.plist` 原本在 `StandardOutPath`、`StandardErrorPath`、`EnvironmentVariables` 寫死使用者家目錄，違反 CLAUDE.md「不放本機路徑、帳號」。launchd 這幾個欄位不展開 `$HOME`，所以把 PATH 設定與 log 導向移進 `bash -c` 指令。行為不變：log 仍附加到 `~/Library/Logs/dash-skills-auto-update.log`。

### 7. 文件與設定清理

- 三份 README：自建 20、外部 25；補上中文版空白的「安裝」；刪掉空的「更新紀錄」；「致謝」移除已不收錄的作者，補上 Cloudflare、Sentry 與自建 skill 的改寫來源。
- `CLAUDE.md`：數量改為 20 / 25。
- `.scanignore`、`.gitignore`：刪掉已移除 skill 的項目。
- `update-external.sh`：刪掉 26 行已移除 skill 留下的註解標題。
- `doubt-driven-development`：兩處指向已不存在的 `external/tgd-skills` 的參照改為文字說明，跨模型流程的兩條安全守則直接寫進本文。
- `link.sh`：新增死連結清理。只移除「指向本 repo 的 `skills/` 或 `external/`、而且目標已不存在」的符號連結，其他連結與目錄不動。原本文件說重跑 `link.sh` 會清掉死連結，但腳本沒有這段邏輯。
- `discover-new-skills.sh`：已抓清單只算來源是 `vercel-labs/agent-skills` 的 skill，不再把另一個 repo 的 `agent-browser` 算進去。
- `openspec/changes/`：7 份已完成的提案移到 `archive/`。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| external/ | 再移除 2 個目錄（web-design-guidelines、trailofbits-skills-curated），外部 25 個。 |
| skills/ | 新增 web-design-guidelines；ui-ux-pro-max 264 → 74 檔；fastapi-patterns 改寫認證與 CORS。自建 20 個。 |
| scripts/ | update-external.sh、discover-new-skills.sh、link.sh、launchd plist。 |
| 使用者的 Mac | 合併後要做三件事，見「合併後」。 |

## 合併後

1. 重新安裝 launchd 設定：`launchctl bootout gui/$(id -u)/com.dash.skills-auto-update`，複製新的 plist 到 `~/Library/LaunchAgents/`，再 `launchctl bootstrap`。不做的話舊設定照常運作，只是沒套用新版。
2. 重跑 `scripts/link.sh`（每日同步也會跑）：它會移除已刪除 skill 留下的死連結，並讓 `ui-ux-pro-max`、`web-design-guidelines` 指向新位置。
3. agent-browser CLI 之後手動升級：`npm install -g agent-browser@<版本>`。

## 剩餘風險

- plist 的新寫法在 Linux 上以相同指令驗證過（log 導向、PATH、`.env` 載入），但沒有在 macOS 的 launchd 下實跑。
- `ui-ux-pro-max` 自帶測試有 4 個載入錯誤，精簡前後相同，原因是測試依賴上游 repo 的目錄結構，與這次變更無關。
- 這次檢查另外發現、但不在本提案範圍的項目：同步的 45 秒硬上限與兩個沒同步進來的上游更新、其餘三個集合型目錄、部分外部 skill 同步時沒帶 LICENSE、直接執行 `update-external.sh`（不經 `auto-update.sh`）會跳過閘門就提交。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n` 檢查 `update-external.sh`、`discover-new-skills.sh`、`link.sh` 通過；`update_*` 函數的定義、平行清單、case 分派三者一致。
2. `plistlib` 能解析 plist；以相同指令在暫存 HOME 下執行，確認 log 寫入與 PATH。
3. `fastapi-patterns` 的 `config.py`、`dependencies.py` 範例實際執行：有效 token 通過；audience 或 issuer 不符、過期、缺欄位、其他金鑰簽的、未知 kid、用公鑰偽造的 HS256、`alg: none`、標頭演算法與金鑰型別不符、亂碼都回 401；scope 不足回 403；JWKS 抓不到回 503。
4. `ui-ux-pro-max` 精簡後 `scripts/search.py` 可查詢，自帶測試結果與精簡前相同。
5. 三份 README 列出 45 個 skill（自建 20、外部 25），與目錄一致。
6. `update-external.sh` 在隔離的副本裡完整跑一次：25 個來源全部成功，抓回的目錄與 README 的外部清單相同。
7. `link.sh` 在暫存 HOME 下測試：指向本 repo 的死連結被移除，指向別處的死連結、有效連結與一般目錄都不動，第二次執行不再有動作。
