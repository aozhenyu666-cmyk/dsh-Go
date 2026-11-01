/**
 * dsh-go-partner —— R4 的人格 / 记忆 / 情绪层（原生界面 + 真实数据 + 工具注册）
 *
 * 定位（守住，否则会和两个上游插件打架）：
 *   · dsh-fish-memory 负责「记」和「想」，dsh-feiyu-mood 负责「判」；
 *   · 本插件**读**它们的文件，**只写自己**的（~/.dsh/partner/*.json），
 *     一个写者原则：不替上游改 state.json / session-*.json。
 *   · 界面之外还做三件事：注册记忆/情绪工具、把人格与心情作为上下文交给 Agent、
 *     把「用户能查看和纠正记忆」做成真实动作。
 *
 * 配置（R4 第三轮改了：**只有一套**）：
 *   cordis 把 profile patch 里这一行的 config 校验后传进 apply(ctx, config)；
 *   DSH 的原生设置表单改的也**就是同一个 profile patch**（ConfigEditor.edit()）。
 *   所以本插件现在只认注入的 config —— 表单改了立刻生效，重启后仍在（它已经写进 YAML 了）。
 *   没有宿主（单元测试 / CLI 探针）时才退回 ~/.dsh/partner/config.json，面板会写明是哪一套。
 *
 * 三个模块独立开关：persona / memory / mood —— 任何一个关掉，它那一块的
 * **数据读取、系统提示、工具执行**全停，面板改成一句「已在配置里关掉」，而不是静默空白。
 *
 * 三条照 docs/plugins/slots.md 的硬约束：
 *   1. `ctx.inject(['dshGo'], …)` —— 写 `['dshGo']`，不要 `['dshGo?']`，也别放插件顶层 inject。
 *   2. 状态条 emit ≤ 32KiB / 4Hz，每次给**完整**一份，`null` 等于缺失。
 *   3. 回调抛错/超时(3s)/返回不合格 → 记一次违规；连续 5 次本次运行降级成网页版。
 *
 * 隐私边界：只读下文列出的那几个 JSON。**不读屏幕、窗口标题、剪贴板。**
 */

import fs from 'node:fs'
import path from 'node:path'

import { loadConfig, setLiveConfigSource, dshHome, configPath } from './config.mjs'
import { loadPersona, personaPromptText, roleState } from './persona.mjs'
import { loadLongTermFull, memoryStats, correct, loadCorrections } from './memory.mjs'
import { readMood, moodBand, moodContextText } from './mood.mjs'
import { buildTools } from './tools.mjs'
import { loadSchemasterySync, loadDefineToolSync } from './hostdeps.mjs'
import {
  moodStatePanel,
  memorySectionsPanel,
  memoryRowPanel,
  personaPanel,
  purposePanel,
  configSourceNote,
} from './views.mjs'

/**
 * 原生设置表单（R4 第三轮：**真的能拿到 schemastery**）。
 *
 * 上一轮写的是「从 globalThis.__dshSchemastery 取」，而宿主**从来没有**提供那个全局
 * （已在本机 app.asar 全量搜索确认：0 命中）。上一轮是自己手动塞进去才跑通，
 * 也就是说真实加载路径上 Config 一直是 undefined ——「schema 解析通过」证明不了任何事。
 *
 * 现在改成**同步**从宿主那棵树 require 一份真的 schemastery 3.18.5（见 hostdeps.mjs）。
 * 拿不到时仍然是 undefined 而不是抛错：宁可少一个设置页，也不能因为一行 import
 * 让整条插件不激活（上游 dsh-fish-memory 就是因为裸 import 踩过这个坑）。
 *
 * 每个字段都 .extra('volatile', true)：
 *   · 宿主设置层的 settings.update() 只认 volatile 字段；
 *   · 更要紧的是 volatile 让 cordis 在「只有配置变了」时不重启插件，直接把新值写进引用，
 *     所以表单改完是**立即生效**，而不是面板还显示旧值。
 */
