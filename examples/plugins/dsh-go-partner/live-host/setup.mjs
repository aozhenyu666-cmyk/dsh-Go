#!/usr/bin/env node
/**
 * 搭一个**临时** DSH profile，把 dsh-go-partner 当成「用户安装的 bundle」挂进去 ——
 * 就是真实安装的那种形状（owner=installed、kind=plugin），不是假的 overlay 行。
 *
 * 为什么必须是 bundle：DSH 的插件配置白名单只放行「已安装的 bundle 里的行」，
 * 用 --patch 直接 insert 的行会被判成 overlay → 设置页不出现。R4 第三轮踩过这个坑，
 * 所以这里照真的装一遍。
 *
 * 用法：node test/live-host/setup.mjs --out <临时根目录> --home <DSH_HOME>
 * 只写临时目录，不动 ~/.dsh。
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
// live-host/ 就在插件根目录下（不在 test/ 里：node --test 会递归跑 test/ 下所有文件，
// 而这个脚本要起真宿主、会跑好几十秒，放进去会把单测拖死）
const pluginDir = path.resolve(here, '..')
const repoRoot = path.resolve(pluginDir, '..', '..', '..')
const bridgeDir = path.join(repoRoot, 'runtime', 'bridge', 'dsh-go-bridge')

function arg(name, fallback) {
  const i = process.argv.indexOf('--' + name)
  return i >= 0 ? process.argv[i + 1] : fallback
}

const out = path.resolve(arg('out', path.join(process.cwd(), 'm3-live')))
const home = path.resolve(arg('home', path.join(out, 'home')))
const schemastery = arg('schemastery', process.env.DSH_SCHEMASTERY_ROOT || '')

fs.mkdirSync(home, { recursive: true })
const profile = path.join(home, 'profiles', 'web')
fs.mkdirSync(path.join(profile, 'node_modules'), { recursive: true })

// ── 1. 一个把 partner + bridge + observer 挂起来的本地 bundle ────────────────
const bundle = path.join(out, 'pkg-partner-bundle')
fs.mkdirSync(path.join(bundle, 'node_modules'), { recursive: true })
fs.writeFileSync(path.join(bundle, 'package.json'), JSON.stringify({
  name: 'm3-partner-bundle', version: '1.0.0', type: 'module',
  exports: { '.': './index.mjs', './package.json': './package.json', './cordis.patch.yml': './cordis.patch.yml' },
  dsh: { bundle: { patch: './cordis.patch.yml' } },
}, null, 2))
fs.writeFileSync(path.join(bundle, 'index.mjs'), 'export function apply() {}\n')
fs.writeFileSync(path.join(bundle, 'cordis.patch.yml'), JSON.stringify([{
  insert: [
    { id: 'partner', name: 'dsh-go-partner', config: {
      persona: { style: '（LIVE-HOST 初始值）' },
      memory: { enabled: true }, mood: { enabled: true }, tools: { enabled: true },
    } },
    { id: 'dsh-go-bridge', name: 'dsh-go-bridge' },
    { id: 'm3-observer', name: path.join(out, 'pkg-observer', 'index.mjs') },
  ],
}], null, 2))
for (const [name, target] of [['dsh-go-partner', pluginDir], ['dsh-go-bridge', bridgeDir]]) {
  const link = path.join(bundle, 'node_modules', name)
  try { fs.unlinkSync(link) } catch {}
  fs.symlinkSync(target, link, 'junction')
}

// ── 2. observer：把插件的真实状态 / 系统提示 / 表单通道暴露成三条只读路由 ─────
const observer = path.join(out, 'pkg-observer')
fs.mkdirSync(observer, { recursive: true })
fs.writeFileSync(path.join(observer, 'package.json'), JSON.stringify({
  name: 'm3-observer', version: '1.0.0', type: 'module',
  exports: { '.': './index.mjs', './package.json': './package.json' },
}, null, 2))
fs.copyFileSync(path.join(here, 'observer.mjs'), path.join(observer, 'index.mjs'))

// ── 3. profile：带上这个 bundle + 关掉会拖慢启动的核心行 ─────────────────────
fs.writeFileSync(path.join(profile, 'package.json'), JSON.stringify({
  name: 'm3-live-profile', version: '1.0.0', private: true,
  dependencies: { 'm3-partner-bundle': 'file:' + bundle },
  dsh: { profile: { bundles: ['@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app', 'm3-partner-bundle'] } },
}, null, 2))
const profileModules = path.join(profile, 'node_modules')
for (const [name, target] of [['m3-partner-bundle', bundle], ['dsh-go-partner', pluginDir], ['dsh-go-bridge', bridgeDir]]) {
  // 三种都要挂：Loader 从 profile 目录解析 specifier，bundle 自己的 node_modules 不算数。
  try { fs.unlinkSync(path.join(profileModules, name)) } catch {}
  fs.symlinkSync(target, path.join(profileModules, name), 'junction')
}

fs.writeFileSync(path.join(profile, 'cordis.patch.yml'), JSON.stringify([
  { id: 'session-title-llm', disabled: true },
  { id: 'llm-pi-ai', disabled: true },
  { id: 'llm-deepseek-account', disabled: true },
  { id: 'session-telemetry-otel', disabled: true },
  { id: 'web-search-deepseek', disabled: true },
  { id: 'web-deepseek-api', disabled: true },
  { id: 'web-fetch-http', disabled: true },
  { id: 'tool-web', disabled: true },
], null, 2))

// ── 4. schemastery：Electron 能读 asar，普通 node 不能。
//       插件运行时自己会从 resources/app.asar 里取（见 lib/hostdeps.mjs），
//       这里不用额外拷贝；但如果调用方给了目录，就放一份进 profile 备着。
if (schemastery) {
  const dest = path.join(profileModules, '@deepseek-ai')
  fs.mkdirSync(dest, { recursive: true })
  fs.cpSync(path.join(schemastery, 'schemastery'), path.join(dest, 'schemastery'), { recursive: true })
}

// ── 5. 一点真实上游数据，面板/提示才有东西可读 ───────────────────────────────
const now = Date.now()
fs.mkdirSync(path.join(home, 'feiyu-mood'), { recursive: true })
fs.writeFileSync(path.join(home, 'feiyu-mood', 'config.json'), JSON.stringify({
  slots: [{ id: '__default__', label: '大肥鱼', selfName: '大肥鱼', ownerName: '鱼片', sessions: ['s1'] }],
  selfName: '大肥鱼', ownerName: '鱼片', moodBase: 70, decayHalfHours: 12, injectMode: 'event', injectConfidence: 55,
}))
fs.writeFileSync(path.join(home, 'feiyu-mood', 'state.json'), JSON.stringify({
  version: 1,
  moods: { __default__: { mood: 71.5, dims: { happy: 0.6, calm: 12, sweet: 6, heartache: 7, worry: 5, sad: 4, jealous: 0.5 },
    lastReason: 'LIVE-HOST：被夸了一句', lastConfidence: 88, lastInjectedText: '', lastInjectedAt: now - 3600000,
    saidAt: [now - 3600000], updatedAt: now - 7200000, lastDecayAt: now - 7200000,
    timeline: [{ at: now - 3600000, mood: 70, delta: 1, reason: 'LIVE-HOST', conf: 80, dims: {}, dimsDelta: {} }] } },
  lastActive: now - 3600000,
}))
fs.mkdirSync(path.join(home, 'fish-memory'), { recursive: true })
fs.writeFileSync(path.join(home, 'fish-memory', 'session-s1.json'), JSON.stringify({
  version: 1, policy: { baseHalfLifeDays: 30 },
  memories: [{ id: 'm1', text: 'LIVE-HOST 记忆：今天想试试新的散热硅脂', at: new Date(now - 3600000).toISOString(),
    createdAt: new Date(now - 3600000).toISOString(), category: 'event', importance: 0.3, emotion: null, tags: [], source: 'LIVE-HOST' }],
  traces: [], deleted: [], purgeEpoch: 'e1',
}))

console.log(JSON.stringify({ out, home, profile, bundle, observer }, null, 2))
