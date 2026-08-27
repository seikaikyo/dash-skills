---
title: 新增 archify skill 同步來源
type: feature
status: in-progress
spec: add-archify-skill-source
created: 2026-08-27
---

# 新增 archify skill 同步來源

## 變更內容

新增 `tt-a1i/archify`（21.4K 星，MIT）為外部 skill 同步來源。agent 產型別化 JSON IR，Node.js 端決定性編譯為自包含 HTML 互動系統圖（架構 / 時序 / 資料流 / 生命週期 / workflow 五種），拓撲經驗證、支援快照 Before / Delta / After 比對與 PNG / SVG / WebM 匯出。與現有工具分工：ASCII 規則管對話解釋、mermaid 管 artifact 輕量圖、archify 管交付級架構文件。

- `scripts/update-external.sh` 加 `update_archify()`（sparse clone repo 的 `archify/` 子目錄，SKILL.md 與 Node 渲染器都在該層）、all_updates 清單、單獨更新 case、--list 條目。
- 不用上游建議的 `npx skills add`，統一走 dash-skills 同步管線。
- 首次同步後過 SkillSpector 掃描閘（新目錄無 baseline，首掃全量告警屬預期），人工判讀後產 rules 制 baseline 再 link。

## 影響範圍

- `scripts/update-external.sh`（四處插入）
- `external/archify/`（新目錄，日常由每日同步維護）
- `security-reports/baselines/archify.yaml`（判讀後產生，gitignored）

## 測試計畫

1. `bash scripts/update-external.sh archify` 單獨同步成功，external/archify/SKILL.md 存在。
2. `bash scripts/scan-skills.sh archify` 首掃出報告，HIGH/CRITICAL 逐類判讀。
3. 判讀通過後 merge-baseline 產 baseline，重掃轉通過。
4. `scripts/link.sh` 連結後 Claude Code 新 session 可見 archify skill。

## Checklist

- [x] 建立 OpenSpec 提案
- [x] update-external.sh 四處插入
- [ ] 首次同步
- [ ] 首掃判讀 + baseline
- [ ] link 生效
- [ ] 提交
