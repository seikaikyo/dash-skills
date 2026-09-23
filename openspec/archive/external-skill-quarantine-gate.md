---
title: 外部 skills 裝載前閘門（告警升級為隔離）
type: feature
status: completed
spec: external-skill-quarantine-gate
created: 2026-09-23
---

# 外部 skills 裝載前閘門（告警升級為隔離）

## 背景

external/ 每天從 50 多個第三方 repo 的分支 HEAD 覆蓋同步，經 link.sh 載進 Claude Code。
v1（skillspector-scan-gate）只告警不阻斷，且 SkillSpector baseline 是 (rule_id, 路徑) 制：
同檔同規則的新發現會被 baseline 蓋掉，惡意內容只要加進已列 baseline 的檔案就能避開。
2026-03 Trivy 發行鏈入侵（GHSA-69fq-xp46-6x23）說明上游被接管是現實風險，
v1 的「等首次真的有告警再升級隔離」前提已不成立。

## 設計

git 已提交的 external/ 就是「已核准版本」。同步後、link.sh 與 commit 之前，
每個有變更的 external/<name> 要過兩關，任一不過就把該目錄退回 HEAD（新目錄直接移除），
被擋下的內容複製到 security-reports/quarantine/ 供人工判讀。skill 不會消失，只停在上一版，
也不會被 commit 進 public repo。

1. **差異規則**（scripts/gate-external.py，只看本次新增的行，不受 baseline 影響）
   - BLOCK：隱形字元（零寬、雙向控制、Unicode tag）、解碼後執行、要 agent 忽略指示或瞞著使用者或繞過權限；
     腳本內的 curl|sh 與讀取本機憑證路徑
   - WARN（只提示）：文件內的 curl|sh 與憑證路徑、新出現的網域
   - diff 用暫存 index 加 -M 計算：同步是 rm -rf 再 cp，改名後的新路徑是未追蹤檔，
     不這樣做的話資安教材類集合一重整目錄，整份攻擊範例都會被當成新增
2. **SkillSpector**（沿用 scan-skills.sh 與既有 baseline）：告警、失敗、逾時、未安裝一律隔離（fail-closed）；
   scan-skills.sh 新增 SCAN_STATUS_FILE 輸出逐目錄結果給閘門讀

放行誤報：SkillSpector 照舊產 baseline；差異規則在 security-reports/gate-allow.tsv 加一行
（閘門會印出可直接執行的指令），可綁檔案 sha256 只放行這一版內容。
security-reports/ 已 gitignore，放行清單只存在本機，與 baseline 的公開政策一致。

## 影響範圍

- scripts/gate-external.py（新檔）
- scripts/scan-skills.sh（SCAN_STATUS_FILE 輸出；單獨執行行為不變）
- scripts/auto-update.sh（[2/5] 改呼叫閘門）

## 覆蓋率誠實聲明

- 以頂層目錄為單位隔離：大型集合（如 anthropic-cybersecurity-skills）只要一個檔被擋，當天整個集合都停在上一版。
- 規則是樣式比對，對改寫過的注入語句或多檔拼接的攻擊擋不住；SkillSpector 的語意層（LLM 分析）仍刻意不開。
- 上游仍從分支 HEAD 取，沒有冷卻期：隔離靠內容判斷，不靠「新版本放幾天再用」。
- 2026-09-23 對現有 51 個目錄全量試跑規則：6 個目錄的既有內容含 BLOCK 樣式（皆為資安教材的攻擊範例），
  因只看新增行，這些既有內容不會觸發；該些檔案日後新增同類範例時會被擋，需人工放行。
- SkillSpector 未安裝或壞掉時所有更新都停：這是刻意的 fail-closed，終端機會明講原因；
  確定要暫時放行可設 DASH_SKILLS_ALLOW_UNSCANNED=1。

## 測試

拋棄式 repo 驗證（2026-09-23）：隱形字元、exec(b64decode)、新 skill 內含「do not tell the user」皆被隔離並還原；
純改名、SAML 憑證的 base64 解碼、emoji ZWJ 皆通過；改名加注入行被擋；
印出的放行指令執行後重跑通過、內容再變動時重新被擋；未裝掃描器且未設放行變數時全數隔離；
--dry-run 不還原；真正的 git index 不被改動。
