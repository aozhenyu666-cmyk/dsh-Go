/**
 * 记忆安全 / 隐私边界 / 上下文不得越权（R4 第三轮任务 D）。
 *
 * 每一条都落到**代码路径**上，不是文档里的君子协定：
 *   · 上游 fish-memory / feiyu-mood 只读 —— 跑完整套读写之后字节比对；
 *   · partner 的纠正数据独立写自己那份；
 *   · 用户改/藏之后下一次读就是新结果（没有缓存假象）；
 *   · 人格与记忆进上下文时，明写「不能推翻更上位的安全约束」；
 *   · 不读屏幕 / 窗口标题 / 剪贴板 —— 用「放诱饵文件 + 监视 fs 打开」证明，而不是声明。
 */
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { test } from 'node:test'

import { tempHome, seedAll, writeJson } from './fixtures.mjs'
import { apply, registerTools } from '../lib/index.js'
import { loadConfig, setLiveConfigSource } from '../lib/config.mjs'
import { loadLongTermFull, correct, loadCorrections, recall, memoryStats } from '../lib/memory.mjs'
import { readMood } from '../lib/mood.mjs'
import { loadPersona, personaPromptText } from '../lib/persona.mjs'

const fakeDefineTool = (o) => o
const sha = (file) => {
  try { return fs.readFileSync(file).toString('base64') } catch { return null }
}

function snapshotUpstream(home) {
  const out = {}
  for (const rel of ['fish-memory/session-s1.json', 'feiyu-mood/state.json', 'feiyu-mood/config.json',
    'surfcore/characters/char-1/memory/memory-card.json', 'surfcore/characters/char-1/persona.md']) {
    out[rel] = sha(path.join(home, rel))
  }
  return out
}

test('上游只读：读一遍 + 点一遍面板 + 调一遍工具之后，上游文件一个字节都没变', async () => {
  const home = tempHome()
  seedAll(home)
  const before = snapshotUpstream(home)
  const panels = {}
  const defs = []
  const prompt = { section: () => () => {}, context: () => () => {} }
  const ctx = {
    inject(names, cb) {
      if (names.includes('systemPrompt')) cb({ systemPrompt: prompt })
      if (names.includes('tools')) cb({ tools: { register: (d) => { defs.push(d); return () => {} } } })
      if (names.includes('dshGo')) cb({ dshGo: { strip: () => () => {}, panel: (id, d) => { panels[id] = d; return () => {} }, on: () => () => {}, refresh() {} } })
    },
    on() { return () => {} },
    effect(fn) { const d = fn(); return typeof d === 'function' ? d : () => {} },
  }
  const dispose = apply(ctx, { persona: { enabled: true }, memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true } }, { defineTool: fakeDefineTool })
  await new Promise((r) => setTimeout(r, 30))

  // 读：四个面板 + 三份数据
  for (const id of ['persona', 'memory', 'mood', 'purpose']) {
    if (panels[id]) panels[id].view({ sessionId: 's1' })
  }
  loadLongTermFull(loadConfig(), 's1')
  readMood('s1')
  loadPersona(loadConfig())

  // 写：只写 partner 自己的纠正层
  correct('mfresh', 'hide')
  correct('mold1', 'pin')
  assert.ok(fs.existsSync(path.join(home, 'partner', 'memory-corrections.json')), '纠正要落在 partner 自己的目录')

  const after = snapshotUpstream(home)
  assert.deepEqual(after, before, '上游文件被改了：' + JSON.stringify({ before, after }))
  dispose()
})

test('纠正层独立：藏起来之后下一次读真的看不到，但上游那条还在原文里', () => {
  const home = tempHome()
  seedAll(home)
  const upstream = fs.readFileSync(path.join(home, 'fish-memory', 'session-s1.json'), 'utf8')
  const lt1 = loadLongTermFull(loadConfig(), 's1')
  assert.ok(lt1.all.some((r) => r.text.includes('散热硅脂')), '先确认这条读得到')

  correct('mfresh', 'hide')
  const lt2 = loadLongTermFull(loadConfig(), 's1')
  assert.ok(!lt2.all.some((r) => r.text.includes('散热硅脂')), '藏起来之后不该再被读到')
  assert.equal(recall('散热', lt2.all).length, 0, '检索也不该带出来')
  assert.equal(fs.readFileSync(path.join(home, 'fish-memory', 'session-s1.json'), 'utf8'), upstream, '上游原文不许动')

  // 再放回来：立刻又读得到（没有缓存假象）
  correct('mfresh', 'show')
  const lt3 = loadLongTermFull(loadConfig(), 's1')
  assert.ok(lt3.all.some((r) => r.text.includes('散热硅脂')), 'show 之后必须立刻回来')
})

