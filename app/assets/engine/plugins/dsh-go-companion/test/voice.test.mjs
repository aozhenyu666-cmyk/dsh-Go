// P4 语音渠道 + 15 分钟换渠道：开了语音才念，没开就照旧靠屏幕。
//
// 渠道规则本身是纯函数（plan），配置与聊天指令走路由，都在这里断言。

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdtempSync, mkdirSync, rmSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { Readable } from 'node:stream'
import { DatabaseSync } from 'node:sqlite'
import { apply } from '../lib/index.js'
import { plan } from '../lib/plan.js'
import { voiceSwitch } from '../lib/silence.js'

const TZ = 'Asia/Shanghai'
const NOW = Date.UTC(2026, 4, 12, 6, 0, 0) // 手机上的 14:00，不在安静时段

/** 一球已经发出去、没人回、过了 16 分钟：阶梯到「换渠道」那一级。 */
function planInput({ voice, stage = 'channel' } = {}) {
  return {
    config: { enabled: true, quietStart: 1, quietEnd: 8, dailyMax: 6, hourlyMax: 3, minGapMs: 0 },
    now: NOW,
    tz: TZ,
    topic: { id: 't1' },
    sentToday: 1,
    sentLastHour: 1,
    lastAt: NOW - 16 * 60_000,
    roll: 1,
    silence: { stage },
    voice,
  }
}

test('开了语音：15 分钟那一级给出 speech 渠道', () => {
  const out = plan(planInput({ voice: true }))
  assert.equal(out.speak, true)
  assert.equal(out.stage, 'channel')
  assert.equal(out.channel, 'speech', '手机读到它才会念')
})

test('没开语音：同一级不留渠道，照旧靠屏幕', () => {
  const out = plan(planInput({ voice: false }))
  assert.equal(out.speak, true)
  assert.equal(out.stage, 'channel')
  assert.equal(out.channel, '', '浮层本来就是手机侧的首选，不用再指定')
})

test('5 分钟那一级换的是球，不是渠道', () => {
  const out = plan(planInput({ voice: true, stage: 'lighter' }))
  assert.equal(out.stage, 'lighter')
  assert.equal(out.channel, '', '换渠道是 15 分钟的事')
})

test('他没有正常发球的档期时，语音也不该自己开', () => {
  const out = plan({ ...planInput({ voice: true, stage: 'none' }), sentToday: 6 })
  assert.equal(out.speak, false)
  assert.equal(out.channel, undefined, '被额度拦下就没有渠道可换')
})

test('聊天里说「开语音 / 别念了」，别的话不算', () => {
  assert.equal(voiceSwitch('开语音'), true)
  assert.equal(voiceSwitch('开一下语音吧'), true)
  assert.equal(voiceSwitch('念出来'), true)
  assert.equal(voiceSwitch('别念了'), false)
  assert.equal(voiceSwitch('关掉语音'), false)
  // 只是话里带了这几个字，不是在喊它念。
  assert.equal(voiceSwitch('我打开了语音助手'), null)
  assert.equal(voiceSwitch('今天不想说话'), null)
})

// ---------------------------------------------------------------- 路由

function makeHost({ agent }) {
  const listeners = new Map()
  let handler
  const ctx = {
    get(name) {
      if (name === 'agents') return { get: () => agent, roots: () => [agent], list: () => [agent] }
      if (name === 'connection') return { requestRejection: () => undefined }
      if (name === 'sessionController') return { resolveAgent: async () => ({ agent }) }
      if (name === 'workspaceRegistry') return { archivedSessionIds: [] }
      return undefined
    },
    on(name, fn) {
      if (!listeners.has(name)) listeners.set(name, [])
      listeners.get(name).push(fn)
    },
    inject(_deps, cb) {
      cb({ webServer: { register(route) { handler = route.handler } }, effect(fn) { fn() } })
    },
    effect(fn) {
      fn()
    },
  }
  apply(ctx)
  return { handler, listeners }
}

function call(handler, method, path, body) {
  const req = Readable.from(body === undefined ? [] : [Buffer.from(JSON.stringify(body))])
  req.method = method
  req.url = path
  req.headers = { 'content-type': 'application/json' }
  const res = {
    statusCode: 0,
    text: '',
    writeHead(status) {
      this.statusCode = status
    },
    end(chunk) {
      this.text = chunk ? String(chunk) : ''
    },
  }
  return Promise.resolve(handler(req, res)).then(() => ({
    status: res.statusCode,
    body: res.text ? JSON.parse(res.text) : null,
  }))
}

