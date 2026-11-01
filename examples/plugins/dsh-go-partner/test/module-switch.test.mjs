/**
 * 三个开关 + 工具开关的**运行期**语义（本地可跑）。
 *
 * 为什么单独一个文件：真机实测（R4 第三轮）发现两个只有真宿主才会暴露的坑，
 * 这里用最小的假 ctx 把它们的**行为契约**钉住，免得以后又漂回去：
 *   1. 开关是 volatile 字段 ⇒ cordis 改了它**不重启插件**，所以「注册时读一次开关」是错的；
 *      工具必须注册着、每次执行时现查（关掉就明确拒绝，而不是照旧干活）。
 *   2. cordis 的 ctx 是 Proxy：没 inject 过的服务**读一下就抛**，不是返回 undefined。
 */
import assert from 'node:assert/strict'
import path from 'node:path'
import { test } from 'node:test'

import { tempHome, seedAll, writeJson } from './fixtures.mjs'
import { apply, registerTools } from '../lib/index.js'
import { setLiveConfigSource } from '../lib/config.mjs'

const fakeDefineTool = (o) => o

/** 一个会在「读到没 inject 的服务」时抛错的 ctx —— 和 cordis 的 Proxy 行为一致。 */
function proxyishCtx(allowed) {
  const store = {}
  const handler = {
    get(target, prop) {
      if (prop in target) return target[prop]
      if (typeof prop === 'symbol') return undefined
      if (allowed.includes(prop)) return store[prop]
      throw new Error('cannot get property "' + String(prop) + '" without inject')
    },
  }
  const ctx = new Proxy({
    inject(names, cb) {
      if (!Array.isArray(names)) return
      // 只有**真的给了**的服务才回调 —— 这就是 cordis 的 inject 语义：
      // 拿不到 dshGo 时那段回调根本不会执行，所以里面的 c.dshGo 也就不会被读。
      if (names.every((n) => allowed.includes(n))) cb(ctx)
    },
    on() { return () => {} },
    effect(fn) { const d = fn(); return typeof d === 'function' ? d : () => {} },
  }, handler)
  store.tools = { register: (def) => { (store.__defs ||= []).push(def); return () => {} } }
  store.__defs = store.__defs || []
  ctx.__defs = store.__defs
  return ctx
}

test('cordis Proxy：没 inject 的服务读一下就抛，插件不许因此挂掉', () => {
  const home = tempHome()
  seedAll(home)
  // dshGo 也不给：apply 里那段桥接代码整个不该被执行，也不该被读
  const ctx = proxyishCtx(['tools'])
  assert.doesNotThrow(() => {
    const dispose = apply(ctx, { persona: { enabled: true }, memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true } }, { defineTool: fakeDefineTool })
    dispose()
  }, '读不到 agents/systemPrompt 只能降级，不能把整条插件带崩')
})

test('工具开关是运行期语义：关着也注册，调用时明确拒绝而不是照旧干活', async () => {
  const home = tempHome()
  seedAll(home)
  const defs = []
  const plain = { tools: { register: (d) => { defs.push(d); return () => {} } } }
  await registerTools(plain, {}, fakeDefineTool)
  assert.equal(defs.length, 4)

  const recall = defs.find((d) => d.name === 'partner_recall')
  const remember = defs.find((d) => d.name === 'partner_remember')
  const mood = defs.find((d) => d.name === 'partner_mood')

  // 全开
  let off = setLiveConfigSource(() => ({ memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true } }))
  try {
    assert.equal(recall.execute({ query: '散热硅脂' }, { sessionId: 's1' }).ok, true)
    assert.equal(mood.execute({}, { sessionId: 's1' }).ok, true)
  } finally { off() }

  // 关工具：四个都要拒
  off = setLiveConfigSource(() => ({ memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: false } }))
  try {
    const r = recall.execute({ query: '散热硅脂' }, { sessionId: 's1' })
    assert.equal(r.ok, false)
    assert.match(r.reason, /关掉/)
    const w = remember.execute({ text: '不该写进去' }, {})
    assert.equal(w.ok, false, '工具关掉之后不许还真写一条进去')
    assert.equal(mood.execute({}, {}).ok, false)
  } finally { off() }

  // 只关记忆：recall 拒、mood 照常
  off = setLiveConfigSource(() => ({ memory: { enabled: false }, mood: { enabled: true }, tools: { enabled: true } }))
  try {
    assert.match(recall.execute({ query: 'x' }, {}).reason, /记忆模块/)
    assert.equal(mood.execute({}, { sessionId: 's1' }).ok, true, '关记忆不该影响心情')
  } finally { off() }
})

test('记忆/情绪/人格三个开关各自独立影响系统提示', () => {
  const home = tempHome()
  seedAll(home)
  const sections = []
  const contexts = []
  const prompt = {
    section: (s) => { sections.push(s); return () => {} },
    context: (c) => { contexts.push(c); return () => {} },
  }
  const ctx = {
    inject(names, cb) { if (names.includes('systemPrompt')) cb({ systemPrompt: prompt }) },
    on() { return () => {} },
    effect(fn) { const d = fn(); return typeof d === 'function' ? d : () => {} },
  }
  // ⚠️ 这里要**原地改**，不能整个换成新对象：cordis 的热更新是把新值写进已有的
  //   Volatile 引用（对象身份不变），插件拿到的就是同一个 config 对象。
  //   用一个「改字段」的小工具模拟它。
  const cfg = { persona: { enabled: true, style: '风格甲' }, memory: { enabled: true }, mood: { enabled: true, inject: true }, tools: { enabled: true }, hint: { enabled: true } }
  const patch = (next) => { for (const [k, v] of Object.entries(next)) Object.assign(cfg[k], v) }
  const off = setLiveConfigSource(() => cfg)
  try {
    const dispose = apply(ctx, cfg, { defineTool: fakeDefineTool })
    const persona = sections.find((s) => s.name === 'partner:persona')
    const hint = sections.find((s) => s.name === 'partner:hint')
    const mood = contexts.find((c) => c.name === 'partner:mood')
    assert.ok(persona && hint && mood)
    assert.match(persona.text(), /风格甲/)
    assert.match(mood.text(), /这会儿的心情/)

    patch({ mood: { enabled: false } })
    assert.equal(mood.text(), '', '关掉情绪后一轮都不许再注入')
    assert.ok(persona.text().length > 0, '人格还开着')

    patch({ persona: { enabled: false } })
    assert.equal(persona.text(), '')
    dispose()
  } finally { off() }
})
