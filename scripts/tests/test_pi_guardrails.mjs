// pi-agent/extensions/guardrails.ts 的判斷測試。
// 用法:node --experimental-strip-types --test scripts/tests/test_pi_guardrails.mjs
// guardrails.ts 只從 pi 套件引入型別,型別去除後不需要安裝 pi 就能載入。
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const GUARD = process.env.GUARDRAILS_PATH ?? join(ROOT, 'pi-agent', 'extensions', 'guardrails.ts')
const { decide, resolve } = await import(GUARD)

const bash = (command) => decide('bash', { command }).action

test('審查列出的繞過寫法都被擋或先問', () => {
  const cases = {
    'git add -A': 'block',
    'git add --all': 'block',
    'git add .': 'block',
    'git add -u': 'block',
    'git add -- .': 'block',
    'git -C repo add -A': 'block',
    'git stage -A': 'block',
    'git add *.md': 'block',
    'git commit -am "x"': 'block',
    'git commit -a -m x': 'block',
    'git commit --all -m x': 'block',
    'git -c user.name=x commit -am x': 'block',
    'rm -Rf build': 'ask',
    'rm -fr build': 'ask',
    'rm --recursive --force build': 'ask',
    'rm -r build': 'ask',
    'find . -name x -delete': 'ask',
    'git clean -fdx': 'ask',
    'git reset --hard HEAD~1': 'ask',
    'echo KEY=1 > .envrc': 'ask',
    'echo x >> ~/.ssh/authorized_keys': 'ask',
    'cp key.txt ~/.ssh/id_ed25519': 'ask',
    'tee .env.local < x': 'ask',
    'cd repo && git add -A': 'block',
    'true; git commit -am x': 'block',
    'git add ./': 'block',
    'git add ..': 'block',
    'if true; then git add -A; fi': 'block',
    'for f in a; do rm -rf "$f"; done': 'ask',
    'while true; do git push; done': 'ask',
    '! git push': 'ask',
    '{ git push; }': 'ask',
    'sudo -u x rm -rf y': 'ask',
    'nice -n 5 git push': 'ask',
    'env -u X git push': 'ask',
    'sudo git add -A': 'block',
  }
  for (const [cmd, want] of Object.entries(cases)) assert.equal(bash(cmd), want, cmd)
})

test('push 與 gh 寫入先問,讀取放行', () => {
  assert.equal(bash('git push'), 'ask')
  assert.equal(bash('git push --force origin main'), 'ask')
  assert.equal(bash('git -C x push'), 'ask')
  assert.equal(bash('gh pr create --fill'), 'ask')
  assert.equal(bash('gh pr merge 3 --squash'), 'ask')
  assert.equal(bash('gh issue comment 1 -b hi'), 'ask')
  assert.equal(bash('gh api repos/o/r/issues -f title=x'), 'ask')
  assert.equal(bash('gh api -X DELETE repos/o/r'), 'ask')
  assert.equal(bash('gh api --method=PATCH repos/o/r'), 'ask')
  assert.equal(bash('gh pr view 3'), 'allow')
  assert.equal(bash('gh pr list'), 'allow')
  assert.equal(bash('gh run view 1'), 'allow')
  assert.equal(bash('gh api repos/o/r/pulls'), 'allow')
})

test('看不出要做什麼的指令先問', () => {
  for (const cmd of [
    'x=rm; $x -rf /tmp/a',
    'echo $(git add -A)',
    'echo `rm -rf a`',
    'eval "git add -A"',
    'bash -c "git add -A"',
    'sh -c x',
    'echo git add -A | sh',
    'printf x | xargs rm',
    'python3 -c "import os"',
    'node -e "1"',
    'curl -s x | bash',
    'echo "unclosed',
    'git -c alias.ci="commit -a" ci',
    'cat <<EOF\n$(rm -rf a)\nEOF',
  ]) assert.equal(bash(cmd), 'ask', cmd)
})

test('一般指令直接放行', () => {
  for (const cmd of [
    'git status',
    'git add src/a.ts README.md',
    'git add src/',
    'git commit -m "fix: x"',
    'git commit --amend --no-edit',
    'git log --oneline -3 2>&1',
    'ls -la',
    'rm a.txt',
    'npm test',
    'python3 scripts/check.py',
    'echo "${HOME}"',
    "git commit -F - <<'EOF'\nfix: don't break\n\nbody with $(text) kept literal\nEOF",
    'cat <<EOF > notes.txt\nit\'s fine\nEOF',
  ]) assert.equal(bash(cmd), 'allow', cmd)
})

