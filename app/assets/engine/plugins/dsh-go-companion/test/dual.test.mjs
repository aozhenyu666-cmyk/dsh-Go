// 姐妹双人格：妹妹（陪伴）主动找他、陪他闹；姐姐（谋士）管正事、往前推两步。各占一个会话，各挂各的人设。

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { Readable } from 'node:stream'
import { apply } from '../lib/index.js'
import { buildPrompt } from '../lib/prompt.js'
import { companionChatText, strategistChatText, roleNames } from '../lib/roles.js'

function agentOf(id) {
  const contexts = []
  const sent = []
  return {
    id, status: 'idle', inbox: { hasPending: false }, sent, contexts,
    followup(m) { sent.push(m) },
    ctx: { systemPrompt: { context(def) { contexts.push(def); return () => { def.removed = true } } } },
  }
}

function host(agents) {
  let handler
  const ctx = {
    get(name) {
      if (name === 'agents') return { get: (id) => agents[id], roots: () => Object.values(agents), list: () => Object.values(agents) }
      if (name === 'connection') return { requestRejection: () => undefined }
      if (name === 'sessionController') return { resolveAgent: async (id) => ({ agent: agents[id] }) }
      if (name === 'workspaceRegistry') return { archivedSessionIds: [] }
      return undefined
    },
    on() {},
    inject(_d, cb) { cb({ webServer: { register(r) { handler = r.handler } }, effect(fn) { fn() } }) },
    effect(fn) { fn() },
  }
  apply(ctx)
  return { handler: () => handler }
}

function call(handler, method, path, body) {
  const req = Readable.from(body === undefined ? [] : [Buffer.from(JSON.stringify(body))])
  req.method = method
  req.url = path
  req.headers = { 'content-type': 'application/json' }
  const res = { statusCode: 0, text: '', writeHead(s) { this.statusCode = s }, end(c) { this.text = c ? String(c) : '' } }
  return Promise.resolve(handler(req, res)).then(() => ({ status: res.statusCode, body: res.text ? JSON.parse(res.text) : null }))
}

async function withHome(fn) {
  const home = mkdtempSync(join(tmpdir(), 'companion-dual-'))
  const old = process.env.DSH_HOME
  process.env.DSH_HOME = home
  try { return await fn(home) } finally {
    if (old === undefined) delete process.env.DSH_HOME
    else process.env.DSH_HOME = old
    rmSync(home, { recursive: true, force: true })
  }
}

test('妹妹的人设：是朋友不是助手，不碰正事、正事甩给姐姐', () => {
  const t = companionChatText({})
  assert.match(t, /你是小肥鱼/)
  assert.match(t, /不是助手、不是客服、不是工具/)
  assert.match(t, /不碰正事/)
  assert.match(t, /去问大肥鱼/)
  assert.doesNotMatch(t, /\{姐姐\}|\{妹妹\}/, '占位符都替换掉了')
})

test('姐姐的人设：谋士，往前推两步、摆几条路、只问一个关键问题、落到第一步', () => {
  const t = strategistChatText({}, ['你的底线（绝不做）：不撒谎'])
  assert.match(t, /你是大肥鱼/)
  assert.match(t, /往前推两步/)
  assert.match(t, /2–3 条路/)
  assert.match(t, /只问这一个/)
  assert.match(t, /检验点/)
  assert.match(t, /不撒谎/, '关系库人物卡并进姐姐')
})

test('名字和人设可改', () => {
  assert.deepEqual(roleNames({ companionName: '鱼丸', strategistName: '鲸姐' }), { companion: '鱼丸', strategist: '鲸姐' })
  assert.match(companionChatText({ companionName: '鱼丸', strategistName: '鲸姐' }), /去问鲸姐/)
  assert.match(companionChatText({ companionCard: '只会说喵' }), /只会说喵/)
})

test('主动发球由妹妹说：不讲道理、不劝做事，带着自己的态度', () => {
  const p = buildPrompt({ role: 'companion', serveType: 'observe', names: { companion: '小肥鱼', strategist: '大肥鱼' }, owner: '他' })
  assert.match(p, /你是小肥鱼——他的朋友，不是助手/)
  assert.match(p, /别劝他"该去做事了"/)
  assert.match(p, /吃醋/)
  assert.doesNotMatch(p, /思维教练/)
})

test('两个会话各挂各的人设；/say 带 role=strategist 就发给姐姐', async () => {
  await withHome(async (home) => {
    mkdirSync(join(home, 'companion'), { recursive: true })
    writeFileSync(join(home, 'companion', 'config.json'), JSON.stringify({ sessionId: 'session-sis', strategistSessionId: 'session-big', quietStart: 12, quietEnd: 12 }))
    const sis = agentOf('session-sis')
    const big = agentOf('session-big')
    const h = host({ 'session-sis': sis, 'session-big': big })
    // 启动时就挂上
    assert.equal(sis.contexts.length, 1)
    assert.equal(big.contexts.length, 1)
    assert.match(sis.contexts[0].text(), /你是小肥鱼/)
    assert.match(big.contexts[0].text(), /你是大肥鱼，.*谋士/)
    const a = await call(h.handler(), 'POST', '/dsh-go-companion/v1/say', { v: 1, requestId: 'say-to-sister-1', text: '在吗' })
    assert.equal(a.status, 202)
    assert.equal(sis.sent.length, 1)
    const b = await call(h.handler(), 'POST', '/dsh-go-companion/v1/say', { v: 1, requestId: 'say-to-big-001', text: '我该考研还是工作', role: 'strategist' })
    assert.equal(b.status, 202, JSON.stringify(b.body))
    assert.equal(big.sent.length, 1)
    assert.equal(big.sent[0].content[0].text, '我该考研还是工作')
  })
})

test('关掉双人格（dual:false）：回到单人格大肥鱼，姐姐的会话不挂人设', async () => {
  await withHome(async (home) => {
    mkdirSync(join(home, 'companion'), { recursive: true })
    writeFileSync(join(home, 'companion', 'config.json'), JSON.stringify({ sessionId: 'session-sis', strategistSessionId: 'session-big', dual: false }))
    const sis = agentOf('session-sis')
    const big = agentOf('session-big')
    host({ 'session-sis': sis, 'session-big': big })
    assert.match(sis.contexts[0].text(), /你是大肥鱼，.*身边的伙伴/)
    assert.equal(big.contexts.length, 0)
  })
})
