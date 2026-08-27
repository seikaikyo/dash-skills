---
title: 外部 skills 每日同步加 SkillSpector 安檢
type: feature
status: completed
spec: skillspector-scan-gate
created: 2026-08-27
---

# 外部 skills 每日同步加 SkillSpector 安檢

## 背景

external/ 每日自動從十多個第三方 repo 同步，內容經 link.sh 連進 ~/.claude/skills 後會被載入 Claude Code 的 context。上游被植入惡意指示（prompt injection、資料外洩、供應鏈投毒）時，現行流程只有 redact 金鑰格式與事後稽核，沒有裝載前的內容安檢。NVIDIA SkillSpector（Apache 2.0）提供 71 種漏洞 pattern 的靜態掃描，JSON 報告含 risk_assessment.score（0-100）與 max_issue_severity。

## 變更內容

1. 新增 `scripts/scan-skills.sh`：包裝 `skillspector scan --no-llm`（純靜態，不打 LLM API）。
   - 預設掃 git 視角下有變更或新增的 `external/<name>` 頂層目錄；`--all` 全掃；可指名目錄。
   - 判定：`max_issue_severity` 為 HIGH/CRITICAL，或 `risk_assessment.severity` 為 HIGH/CRITICAL，即告警。
   - 行為：警報不阻斷（v1 alert-only）。告警印終端機加寫 `security-reports/findings.log`，完整 JSON 報告存 `security-reports/`。
   - 掃描器未安裝、逾時或個別掃描失敗：明講跳過，不靜默。
2. `scripts/auto-update.sh` 插入安檢步驟：同步 external 之後、link.sh 重建 symlink 之前，步驟編號 4 步改 5 步。單次掃描 240 秒逾時保護。
3. `.gitignore` 加 `security-reports/`：repo 是 public，第三方 skill 的漏洞判定不對外發布（誤報有毀謗風險，同 repo 禁寫負面描述慣例）。

## 影響範圍

- `scripts/scan-skills.sh`（新檔）
- `scripts/auto-update.sh`（插入步驟、renumber）
- `.gitignore`（一行）
- 前置：`uv tool install git+https://github.com/NVIDIA/skillspector.git`（Python 3.12+，機器已具備）

## 覆蓋率誠實聲明

- v1 是警報不是硬擋：告警的 skill 仍會被 link.sh 連結。要升級成隔離（不連結、標記 quarantine）等首次真的有告警再做，避免對誤報做不可逆處置。
- 只掃有變更的目錄：既有存量靠一次性 `--all` 基線掃描補。
- 靜態掃描（--no-llm）不含語意層判定，LLM 二階段分析刻意不開（成本與金鑰暴露考量）。
- 絕對分數在這個 corpus 上不可用：2026-08-27 基線日 50 目錄中 34 個告警（含 anthropics 官方 docx / pptx / xlsx 全部 score 90 以上判 DO_NOT_INSTALL），靜態 pattern 對「帶腳本的 skill」一律重判。防護模型因此是 diff 制：全量人工判讀後產 per-dir baseline（`security-reports/baselines/<name>.yaml`），每日掃描帶 `--baseline` 只報基線外的新發現，新告警才是真訊號。基線日抽查結論：最重目錄（cybersecurity、trailofbits-curated、sentry-security-review、remotion、archify）的 HIGH/CRITICAL 項全部與該集合用途相符（資安教學文件裡的攻擊範例、SIEM/TTS 整合腳本的正當 API 呼叫、viewer 模板的指令樣文字），無內容與用途不符的注入跡象。
- baseline 用 rules 制不用官方 fingerprints 制（scripts/merge-baseline.py 從已判讀報告聯集產生）：官方指紋綁定檔案完整內容雜湊（suppression.py finding_fingerprint），上游每日同步任何改檔即全數失效重報，噪音不可運營；且 report 的 match_fingerprint 與 baseline 指紋是不同雜湊無法離線合成，同 hash 跨檔又不准重複列。rules 制以 (rule_id, 確切路徑) 抑制，代價是同檔同規則的新發現會被蓋掉，新檔案與新規則型照常告警。
- 報告 issues 輸出有上限：大目錄一輪報告蓋不住全部 findings，壓掉已知後會露出下一批，merge 加 rescan 迭代到收斂（scratchpad converge 腳本，收斂後日常不再需要）。
- skillspector 對高風險判定 exit 1 但報告照常產出：腳本以報告 JSON 有效性判完成，不看 exit code（初版誤把 exit 1 當逾時，28 個完成掃描被誤標，已修）。

## 測試計畫

1. `scan-skills.sh` 對單一乾淨 skill 目錄跑，確認 JSON 產出與 exit 0。
2. 未安裝 skillspector 時跑，確認印出明確跳過訊息、不中斷 auto-update 流程。
3. `--all` 基線掃描跑完，findings.log 內容人工過目。
4. auto-update.sh 全流程 dry 跑一次（隔日終端機自然觸發亦可驗）。

## Checklist

- [x] 建立 OpenSpec 提案
- [x] scripts/scan-skills.sh（含 baseline 抑制、exit code 語意修正、逾時環境變數覆寫）
- [x] scripts/auto-update.sh 插入步驟（4 步改 5 步）
- [x] .gitignore
- [x] 安裝 skillspector 2.10.0（使用者親跑 uv tool install）
- [x] 基線 --all 掃描（50/50 覆蓋，6 個 CAUTION 帶 HIGH 逐項判讀皆誤報、28 個 DO_NOT_INSTALL 抽查與用途相符）
- [x] 全量 per-dir baseline 產製
- [x] baseline 生效驗證（51 目錄全數重掃通過歸零，含三個大目錄迭代收斂）
- [x] 提交 push（歸檔 commit）
