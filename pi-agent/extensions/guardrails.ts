/**
 * guardrails — 工作防護 extension
 *
 * 把常用的攔截搬到 pi:危險 git 指令、機敏檔寫入、emoji。
 * 等同 Claude Code 那套 git-add-all / emoji / dangerous-command hook。
 *
 * 基於 @earendil-works/pi 公開版的 extension API。若內網 pi 是改過的
 * fork,event.input 的欄位名(command / path / content)可能要對照
 * 內部文件微調。
 *
 * 安裝:放到 ~/.pi/agent/extensions/guardrails.ts,進 pi 後執行 /reload。
 * 驗證:要 agent 跑 `git add -A`,應被擋下並回上面的 reason。
 */
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { isToolCallEventType } from '@earendil-works/pi-coding-agent'

// emoji 與裝飾性符號。箭頭區段(U+2190-21FF)刻意不納入,維持豁免。
const DECORATIVE =
  /[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}\u{1F1E6}-\u{1F1FF}]/u

export default function (pi: ExtensionAPI) {
  pi.on('tool_call', async (event, ctx) => {
    if (isToolCallEventType('bash', event)) {
      const cmd = event.input.command ?? ''

      // 禁全量 add,強制指名檔案
      if (/\bgit\s+add\s+(-A|--all|\.)(\s|$)/.test(cmd) || /\bgit\s+commit\s+.*-a\b/.test(cmd)) {
        return { block: true, reason: '禁 git add -A / . / commit -a,請指名檔案' }
      }

      // 危險刪除先確認
      if (/\brm\s+-[rf]/.test(cmd)) {
        const ok = await ctx.ui.confirm('危險指令', `確定執行?\n${cmd}`)
        if (!ok) return { block: true, reason: '使用者取消 rm' }
      }

      // commit message 含 emoji
      const commitMsg = cmd.match(/git\s+commit[^]*?-m\s+["']([^]*?)["']/)?.[1]
      if (commitMsg && DECORATIVE.test(commitMsg)) {
        return { block: true, reason: 'commit message 禁 emoji' }
      }
    }

    if (isToolCallEventType('write', event)) {
      const path = event.input.path ?? ''

      // 機敏檔寫入先確認
      if (/(^|\/)\.env(\.|$)/.test(path) || /(id_rsa|\.pem$|credentials|secret)/i.test(path)) {
        const ok = await ctx.ui.confirm('機敏檔', `確定寫入 ${path}?`)
        if (!ok) return { block: true, reason: '使用者取消機敏檔寫入' }
      }

      // 寫入內容含 emoji
      const content = (event.input as { content?: string }).content ?? ''
      if (DECORATIVE.test(content)) {
        const ok = await ctx.ui.confirm('內容含 emoji', `${path} 內容含裝飾符號,仍要寫入?`)
        if (!ok) return { block: true, reason: '使用者取消(emoji)' }
      }
    }
  })
}