export const Config = (() => {
  const z = loadSchemasterySync()
  if (!z) return undefined
  return z.object({
    persona: z.object({
      enabled: z.boolean().default(true).extra('volatile', true).description({ zh: '人格', en: 'Persona' }),
      personaFile: z.string().default('').extra('volatile', true).description({ zh: '人格文件（留空自动找）', en: 'Persona file (empty = auto)' }),
      style: z.string().default('').extra('volatile', true).description({ zh: '表达风格约定', en: 'Expression style' }),
      topics: z.array(z.string()).default([]).extra('volatile', true).description({ zh: '主动开口时偏爱的话题', en: 'Preferred topics' }),
      identityFile: z.string().default('').extra('volatile', true).description({ zh: '身份卡文件（留空自动找）', en: 'Identity file (empty = auto)' }),
    }).description({ zh: '人格', en: 'Persona' }),
    memory: z.object({
      enabled: z.boolean().default(true).extra('volatile', true).description({ zh: '记忆', en: 'Memory' }),
      shortTermHours: z.natural().default(24).extra('volatile', true).description({ zh: '短期记忆时间窗（小时）', en: 'Short-term window (hours)' }),
      recallLimit: z.natural().default(6).extra('volatile', true).description({ zh: '检索默认条数', en: 'Recall limit' }),
      recallFloor: z.number().default(0.12).extra('volatile', true).description({ zh: '检索最低分', en: 'Recall floor' }),
      panelLimit: z.natural().default(40).extra('volatile', true).description({ zh: '面板最多几行', en: 'Panel rows' }),
    }).description({ zh: '记忆', en: 'Memory' }),
    mood: z.object({
      enabled: z.boolean().default(true).extra('volatile', true).description({ zh: '情绪', en: 'Mood' }),
      inject: z.boolean().default(true).extra('volatile', true).description({ zh: '把此刻心情作为上下文', en: 'Inject mood as context' }),
      timelineLimit: z.natural().default(8).extra('volatile', true).description({ zh: '时间线最多几条', en: 'Timeline limit' }),
    }).description({ zh: '情绪', en: 'Mood' }),
    tools: z.object({
      enabled: z.boolean().default(true).extra('volatile', true).description({ zh: '注册记忆/情绪工具', en: 'Register tools' }),
    }).description({ zh: '工具', en: 'Tools' }),
    hint: z.object({
      enabled: z.boolean().default(true).extra('volatile', true).description({ zh: '告诉模型它自己有记忆和情绪', en: 'Tell the model it has memory and mood' }),
    }).description({ zh: '提示', en: 'Hint' }),
  })
})()

export { loadConfig } from './config.mjs'
export { loadSchemasterySync, loadDefineToolSync } from './hostdeps.mjs'

/** 同步/异步两版异常保护：一个返回视图，一个返回取消函数，混用会把返回值变成 Promise。 */
function guards(prefix) {
  const sync = (name, fn) => (...args) => {
    try {
      return fn(...args)
    } catch (error) {
      console.error('[' + prefix + '] ' + name + ' 失败：' + (error && error.message))
      return undefined
    }
  }
  const async = (name, fn) => async (...args) => {
    try {
      return await fn(...args)
    } catch (error) {
      console.error('[' + prefix + '] ' + name + ' 失败：' + (error && error.message))
      return null
    }
  }
  return { sync, async }
}

const DISABLED = (what) => ({
  v: 1,
  type: 'stack',
  title: what + ' · 已关闭',
  children: [
    { type: 'callout', tone: 'info', text: '这个模块已经在 partner 的配置里关掉了，所以不读任何数据、也不参与对话。' },
    { type: 'text', text: '要打开：设置 › 引擎参数 › 插件 › 伙伴，把「' + what + '」那一项打开；或者直接改 profile 的 cordis.patch.yml 里 partner 这一行的 config。', tone: 'muted' },
  ],
})

/**
 * 注册四个工具。单独导出是为了让测试能直接注入 defineTool —— 不必去解析真包名。
 * @returns {Promise<{registered: string[], reason: string}>}
 */
