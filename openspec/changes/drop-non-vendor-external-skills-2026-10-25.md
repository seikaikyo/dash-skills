# 移除非原廠外部 skill，改採原廠或自建

- **type**: chore
- **建立日期**: 2026-10-25

## 背景

external/ 收錄的外部 skill 來自多個第三方帳號，每日從上游自動覆蓋。其中 mukul975/Anthropic-Cybersecurity-Skills 冒用 Anthropic 名稱，內含 818 個攻擊型 skill 與可執行腳本，是典型的名稱冒用供應鏈風險。使用者決定 external/ 只保留產品原廠帳號的 skill，其餘非原廠一律移除；自己實際在用的，改由我們依自家流程重寫成全新自建 skill。

原廠帳號（保留）：anthropics、vercel-labs、neondatabase、getsentry、cloudflare、trailofbits。

## 變更內容

### 第一階段：移除 17 個沒在使用、全域設定零引用的非原廠 skill

anthropic-cybersecurity-skills、antfu-skills、cc-skills-golang、addy-agent-skills、tgd-skills、bencium-marketplace、accessibility-agents、security-audit、security-skills、claude-code-owasp、ot-security-mcp、archify、content-research-writer、creative-writing-skills、paper-writer-skill、storytelling、remotion-video-skill。

每個移除：
1. `scripts/update-external.sh` 刪掉對應的 `update_*` 函數、主流程 run 清單、case 分派、show_available 清單項目。tgd-skills 無同步函數（上游已消失、凍結），只刪目錄。
2. `git rm -r external/<name>`。
3. 移除 `~/.claude/skills/<name>` 符號連結。
4. 三份 README（README.md、README.en.md、README.ja.md）刪掉清單列，外部數量 51 → 34。

### 第二階段：5 個在用的改寫成全新自建 skill（另案，先建後拆）

interface-design、ui-ux-pro-max、humanizer-zh-tw、humanizer-en、webapp-uat 由我們依自家流程原創重寫，放進 skills/（自建、不進每日同步）。寫好、CLAUDE.md 與 hooks 的引用改指自建版本後，才移除對應的 external 版本。順序不可顛倒：quality-gate-push.sh、cis-check.sh 現在指著 external 的 interface-design。本提案只記錄計畫，實作在各自的提案。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| external/ | 第一階段移除 17 個目錄，第二階段再移除 5 個。 |
| scripts/update-external.sh | 刪 16 個 `update_*` 函數與其分派（tgd 無函數）。 |
| README × 3 | 外部 skill 清單與數量更新。 |
| ~/.claude/skills | 移除 17 個符號連結。 |
| 攻擊面 | 不再每日從個人帳號自動同步未經審查內容。 |

## 剩餘風險

第二階段完成前，5 個在用的 external skill 仍在原處；它們每日仍會同步，但來源已知、且使用者確認續用至重寫完成。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh` 通過。
2. `grep` 確認腳本不再出現 17 個已移除 skill 的函數名或目錄名；原廠 6 家的函數完整保留。
3. `scripts/link.sh` 重建符號連結後，`~/.claude/skills` 不再有 17 個死連結，自建與原廠 skill 連結無缺。
4. 三份 README 的外部數量一致為 34，清單無殘列。