function seed(home, config = {}) {
  const memDir = join(home, 'fish-memory')
  mkdirSync(memDir, { recursive: true })
  const cfgDir = join(home, 'companion')
  mkdirSync(cfgDir, { recursive: true })
  writeFileSync(
    join(cfgDir, 'config.json'),
    JSON.stringify({ sessionId: 'session-abc', quietStart: 12, quietEnd: 12, minGapMs: 0, ...config }),
  )
  const db = new DatabaseSync(join(memDir, 'fish-memory.sqlite'))
  db.exec('CREATE TABLE topics (id TEXT PRIMARY KEY, scope TEXT, title TEXT, detail TEXT, status TEXT, priority INTEGER, opened_at INTEGER, updated_at INTEGER, last_touch_at INTEGER, next_ask_at INTEGER, attempts INTEGER, due_at INTEGER, closed_at INTEGER, reason TEXT)')
  db.exec('CREATE TABLE facts (id TEXT PRIMARY KEY, scope TEXT, text TEXT, importance INTEGER, pinned INTEGER, updated_at INTEGER, status TEXT)')
  db.exec('CREATE TABLE episodes (id TEXT PRIMARY KEY, scope TEXT, text TEXT, tags TEXT, at INTEGER)')
  db.prepare('INSERT INTO topics (id, scope, title, detail, status, priority, opened_at, next_ask_at) VALUES (?,?,?,?,?,?,?,?)')
    .run('t1', 'session:session-abc', '面试结果', '她说周五出结果', 'open', 2, Date.now() - 86400000, 0)
  db.close()
}

/** 一球 16 分钟前发出去、没人回：下一次 plan 就落在「换渠道」那一级。 */
function seedSilentServe(home) {
  writeFileSync(
    join(home, 'companion', 'ledger.jsonl'),
    JSON.stringify({
      v: 1,
      requestId: 'old-1',
      sessionId: 'session-abc',
      state: 'generated',
      at: Date.now() - 16 * 60_000,
      serveType: 'provoke',
      text: '我猜你在躲申论',
      rallyId: 'rally-old',
      shot: 1,
    }) + '\n',
  )
}

function makeAgent() {
  const sent = []
  return {
    id: 'session-abc',
    status: 'idle',
    inbox: { hasPending: false },
    config: { provider: 'test', model: 'test-model' },
    sent,
    followup(msg) {
      sent.push(msg)
    },
  }
}

async function withHome(fn) {
  const home = mkdtempSync(join(tmpdir(), 'companion-p4-'))
  const oldHome = process.env.DSH_HOME
  process.env.DSH_HOME = home
  try {
    return await fn(home)
  } finally {
    if (oldHome === undefined) delete process.env.DSH_HOME
    else process.env.DSH_HOME = oldHome
    rmSync(home, { recursive: true, force: true })
  }
}

test('说一句「开语音」就写进配置，plan 之后才带渠道', async () => {
  await withHome(async (home) => {
    seed(home)
    seedSilentServe(home)
    const agent = makeAgent()
    const host = makeHost({ agent })
    const fire = async (event) => {
      for (const fn of host.listeners.get('session/event') || []) await fn({ id: 'session-abc' }, event)
    }

    const before = await call(host.handler, 'POST', '/dsh-go-companion/v1/plan', { v: 1, timeZone: TZ })
    assert.equal(before.body.channel, '', '默认没开语音')

    await fire({ type: 'user/message', data: { content: [{ type: 'text', text: '开语音' }] } })
    const cfg = JSON.parse(readFileSync(join(home, 'companion', 'config.json'), 'utf8'))
    assert.equal(cfg.voice, true, '要写进配置')

    const after = await call(host.handler, 'POST', '/dsh-go-companion/v1/plan', { v: 1, timeZone: TZ })
    assert.equal(after.body.stage, 'channel')
    assert.equal(after.body.channel, 'speech', '开了语音，这一级就该念出来')

    const status = await call(host.handler, 'GET', '/dsh-go-companion/v1/status')
    assert.equal(status.body.config.voice, true, '/status 要能看见这个开关')

    const ledger = readFileSync(join(home, 'companion', 'ledger.jsonl'), 'utf8')
      .split('\n')
      .filter(Boolean)
      .map((l) => JSON.parse(l))
    const voiced = ledger.find((e) => e.state === 'voice')
    assert.ok(voiced, '账本要记下他开过语音')
    assert.equal(voiced.voice, true)
  })
})

test('说「别念了」就关掉，重复说不再记一遍', async () => {
  await withHome(async (home) => {
    seed(home, { voice: true })
    seedSilentServe(home)
    const agent = makeAgent()
    const host = makeHost({ agent })
    const fire = async (event) => {
      for (const fn of host.listeners.get('session/event') || []) await fn({ id: 'session-abc' }, event)
    }
    const say = (text) => fire({ type: 'user/message', data: { content: [{ type: 'text', text }] } })

    await say('别念了')
    assert.equal(JSON.parse(readFileSync(join(home, 'companion', 'config.json'), 'utf8')).voice, false)

    const planOut = await call(host.handler, 'POST', '/dsh-go-companion/v1/plan', { v: 1, timeZone: TZ })
    assert.equal(planOut.body.channel, '', '关了就不念')

    // 已经是关的，再说一次不该再写一条 voice 记录。
    await say('别念了')
    const count = readFileSync(join(home, 'companion', 'ledger.jsonl'), 'utf8')
      .split('\n')
      .filter(Boolean)
      .map((l) => JSON.parse(l))
      .filter((e) => e.state === 'voice').length
    assert.equal(count, 1)
  })
})
