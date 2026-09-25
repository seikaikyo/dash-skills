# Humanizer-zh-TW：中文文字潤飾 Skill（繁體中文版）

> **聲明：**
>
> - 本專案由 [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh) 繁體化而來，目前同步至其 2026-09-23 修訂
> - 核心規則源自 [blader/humanizer](https://github.com/blader/humanizer)，目前對齊 [v3.0.0](https://github.com/blader/humanizer/blob/v3.0.0/SKILL.md)
> - 中文專屬的 F 組檢查點來自 [Humanizer-zh PR #39](https://github.com/op7418/Humanizer-zh/pull/39)
> - 簡潔表達、編輯檢查與品質評分參考了 [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop)
> - 原專案的觀察來源是維基百科的 [Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) 指南

---

## 專案簡介

Humanizer-zh-TW 用來編輯中文文章、評論和文件中的空話、重複及公式化表達，讓文字更自然，同時保留事實、確定程度和作者聲音。輸入一段文字或一個檔案，預設輸出最終改寫稿；沒有問題的句子可以不改。

這是一份由 AI 代理程式讀取執行的編輯指引，不是獨立的偵測程式。它不能證明文章由誰撰寫，也不保證通過任何 AI 偵測器。

> 2026-09-25 更新：同步上游 2026-09-23 的修訂。規則改為 31 個檢查點，明確要求保留事實、作者立場和文體；一般的排比、破折號和連接詞不再一律修改，也不再預設附上自評分。詳見[更新紀錄](CHANGELOG.md)。

本專案適用於：

- 潤飾、審閱 AI 生成或公式化的中文內容
- 在不改變原意的前提下，刪去空話與重複
- 學習辨識常見的公式化寫作模式
- 以獨立 skill 檢查文字型 AI provenance 與不可見 Unicode 標記

## 安裝

### 方式一：透過 npx skills 安裝（推薦）

使用 [skills](https://github.com/vercel-labs/skills) 工具可以快速安裝到各種 AI 代理程式。本 repo 根目錄是 `humanizer-zh-tw`，子資料夾另有 `text-watermark-cleaner-zh-tw`；加上 `--full-depth` 才會一併找到子資料夾中的 skill。

#### 自動偵測已安裝的代理程式

```bash
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth
```

執行後會列出兩個 skill，並自動偵測您已安裝的 AI 代理程式，讓您選擇要安裝哪些 skill、裝到哪些環境。

#### 安裝到特定代理程式

以下指令會同時安裝兩個 skill：

```bash
# 安裝到 Claude Code
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a claude-code -g -y

# 安裝到 Antigravity
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a antigravity -g -y

# 安裝到 Cursor
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a cursor -g -y

# 安裝到 Codex
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a codex -g -y

# 安裝到 Gemini CLI
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a gemini-cli -g -y

# 安裝到 GitHub Copilot
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a github-copilot -g -y

# 安裝到 Windsurf
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a windsurf -g -y
```

#### 安裝到多個代理程式

```bash
# 同時安裝到 Claude Code 和 Antigravity
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth -a claude-code -a antigravity -g -y
```

#### 只安裝其中一個 skill

```bash
# 只安裝 humanizer-zh-tw（不加 --full-depth 時只會找到根目錄的 skill）
npx skills add kevintsai1202/Humanizer-zh-TW -a claude-code -g -y

# 只安裝 text-watermark-cleaner-zh-tw
npx skills add kevintsai1202/Humanizer-zh-TW --full-depth --skill text-watermark-cleaner-zh-tw -a claude-code -g -y
```

**參數說明：**
- `--full-depth`：根目錄已有 `SKILL.md` 時，仍搜尋子資料夾；本 repo 需要它才能找到 `text-watermark-cleaner-zh-tw`
- `-s, --skill <skills>`：只安裝指定名稱的 skill
- `-a, --agent <agents...>`：指定要安裝的代理程式
- `-g, --global`：安裝到全域目錄（而非專案目錄）
- `-y, --yes`：跳過確認提示，直接安裝

### 附加技能：文字浮水印清理（繁體中文版）

本專案另附一個獨立的 `text-watermark-cleaner-zh-tw` skill。它專門處理不可見 Unicode、zero-width、tag characters、異形空白與文字型 AI provenance；不把自然改寫誤稱為浮水印解碼，也不處理可見圖片浮水印或二進位檔案 metadata。

中文是這個 skill 的主要說明語言；`zero-width`、`C2PA`、`provenance`、`Claude watermark` 等英文術語會保留，方便不同代理程式觸發與對接服務。

技能內附從上游 `watermarks-remover` 擷取的 Python deterministic scripts，以及 Windows PowerShell 入口；可先對 Markdown／純文字做 inspect，再輸出保留原檔的 `.cleaned` 副本。上游腳本與 MIT 授權副本位於 `text-watermark-cleaner-zh-tw/scripts/`。

建議用上方「只安裝其中一個 skill」的 npx 指令安裝。不使用 npx skills 時，也可以從本 repo 手動複製：

```powershell
# Claude Code（Windows PowerShell）
Copy-Item -Recurse .\text-watermark-cleaner-zh-tw `
  "$env:USERPROFILE\.claude\skills\text-watermark-cleaner-zh-tw"

# Codex（Windows PowerShell）
Copy-Item -Recurse .\text-watermark-cleaner-zh-tw `
  "$env:USERPROFILE\.codex\skills\text-watermark-cleaner-zh-tw"
```

使用範例：

```text
/text-watermark-cleaner-zh-tw 請檢查這段繁中是否有不可見文字標記，不要改內容。
/text-watermark-cleaner-zh-tw 請清理 article.md 的 zero-width 字元，但保留程式碼、URL、引用與全形標點。
```

本地腳本範例：

```powershell
& .\text-watermark-cleaner-zh-tw\scripts\run-text-watermark.ps1 `
  -Mode Inspect -InputPath .\article.md -Json
& .\text-watermark-cleaner-zh-tw\scripts\run-text-watermark.ps1 `
  -Mode Clean -InputPath .\article.md -OutputPath .\article.cleaned.md -Stats
```

### 方式二：透過 Git 複製

```bash
# 複製到 Claude Code 的 skills 目錄
git clone https://github.com/kevintsai1202/Humanizer-zh-TW.git ~/.claude/skills/humanizer-zh-tw
# 複製到 Antigravity 的 skills 目錄
git clone https://github.com/kevintsai1202/Humanizer-zh-TW.git ~/.gemini/antigravity/skills/humanizer-zh-tw
# 複製到 Codex 的 skills 目錄
git clone https://github.com/kevintsai1202/Humanizer-zh-TW.git ~/.codex/skills/humanizer-zh-tw
# 複製到 Gemini CLI 的 skills 目錄
git clone https://github.com/kevintsai1202/Humanizer-zh-TW.git ~/.gemini/cli/skills/humanizer-zh-tw
```

### 方式三：手動安裝

1. 下載本專案的 ZIP 檔案或複製到本機
2. 將 `Humanizer-zh-TW` 資料夾複製到對應工具的技能目錄：

   - **Claude Code**:
     - **macOS/Linux**: `~/.claude/skills/`
     - **Windows**: `%USERPROFILE%\.claude\skills\`
   - **Antigravity**:
     - **macOS/Linux**: `~/.gemini/antigravity/skills/`
     - **Windows**: `%USERPROFILE%\.gemini\antigravity\skills\`

3. 確保資料夾結構如下：

   **Claude Code:**
   ```
   ~/.claude/skills/humanizer-zh-tw/
   ├── SKILL.md       # 技能定義檔案（繁體中文版）
   └── README.md      # 說明文件
   ```

   **Antigravity:**
   ```
   ~/.gemini/antigravity/skills/humanizer-zh-tw/
   ├── SKILL.md       # 技能定義檔案（繁體中文版）
   └── README.md      # 說明文件
   ```

### 驗證安裝

重新啟動 Claude Code / Antigravity 或重新載入 skills 後，在對話中輸入：

```
/humanizer-zh-tw
```

如果安裝成功，該技能將被啟用。

## 使用

### 基礎用法

在 Claude Code、Antigravity 或其他支援 skills 的代理程式中，可以透過以下方式使用：

#### 1. 直接呼叫技能（Claude Code）

```text
/humanizer-zh-tw 請潤飾下面的文章，保留技術評論的語氣：

[貼上原文]
```

#### 2. 在對話中使用

```text
請用 humanizer 幫我改寫這段話，讓它更自然：

這個專案作為我們團隊致力於創新的證明。此外，它展示了我們在不斷演進的技術佈局中的關鍵角色。
```

#### 3. 處理檔案內容

```text
/humanizer-zh-tw 請潤飾 article.md 中的正文
```

只要審閱時，請註明「給建議，不修改檔案」。有作者樣本時可以一併提供，skill 會借鏡表達習慣，但不會把樣本中的經歷、數據或觀點搬進原文。預設不附自評分；需要 50 分品質評分時，請明確提出。

### 改寫範例

以下都是教學用的輸入，沒有未展示的補充材料。

**產品介紹，缺少數據：**

> 原文：該方案穩定可靠、快速回應、易於維護。
>
> 改寫：這套方案運作穩定、回應快，也方便維護。

沒有補寫上線時間、回應速度或維護成本。原文缺少證據時，可以向作者索取，不能靠潤飾補出數據。

**故障回報，有不確定性：**

> 原文：該問題被社群多次回報，被認為可能與記憶體洩漏有關，但原因尚未確認。
>
> 改寫：社群多次回報這個問題。它被認為可能與記憶體洩漏有關，但原因尚未確認。

保留「可能有關」和「尚未確認」，不把推測改成因果結論，也不把原因判斷擅自歸給社群。

**更新說明，有真實的三項功能：**

> 原文：這次更新彰顯了團隊對創新的追求。它新增匯出、搜尋和批次重新命名。離線編輯計畫在下一版推出，目前尚未完成測試。
>
> 改寫：這次更新新增匯出、搜尋和批次重新命名。離線編輯計畫在下一版推出，目前尚未完成測試。

保留三個功能，不為了避開三段式而刪項或湊項；計畫和測試狀態維持原意。

**已經清楚的文字：**

> 原文：先儲存檔案，再關閉視窗。未儲存的修改會遺失。
>
> 改寫：先儲存檔案，再關閉視窗。未儲存的修改會遺失。

不要求每次呼叫都產生修改。

> 注意：若需要處理文字浮水印，請改用 `text-watermark-cleaner-zh-tw`。

## 編輯原則

約束的優先順序是：保留資訊和確定程度，遵守使用者的範圍與文體，貼合作者聲音，最後才處理具體的表達問題。模式命中不能凌駕這些要求。

- 不編造功能、數據、來源、人物身分或第一人稱經歷。
- 保留否定、條件、歸因、範圍、時間和完成狀態；「可能」不變成「確定」，「計畫」不變成「已經」。
- 三項列舉、四字格、被動句、破折號和連接詞依作用判斷，不機械刪除。
- 隨筆可以保留個性，學術和商務文字保留正式程度；不把所有文章改成同一種口語。
- 編輯檔案時，預設保留程式碼、指令、路徑、連結目標、YAML、資料、標題和錨點。修改標題或結構前，要檢查引用。
- 預設只交付最終稿，不附中間草稿、命中清單或自評分。
- 繁體字、全形標點與原本的空白語意保持不變，不擅自簡繁轉換。

## 模式目錄

共 31 個檢查點，沿用 PR #39 的 A–F 分類，方便與上游對照。這是編輯問題清單，不是作者身分的偵測標準。

| 分類 | 檢查點 |
| --- | --- |
| A：鋪墊代替陳述（1–5） | 假對比、戲劇性碎片、偽深度、起跑式鋪墊、與假想敵辯論 |
| B：公式化節奏（6–11） | 強湊三段式、句首重複、萬用破折號、限定詞堆疊、自創複合詞、被動與缺主詞 |
| C：拔高與借權威（12–18） | 空泛的高頻詞、意義拔高、模糊關聯、句尾拔高、宣傳語、權威背書、迴避「是／有」 |
| D：公式化排版（19–21） | 裝飾性粗體、裝飾性標題、引號與中文標點 |
| E：聊天與草稿殘留（22–25） | 客服腔、重複免責與猜測填補、首句重述標題、談論上一稿 |
| F：中文補充檢查（26–31） | 層疊的「的」、「進行＋動詞」、被字句堆疊、四字詞排比、「隨著……的發展」式開頭、套話收尾 |

每條都包含修改條件、前後範例和「保留」邊界，詳見 [SKILL.md](SKILL.md)。

## 驗證

[測試說明](tests/README.md)包含 18 個短文字案例、一份 Markdown 檔案樣例和結構檢查腳本，都由上游移植並改為繁體與台灣用語。單次、有限的樣例不能代表所有模型和文體；不能用字數減少或模型自評分證明效果。

### 用 hook 自動驗證（選用）

代理程式以檔案模式潤飾 Markdown 後，可以用 hook 自動做一次結構檢查，確認 YAML、程式碼、標題、連結目標、表格、步驟與明確的 ID 屬性沒有被改動。這裡只說明做法，不附現成的腳本或設定檔；請依自己的代理程式與環境撰寫。

#### 共通做法

1. **改檔前留快照**：在「編輯前」的事件記下目標檔案目前的內容。只處理要保護的 Markdown 路徑；新建的檔案沒有原稿，直接略過。
2. **改檔後比對**：在「編輯後」的事件，以快照為原稿、改寫後的檔案為副本，套用 `tests/check_structure.py` 的八類比對規則。
3. **把結果回給代理程式**：有不一致時，列出被改動的類別，讓代理程式在同一個 session 中還原。只顯示給使用者的訊息，代理程式看不到，也就不會自行修正；各家的回報管道不同，見下表。
4. **限定範圍**：只在需要潤飾的寫作專案或資料夾啟用。本 repo 的 `SKILL.md`、`README.md` 常需要正當地修改標題與程式碼區塊，不適合全域套用。使用者明確要求修改標題或重排結構時，也要暫停這項檢查。
5. **快照步驟不要擋下編輯**：多數代理程式把「編輯前」事件的 exit code 2 當成拒絕，快照步驟應一律正常結束。

#### Windows 注意事項

- hook 指令不要直接呼叫 `python3`。Windows 上的 `python3` 可能只是 Microsoft Store 的應用程式執行別名，沒有安裝 Store 版 Python 時會直接失敗，而且沒有錯誤訊息。請改用 `py -3` 或 Python 的完整路徑。
- hook 從 stdin 收到的 JSON 要以 UTF-8 解碼，回給代理程式的訊息也要以 UTF-8 輸出；否則中文路徑與訊息可能被當成 cp950 解讀而變成亂碼。
- 腳本路徑請寫絕對路徑，或使用代理程式提供的專案根目錄變數。

#### 各代理程式的 hook 支援

以下整理自 2026-09-25 查閱的官方文件。各家功能更新頻繁，啟用前請再對照官方文件。

| 代理程式 | 設定位置 | 編輯前 | 編輯後 | 讓代理程式看到結果的方式 |
| --- | --- | --- | --- | --- |
| Claude Code | `.claude/settings.json`、`.claude/settings.local.json`、`~/.claude/settings.json`，或 skill front matter 的 `hooks` | `PreToolUse` | `PostToolUse` | exit code 2 的 stderr，或 `decision: "block"` 加 `reason` |
| Codex CLI | `.codex/hooks.json` 或 `.codex/config.toml`；使用者層在 `~/.codex/` | `PreToolUse` | `PostToolUse` | exit code 2，或 `decision: "block"` 加 `reason`，會取代工具結果 |
| Gemini CLI | `.gemini/settings.json`、`~/.gemini/settings.json` 中的 `hooks` | `BeforeTool` | `AfterTool` | `reason` 取代工具結果，或用 `additionalContext` 附加在結果之後 |
| Antigravity | `.agents/hooks.json`、`~/.gemini/config/hooks.json` | `PreToolUse` | `PostToolUse`（無法回報） | 改由 `PostInvocation` 或 `Stop` 把訊息注入對話 |
| Cursor | `.cursor/hooks.json`、`~/.cursor/hooks.json` | `preToolUse` | `postToolUse`、`afterFileEdit` | `postToolUse` 的 `additional_context`，或 `stop` 的 `followup_message` |
| Windsurf（Devin Desktop） | `.devin/hooks.json`（舊版為 `.windsurf/hooks.json`）、`~/.codeium/windsurf/hooks.json` | `pre_write_code` | `post_write_code` | exit code 2 的 stderr |
| GitHub Copilot | `.github/hooks/*.json`；使用者層在 `~/.copilot/hooks/` | `PreToolUse`／`preToolUse` | `PostToolUse`／`postToolUse` | 依介面而異，見下方說明 |

**Claude Code**（[官方文件](https://code.claude.com/docs/en/hooks)）

- matcher 設為 `Edit|Write`，stdin JSON 的 `tool_input.file_path` 是目標檔案路徑。可以再用 hook 的 `if` 欄位（權限規則語法，例如 `Edit(*.md)`）限定只在 Markdown 檔觸發。
- `PostToolUse` 觸發時檔案已經寫入。以 exit code 2 結束時，stderr 會顯示給 Claude；也可以 exit 0 並輸出 JSON，讓 `decision: "block"` 把 `reason` 附在工具結果旁。兩種方式擇一。
- 寫在 skill front matter 的 `hooks`，會在 skill 被呼叫後持續作用到這個 session 結束。官方文件只說明 `${CLAUDE_SKILL_DIR}` 會在 skill 內文與 `allowed-tools` 中替換，沒有提到 hook 指令，所以要指向 skill 內附的檔案時，請寫絕對路徑。
- Windows 上沒有指定 `shell` 時用 Git Bash，沒有 Git Bash 才用 PowerShell。設為 `"shell": "powershell"` 時，會優先使用 `pwsh.exe`（PowerShell 7），找不到才改用 Windows PowerShell 5.1。專案根目錄可寫成 `${CLAUDE_PROJECT_DIR}` 或 `$env:CLAUDE_PROJECT_DIR`。
- `/hooks` 選單可檢視已載入的 hook；`claude --debug` 會顯示執行紀錄。

**Codex CLI**（[官方文件](https://developers.openai.com/codex/hooks)）

- 專案層設定只在專案被信任後載入；非管理者提供的 hook 要先在 `/hooks` 檢視並信任，內容變更後要重新信任。
- 改檔一律經過 `apply_patch`，沒有獨立的檔案路徑欄位；路徑要從 `tool_input.command` 內 patch 標頭（例如 `*** Update File:`）解析。
- `PostToolUse` 被擋下時，Codex 會以回報內容取代工具結果，並讓模型繼續處理。舊的 `notify` 設定只在回合結束時通知，看不到輸出也無法回報，不適合這個用途。
- Windows 可用 `commandWindows`（TOML 寫作 `command_windows`）另外指定指令。

**Gemini CLI**（[官方文件](https://geminicli.com/docs/hooks/)）

- matcher 是正規表示式，例如 `write_file|replace`；這兩個工具的 `tool_input` 都有 `file_path`。
- 官方建議以 exit 0 輸出 JSON，而且 stdout 只能有 JSON。`AfterTool` 的 `reason` 會取代工具結果，`additionalContext` 會附加在工具結果之後。
- 專案層 hook 會以 fingerprint 記錄，名稱或指令改變後會被視為未信任。
- Windows 範例使用 `.ps1`，可能需要調整 PowerShell 的 execution policy。

**Antigravity**（[官方文件](https://antigravity.google/docs/hooks)）

- 編輯工具（`write_to_file`、`replace_file_content`、`multi_replace_file_content`）的參數以 `TargetFile` 帶出路徑。
- `PostToolUse` 只能回傳空物件，代理程式看不到它的輸出。可以先在 `PostToolUse` 把比對結果存成暫存檔，再由 `PostInvocation` 的 `injectSteps`，或 `Stop` 的 `decision: "continue"` 加 `reason` 注入對話。這個串接方式是依文件推論，尚未實測。
- 文件沒有說明 exit code、Windows 上的 shell 與編碼；功能仍在快速變動，啟用前請先實測。

**Cursor**（[官方文件](https://cursor.com/docs/agent/hooks)）

- 編輯前可以用 `preToolUse`（matcher 設 `Write`）留快照。`preToolUse` 的 exit code 2 等同拒絕；其他非零 exit code 視為 hook 失敗，動作照常進行。
- `afterFileEdit` 會帶出絕對路徑 `file_path` 與 `edits`，文件把它定位在格式化等用途，沒有列出能回給代理程式的輸出欄位。要讓代理程式看到比對結果，改用 `postToolUse`（matcher 設 `Write`）的 `additional_context`，或在 `stop` 用 `followup_message` 自動送出下一則訊息（預設最多 5 次，可用 `loop_limit` 調整）。

**Windsurf（Devin Desktop）**（[官方文件](https://docs.windsurf.com/windsurf/cascade/hooks)）

- `pre_write_code` 與 `post_write_code` 都在 `tool_info.file_path` 帶出路徑；官方文件本身就把「修改前備份檔案」列為 `pre_write_code` 的用途。
- exit code 2 時，Cascade 會看到 stderr 的訊息。只有編輯前的 hook 能擋下動作，`post_write_code` 用 exit code 2 只會回報、不會擋。
- 每個 hook 可以另外設 `powershell` 欄位，在 Windows 上以 `powershell -Command` 執行；沒有設定時改用 `command`。`show_output` 只決定使用者介面是否顯示輸出。
- 系統、使用者、工作區三層設定會合併，依序全部執行。

**GitHub Copilot**（[hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference)、[VS Code hooks](https://code.visualstudio.com/docs/agent-customization/hooks)）

三種介面都會讀 `.github/hooks/*.json`，但事件名稱、輸出欄位與 shell 各不相同，同一份設定不一定能共用：

- **VS Code agent mode**（Preview）：事件為 `PreToolUse`、`PostToolUse`。它會忽略 matcher，所有工具都會觸發，要在腳本中自行判斷 `tool_name`。exit code 2 的 stderr 會交給模型；`PostToolUse` 也可以用 `decision: "block"` 加 `reason`。Windows 可用 `windows` 欄位另外指定指令；文件沒有說明預設的 shell，要用 PowerShell 7 請在指令中明確呼叫 `pwsh`。啟用 `chat.useClaudeHooks` 後，也會讀取 `.claude/settings.json` 中的 Claude 格式 hook。
- **Copilot CLI**：事件為 `preToolUse`、`postToolUse`，工具參數 `toolArgs` 是 JSON 字串，要再解析一次。`postToolUse` 的 exit code 2 只顯示給使用者，模型看不到；要讓模型看到比對結果，請 exit 0 並輸出 JSON 的 `additionalContext`，它會附加在工具結果之後。Windows 可設 `powershell` 欄位，文件要求 PATH 中有 PowerShell 7 以上版本。
- **Copilot cloud agent**：只讀預設分支上的 `.github/hooks/*.json`，在 Linux 環境執行，只採用 `bash` 欄位。

**Git pre-commit（不限代理程式）**（[官方文件](https://git-scm.com/docs/githooks)）

- 適合沒有 hook 功能的代理程式，或手動編輯：commit 前，針對暫存區中修改過的 Markdown，以 HEAD 版本為原稿、暫存版本為副本比對。新增的檔案沒有原稿，略過。
- hook 放在 `.git/hooks/pre-commit`；要納入版控時，用 `git config core.hooksPath <目錄>` 指向 repo 內的 hooks 目錄。Git 執行 hook 時，工作目錄是工作樹的根目錄。
- hook 以非零狀態結束會中止 commit；確定要修改結構時，用 `git commit --no-verify` 略過。
- 缺點是要到 commit 時才會發現問題，代理程式不會在編輯當下自動修正。
- Windows 上可以把 hook 寫成 `#!/bin/sh` 腳本，從 PowerShell 7 執行 `git commit` 時一樣會觸發；需要時再由它呼叫 `py -3` 或 `pwsh`。

## 檔案說明

- **`SKILL.md`** - 繁體中文版技能定義檔案
- **`README.md`** - 本說明文件
- **`CHANGELOG.md`** - 更新紀錄
- **`tests/`** - 改寫邊界的測試案例、Markdown 樣例與結構檢查腳本
- **`text-watermark-cleaner-zh-tw/SKILL.md`** - 繁體中文文字浮水印清理 skill

**註：** 英文原版請參考 [blader/humanizer](https://github.com/blader/humanizer)

## 貢獻

如果你發現翻譯問題或想要改進文件，歡迎提交 Issue 或 Pull Request。修改規則時，請同步更新 `SKILL.md`、本文件的模式目錄與 `CHANGELOG.md`。

### 中文語境特殊性

在翻譯和在地化過程中，我們考慮了繁體中文寫作的特點：

- F 組六個檢查點專門處理中文句式，例如層疊的「的」、「進行＋動詞」與被字句堆疊。
- 中文破折號（——）有解釋、插入和轉折等正當用途，沒有作者樣本時也不一律刪除；英文原版則要求沒有樣本時刪除破折號。
- 引號以台灣慣用的「」為主、『』為內層；程式碼與結構化資料中的直引號保持原樣。
- 英文標題的大小寫規則，只在處理英文內容時適用。
- 範例改用台灣用語，例如「匯出」、「快取」、「記憶體」、「週三」。

### 文字浮水印的分工

`humanizer-zh-tw` 負責文字語氣與結構；`text-watermark-cleaner-zh-tw` 負責不可見文字載體與統計式文字標記的獨立流程。自然改寫只能降低統計相似度，不能證明 Claude 浮水印已移除，也不能證明作者身分。

## 參考資源

- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) - 原始指南來源
- [WikiProject AI Cleanup](https://en.wikipedia.org/wiki/Wikipedia:WikiProject_AI_Cleanup) - 維基百科 AI 清理專案
- [blader/humanizer v3.0.0](https://github.com/blader/humanizer/blob/v3.0.0/SKILL.md) - 原始英文版專案；A–E 分類、聲音校準與檔案模式的來源
- [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh) - 簡體中文版，本專案的直接上游
- [Humanizer-zh PR #39](https://github.com/op7418/Humanizer-zh/pull/39) - 上游修訂的結構基礎與中文檢查點來源
- [Humanizer-zh PR #34](https://github.com/op7418/Humanizer-zh/pull/34) - 上游修訂時，範例保真修正的對照參考
- [hardikpandya/stop-slop](https://github.com/hardikpandya/stop-slop) - 簡潔表達、編輯檢查與品質評分的靈感來源
- [`text-watermark-cleaner-zh-tw/SKILL.md`](text-watermark-cleaner-zh-tw/SKILL.md) - 繁體中文文字浮水印清理 skill

## 許可

本專案遵循 repo 中的 [MIT License](LICENSE)。核心內容基於維基百科社群的觀察和總結。

---

**提示：** 這個工具不是為了「欺騙」AI 偵測器，而是為了真正提升寫作品質。最好的「去 AI 化」方法，是讓文字保有作者真實的想法和聲音。
