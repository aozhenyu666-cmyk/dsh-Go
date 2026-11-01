/**
 * 配置链路（本地可跑，不需要 DSH）：证明**宿主注入的 config 是唯一来源**，
 * 以及「改一个 volatile 字段 → 下一轮立刻读到新值」这件事真的成立。
 *
 * 这里用**真的 schemastery 3.18.5** 把 config 解析一遍，再喂给 setLiveConfigSource(),
 * 模拟 cordis 干的那一步。schemastery 拿不到时按「NOT_TESTED」跳过并说明原因，
 * 不假装通过（跟 real-dsh-tools.test.mjs 同一个规矩）。
 */
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { test } from 'node:test'

import { tempHome, seedAll, writeJson } from './fixtures.mjs'
import { loadSchemasterySync } from '../lib/hostdeps.mjs'
import { loadConfig, setLiveConfigSource, DEFAULTS } from '../lib/config.mjs'
import { Config, apply } from '../lib/index.js'

const z = loadSchemasterySync()

test('原生表单的 schema 真的拿得到（不是 undefined，也不是自己塞的全局）', (t) => {
  if (!z) {
    t.skip('这台机器上找不到宿主的 @deepseek-ai/schemastery（设 DSH_SCHEMASTERY_ROOT 后可跑）')
    return
  }
  assert.notEqual(Config, undefined, '宿主拿不到 schema 就画不出表单；这里必须是真 schema')
  assert.equal(typeof Config['~standard']?.validate, 'function', 'schemastery schema 必须能校验（cordis 就是这么用的）')
  const graph = Config.toJSON()
  assert.equal(typeof graph.uid, 'number')
  assert.ok(Object.keys(graph.refs).length > 5)
  // 每个**可编辑字段**都必须自己带 volatile：宿主设置层（dsh-settings 的 volatileForm）
  // 和 cordis 的热更新都只认它。组本身（object）不必带，数组的 inner 也不必带
  // （数组字段自己 volatile 就够了）。
  const root = graph.refs[graph.uid]
  assert.equal(root.type, 'object')
  const fields = []
  for (const [group, id] of Object.entries(root.dict ?? {})) {
    const node = graph.refs[id]
    assert.equal(node.type, 'object', group + ' 应该是一个组')
    for (const [key, childId] of Object.entries(node.dict ?? {})) {
      fields.push([group + '.' + key, graph.refs[childId]])
    }
  }
  assert.ok(fields.length >= 12, '字段数不该少（现有 15 个）')
  const missing = fields.filter(([, n]) => n.meta?.volatile !== true).map(([k]) => k)
  assert.deepEqual(missing, [], '这些字段没标 volatile，宿主表单会拒写：' + missing.join(', '))
  // 没有字段时校验也要能过（cordis 用 ~standard.validate 走同一条路）
  assert.equal(Config['~standard'].validate({}).issues, undefined)
})

test('配置只有一套：注入 host config 之后，JSON 文件不再参与运行', (t) => {
  const home = tempHome()
  seedAll(home)
  // 文件里写一套「完全相反」的值
  writeJson(path.join(home, 'partner', 'config.json'), { persona: { style: '文件里的风格', enabled: false } })
  const fromFile = loadConfig()
  assert.equal(fromFile.__source, 'file')
  assert.equal(fromFile.persona.style, '文件里的风格')

  // 宿主注入一份 config（cordis 校验后的形状：volatile 字段是 { get() } 引用）
  const off = setLiveConfigSource(() => ({ persona: { style: '表单里的风格', enabled: true } }))
  try {
    const fromHost = loadConfig()
    assert.equal(fromHost.__source, 'host')
    assert.equal(fromHost.persona.style, '表单里的风格', '有 host config 时**不许**再读文件')
    assert.equal(fromHost.persona.enabled, true)
    assert.equal(fromHost.__legacy, path.join(home, 'partner', 'config.json'), '旧文件还在时要说出来，不能静默忽略')
    // 缺的字段用默认补齐
    assert.equal(fromHost.memory.recallLimit, DEFAULTS.memory.recallLimit)
  } finally {
    off()
  }
  assert.equal(loadConfig().__source, 'file', 'disposer 之后退回文件源')
})

test('volatile 引用是每次现取的：改引用值，下一次 loadConfig 立刻是新值', (t) => {
  const home = tempHome()
  seedAll(home)
  let style = 'A'
  const off = setLiveConfigSource(() => ({ persona: { style } }))
  try {
    assert.equal(loadConfig().persona.style, 'A')
    style = 'B' // 等价于 cordis 把一个新值写进 Volatile 引用
    assert.equal(loadConfig().persona.style, 'B', '不许缓存快照，否则表单改了不生效')
  } finally {
    off()
  }
})

test('apply 用注入的 config 跑：面板说「配置来自原生表单」，不再提 config.json', (t) => {
  const home = tempHome()
  seedAll(home)
  writeJson(path.join(home, 'partner', 'config.json'), { persona: { style: '旧文件' } })
  const panels = {}
  const ctx = {
    inject(names, cb) { if (Array.isArray(names) && names.includes('dshGo')) cb(ctx) },
    on() { return () => {} },
    effect(fn) { const d = fn(); return typeof d === 'function' ? d : () => {} },
    dshGo: { strip() { return () => {} }, panel(id, def) { panels[id] = def; return () => {} }, on() { return () => {} }, refresh() {} },
  }
  const dispose = apply(ctx, { persona: { style: '来自表单' }, memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true } })
  assert.equal(typeof dispose, 'function')
  const view = JSON.stringify(panels.persona.view({ sessionId: 's1' }))
  assert.match(view, /原生设置表单/, '面板要写明当前生效的是表单')
  assert.match(view, /来自表单/, 'style 要来自注入的 config')
  assert.ok(!view.includes('旧文件'), '文件里的值不许再出现在面板上')
  assert.match(view, /不再参与运行/, '旧 JSON 还在时必须提示它已经不生效了')
  dispose()
})