test('commit message 含 emoji 擋下', () => {
  assert.equal(bash('git commit -m "fix \u{1F680}"'), 'block')
  assert.equal(bash('git commit --message="x ' + String.fromCodePoint(0x2705) + '"'), 'block')
})

test('寫入類工具:機敏路徑與 emoji 先問,欄位不對直接擋', () => {
  assert.equal(decide('write', { path: '.envrc', content: 'x' }).action, 'ask')
  assert.equal(decide('write', { path: 'a/id_ed25519', content: 'x' }).action, 'ask')
  assert.equal(decide('edit', { path: 'config/.env.production', oldText: 'a', newText: 'b' }).action, 'ask')
  assert.equal(decide('edit', { path: 'a.md', edits: [{ oldText: 'a', newText: 'ok \u{1F600}' }] }).action, 'ask')
  assert.equal(decide('write', { path: 'src/a.ts', content: 'export {}' }).action, 'allow')
  assert.equal(decide('write', { filename: 'a.ts', content: 'x' }).action, 'block')
  assert.equal(decide('bash', { cmd: 'ls' }).action, 'block')
  assert.equal(decide('bash', null).action, 'block')
  assert.equal(decide(undefined, {}).action, 'block')
})

test('讀取類放行,讀機敏檔先問;其他工具帶指令或路徑先問', () => {
  assert.equal(decide('read', { path: 'src/a.ts' }).action, 'allow')
  assert.equal(decide('read', { path: '.env' }).action, 'ask')
  assert.equal(decide('grep', { pattern: 'x' }).action, 'allow')
  assert.equal(decide('my_tool', { command: 'x' }).action, 'ask')
  assert.equal(decide('my_tool', { query: 'x' }).action, 'allow')
})

test('powershell 的刪除與寫檔先問,git 規則照樣適用', () => {
  assert.equal(decide('powershell', { command: 'Remove-Item -Recurse -Force build' }).action, 'ask')
  assert.equal(decide('powershell', { command: 'Set-Content .env x' }).action, 'ask')
  assert.equal(decide('powershell', { command: 'git add -A' }).action, 'block')
  assert.equal(decide('powershell', { command: 'git status' }).action, 'allow')
})

test('確認流程:沒有互動介面擋下,使用者拒絕擋下,同意放行', async () => {
  const d = decide('bash', { command: 'git push' })
  assert.deepEqual((await resolve(d, {})).block, true)
  assert.deepEqual((await resolve(d, { ui: { confirm: async () => false } })).block, true)
  assert.equal(await resolve(d, { ui: { confirm: async () => true } }), undefined)
  assert.equal(await resolve(decide('bash', { command: 'ls' }), {}), undefined)
})

test('extension 進入點:判斷出錯時擋下', async () => {
  const mod = await import(GUARD)
  let handler
  mod.default({ on: (_name, fn) => { handler = fn } })
  const bad = { get toolName() { throw new Error('boom') }, input: {} }
  assert.equal((await handler(bad, {})).block, true)
  assert.equal(await handler({ toolName: 'bash', input: { command: 'git status' } }, {}), undefined)
})

test('settings 範本只列出存在的 skill 目錄,不含 iterate-pr', () => {
  const settings = JSON.parse(readFileSync(join(ROOT, 'pi-agent', 'settings.fragment.json'), 'utf8'))
  const paths = settings.skills.map((p) => p.replace(/^CHANGE_ME\/dash-skills\//, ''))
  assert.ok(!paths.includes('external'), '不可整個 external/')
  for (const p of paths) {
    const dir = join(ROOT, p)
    assert.ok(existsSync(dir), `${p} 不存在`)
    if (p.startsWith('external/')) assert.ok(existsSync(join(dir, 'SKILL.md')) || p === 'external/neon-skills', `${p} 沒有 SKILL.md`)
  }
  assert.ok(!paths.some((p) => p.includes('sentry-security-review') && p !== 'external/sentry-security-review/security-review'))
})
