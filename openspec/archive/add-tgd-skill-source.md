# 新增 tGD 外部 skill 同步來源（僅文件層）

- **Title**: add-tgd-skill-source
- **Type**: feature
- **Date**: 2026-07-13

## 變更內容

`scripts/update-external.sh` 新增 `tgd-skills`（openclawyhwang-hub/tGD，Apache-2.0）同步來源：

- 28 個 PDLC 工程紀律 skills（doubt-driven-development / spec-driven / subagent-driven / verification-before-completion / context-engineering 等）
- 只同步 `skills/*` 與共用 `references/`（5 份 checklist）加 README / LICENSE
- 明確排除 `hooks/`、`agents/`、`setup.sh`、`bin/`：不執行任何安裝腳本、不裝 hook（供應鏈紀律；上游 setup.sh 會對所有 agent CLI 裝 hook，不允許）

定位：語料參考，與 superpowers（方法論主軸，plugin 管道）互補不取代。

## 影響範圍

- `scripts/update-external.sh`（唯一修改檔）
- 新增目錄 `external/tgd-skills/`（同步產物）

## 測試計畫

- `DASH_SKILLS_NO_PUSH=1 bash scripts/update-external.sh tgd-skills` 確認 `external/tgd-skills/` 內有 tgd-* 子目錄、SKILL.md 與 references/
- 確認產物內無 hooks/、setup.sh、bin/