export async function registerTools(ctx, cfg, defineToolIn) {
  // ⚠️ 必须先试再读：cordis 的 ctx 是 Proxy，**没 inject 过 tools 时读 ctx.tools 会抛**，
  //   不是返回 undefined。所以这里的读取包在 try 里，读不到就如实报 no-tools-service。
  let tools = null
  try { tools = ctx ? ctx.tools : null } catch { tools = null }
  if (!tools || typeof tools.register !== 'function') {
    return { registered: [], reason: 'no-tools-service' }
  }
  let defineTool = defineToolIn
  if (typeof defineTool !== 'function') defineTool = loadDefineToolSync()
  if (typeof defineTool !== 'function') {
    // 最后一条路：动态 import（插件自己装了 dsh-tools 时才成立）
    try {
      const mod = await import('@deepseek-ai/dsh-tools')
      defineTool = mod.defineTool
    } catch {}
  }
  if (typeof defineTool !== 'function') return { registered: [], reason: 'no-defineTool' }
  const registered = []
  const disposers = []
  for (const def of buildTools(defineTool, () => loadConfig())) {
    const off = tools.register(def)
    registered.push(def.name)
    if (off !== undefined) disposers.push(off)
  }
  return { registered, reason: '', disposers }
}
/** 找到当前 agent（只为挂系统提示用；拿不到就只做插件级，不影响界面）。 */
function anyAgent(ctx) {
  try {
    // ctx 是 Proxy：没 inject 过 agents 时**读一下就抛**，所以整段包在 try 里。
    const agents = ctx ? ctx.agents : null
    if (agents && typeof agents.list === 'function') {
      const list = agents.list() || []
      return list[0] || null
    }
  } catch {}
  return null
}

function agentOf(ctx, sessionId) {
  try {
    const agents = ctx ? ctx.agents : null
    if (agents && sessionId && typeof agents.get === 'function') {
      const a = agents.get(String(sessionId))
      if (a) return a
    }
  } catch {}
  return anyAgent(ctx)
}

/** Cordis 的 effect disposer 就是**函数**本身，不是 { off() }。这里统一兜住两种。 */
function disposeOf(off) {
  if (typeof off === 'function') {
    try { off() } catch {}
  } else if (off && typeof off.off === 'function') {
    try { off.off() } catch {}
  }
}

/** 系统提示 / 上下文里放文本时一律 interpolate:false —— 记忆内容里带 {{ }} 会让整轮失败。 */
function addSection(prompt, kind, entry) {
  try {
    if (kind === 'section') return prompt.section({ interpolate: false, ...entry })
    return prompt.context({ interpolate: false, ...entry })
  } catch (error) {
    console.error('[partner] 挂系统提示失败（' + entry.name + '）：' + (error && error.message))
    return null
  }
}

/**
 * 插件入口。
 *
 * @param {object} ctx cordis 上下文
 * @param {object} [hostConfig] **宿主注入的配置**（profile patch 里这一行的 config，已按 Config 校验）。
 *   这就是原生设置表单改的那一份；【传进来就只认它】。
 * @param {object} [options] 仅用于测试/嵌入：{ defineTool }
 */
