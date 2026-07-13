# 新增 Go 與 Vue/Nuxt 外部 skill 同步來源

- **Title**: add-golang-vue-skill-sources
- **Type**: feature
- **Date**: 2026-07-13

## 變更內容

`scripts/update-external.sh` 新增兩個外部 skill 同步來源：

1. `cc-skills-golang`（samber/cc-skills-golang）：40+ 個 Go 開發 skills（concurrency / error handling / observability / security / project layout 等），作者為 lo / do / slog 函式庫維護者。對應 dashai-go 後端開發。
2. `antfu-skills`（antfu/skills）：Anthony Fu（Vue / Vite core team）維護的 19 個 skills（nuxt / vue-best-practices / vue-testing / pinia / vueuse / vitest 等）。對應 shukuyo Nuxt 前端開發。

實作內容：

- 各新增一個 `update_*` 函數（full clone depth 1，複製 `skills/*` 到 `external/<name>/`，含 README / LICENSE）
- 註冊進 `all_updates` 平行更新陣列
- 註冊進單一 skill 更新的 case 分支（別名 `golang` / `antfu`）
- `show_available` 開發類清單各補一行

## 影響範圍

- `scripts/update-external.sh`（唯一修改檔）
- 新增目錄 `external/cc-skills-golang/`、`external/antfu-skills/`（同步產物）
- link.sh 自動掃 external/ 全部，不需修改

## 測試計畫

- `bash scripts/update-external.sh cc-skills-golang`（帶 `DASH_SKILLS_NO_PUSH=1`）確認 clone 成功、`external/cc-skills-golang/` 內有 golang-* 子目錄與 SKILL.md
- `bash scripts/update-external.sh antfu-skills` 同上，確認 vue / nuxt 子目錄存在
- `bash scripts/update-external.sh` 無參數模式不驗全跑（依賴既有平行機制，新函數與既有 pattern 一致）
