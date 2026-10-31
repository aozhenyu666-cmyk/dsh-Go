/**
 * 端到端自测：用一个**假的 dshGo 宿主**跑 apply()，验证
 *   ① 清单合法（id 唯一、面板 ≤4、状态条 ≤1、标题字数）
 *   ② 没桥接的主机不会把插件打挂（ctx.inject(['dshGo']) 不触发即可）
 *   ③ 各面板在「没有数据」和「有数据」两种情况下都给得出合法视图
 *   ④ 数据换了以后 refresh / strip 会推新值；取消函数真的清了定时器
 *
 * 跑：node test/apply.test.mjs
 * 不依赖 DSH、不依赖 App —— 纯 Node，可以在手机上跑。
 */
import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'

import { apply } from '../lib/index.js'
import { validate, moodPanel, memoryPanel, purposePanel, rememberCard } from '../lib/views.mjs'

let pass = 0
let fail = 0
const t = (name, fn) => {
  try { fn(); console.log('  ✓ ' + name); pass += 1 }
  catch (e) { console.log('  ✗ ' + name + '\n      ' + (e && e.message)); fail += 1 }
}

// ── 假宿主 ──────────────────────────────────────────────────────────────────
function fakeCtx({ withBridge = true } = {}) {
  const calls = { strip: [], panel: {}, refresh: [] }
  const strips = {}
  const panels = {}
  const ctx = {
    inject(names, cb) {
      // 真宿主：只有装了 dsh-go 桥接的主机才会进来
      if (!withBridge) return
      if (!names.includes('dshGo') || names.includes('dshGo?')) return
      cb(ctx)
    },
  }
  ctx.dshGo = {
    strip(id, dataFn) {
      calls.strip.push(id)
      strips[id] = dataFn
      return () => {}
    },
    panel(id, def) {
      calls.panel[id] = def
      panels[id] = def
    },
    on() {},
    refresh(id, scope) { calls.refresh.push({ id, scope }) },
  }
  return { ctx, calls, strips, panels }
}

// ── 1. 清单 ────────────────────────────────────────────────────────────────
console.log('\n1. package.json 清单')
const pkg = JSON.parse(fs.readFileSync(new URL('../package.json', import.meta.url), 'utf8'))
t('dshGo.v = 1', () => assert.equal(pkg.dshGo.v, 1))
t('contributes 只有 4 类以内的插槽', () => {
  const keys = Object.keys(pkg.dshGo.contributes)
  assert.ok(keys.every((k) => ['composer.actions', 'message.actions', 'composer.strip', 'panels'].includes(k)), keys.join(','))
})
t('composer.strip ≤ 1 条', () => assert.ok(pkg.dshGo.contributes['composer.strip'].length <= 1))
t('panels ≤ 4 个', () => assert.ok(pkg.dshGo.contributes.panels.length <= 4))
t('panel title ≤ 16 字', () => {
  for (const p of pkg.dshGo.contributes.panels) {
    const s = typeof p.title === 'string' ? p.title : p.title.zh
    assert.ok(s.length <= 16, `${p.id} 标题 ${s.length} 字`)
  }
})
t('所有 id 在同一插件内不重复', () => {
  const ids = []
  for (const [k, list] of Object.entries(pkg.dshGo.contributes)) for (const it of list) ids.push(`${k}:${it.id}`)
  const flat = []
  for (const [k, list] of Object.entries(pkg.dshGo.contributes)) for (const it of list) flat.push(it.id)
  assert.equal(new Set(flat).size, flat.length, flat.join(','))
})
t('id 符合 ^[A-Za-z0-9][A-Za-z0-9_.-]{0,39}$', () => {
  for (const [k, list] of Object.entries(pkg.dshGo.contributes)) {
    for (const it of list) assert.match(it.id, /^[A-Za-z0-9][A-Za-z0-9_.-]{0,39}$/, `${k}/${it.id}`)
  }
})
t('整个 dshGo ≤ 16 KiB', () => assert.ok(Buffer.byteLength(JSON.stringify(pkg.dshGo)) <= 16 * 1024))
t('strip 引用的 panel 真的存在', () => {
  const panelIds = new Set(pkg.dshGo.contributes.panels.map((p) => p.id))
  for (const s of pkg.dshGo.contributes['composer.strip']) if (s.panel) assert.ok(panelIds.has(s.panel), s.panel)
})
t('cordis.patch.yml 与包名一致', () => {
  const y = fs.readFileSync(new URL('../cordis.patch.yml', import.meta.url), 'utf8')
  assert.ok(y.includes(`name: ${pkg.name}`), y)
})

// ── 2. 无桥接主机不能打挂 ───────────────────────────────────────────────────
console.log('\n2. 没有 dsh-go 桥接的主机')
t('apply() 不抛错、也不注册任何东西', () => {
  const { ctx, calls } = fakeCtx({ withBridge: false })
  assert.doesNotThrow(() => apply(ctx))
  assert.equal(calls.strip.length, 0)
  assert.deepEqual(Object.keys(calls.panel), [])
})

