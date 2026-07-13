# 升級三篇 tGD skill 進自建區

- **Title**: promote-three-tgd-skills
- **Type**: feature
- **Date**: 2026-07-13

## 變更內容

依主對話全文評估結論（29 篇讀 9 篇全文，3 篇有 superpowers 與既有 hook 體系蓋不到的獨特價值），將三篇 tGD skill 改寫後放進 `skills/` 自建區：

1. `skills/doubt-driven-development/`：非平凡決策的新鮮 context 對抗審查（進行中決策層，補 /code-review 事後層的空缺）
2. `skills/interview-me/`：需求不明時的意圖萃取訪談（一次一題附猜測、明確 yes 才動工）
3. `skills/sketch/`：拋棄式 HTML mockup 比稿（2 到 3 個設計立場變體 + 有立場的對比）

改寫原則：

- 剝掉 tGD 框架耦合（TGD_DIR、persona、/tgd-* 指令、GSD 引用），接上本環境（Agent tool 派 sora、agent-browser、OpenSpec、superpowers）
- 正體中文改寫，符合自建區 frontmatter 慣例（name / description / source / updated）
- source 欄位保留 Apache-2.0 出處；external/tgd-skills/ 原文不動，作完整版參考
- doubt-driven 的跨模型第二意見段不搬（環境沒有常備 Gemini/Codex CLI），指回原文

## 影響範圍

- 新增 `skills/doubt-driven-development/SKILL.md`、`skills/interview-me/SKILL.md`、`skills/sketch/SKILL.md`
- `README.md` / `README.en.md` / `README.ja.md` 自建 skill 表各補三列（三語同步）
- 執行 `scripts/link.sh` 建立 symlink 到 ~/.claude/skills/

## 測試計畫

- 三個 SKILL.md frontmatter 欄位齊全、正體中文、無 emoji 無破折號
- link.sh 執行後 `ls -la ~/.claude/skills/` 確認三個 symlink 存在且指向正確
- dash validate（pre-push）通過
