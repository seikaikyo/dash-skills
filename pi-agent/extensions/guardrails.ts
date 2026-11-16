/**
 * guardrails — 工作防護 extension
 *
 * 把常用的攔截搬到 pi:危險 git 指令、對外動作確認、刪除確認、機敏檔寫入、emoji。
 * 等同 Claude Code 那套 git-add-all / emoji / dangerous-command hook。
 *
 * 判斷方式(2026-11-16 改寫):shell 指令先拆成一個個簡單指令再逐詞判斷,
 * 不對整串字做比對(舊版用幾條正規表示式,`git commit -am`、`rm -Rf` 這類寫法都擋不到)。
 * 看不出要做什麼的指令(指令替換、變數當指令、巢狀 shell、xargs)一律先問。
 * 已知工具的欄位格式認不得就擋,不放行。
 *
 * 基於 @earendil-works/pi 公開版的 extension API。若內網 pi 是改過的
 * fork,event.input 的欄位名(command / path / content)可能要對照內部文件微調;
 * 欄位對不上時這裡會擋下並在 reason 說明,不會默默放行。
 *
 * 安裝:放到 ~/.pi/agent/extensions/guardrails.ts,進 pi 後執行 /reload。
 * 驗證:要 agent 跑 `git add -A`,應被擋下並回 reason。
 * 測試:node --experimental-strip-types --test scripts/tests/test_pi_guardrails.mjs
 */
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export type Decision = { action: 'allow' } | { action: 'ask' | 'block'; reason: string }

const ALLOW: Decision = { action: 'allow' }
const ask = (reason: string): Decision => ({ action: 'ask', reason })
const block = (reason: string): Decision => ({ action: 'block', reason })

// emoji 與裝飾性符號。箭頭區段(U+2190-21FF)刻意不納入,維持豁免。
const DECORATIVE =
  /[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}\u{1F1E6}-\u{1F1FF}]/u

const SENSITIVE =
  /(^|\/)\.env(\.[^/]*)?$|(^|\/)\.envrc$|(^|\/)id_(rsa|dsa|ecdsa|ed25519)(\.pub)?$|\.(pem|key|p12|pfx)$|credentials|secret|(^|\/)\.(ssh|aws|gnupg)(\/|$)|(^|\/)\.(netrc|npmrc|pypirc)$|\.docker\/config\.json$|keys\.json$/i

const READ_TOOLS = new Set(['read', 'grep', 'find', 'ls'])
const SHELL_TOOLS = new Set(['bash', 'powershell'])
const WRITE_TOOLS = new Set(['write', 'edit'])
const SHELLS = new Set(['sh', 'bash', 'zsh', 'dash', 'ksh', 'fish', 'pwsh', 'powershell'])
const INTERPRETERS = new Set(['python', 'python3', 'node', 'perl', 'ruby', 'php', 'deno', 'bun', 'osascript'])
const OPAQUE = new Set(['eval', 'exec', 'source', '.', 'xargs', 'parallel', 'watch', 'nohup', 'timeout'])
const PREFIXES = new Set(['sudo', 'command', 'builtin', 'time', 'env', 'nice', 'doas'])
const WRITERS = new Set(['tee', 'cp', 'mv', 'ln', 'install', 'dd', 'touch', 'truncate', 'chmod', 'chown', 'rm'])
const GH_READ = new Set(['view', 'list', 'status', 'diff', 'checks', 'search'])

type Simple = { words: string[]; redirects: string[]; pipedFrom: boolean }

