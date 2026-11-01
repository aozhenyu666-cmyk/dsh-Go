/**
 * 从**宿主那棵树**里同步取回 @deepseek-ai/schemastery。
 *
 * 为什么必须同步：cordis 读插件形状时是同步读 module namespace 的 `Config` 导出，
 * 拿不到就当成「这个插件没有 schema」，表单整个不出现。异步 import 来不及。
 *
 * 为什么不能 `import '@deepseek-ai/schemastery'`：本包零依赖、也不该为了一行 import
 * 把整条插件拖成「failed to import」——上游 dsh-fish-memory 踩过这个坑（见它的 hostdeps.mjs）。
 *
 * 本机实测（R4 第三轮）：
 *   $DSH_HOME/profiles/desktop/node_modules/@deepseek-ai/schemastery   ← require 成功，3.18.5
 *   resources/app.asar/dsh/node_modules/@deepseek-ai/schemastery       ← 只在 Electron 里能读
 * 所以按「宿主自己的那份优先」排序，逐个试；全拿不到就返回 null，插件照常加载（只是没有原生表单）。
 */
import { existsSync, readFileSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import os from 'node:os'

const SELF_ROOT = dirname(dirname(fileURLToPath(import.meta.url)))

/** 可能装着宿主 @deepseek-ai 包的目录（按「跟宿主同一份」的可能性排序）。 */
export function schemasteryRoots() {
  const out = []
  const push = (p) => { if (p && !out.includes(p)) out.push(p) }
  push(process.env.DSH_SCHEMASTERY_ROOT)
  // ★ 最可靠的一条：**正在跑的宿主自己那棵树**。
  //   Electron 桌面版把 dsh 装在 resources/app.asar/dsh/node_modules 下，
  //   process.resourcesPath 就在 dsh 被 import 的那个进程里，不用猜任何路径。
  //   （必须放在 profile 之前：profile 里可能只有别人的 hoist，甚至是转发 shim。）
  const res = process.resourcesPath
  if (res) {
    push(join(res, 'app.asar', 'dsh', 'node_modules', '@deepseek-ai'))
    push(join(res, 'app', 'dsh', 'node_modules', '@deepseek-ai'))
    push(join(res, 'dsh', 'node_modules', '@deepseek-ai'))
  }
  const home = process.env.DSH_HOME || join(os.homedir(), '.dsh')
  // profile 树：宿主自己就是这个模块图的根，最可能命中同一份实例
  for (const name of ['desktop', 'web', 'headless', 'tui']) push(join(home, 'profiles', name, 'node_modules', '@deepseek-ai'))
  for (const p of process.env.DSH_PROFILE_NAMES ? String(process.env.DSH_PROFILE_NAMES).split(/[,;\s]+/).filter(Boolean) : []) {
    push(join(home, 'profiles', p, 'node_modules', '@deepseek-ai'))
  }
  // 全局 npm 装法
  const appdata = process.env.APPDATA
  if (appdata) {
    push(join(appdata, 'npm', 'node_modules', '@deepseek-ai', 'dsh', 'node_modules', '@deepseek-ai'))
    push(join(appdata, 'npm', 'node_modules', '@deepseek-ai'))
  }
  push('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai')
  push('/usr/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai')
  push('/usr/local/lib/node_modules/@deepseek-ai')
  push('/usr/lib/node_modules/@deepseek-ai')
  // 插件自己那份（装了才有）
  push(join(SELF_ROOT, 'node_modules', '@deepseek-ai'))
  return out
}

function entryOf(root, name) {
  try {
    const dir = join(root, name)
    const pkg = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'))
    const dot = pkg.exports?.['.']
    const rel = typeof dot === 'string' ? dot : (dot?.require || dot?.default || dot?.import || pkg.main)
    if (!rel) return null
    const file = join(dir, String(rel).replace(/^\.\//, ''))
    return existsSync(file) ? file : null
  } catch {
    return null
  }
}

/**
 * 同步拿一个 schemastery 构造函数。
 * @returns {Function|null} z（拿不到是 null，**不抛**）
 */
export function loadSchemasterySync() {
  const mod = requireFromHostTree('schemastery')
  const z = mod?.default ?? mod
  return z && typeof z.object === 'function' ? z : null
}

/** 同样从宿主树里同步取 defineTool（拿不到返回 null，调用方会退到动态 import / 报 no-defineTool）。 */
export function loadDefineToolSync() {
  const mod = requireFromHostTree('dsh-tools')
  const defineTool = mod?.defineTool ?? mod?.default?.defineTool
  return typeof defineTool === 'function' ? defineTool : null
}

/** 从宿主树里同步 require 一个包；全失败返回 null（**不抛**）。 */
export function requireFromHostTree(name) {
  for (const root of schemasteryRoots()) {
    const file = entryOf(root, name)
    if (!file) continue
    try {
      const req = createRequire(file)
      return req(file)
    } catch {
      // 下一棵
    }
  }
  return null
}
