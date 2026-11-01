#!/usr/bin/env node
/**
 * 真宿主端到端：改 setting → 插件重新读 → 系统提示变化 → 重启后仍有效。
 *
 * 用法：node test/live-host/run.mjs --home <DSH_HOME> [--port 39551] [--exe <DeepSeek Harness.exe>]
 * 退出码：全过 0，任何一条 FAIL 非 0。
 */
import fs from 'node:fs'
import path from 'node:path'
import { spawn } from 'node:child_process'

function arg(name, fallback) {
  const i = process.argv.indexOf('--' + name)
  return i >= 0 ? process.argv[i + 1] : fallback
}

const home = path.resolve(arg('home', ''))
if (!home) { console.error('需要 --home <DSH_HOME>'); process.exit(2) }
const port = Number(arg('port', '39551'))
const exe = arg('exe', process.env.DSH_EXE || 'C:\\Users\\敖震宇\\AppData\\Local\\Programs\\DeepSeek Harness\\DeepSeek Harness.exe')
const cli = path.join(path.dirname(exe), 'resources', 'app.asar', 'dsh', 'node_modules', '@deepseek-ai', 'dsh-desktop-host', 'lib', 'cli.js')
const logPath = path.join(home, 'live-host.log')

const results = []
const check = (name, ok, detail) => { results.push({ name, ok: Boolean(ok), detail }); console.log((ok ? 'PASS  ' : 'FAIL  ') + name + (detail && !ok ? '  ← ' + detail : '')) }

async function boot(p) {
  const fd = fs.openSync(logPath, 'w')
  const child = spawn(exe, ['--expose-internals', cli, '--profile', 'web', '--no-open', '--host', '127.0.0.1', '--port', String(p)], {
    cwd: home,
    env: { ...process.env, ELECTRON_RUN_AS_NODE: '1', DSH_HOME: home, DSH_TELEMETRY_DISABLED: '1', TZ: 'Asia/Shanghai' },
    stdio: ['ignore', fd, fd],
  })
  let token = ''
  for (let i = 0; i < 400; i++) {
    await new Promise((r) => setTimeout(r, 200))
    const txt = fs.existsSync(logPath) ? fs.readFileSync(logPath, 'utf8') : ''
    const m = /token=([\w-]+)/.exec(txt)
    if (m) { token = m[1]; break }
    if (child.exitCode !== null) throw new Error('宿主退出：' + txt.slice(0, 2000))
  }
  if (!token) throw new Error('宿主没在超时内给出 token')
  const base = 'http://127.0.0.1:' + p
  const r0 = await fetch(base + '/?token=' + token, { redirect: 'manual' })
  const sc = r0.headers.getSetCookie ? r0.headers.getSetCookie() : [r0.headers.get('set-cookie')]
  const cookie = sc.filter(Boolean).map((c) => c.split(';')[0]).join('; ')
  const req = async (p2, init = {}) => {
    const r = await fetch(base + p2, { ...init, headers: { ...(init.headers || {}), cookie } })
    const txt = await r.text()
    let body
    try { body = JSON.parse(txt) } catch { body = txt }
    return { status: r.status, body }
  }
  return { child, req }
}

const edit = (h, patch) => h.req('/m3/edit', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(patch) })
const sec = (p, name) => ((p.body.sections || []).find((s) => s.name === name) || {}).text || ''
const ctxOf = (p, name) => ((p.body.contexts || []).find((s) => s.name === name) || {}).text || ''
const kill = (h) => { try { h.child.kill('SIGKILL') } catch {} }

let h = await boot(port)
try {
  // ① 原生表单的 schema 真的到了宿主
  const form = await h.req('/dsh-go/v1/plugin-config/partner')
  check('宿主提供真 Config（表单可读）', form.status === 200 && Object.keys(form.body?.schema?.refs || {}).length > 5,
    'status=' + form.status + ' refs=' + Object.keys(form.body?.schema?.refs || {}).length)

  // ② 初始状态
  let p = await h.req('/m3/prompt')
  check('人格进了系统提示', sec(p, 'partner:persona').length > 0)
  check('心情进了每轮上下文', ctxOf(p, 'partner:mood').length > 0)
  check('四个工具都注册上了', p.body.tools.filter((t) => t.startsWith('partner_')).length === 4,
    JSON.stringify(p.body.tools.filter((t) => t.startsWith('partner_'))))

  // ③ 改 persona.style → 系统提示立刻变
  let e = await edit(h, { persona: { style: '【LIVE】只回一句话' } })
  check('改 persona.style 被接受', e.body.ok === true, e.body.error)
  p = await h.req('/m3/prompt')
  check('persona.style 立刻出现在系统提示里', sec(p, 'partner:persona').includes('【LIVE】只回一句话'))

  // ④ 三个开关
  await edit(h, { memory: { enabled: false } })
  p = await h.req('/m3/prompt')
  check('关记忆 → 提示段不再提记忆', !sec(p, 'partner:hint').includes('【记忆】'))

  await edit(h, { mood: { enabled: false } })
  p = await h.req('/m3/prompt')
  check('关情绪 → 心情上下文为空', ctxOf(p, 'partner:mood') === '')

  await edit(h, { tools: { enabled: false } })
  p = await h.req('/m3/prompt')
  check('关工具 → 提示段为空', sec(p, 'partner:hint') === '')

  await edit(h, { persona: { enabled: false } })
  p = await h.req('/m3/prompt')
  check('关人格 → 人格段为空', sec(p, 'partner:persona') === '')

  // ⑤ 全部打开 + 一个可辨认的值，供重启验证
  await edit(h, { persona: { enabled: true, style: '【LIVE-重启后仍在】' }, memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true } })
  p = await h.req('/m3/prompt')
  check('恢复后人格段回来', sec(p, 'partner:persona').includes('【LIVE-重启后仍在】'))
} finally { kill(h) }

await new Promise((r) => setTimeout(r, 2000))

// ⑥ 全新进程 = 重启
h = await boot(port + 1)
try {
  const s = await h.req('/m3/state')
  check('重启后 style 仍是改过的值', s.body.live?.style === '【LIVE-重启后仍在】', JSON.stringify(s.body.live))
  const p = await h.req('/m3/prompt')
  check('重启后系统提示仍带它', sec(p, 'partner:persona').includes('【LIVE-重启后仍在】'))
  check('重启后四个工具仍在', p.body.tools.filter((t) => t.startsWith('partner_')).length === 4)
  const form = await h.req('/dsh-go/v1/plugin-config/partner')
  check('重启后原生表单读到同一个值', form.body?.value?.persona?.style === '【LIVE-重启后仍在】', JSON.stringify(form.body?.value?.persona))
} finally { kill(h) }

const failed = results.filter((r) => !r.ok)
console.log('')
console.log(results.length - failed.length + '/' + results.length + ' 通过')
process.exit(failed.length ? 1 : 0)