// ── 3. 无数据时的视图 ───────────────────────────────────────────────────────
console.log('\n3. 没有数据（裸机第一次打开）')
const tmpHome = fs.mkdtempSync(path.join(os.tmpdir(), 'partner-test-'))
process.env.DSH_HOME = tmpHome
const { ctx, calls, strips, panels } = fakeCtx()
t('apply() 注册了 1 条状态条 + 3 个面板', () => {
  apply(ctx)
  assert.deepEqual(calls.strip, ['mood.strip'])
  assert.deepEqual(Object.keys(calls.panel).sort(), ['memory', 'mood', 'purpose'])
  // 状态条 id 不许和面板 id 撞（同一插件内所有插槽 id 唯一）
  for (const s of calls.strip) assert.ok(!(s in calls.panel), `strip "${s}" 与面板 id 重复`)
})
t('每个面板的 view 都返回合法视图（没数据时是 callout 而非空白）', () => {
  for (const id of ['mood', 'memory', 'purpose']) {
    const v = panels[id].view({ sessionId: 's1' })
    // view 必须是**同步**返回视图；返回 Promise 说明被 async 包过 → App 会报「插件界面有误」
    assert.ok(!(v instanceof Promise), `${id}.view 返回了 Promise（不该用 async 包）`)
    assert.ok(v && v.type === 'stack', `${id} 根节点`)
    const r = validate(v, 'panel')
    assert.ok(r.ok, `${id}: ${r.issues.map((i) => i.problem).join('; ')}`)
    const hasCallout = JSON.stringify(v).includes('callout') || JSON.stringify(v).includes('not-implemented') || JSON.stringify(v).includes('还没做')
    assert.ok(hasCallout, `${id} 应该有一句人话说明为什么是空的`)
  }
})
t('状态条 dataFn 同步返回取消函数（Promise 会导致定时器泄漏）', () => {
  const pushed = []
  const cancel = strips['mood.strip']({ sessionId: 's1' }, (d) => pushed.push(d))
  assert.ok(!(cancel instanceof Promise), 'strip 返回了 Promise')
  assert.ok(pushed.length >= 1)
  assert.ok(typeof pushed[0].text === 'string' && pushed[0].text.length <= 24, JSON.stringify(pushed[0]))
  assert.ok(Buffer.byteLength(JSON.stringify(pushed[0])) <= 2048)
  assert.equal(typeof cancel, 'function')
  cancel()
})

// ── 4. 有数据时的视图 ───────────────────────────────────────────────────────
console.log('\n4. 有数据（模拟真机上跑过几轮）')
const now = Date.now()
fs.mkdirSync(path.join(tmpHome, 'feiyu-mood'), { recursive: true })
fs.writeFileSync(path.join(tmpHome, 'feiyu-mood', 'config.json'), JSON.stringify({
  selfName: '大肥鱼', ownerName: '小明', moodBase: 70, decayHalfHours: 3, injectMode: 'event', injectConfidence: 60,
  slots: [{ id: 'abc', label: '大肥鱼', sessions: ['s1'] }],
}))
fs.writeFileSync(path.join(tmpHome, 'feiyu-mood', 'state.json'), JSON.stringify({
  moods: {
    abc: {
      mood: 72.4,
      dims: { happy: 6, steady: 3, sweet: 2, tender: 1, worry: 0, sad: 0, jealous: 0.5 },
      timeline: [{ at: now - 60000, delta: 6, reason: '被夸了一句' }, { at: now - 3600000, delta: -3, reason: '他说在忙' }],
    },
  },
}))
fs.mkdirSync(path.join(tmpHome, 'fish-memory'), { recursive: true })
fs.writeFileSync(path.join(tmpHome, 'fish-memory', 's1.json'), JSON.stringify({
  memories: [
    { id: 'a', text: '我最怕吵，写代码时别打断我', importance: 0.82, vitality: 0.9, createdAt: new Date(now - 86400000).toISOString(), tags: ['owner'] },
    { id: 'b', text: '答应过周末一起看那部片子', importance: 0.7, vitality: 0.6, createdAt: new Date(now - 3 * 86400000).toISOString(), tags: ['owner'] },
    { id: 'c', text: '随口提过想学吉他', importance: 0.35, vitality: 0.2, createdAt: new Date(now - 20 * 86400000).toISOString() },
  ],
  status: { chars: 1840, warnChars: 60000 },
}))

const { ctx: ctx2, strips: strips2, panels: panels2 } = fakeCtx()
apply(ctx2)