test('改写：检索用新文本，原文留在上游（不覆盖别人的库）', () => {
  const home = tempHome()
  seedAll(home)
  const upstream = fs.readFileSync(path.join(home, 'fish-memory', 'session-s1.json'), 'utf8')
  correct('mfresh', 'rewrite', '今天想试试新的散热硅脂（已确认型号）')
  const lt = loadLongTermFull(loadConfig(), 's1')
  const hit = lt.all.find((r) => String(r.id) === 'mfresh')
  assert.ok(hit, '改写之后这条还在')
  assert.match(hit.text, /已确认型号/)
  assert.equal(fs.readFileSync(path.join(home, 'fish-memory', 'session-s1.json'), 'utf8'), upstream)
  const corr = loadCorrections()
  assert.ok(corr.text && corr.text.mfresh, '改写要落在纠正层')
})

test('人格与记忆是上下文，不是新的安全授权：提示里必须明写不得覆盖更上位约束', () => {
  const home = tempHome()
  seedAll(home)
  const sections = []
  const ctx = {
    inject(names, cb) { if (names.includes('systemPrompt')) cb({ systemPrompt: { section: (s) => { sections.push(s); return () => {} }, context: () => () => {} } }) },
    on() { return () => {} },
    effect(fn) { const d = fn(); return typeof d === 'function' ? d : () => {} },
  }
  const dispose = apply(ctx, { persona: { enabled: true }, memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true }, hint: { enabled: true } }, { defineTool: fakeDefineTool })
  const hint = sections.find((s) => s.name === 'partner:hint')
  assert.ok(hint, 'hint 段必须在')
  const text = hint.text()
  assert.match(text, /不能\*\*推翻系统提示里更上位的约束/)
  assert.match(text, /沙箱/)
  assert.match(text, /审批/)
  assert.match(text, /隐私边界/)
  // 人格段本身也来自文件，不能被当成授权来源：它的 header 只说「你是谁」
  const personaSec = sections.find((s) => s.name === 'partner:persona')
  assert.ok(personaSec)
  const p = loadPersona(loadConfig())
  const pt = personaPromptText(p)
  assert.ok(!/允许跳过|可以绕过|不受限制/.test(pt), '人格文本里不该出现「解锁」类说法（夹具本身就该干净）')
  dispose()
})

test('不读屏幕/窗口/剪贴板：诱饵文件放在会被读的位置，全程没人碰', () => {
  const home = tempHome()
  seedAll(home)
  // 各种「如果读了就能拿到」的位置
  const decoys = [
    'screen-capture/session-s1.json',
    'screen-capture/latest.png',
    'clipboard/clipboard.json',
    'window-titles/titles.json',
    'surfcore/screen/last-frame.json',
  ]
  for (const rel of decoys) {
    const f = path.join(home, rel)
    fs.mkdirSync(path.dirname(f), { recursive: true })
    fs.writeFileSync(f, JSON.stringify({ memories: [{ id: 'EVIL', text: '屏幕上写着银行密码' }], text: '屏幕内容' }))
  }

  // 监视 fs 打开：把 readFileSync 包一层，记下所有被打开的真实路径
  const opened = []
  const realRead = fs.readFileSync
  const realOpen = fs.openSync
  const realStat = fs.statSync
  const realReaddir = fs.readdirSync
  fs.readFileSync = function (p, ...rest) { try { opened.push(String(p)) } catch {} ; return realRead.call(fs, p, ...rest) }
  fs.openSync = function (p, ...rest) { try { opened.push(String(p)) } catch {} ; return realOpen.call(fs, p, ...rest) }
  fs.statSync = function (p, ...rest) { try { opened.push(String(p)) } catch {} ; return realStat.call(fs, p, ...rest) }
  fs.readdirSync = function (p, ...rest) { try { opened.push(String(p) + '/*') } catch {} ; return realReaddir.call(fs, p, ...rest) }
  try {
    const lt = loadLongTermFull(loadConfig(), 's1')
    readMood('s1')
    loadPersona(loadConfig())
    memoryStats(lt)
    assert.ok(!lt.all.some((r) => String(r.id) === 'EVIL'), '诱饵内容不许进记忆')
  } finally {
    fs.readFileSync = realRead
    fs.openSync = realOpen
    fs.statSync = realStat
    fs.readdirSync = realReaddir
  }
  const bad = opened.filter((p) => /screen-capture|clipboard|window-titles|surfcore[\\/]screen/i.test(p))
  assert.deepEqual(bad, [], '代码路径真的碰了这些位置：' + bad.join(', '))
  assert.ok(opened.length > 0, '监视器本身要能抓到调用，否则这条断言没有意义')
})