/** 簡化版 shell 斷詞:處理引號、跳脫、控制運算子與重新導向。回傳 null 代表含看不懂的結構。 */
export function parseShell(src: string): Simple[] | null {
  const cmds: Simple[] = []
  let cur: Simple = { words: [], redirects: [], pipedFrom: false }
  let word = ''
  let inWord = false
  let redirectNext = false
  const endWord = () => {
    if (!inWord) return
    if (redirectNext) cur.redirects.push(word)
    else cur.words.push(word)
    word = ''
    inWord = false
    redirectNext = false
  }
  const endCmd = (piped: boolean) => {
    endWord()
    if (cur.words.length || cur.redirects.length) cmds.push(cur)
    cur = { words: [], redirects: [], pipedFrom: piped }
  }
  for (let i = 0; i < src.length; i++) {
    const c = src[i]
    if (c === '\\') {
      if (i + 1 < src.length && src[i + 1] !== '\n') word += src[i + 1]
      i++
      inWord = true
    } else if (c === "'") {
      const j = src.indexOf("'", i + 1)
      if (j < 0) return null
      word += src.slice(i + 1, j)
      i = j
      inWord = true
    } else if (c === '"') {
      let j = i + 1
      for (; j < src.length && src[j] !== '"'; j++) {
        if (src[j] === '\\') j++
        else if (src[j] === '`' || (src[j] === '$' && src[j + 1] === '(')) return null
      }
      if (j >= src.length) return null
      word += src.slice(i + 1, j).replace(/\\(["\\$`])/g, '$1')
      i = j
      inWord = true
    } else if (c === '`' || (c === '$' && src[i + 1] === '(') || ((c === '<' || c === '>') && src[i + 1] === '(')) {
      return null
    } else if (c === ';' || c === '\n' || c === '&' || c === '|' || c === '(' || c === ')' || c === '{' || c === '}') {
      if (c === '&' && src[i + 1] === '>') {
        endWord()
        i += src[i + 2] === '>' ? 2 : 1
        redirectNext = true
        continue
      }
      const piped = c === '|' && src[i + 1] !== '|'
      if ((c === '&' || c === '|') && src[i + 1] === c) i++
      endCmd(piped)
    } else if (c === '<' && src[i + 1] === '<' && src[i + 2] === '<') {
      // here-string:後面那個字是資料,不是指令
      endWord()
      i += 2
      while (src[i + 1] === ' ' || src[i + 1] === '\t') i++
      const m = /^('[^']*'|"[^"]*"|\S+)/.exec(src.slice(i + 1))
      if (m) i += m[0].length
    } else if (c === '<' && src[i + 1] === '<') {
      // heredoc:內文是資料,跳到結束標記那一行
      endWord()
      i += src[i + 2] === '-' ? 2 : 1
      while (src[i + 1] === ' ' || src[i + 1] === '\t') i++
      const m = /^('([^']*)'|"([^"]*)"|\\?([^\s;&|<>]+))/.exec(src.slice(i + 1))
      if (!m) return null
      const delim = m[2] ?? m[3] ?? m[4]
      i += m[0].length
      const nl = src.indexOf('\n', i + 1)
      if (nl < 0) return null
      // 開頭那一行剩下的部分(例如 | 或 && 後面的指令)照常解析
      const head = parseShell(src.slice(i + 1, nl))
      if (!head) return null
      const lines = src.slice(nl + 1).split('\n')
      const end = lines.findIndex((ln) => ln.replace(/^\t+/, '') === delim)
      if (end < 0) return null
      // 結束標記沒加引號時,內文的 $(...) 與反引號照樣會執行
      const quoted = m[4] === undefined || m[0].startsWith('\\')
      if (!quoted && /\$\(|`/.test(lines.slice(0, end).join('\n'))) return null
      const tail = parseShell(lines.slice(end + 1).join('\n'))
      if (!tail) return null
      endCmd(false)
      return [...cmds, ...head, ...tail]
    } else if (c === '$' && src[i + 1] === '{') {
      const j = src.indexOf('}', i + 2)
      if (j < 0) return null
      word += src.slice(i, j + 1)
      i = j
      inWord = true
    } else if (c === '>' || c === '<') {
      // 2>&1 這類複製檔案描述子的不算寫檔
      if (/^\d*$/.test(word) && src[i + 1] === '&' && /\d|-/.test(src[i + 2] ?? '')) {
        word = ''
        inWord = false
        i += 2
        continue
      }
      if (/^\d+$/.test(word)) {
        word = ''
        inWord = false
      }
      endWord()
      if (src[i + 1] === c || src[i + 1] === '|') i++
      redirectNext = c === '>'
      if (c === '<') redirectNext = false
    } else if (c === ' ' || c === '\t') {
      endWord()
    } else {
      word += c
      inWord = true
    }
  }
  endCmd(false)
  return cmds
}

// 流程控制關鍵字後面接的才是真正的指令(if x; then git add -A; fi)
const KEYWORDS = new Set(['if', 'then', 'else', 'elif', 'fi', 'do', 'done', 'while', 'until', 'case', 'esac', '!', '{', '}'])

/** 去掉變數設定、流程關鍵字與 sudo 這類包裝。包裝帶選項時看不出哪個字是指令,回傳 null。 */
function stripPrefixes(words: string[]): string[] | null {
  let i = 0
  while (i < words.length) {
    const w = words[i]
    if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(w) || KEYWORDS.has(w)) i++
    else if (PREFIXES.has(w)) {
      i++
      if (w === 'command' && /^-[vV]$/.test(words[i] ?? '')) return []
      if ((words[i] ?? '').startsWith('-')) return null
    } else break
  }
  return words.slice(i)
}

function gitDecision(args: string[]): Decision {
  // 跳過全域選項,找到子指令
  let i = 0
  while (i < args.length && args[i].startsWith('-')) {
    // 臨時定義的別名可以把任何指令包成新名字,看不出會做什麼
    if (args[i] === '-c' && /^alias\./i.test(args[i + 1] ?? '')) return ask(`git -c 定義別名,看不出會執行什麼:\ngit ${args.join(' ')}`)
    if (['-C', '-c', '--git-dir', '--work-tree', '--namespace', '--exec-path'].includes(args[i])) i += 2
    else i++
  }
  const sub = args[i]
  const rest = args.slice(i + 1)
  if (sub === 'add' || sub === 'stage') {
    for (const a of rest) {
      if (a === '--') continue
      if (['-A', '--all', '-u', '--update', '--no-ignore-removal'].includes(a) || /^-[^-]*[Au]/.test(a))
        return block('禁 git add -A / -u / --all,請指名檔案')
      if (/^[./]+$/.test(a) || a === ':' || a.startsWith(':/') || /[*?[]/.test(a))
        return block('禁 git add . 與萬用字元,請指名檔案')
      if (a.startsWith('-')) return ask(`git add 帶選項 ${a},確定執行?`)
    }
    return ALLOW
  }
  if (sub === 'commit') {
    for (let k = 0; k < rest.length; k++) {
      const a = rest[k]
      if (a === '--all' || /^-[^-]*a/.test(a.replace(/m.*$/, ''))) return block('禁 git commit -a,請先指名 git add')
      const msg = a === '-m' || a === '--message' ? rest[k + 1] : a.startsWith('--message=') ? a.slice(10) : /^-[^-]*m./.test(a) ? a.slice(a.indexOf('m') + 1) : undefined
      if (msg && DECORATIVE.test(msg)) return block('commit message 禁 emoji')
    }
    return ALLOW
  }
  if (sub === 'push') return ask(`git push 會推到遠端,確定執行?\ngit ${args.join(' ')}`)
  if (sub === 'clean') return ask(`git clean 會刪除未追蹤檔案,確定執行?\ngit ${args.join(' ')}`)
  if (sub === 'reset' && rest.includes('--hard')) return ask('git reset --hard 會丟掉未提交的改動,確定執行?')
  return ALLOW
}

function ghDecision(args: string[]): Decision {
  const [group, verb] = args
  if (group === 'api') {
    const writes = args.some((a, k) =>
      ['-f', '-F', '--field', '--raw-field', '--input'].includes(a) || a.startsWith('--field=') || a.startsWith('--raw-field=') ||
      ((a === '-X' || a === '--method') && (args[k + 1] ?? '').toUpperCase() !== 'GET') ||
      (a.startsWith('--method=') && a.slice(9).toUpperCase() !== 'GET') || (/^-X./.test(a) && a.slice(2).toUpperCase() !== 'GET'))
    return writes ? ask(`gh api 寫入動作,確定執行?\ngh ${args.join(' ')}`) : ALLOW
  }
  if (group === 'search' || group === 'status' || (verb && GH_READ.has(verb))) return ALLOW
  return ask(`gh ${group ?? ''} ${verb ?? ''} 可能寫入 GitHub,確定執行?\ngh ${args.join(' ')}`)
}

function commandDecision(cmd: Simple): Decision {
  for (const target of cmd.redirects) {
    if (SENSITIVE.test(target)) return ask(`重新導向寫入機敏檔 ${target},確定執行?`)
  }
  const words = stripPrefixes(cmd.words)
  if (!words) return ask(`包裝指令帶選項,看不出實際執行什麼:\n${cmd.words.join(' ')}`)
  if (!words.length) return ALLOW
  const name = words[0].split('/').pop() ?? words[0]
  const args = words.slice(1)
  if (words[0].includes('$')) return ask(`指令名稱由變數決定,看不出要執行什麼:\n${words.join(' ')}`)
  if (OPAQUE.has(name)) return ask(`${name} 會執行另一段指令,看不出內容:\n${words.join(' ')}`)
  if (SHELLS.has(name) && (args.some((a) => /^-[a-z]*c/.test(a)) || cmd.pipedFrom))
    return ask(`巢狀 shell,看不出要執行什麼:\n${words.join(' ')}`)
  if (INTERPRETERS.has(name.replace(/[\d.]+$/, '')) && (args.some((a) => ['-c', '-e', '--eval', '-'].includes(a)) || cmd.pipedFrom))
    return ask(`直譯器執行一段指令,看不出內容:\n${words.join(' ')}`)
  if (name === 'git') return gitDecision(args)
  if (name === 'gh') return ghDecision(args)
  if (name === 'rm' || name === 'rmdir') {
    if (args.some((a) => /^-[^-]*[rRf]/.test(a) || ['--recursive', '--force', '--dir'].includes(a)))
      return ask(`刪除指令,確定執行?\n${words.join(' ')}`)
  }
  if (name === 'find' && args.some((a) => a === '-delete' || a === '-exec' || a === '-execdir' || a === '-ok'))
    return ask(`find 會刪除或執行指令,確定執行?\n${words.join(' ')}`)
  if (name === 'sed' && args.some((a) => /^-[^-]*i/.test(a) || a.startsWith('--in-place')) && args.some((a) => SENSITIVE.test(a)))
    return ask('sed -i 改寫機敏檔,確定執行?')
  if (WRITERS.has(name) && args.some((a) => SENSITIVE.test(a))) return ask(`${name} 碰到機敏檔,確定執行?\n${words.join(' ')}`)
  return ALLOW
}

// PowerShell 的刪除、寫檔、執行字串;斷詞照 sh 規則只能抓到一部分,其餘靠這條
const POWERSHELL_RISKY =
  /\b(Remove-Item|Set-Content|Add-Content|Out-File|New-Item|Move-Item|Copy-Item|Invoke-Expression|iex|Start-Process|Invoke-WebRequest|Invoke-RestMethod)\b/i

function shellDecision(toolName: string, command: unknown): Decision {
  if (typeof command !== 'string') return block(`看不懂 ${toolName} 工具的欄位格式(找不到字串 command),先擋下`)
  if (toolName === 'powershell' && POWERSHELL_RISKY.test(command)) return ask(`PowerShell 指令會刪除、寫檔或執行字串,確定執行?\n${command}`)
  const cmds = parseShell(command)
  if (!cmds) return ask(`指令含指令替換或引號沒有閉合,看不出要執行什麼:\n${command}`)
  let pending: Decision = ALLOW
  for (const c of cmds) {
    const d = commandDecision(c)
    if (d.action === 'block') return d
    if (d.action === 'ask' && pending.action === 'allow') pending = d
  }
  return pending
}

function writeDecision(toolName: string, input: Record<string, unknown>): Decision {
  const path = input.path ?? input.file_path
  if (typeof path !== 'string') return block(`看不懂 ${toolName} 工具的欄位格式(找不到字串 path),先擋下`)
  if (SENSITIVE.test(path)) return ask(`確定寫入機敏檔 ${path}?`)
  const texts: unknown[] = [input.content, input.newText, input.new_string, input.newString]
  if (Array.isArray(input.edits)) for (const e of input.edits) texts.push((e as Record<string, unknown>)?.newText, (e as Record<string, unknown>)?.new_string)
  if (texts.some((t) => typeof t === 'string' && DECORATIVE.test(t))) return ask(`${path} 內容含裝飾符號,仍要寫入?`)
  return ALLOW
}

/** 對一次工具呼叫做判斷。只看工具名稱與輸入,不依賴 pi 執行環境。 */
export function decide(toolName: unknown, input: unknown): Decision {
  if (typeof toolName !== 'string' || typeof input !== 'object' || input === null)
    return block('看不懂這次工具呼叫的格式,先擋下')
  const fields = input as Record<string, unknown>
  if (READ_TOOLS.has(toolName)) {
    const p = fields.path ?? fields.file_path
    return typeof p === 'string' && SENSITIVE.test(p) ? ask(`確定讀取機敏檔 ${p}?`) : ALLOW
  }
  if (SHELL_TOOLS.has(toolName)) return shellDecision(toolName, fields.command)
  if (WRITE_TOOLS.has(toolName)) return writeDecision(toolName, fields)
  // 其他工具(自訂、MCP):帶了指令或路徑欄位就先問
  if (['command', 'cmd', 'script', 'path', 'file_path'].some((k) => typeof fields[k] === 'string'))
    return ask(`工具 ${toolName} 帶了指令或路徑,確定執行?`)
  return ALLOW
}

type Ctx = { ui?: { confirm?: (title: string, message: string) => Promise<boolean> } }

/** 把判斷結果轉成 tool_call 的回傳值;要確認但沒有互動介面時擋下。 */
export async function resolve(d: Decision, ctx: Ctx): Promise<{ block: true; reason: string } | undefined> {
  if (d.action === 'allow') return undefined
  if (d.action === 'block') return { block: true, reason: d.reason }
  if (typeof ctx?.ui?.confirm !== 'function') return { block: true, reason: `需要確認但目前沒有互動介面:${d.reason}` }
  const ok = await ctx.ui.confirm('需要確認', d.reason)
  return ok ? undefined : { block: true, reason: '使用者取消' }
}

export default function (pi: ExtensionAPI) {
  pi.on('tool_call', async (event, ctx) => {
    try {
      return await resolve(decide(event.toolName, event.input), ctx as Ctx)
    } catch (err) {
      return { block: true, reason: `防護判斷出錯,先擋下:${String(err)}` }
    }
  })
}