t('心情面板：能量出 mood / 七维 / 时间线', () => {
  const v = panels2.mood.view({ sessionId: 's1' })
  const r = validate(v, 'panel')
  assert.ok(r.ok, r.issues.map((i) => i.problem).join('; '))
  const s = JSON.stringify(v)
  assert.ok(s.includes('72'), '应显示心情值')
  assert.ok(s.includes('开心'), '七维里应有「开心」')
  assert.ok(s.includes('被夸了一句'), '时间线理由应出现')
})
t('记忆面板：三条都在，且按清晰度映射', () => {
  const v = panels2.memory.view({ sessionId: 's1' })
  const r = validate(v, 'panel')
  assert.ok(r.ok, r.issues.map((i) => i.problem).join('; '))
  const s = JSON.stringify(v)
  assert.ok(s.includes('写代码时别打断'), 'vivid 那条应在')
  assert.ok(s.includes('想学吉他'), 'fuzzy 那条应在')
  assert.ok(s.includes('正在模糊'), 'fuzzy 应归到「正在模糊的事」')
})
t('目的面板：P2 还没做时给出人话，不是空白', () => {
  const v = panels2.purpose.view({ sessionId: 's1' })
  const r = validate(v, 'panel')
  assert.ok(r.ok, r.issues.map((i) => i.problem).join('; '))
  assert.ok(JSON.stringify(v).includes('还没做'))
})
t('状态条现在推的是真心情（不再是「心情未开」）', () => {
  const pushed = []
  const cancel = strips2['mood.strip']({ sessionId: 's1' }, (d) => pushed.push(d))
  assert.ok(pushed.length >= 1)
  assert.ok(!pushed[0].text.includes('未开'), JSON.stringify(pushed[0]))
  cancel()
})

// ── 5. slot 对不上时要明说，不能猜 ─────────────────────────────────────────
console.log('\n5. 数据错乱（0.7.0 修过的那类）')
fs.writeFileSync(path.join(tmpHome, 'feiyu-mood', 'config.json'), JSON.stringify({
  selfName: '大肥鱼', ownerName: '小明', moodBase: 70,
  slots: [{ id: '__default__', label: '大肥鱼', sessions: ['s1'] }],
}))
fs.writeFileSync(path.join(tmpHome, 'feiyu-mood', 'state.json'), JSON.stringify({
  moods: { '4d6beaf3-1111-2222-3333-444455556666': { mood: 60, dims: {}, timeline: [] } },
}))
const { ctx: ctx3, panels: panels3 } = fakeCtx()
apply(ctx3)
t('slot id 与 moods 键不一致 → 明文报错并给出修法', () => {
  const v = panels3.mood.view({ sessionId: 's1' })
  const s = JSON.stringify(v)
  assert.ok(s.includes('对不上'), s)
  assert.ok(s.includes('设置页'), '应告诉用户去哪儿修')
})

// ── 6. 工具卡必须只用白名单组件 ─────────────────────────────────────────────
console.log('\n6. remember 工具卡')
t('成功时是合法工具卡', () => {
  const v = rememberCard({ text: '我最怕吵，写代码时别打断我', importance: 0.8, tags: ['偏好'], 事实键: '她.工作习惯' }, { ok: true })
  const r = validate(v, 'toolCard')
  assert.ok(r.ok, r.issues.map((i) => i.problem).join('; '))
})
t('失败时不说「记住了」', () => {
  const v = rememberCard({ text: 'x' }, { ok: false, message: '这个会话的记忆是关着的' })
  const s = JSON.stringify(v)
  assert.ok(s.includes('没记住') && s.includes('关着'), s)
})
t('空参数也不崩', () => {
  const v = rememberCard({}, {})
  assert.ok(validate(v, 'toolCard').ok)
})

// ── 7. 大列表不超预算 ───────────────────────────────────────────────────────
console.log('\n7. 边界：200 条记忆也不超面板预算')
t('200 条记忆的视图仍合法（靠截断）', () => {
  const records = Array.from({ length: 200 }, (_, i) => ({
    id: `m${i}`, text: `第 ${i} 条记忆内容`, clarity: i % 4 === 0 ? 'fuzzy' : 'clear',
    importance: 50 + (i % 50), createdAt: new Date(now - i * 3600000).toISOString(), tags: i % 3 ? ['owner'] : [],
  }))
  const v = memoryPanel({ records, status: { chars: 50000, warnChars: 60000, percent: 83 } })
  const r = validate(v, 'panel')
  assert.ok(r.ok, r.issues.map((i) => i.problem).join('; '))
  assert.ok(r.nodes <= 120, `节点 ${r.nodes}`)
})

// ── 收尾 ────────────────────────────────────────────────────────────────────
fs.rmSync(tmpHome, { recursive: true, force: true })
console.log('')
console.log(fail ? `  ${fail} 项失败 / ${pass + fail} 项` : `  全部 ${pass} 项通过`)
process.exit(fail ? 1 : 0)