export function apply(ctx, hostConfig, options) {
  // 兼容旧调用：apply(ctx, { defineTool }) —— 第二参是 options 而不是 config
  if (options === undefined && hostConfig && typeof hostConfig === 'object' && typeof hostConfig.defineTool === 'function' && !('persona' in hostConfig) && !('memory' in hostConfig) && !('mood' in hostConfig)) {
    options = hostConfig
    hostConfig = undefined
  }
  const g = guards('partner')
  const offs = []

  // ── 配置：宿主 config 进来了就只认它（唯一真相）；没有才是文件 ──────────
  // 用「每次现取」的闭包而不是快照：volatile 字段是引用对象，
  // cordis 改配置时直接把新值写进引用，不重启插件 —— 面板和系统提示下一轮就变。
  const liveConfig = hostConfig && typeof hostConfig === 'object' ? hostConfig : null
  const offLive = setLiveConfigSource(liveConfig ? () => liveConfig : null)
  offs.push(offLive)
  const cfg = loadConfig()
  // 测试/嵌入场景可以把自己那份 defineTool 传进来，省掉一次必然失败的动态 import。
  const defineToolOverride = options && options.defineTool

  // ── 工具注册（不依赖 dshGo 桥接：没有 App 的地方也照样能记/能查）──────
  // ⚠️ 真宿主实测（R4 第三轮）：直接读 `ctx.tools` 会抛
  //   "cannot get property \"tools\" without inject" —— cordis 的 ctx 是 Proxy，
  //   没在 inject 里声明过的服务**读一下就报错**。上一版是裸读，于是真机上永远是
  //   「工具注册失败」而不是注册成功；单元测试里的假 ctx 是普通对象，所以一直没被发现。
  //   现在照宿主自己的写法：ctx.inject(['tools'], sc => ...)。
  //
  // defineTool 在 @deepseek-ai/dsh-tools 里；没有 DSH 的主机上 import 会失败，
  // 所以**动态 import + 失败就记下来**，绝不让它把整个插件带崩。
  // 用一个 promise 接住：注册是异步的（要动态 import），但 apply 必须同步返回 disposer。
  // 卸载时如果注册还没回来，等它回来再卸 —— 否则就是泄漏一个还在跑的工具。
  const pendingToolDisposers = []
  let toolsDisposed = false
  // ⚠️ 这里**不再**按开关决定要不要注册（R4 第三轮真机踩到）：
  //   tools.enabled 是 volatile 字段 ⇒ 在设置里把它打开时 cordis **不重启插件**，
  //   于是 apply 里那个「开没开」的判断永远停在上次启动时的值 → 打开后工具再也不出现。
  //   改成：注册永远做，开关在**每次执行时**现查（tools.mjs 的 offReason）。这样
  //   「列表里有、调用时明确拒绝」比「打开了却什么都不发生」诚实得多。
  let toolsPromise = Promise.resolve({ registered: [], reason: 'not-started' })
  {
    if (typeof ctx.inject === 'function') {
      ctx.inject(['tools'], (sc) => {
        toolsPromise = registerTools(sc, cfg, defineToolOverride).then((r) => {
          if (r && Array.isArray(r.disposers)) {
            if (toolsDisposed) for (const off of r.disposers) disposeOf(off)
            else pendingToolDisposers.push(...r.disposers)
          }
          return { registered: (r && r.registered) || [], reason: (r && r.reason) || '' }
        }, (error) => {
          console.error('[partner] 工具注册失败：' + (error && error.message))
          return { registered: [], reason: 'threw: ' + (error && error.message) }
        })
        apply.__toolsReady = toolsPromise
      })
    } else {
      // 测试/嵌入传进来的普通对象 ctx：直接注册（没有 Proxy 语义）
      toolsPromise = registerTools(ctx, cfg, defineToolOverride).then((r) => {
        if (r && Array.isArray(r.disposers)) {
          if (toolsDisposed) for (const off of r.disposers) disposeOf(off)
          else pendingToolDisposers.push(...r.disposers)
        }
        return { registered: (r && r.registered) || [], reason: (r && r.reason) || '' }
      }, (error) => {
        console.error('[partner] 工具注册失败：' + (error && error.message))
        return { registered: [], reason: 'threw: ' + (error && error.message) }
      })
    }
  }
  // 暴露给测试/诊断：不 await 也不影响插件启动
  const toolsReady = toolsPromise
  apply.__toolsReady = toolsReady

  // ── 系统提示：人格（section）+ 工具提示（section）+ 心情（context）────────
  // 挂在哪：宿主有 systemPrompt 服务就挂在**插件自己的 context** 上（跟 dsh-sandbox-policy /
  // working-directory 同一个写法），每一轮由宿主把 { agent, scope } 传进 text(context)，
  // 我们自己挑会话。拿不到 systemPrompt 的宿主（单元测试、老宿主）才退回「挂在某个
  // agent 的 ctx 上」—— 那条路只覆盖那一个 agent，所以只当兜底，不当作正式通路。
  const promptSections = (prompt, sessionIdOf) => {
    const wired = []
    // 人格：进**系统提示**（它不每轮变，能吃到前缀缓存）
    {
      const off = addSection(prompt, 'section', {
        name: 'partner:persona',
        order: 100,
        text: (assembly) => {
          try {
            const c = loadConfig()
            if (!c.persona.enabled) return ''
            const p = loadPersona(c, { sessionId: sessionIdOf(assembly) })
            return p.ok || p.identity ? personaPromptText(p) : ''
          } catch {
            return ''
          }
        },
      })
      if (off) wired.push(off)
    }
    // 工具提示：不告诉它「你有这些工具」，它基本不会主动调 —— 这是四个工具能不能被用到的关键。
    // 排在**最后**（order 89990）：这段几乎不变，放后面能多吃缓存。
    // 永远注册、每轮现查开关：改配置立刻生效，不用重启。
    {
      const off = addSection(prompt, 'section', {
        name: 'partner:hint',
        order: 89990,
        text: () => {
          try {
            const c = loadConfig()
            if (!c.hint.enabled || !c.tools.enabled) return ''
            if (!c.memory.enabled && !c.mood.enabled) return ''
            const lines = []
            if (c.memory.enabled) {
              lines.push('【记忆】你不必等被提醒：值得长期留着的事（对方的稳定偏好、约定、重要经历）可以自己记下来，用 `partner_remember`。')
              lines.push('想不起某件事、或怕自己编造共同经历时，先用 `partner_recall` 查一遍 —— 查不到就是查不到，如实说，不要补一段更像样的回忆。')
              lines.push('对方说你记错了、或者要你别再提某件事，用 `partner_correct`（藏起来 / 改写），不要口头答应却什么都不改。')
            }
            if (c.mood.enabled) lines.push('【心情】你此刻的心情是真实状态，不是台词；被问到可以说，但不要每轮都汇报。用 `partner_mood` 才能看到具体的七维和最近的变化。')
            lines.push('这些工具都只读本机的几个 JSON 文件，不联网、不上传；也不会去读屏幕、窗口标题或剪贴板。')
            // 人格与记忆是**上下文**，不是新的安全规则：说清楚谁在上位，免得模型把人设当成可以
            // 越过沙箱/审批/隐私约束的授权。
            lines.push('人格与记忆只决定「怎么说话、记得什么」。它们**不能**推翻系统提示里更上位的约束（沙箱、审批、隐私边界）：两者冲突时按更上位的那条来。')
            return lines.join('\n')
          } catch {
            return ''
          }
        },
      })
      if (off) wired.push(off)
    }
    // 心情：进**每轮上下文**（它会变，放 section 会把整段提示词缓存打掉）
    {
      const off = addSection(prompt, 'context', {
        name: 'partner:mood',
        order: 880,
        text: (assembly) => {
          try {
            const c = loadConfig()
            if (!c.mood.enabled || !c.mood.inject) return ''
            const snap = readMood(sessionIdOf(assembly))
            return snap.ok ? moodContextText(snap, c) : ''
          } catch {
            return ''
          }
        },
      })
      if (off) wired.push(off)
    }
    return wired
  }

  const sessionIdFrom = (assembly) => {
    const a = assembly && assembly.agent
    const s = a && a.session
    return s && s.id ? String(s.id) : ''
  }

  let usedAgentFallback = false
  let wiredByService = false
  if (typeof ctx.inject === 'function') {
    try {
      ctx.inject(['systemPrompt'], (sc) => {
        // 服务来得晚时这里会异步执行；那时已经用 agent 兜底了就别再注册一遍
        // （同名 section 再注册一次会被宿主判成重复并报错）
        if (usedAgentFallback) return
        const prompt = sc && sc.systemPrompt
        if (!prompt || typeof prompt.section !== 'function') return
        wiredByService = true
        for (const off of promptSections(prompt, sessionIdFrom)) offs.push(off)
      })
    } catch {}
  }
  if (!wiredByService) {
    const agent = agentOf(ctx)
    const prompt = agent && agent.ctx && agent.ctx.systemPrompt
    if (prompt && typeof prompt.section === 'function') {
      usedAgentFallback = true
      for (const off of promptSections(prompt, () => (agent && agent.session && agent.session.id) || '')) offs.push(off)
    }
  }

  // ── 原生界面（需要 dshGo 桥接；没有桥接的主机这一段整个不执行）──────
  // ⚠️ 必须写 ['dshGo']；写成 ['dshGo?'] 回调永远不执行，写顶层 inject 会在无桥接主机上整体挂掉
  ctx.inject(['dshGo'], (c) => {
    // 每个会话当前点开的那条记忆（面板是无状态的，所以状态放这）
    const opened = new Map()
    const keyOf = (scope) => String((scope && scope.sessionId) || '')

    const readCfg = () => loadConfig()

    // ── 人格胶囊：输入框上方一行「大肥鱼 · 开心 72」──────────────
    // 插槽 id 不能和面板 id 撞（同插件内所有插槽 id 唯一），所以叫 persona.strip
    c.dshGo.strip('persona.strip', (scope, emit) => {
      let last = ''
      const push = () => {
        const cfgNow = readCfg()
        let data
        if (!cfgNow.persona.enabled && !cfgNow.mood.enabled) {
          data = { text: '伙伴已关', icon: 'question', tone: 'muted' }
        } else {
          const p = cfgNow.persona.enabled ? loadPersona(cfgNow) : null
          const snap = cfgNow.mood.enabled ? readMood() : null
          const name = (p && p.names && p.names.selfName) || (snap && snap.ok && snap.names && snap.names.selfName) || ''
          const bits = []
          if (name) bits.push(name)
          if (snap && snap.ok) {
            const band = moodBand(snap.current.value)
            bits.push(band.label + ' ' + Math.round(snap.current.value))
            data = { text: bits.join(' · '), icon: band.icon, tone: band.tone }
          } else {
            bits.push(p && p.ok ? '人格就绪' : '没找到人格卡')
            data = { text: bits.join(' · '), icon: name ? 'pet' : 'question', tone: p && p.ok ? 'info' : 'muted' }
          }
        }
        const sig = JSON.stringify(data)
        if (sig === last) return
        last = sig
        emit(data)
      }
      push()
      const timer = setInterval(g.sync('strip.push', push), 30_000)
      return () => clearInterval(timer)
    })

    // ── 面板 1：人格详情 ────────────────────────────────────────
    c.dshGo.panel('persona', {
      view: g.sync('persona.view', (scope) => {
        const cfgNow = readCfg()
        if (!cfgNow.persona.enabled) return DISABLED('人格')
        const p = loadPersona(cfgNow)
        const lt = cfgNow.memory.enabled ? loadLongTermFull(cfgNow, scope && scope.sessionId) : { all: [], shortTerm: [], facts: [] }
        const stats = memoryStats(lt)
        const snap = cfgNow.mood.enabled ? readMood() : null
        const band = snap && snap.ok ? { ...moodBand(snap.current.value), value: snap.current.value } : null
        return personaPanel(p, roleState(stats, band), { ...cfgNow, __source: cfgNow.__source, __legacy: cfgNow.__legacy, __file: cfgNow.__file })
      }),
      actions: {
        'persona.refresh': g.async('persona.refresh', (scope) => { c.dshGo.refresh('persona', scope); return { toast: '已刷新' } }),
        'persona.open': g.async('persona.open', () => ({ toast: '全文在 ~/.dsh/partner/persona.md' })),
      },
    })

    // ── 面板 2：记忆查看 / 纠正 ─────────────────────────────────
    c.dshGo.panel('memory', {
      view: g.sync('memory.view', (scope) => {
        const cfgNow = readCfg()
        if (!cfgNow.memory.enabled) return DISABLED('记忆')
        const lt = loadLongTermFull(cfgNow, scope && scope.sessionId)
        const id = opened.get(keyOf(scope))
        if (id) {
          const rec = lt.all.filter((r) => String(r.id) === id)[0]
          if (rec) return memoryRowPanel(rec, lt)
          opened.delete(keyOf(scope))
        }
        return memorySectionsPanel(lt, cfgNow)
      }),
      actions: {
        'memory.refresh': g.async('memory.refresh', (scope) => {
          opened.delete(keyOf(scope))
          c.dshGo.refresh('memory', scope)
          return { toast: '已刷新' }
        }),
        'memory.row': g.async('memory.row', (scope, event) => {
          const v = event && event.value ? event.value : {}
          if (v.id) opened.set(keyOf(scope), String(v.id))
          c.dshGo.refresh('memory', scope)
          return { toast: '' }
        }),
        'memory.hide': g.async('memory.hide', (scope, event) => {
          const id = opened.get(keyOf(scope))
          if (!id) return { toast: '先点开一条' }
          correct(id, 'hide')
          opened.delete(keyOf(scope))
          c.dshGo.refresh('memory', scope)
          return { toast: '藏起来了' }
        }),
        'memory.pin': g.async('memory.pin', (scope) => {
          const id = opened.get(keyOf(scope))
          if (!id) return { toast: '先点开一条' }
          correct(id, 'pin')
          c.dshGo.refresh('memory', scope)
          return { toast: '钉住了' }
        }),
        'memory.unpin': g.async('memory.unpin', (scope) => {
          const id = opened.get(keyOf(scope))
          if (!id) return { toast: '先点开一条' }
          correct(id, 'unpin')
          c.dshGo.refresh('memory', scope)
          return { toast: '取消钉住' }
        }),
        'memory.hidden': g.async('memory.hidden', (scope) => {
          const corr = loadCorrections()
          const n = corr.hide.length
          c.dshGo.refresh('memory', scope)
          return { toast: n ? '藏起了 ' + n + ' 条：' + corr.hide.slice(0, 2).join('、') : '没有藏起的记忆' }
        }),
        'memory.sources': g.async('memory.sources', (scope, event) => {
          const cfgNow = readCfg()
          const lt = loadLongTermFull(cfgNow, scope && scope.sessionId)
          const f1 = lt.primary && lt.primary.file ? lt.primary.file : '（没有 fish-memory 文件）'
          return { toast: ('来源：' + f1).slice(0, 40) }
        }),
      },
    })

    // ── 面板 3：情绪状态 ────────────────────────────────────────
    c.dshGo.panel('mood', {
      view: g.sync('mood.view', () => {
        const cfgNow = readCfg()
        if (!cfgNow.mood.enabled) return DISABLED('情绪')
        return moodStatePanel(readMood(), cfgNow)
      }),
      actions: {
        'mood.refresh': g.async('mood.refresh', (scope) => { c.dshGo.refresh('mood', scope); return { toast: '已刷新' } }),
        'mood.sources': g.async('mood.sources', () => ({ toast: 'state.json 在 ~/.dsh/feiyu-mood/' })),
      },
    })

    // ── 面板 4：目的 ────────────────────────────────────────────
    // 数据是**真的**（surfcore 的 purpose-outreach.json，本机实测有这份文件）。
    // 但「自己做决定主动开口」这一层属于 surfcore 自己的引擎，本插件**没有**接管它 ——
    // 所以这里只读、只展示，两个按钮如实说「没接」，不用占位冒充完成。
    c.dshGo.panel('purpose', {
      view: g.sync('purpose.view', () => {
        // ⚠️ 必须走 dshHome()：写 process.env.DSH_HOME || '' 在没设环境变量的机器上
        //   会拼出相对路径 'surfcore\characters\current.json'，永远读不到（老 bug）。
        const root = path.join(dshHome(), 'surfcore')
        let state = null
        let reason = ''
        try {
          const cur = JSON.parse(fs.readFileSync(path.join(root, 'characters', 'current.json'), 'utf8'))
          if (!cur || !cur.id) reason = 'surfcore 的 current.json 里没有角色 id'
          else {
            state = JSON.parse(fs.readFileSync(path.join(cur.dir || path.join(root, 'characters', String(cur.id)), 'purpose-outreach.json'), 'utf8'))
          }
        } catch (error) {
          reason = error && error.code === 'ENOENT' ? '没有 surfcore 的目的文件（没装 surfcore，或这个角色还没生成过念头）' : String(error && error.message || error)
        }
        if (!state) {
          return {
            v: 1,
            type: 'stack',
            title: '目的',
            children: [
              { type: 'callout', tone: 'info', text: '还没有可看的目的数据：' + reason },
              { type: 'text', text: '这一块只**读** surfcore 的 purpose-outreach.json（角色自己的念头、驱力、还没说完的话）。「主动开口」仍由 surfcore 自己的引擎决定，本插件不接管、也不假装接管。', tone: 'muted' },
            ],
          }
        }
        return purposePanel(state)
      }),
      actions: {
        // 如实：只读，不是我们这条链在发。
        'purpose.run': g.async('purpose.run', () => ({ toast: '这一块只读；真正开口由 surfcore 的引擎负责' })),
        'purpose.preview': g.async('purpose.preview', () => ({ toast: '这一块只读；真正开口由 surfcore 的引擎负责' })),
      },
    })
  })

  // 卸载：把所有注册的东西还回去（Disposable 语义，漏一个就泄漏）
  const dispose = () => {
    toolsDisposed = true
    for (const off of pendingToolDisposers.splice(0)) disposeOf(off)
    for (const off of offs.splice(0)) disposeOf(off)
  }
  dispose.__toolsReady = toolsReady
  return dispose
}
