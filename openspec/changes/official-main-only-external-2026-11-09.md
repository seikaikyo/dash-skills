# 外部 skill 只收原廠 main 分支，Python 部署改自建

- **type**: chore
- **建立日期**: 2026-11-09

## 背景

延續 drop-non-vendor-external-skills-2026-10-25（只保留原廠帳號）。複查發現 vercel-labs/agent-skills 的 6 個 skill 並非從 main 同步，而是從還沒合併的工作分支：

| skill | 原本的來源分支 | 分支最後 commit |
| --- | --- | --- |
| react-best-practices | `react-best-practices` | 2026-01-14 |
| web-design-guidelines | `web-design-guidelines` | 2026-01-14 |
| deploy-to-vercel | `deploy-to-vercel` | 2026-03-06 |
| vercel-react-best-practices | `versioned-react-best-practices` | 2026-01-15 |
| vercel-cost-optimization | `mingchungx/vercel-cost-optimization`（個人分支） | 2026-02-25 |
| vercel-python | `gscho/PY-222-vercel-python-skill`（個人分支） | 2026-05-07 |

工作分支沒經過合併審查，任何有推送權限的人改了，我們隔天就同步；分支停更後也拿不到 main 上的修正。使用者決定：外部 skill 只收各原廠的 main 分支，需要但 main 沒有的功能自己寫；security-radar 也暫停每週一找新候選。

## 變更內容

1. `scripts/update-external.sh`
   - react-best-practices、web-design-guidelines、deploy-to-vercel 改從 main 同步（main 上有同名 skill）。
   - 刪除 vercel-react-best-practices、vercel-cost-optimization、vercel-python 的 `update_*` 函數、主流程、case 分派與 show_available 項目。
   - 新增 `update_vercel_optimize`：Vercel 官方 main 的 vercel-optimize（以正式環境 metrics 為準的成本與效能審查，支援 Nuxt），取代 vercel-cost-optimization。
2. `git rm -r external/{vercel-react-best-practices,vercel-cost-optimization,vercel-python}`。
   vercel-react-best-practices 與 react-best-practices 重疊，不另補。
3. external/vercel-optimize 不手動加入，由下一次每日同步抓取並經 `gate-external.py` 與 SkillSpector 安檢後才落地。
4. `scripts/discover-new-skills.sh`：Vercel 部分改為比對 main 分支 `skills/` 目錄，不再列工作分支為候選。
5. `skills/fastapi-patterns/SKILL.md`：新增「Vercel 部署」章節取代 vercel-python，內容依 Vercel 官方文件原創（入口偵測、`pyproject.toml` 入口設定、`.python-version`、`vercel.json` 的 regions / maxDuration / excludeFiles、lifespan 差異、Neon pooled 連線與 NullPool）。
6. `skills/security-radar/SKILL.md`：每週一新候選暫停，淘汰時不找替代品、空位記在矩陣缺口欄；每日複查照舊。
7. 三份 README：刪 vercel-react-best-practices、vercel-python、vercel-cost-optimization 三列，加 vercel-optimize 一列，外部 29 → 27。

## 影響範圍

| 對象 | 影響 |
| --- | --- |
| external/ | 移除 3 個目錄；3 個改從 main 同步，下次同步內容會換成 main 版本；新增 1 個待同步。 |
| scripts/ | update-external.sh、discover-new-skills.sh。 |
| skills/ | fastapi-patterns 增章節，security-radar 改維護節奏；自建數量不變（19）。 |
| README × 3 | 外部 27。 |
| ~/.claude/skills | 使用者重跑 `scripts/link.sh` 後移除 3 個死連結。 |

## 剩餘風險

- vercel-optimize 帶約 30 支 .mjs 腳本，若首次同步被閘門擋下，README 會比 external/ 多一列，需人工判讀 security-reports/quarantine/ 後放行或撤回。
- 3 個改從 main 同步的 skill，main 版本與舊分支內容不同，首次同步的差異較大，閘門可能要求人工確認。

## UI 規格

無 UI 變更。

## 測試計畫

1. `bash -n scripts/update-external.sh scripts/discover-new-skills.sh` 通過。
2. `grep` 確認腳本不再出現已移除的 3 個函數或分支名，`_update_vercel_agent_skill` 與專用函數只用 `main`。
3. 下次每日同步後確認 external/vercel-optimize 存在且通過閘門，react-best-practices、web-design-guidelines、deploy-to-vercel 內容為 main 版本。
4. 三份 README 外部數量一致為 27。
