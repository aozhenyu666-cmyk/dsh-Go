/**
 * dsh-go 原生视图构造器 + 预算校验器 —— R4 人格/记忆/情绪面板
 *
 * 为什么要这一层：
 *   dsh-go 的插件视图是**一棵 JSON 组件树**，有硬预算（面板 32KiB/120 节点/8 层；
 *   状态条 2KiB/8 节点/3 层；工具卡 8KiB/40 节点/6 层）。JSON 写错、组件名写错、
 *   超预算的后果不是报错，是**整块降级成「插件界面有误」或灰色占位** —— 很难查。
 *   所以：**先构造 + 本地校验，再交给 App 渲染**。
 *
 * 用法：
 *   import { moodPanel, memoryPanel, purposePanel, moodStrip, rememberCard } from './views.mjs'
 *   moodPanel(state, cfg)            → 面板视图（placement: chat.panel / session.tab）
 *   moodStrip(state)                 → 状态条视图（emit 的数据）
 *   rememberCard(args, value)        → 工具卡视图（presentationMeta）
 *   validate(view, 'panel')          → { ok, issues[] }   —— 与 App 插件详情页同一套判据
 *   node views.mjs --selftest        → 用假数据跑一遍全部视图 + 预算
 *
 * ⚠️ 三条铁律（踩过就知道多重要）：
 *   1. 工具卡只用最稳的 8 个组件（stack/row/text/metric/chart/compare/steps/callout）——
 *      它写进对话记录，一年后打开老对话也要能画。
 *   2. 面板可以用 list/keyValue/table/actions/options/confirm，但**根节点别放 v2 独有组件**
 *      （emptyState/gallery），老 App 会整块画成占位。
 *   3. 任何值都可以写绑定 { "$": "data.x.y" }，但 `type` 不能绑定。
 */

// ── 预算（照抄 docs/plugins/components.md §上限）─────────────────────────────
export const BUDGET = {
  toolCard: { bytes: 8 * 1024, nodes: 40, depth: 6 },
  panel: { bytes: 32 * 1024, nodes: 120, depth: 8 },
  strip: { bytes: 2 * 1024, nodes: 8, depth: 3 },
}

// ── v1 的 16 个组件（前 10 个 = 模型 dsh-ui 卡也认；后 6 个 = 插件视图独有）────
const V1_TYPES = new Set([
  'stack', 'row', 'text', 'callout', 'steps', 'compare', 'metric', 'chart', 'progress',
  'list', 'keyValue', 'table', 'actions', 'image', 'options', 'confirm',
])
// v2 才有的（面板可用，但**别放根节点**）—— 老 App 画灰色占位
const V2_TYPES = new Set(['emptyState', 'gallery', 'grid', 'card', 'spacer', 'divider'])

// 工具卡白名单：只用最稳的 8 个
const TOOLCARD_TYPES = new Set(['stack', 'row', 'text', 'metric', 'chart', 'compare', 'steps', 'callout'])

const ICONS = new Set(`bolt star sparkle heart flag bookmark pin bell clock alarm calendar todo note document folder search code terminal globe chart lightbulb book puzzle robot chat mail translate image camera mic link summary wrench bug travel school home play refresh archive team wallet palette coin money speaker read copy quote share edit write save paste add remove delete clear fork regenerate reply select-text qr download downloads external info warning check done success error question pending running tip list table panel sidebar menu more expand collapse file folder-open workspace storage pdf zip slides article text diff gallery audio music video video-file play-video pause stop replay generate-image generate-video diagram plugin bot agent skill model tool workflow goal plan job automation command trajectory web web-search browser history time today timezone schedule repeat reminder user account group chats mention invite announcement reaction poll notification send community forum feedback wechat qq telegram discord phone computer cloud server power restart retry theme color text-size pet featured badge favorite settings`.split(/\s+/))

// ── 校验器 ───────────────────────────────────────────────────────────────────
function countNodes(node, depth = 1, acc = { n: 0, maxDepth: 0, bad: [] }) {
  if (!node || typeof node !== 'object' || Array.isArray(node)) { acc.bad.push('节点不是对象'); return acc }
  acc.n += 1
  acc.maxDepth = Math.max(acc.maxDepth, depth)
  const children = []
  if (Array.isArray(node.children)) children.push(...node.children.map((c, i) => ({ c, where: `children[${i}]` })))
  if (Array.isArray(node.items)) children.push(...node.items.map((c, i) => ({ c, where: `items[${i}]` })))
  for (const { c, where } of children) {
    if (!c || typeof c !== 'object' || Array.isArray(c)) { acc.bad.push(`${where} 不是对象`); continue }
    // items 里既可能是子组件也可能是数据行（list/table/compare/steps/gallery）
    if (typeof c.type !== 'string') continue
    countNodes(c, depth + 1, acc)
  }
  return acc
}

function checkNode(node, path, issues, budget) {
  if (!node || typeof node !== 'object' || Array.isArray(node)) { issues.push({ path, problem: '不是对象' }); return }
  if (node.type !== undefined) {
    if (typeof node.type === 'string') {
      const known = V1_TYPES.has(node.type) || V2_TYPES.has(node.type)
      if (!known) issues.push({ path, problem: `不认识的组件 type="${node.type}"（会画成灰色占位）` })
      if (budget === 'toolCard' && !TOOLCARD_TYPES.has(node.type)) {
        issues.push({ path, problem: `工具卡不能用 "${node.type}"（只能用 stack/row/text/metric/chart/compare/steps/callout）` })
      }
    } else {
      issues.push({ path, problem: 'type 不能写绑定' })
    }
  } else if (path === 'root') {
    issues.push({ path, problem: '根节点缺 type' })
  }
  if (typeof node.icon === 'string' && !ICONS.has(node.icon)) issues.push({ path, problem: `不认识的图标 "${node.icon}"（会画默认图标）` })
  if (node.tone !== undefined && !['good', 'warn', 'bad', 'info', 'muted', 'success', 'warning', 'danger', 'error', 'note', 'secondary'].includes(node.tone)) {
    issues.push({ path, problem: `不认识的 tone "${node.tone}"` })
  }
  // 关键必填属性
  if (node.type === 'text' && typeof node.text !== 'string' && !node.text?.$) issues.push({ path, problem: 'text 组件缺 text' })
  if (node.type === 'metric' && node.value === undefined) issues.push({ path, problem: 'metric 缺 value' })
  if (node.type === 'progress' && node.value === undefined) issues.push({ path, problem: 'progress 缺 value' })
  if (node.type === 'chart') {
    const total = (node.series || []).reduce((s, x) => s + (Array.isArray(x.values) ? x.values.length : 0), 0)
    if (total > 60) issues.push({ path, problem: `chart 数据点 ${total} > 60` })
    if ((node.series || []).length > 6) issues.push({ path, problem: `chart 组数 ${node.series.length} > 6` })
  }
  if (node.type === 'list' && Array.isArray(node.items) && node.items.length > 50) issues.push({ path, problem: `list ${node.items.length} 行 > 50` })
  if (node.type === 'keyValue' && Array.isArray(node.items) && node.items.length > 24) issues.push({ path, problem: `keyValue ${node.items.length} 项 > 24` })
  if (node.type === 'table') {
    if (Array.isArray(node.columns) && node.columns.length > 8) issues.push({ path, problem: `table ${node.columns.length} 列 > 8` })
    if (Array.isArray(node.rows) && node.rows.length > 50) issues.push({ path, problem: `table ${node.rows.length} 行 > 50` })
  }
  if (node.type === 'actions') {
    const n = (node.items || []).length
    if (n > 4) issues.push({ path, problem: `actions ${n} 个 > 4` })
    if ((node.items || []).filter((x) => x.style === 'primary').length > 1) issues.push({ path, problem: 'actions 最多一个 primary' })
  }
  if (node.type === 'options' && Array.isArray(node.options) && node.options.length > 8) issues.push({ path, problem: `options ${node.options.length} 个 > 8` })
  if (node.type === 'steps' && Array.isArray(node.items) && node.items.length > 12) issues.push({ path, problem: `steps ${node.items.length} 项 > 12` })
  if (node.type === 'compare') {
    const n = (node.items || []).length
    if (n < 2 || n > 4) issues.push({ path, problem: `compare 需要 2–4 项，当前 ${n}` })
  }
  if (node.type === 'image' && typeof node.src === 'string'
    && !node.src.startsWith('asset:') && !node.src.startsWith('data:image/')) {
    issues.push({ path, problem: 'image.src 只收 asset: 或 data:image/…' })
  }
  // 递归
  const kids = []
  if (Array.isArray(node.children)) node.children.forEach((c, i) => kids.push({ c, p: `${path}.children[${i}]` }))
  if (Array.isArray(node.items)) node.items.forEach((c, i) => { if (c && typeof c === 'object' && typeof c.type === 'string') kids.push({ c, p: `${path}.items[${i}]` }) })
  for (const k of kids) checkNode(k.c, k.p, issues, budget)
}

export function validate(view, budget = 'panel') {
  const b = BUDGET[budget] || BUDGET.panel
  const issues = []
  checkNode(view, 'root', issues, budget)
  const json = JSON.stringify(view)
  const bytes = Buffer.byteLength(json, 'utf8')
  const { n, maxDepth } = countNodes(view)
  if (bytes > b.bytes) issues.push({ path: 'root', problem: `视图 ${bytes}B 超过 ${b.bytes}B 上限（整块降级）` })
  if (n > b.nodes) issues.push({ path: 'root', problem: `节点 ${n} > ${b.nodes}` })
  if (maxDepth > b.depth) issues.push({ path: 'root', problem: `层数 ${maxDepth} > ${b.depth}` })
  return { ok: issues.length === 0, bytes, nodes: n, depth: maxDepth, budget: b, issues }
}

// ── 语义小工具 ──────────────────────────────────────────────────────────────
/** 心情 0–100 → 五档（阈值照抄 dsh-feiyu-mood README）*/
export function moodBand(v) {
  const n = Number(v)
  if (!Number.isFinite(n)) return { label: '不知道', icon: 'question', tone: 'muted' }
  if (n >= 80) return { label: '欢喜', icon: 'sparkle', tone: 'good' }
  if (n >= 62) return { label: '开心', icon: 'heart', tone: 'good' }
  if (n >= 42) return { label: '一般', icon: 'chat', tone: 'info' }
  if (n >= 25) return { label: '心疼', icon: 'warning', tone: 'warn' }
  return { label: '难过', icon: 'warning', tone: 'bad' }
}

const DIM_LABEL = { happy: '开心', steady: '踏实', sweet: '甜蜜', tender: '心疼', worry: '担心', sad: '难过', jealous: '吃醋' }

function relTime(ts, now = Date.now()) {
  const t = Number(ts)
  if (!t) return '时间未知'
  const d = now - t
  if (d < 0) return '待会儿'
  if (d < 60000) return '刚刚'
  if (d < 3600000) return `${Math.max(1, Math.round(d / 60000))} 分钟前`
  if (d < 86400000) return `${Math.max(1, Math.round(d / 3600000))} 小时前`
  return `${Math.max(1, Math.round(d / 86400000))} 天前`
}

const CLARITY_LABEL = { vivid: '清晰', clear: '清楚', fuzzy: '模糊', trace: '只剩印象' }
const CLARITY_TONE = { vivid: 'good', clear: 'info', fuzzy: 'muted', trace: 'warn' }

// ── 面板 1：心情 ────────────────────────────────────────────────────────────
/**
 * @param {object} s  state.json 里的一份 mood：{ mood, dims, timeline:[{at, delta, reason}] }
 * @param {object} c  所属 slot：{ label, selfName, ownerName, moodBase }
 */
export function moodPanel(s = {}, c = {}) {
  const mood = Number(s.mood ?? s.value ?? c.moodBase ?? 70)
  const band = moodBand(mood)
  const dims = s.dims || s.emotions || {}
  const tl = Array.isArray(s.timeline) ? s.timeline.slice(-6).reverse() : []
  const dimRows = Object.entries(DIM_LABEL)
    .map(([k, label]) => ({ label, value: Math.round((Number(dims[k]) || 0) * 10) / 10 }))
    .filter((r) => r.value !== 0)
  const last = tl[0]

  const children = [
    // 绑定对不上时，警告必须在**最上面** —— 底下所有数字都要按「可能不是这份」来读
    ...(c.bindingWarning ? [{ type: 'callout', tone: 'warn', text: String(c.bindingWarning).slice(0, 400) }] : []),
    {
      type: 'row',
      children: [
        { type: 'metric', label: '此刻心情', value: Math.round(mood), tone: band.tone, caption: band.label },
        { type: 'metric', label: '更新时间', value: last ? relTime(last.at) : '还没判过', caption: c.ownerName ? `对 ${c.ownerName}` : undefined },
      ],
    },
  ]

  if (dimRows.length) {
    children.push({
      type: 'chart',
      kind: 'bar',
      categories: dimRows.map((r) => r.label),
      series: [{ name: '强度', values: dimRows.map((r) => r.value) }],
      caption: '七根情绪各自还剩多少（会自己衰减回 0）',
    })
  } else if (!tl.length) {
    // 只有在「七维都归零 **且** 时间线也空」时才说没波动 —— 否则会和下面的
    // 「最近几次」自相矛盾（真机上踩到过：七维已衰减到 0，但历史记录还在）
    children.push({ type: 'callout', tone: 'info', text: '这几轮没有情绪波动 —— 无变化不记账，是设计不是坏。' })
  }

  if (tl.length) {
    children.push({ type: 'text', text: '**最近几次**', tone: 'muted' })
    children.push({
      type: 'list',
      items: tl.map((e) => ({
        title: String(e.reason || e.purpose || '（没写理由）').slice(0, 60),
        subtitle: relTime(e.at),
        trailing: `${Number(e.delta) >= 0 ? '+' : ''}${Number(e.delta) || 0}`,
        tone: Number(e.delta) > 0 ? 'good' : Number(e.delta) < 0 ? 'warn' : undefined,
      })),
    })
  }

  children.push({
    type: 'keyValue',
    items: [
      ['基线', String(c.moodBase ?? 70)],
      ['衰减半衰期', `${c.decayHalfHours ?? 3} 小时`],
      ['告诉它的方式', c.injectMode === 'off' ? '不告诉它' : c.injectMode === 'state' ? '只说心情' : '说刚才那件事'],
      ['可信度门槛', String(c.injectConfidence ?? 60)],
    ],
  })

  children.push({
    type: 'actions',
    items: [
      { label: '刷新', action: 'mood.refresh', icon: 'refresh', style: 'primary' },
      { label: '完整记录', action: 'mood.timeline', icon: 'time' },
    ],
  })

  return { v: 1, type: 'stack', title: `心情 ${Math.round(mood)} · ${band.label}`, children }
}

// ── 面板 2：记忆 ────────────────────────────────────────────────────────────
/**
 * @param {object} s { records:[{ id, text, title, clarity, importance, createdAt, tags, pinned, isInitial, firstMet }],
 *                     status:{ chars, warnChars, percent, level, counts } }
 */
export function memoryPanel(s = {}) {
  const records = Array.isArray(s.records) ? s.records : []
  const st = s.status || {}
  const children = []

  if (!records.length) {
    children.push({ type: 'callout', tone: 'info', text: '还没有记忆。聊几句、说过一件明确的事，它就会自己记下来。' })
    return { v: 1, type: 'stack', title: '记忆 · 空', children }
  }

  // 容量：**只在真的读到数字时**才画进度条。
  // 读不到就画一条「0 字」是错的 —— 用户会以为记忆是空的（真机上踩到过：
  // fish-memory 的字段名在各版本间不稳定，status 可能根本不存在）。
  const hasCap = Number.isFinite(Number(st.chars)) && Number(st.chars) > 0
  const percent = Number(st.percent ?? 0)
  if (hasCap) {
    children.push({
      type: 'progress',
      value: Math.min(100, Math.round(percent)),
      max: 100,
      label: '记忆卡容量',
      tone: percent >= 90 ? 'bad' : percent >= 80 ? 'warn' : 'good',
      caption: st.warnChars ? `${st.chars} / ${st.warnChars} 字` : `${st.chars} 字`,
    })
  }

  // 分组：初次相遇 > 永不遗忘 > 最初 > 和主人 > 最近 > 正在模糊
  const groups = [
    ['初次相遇', records.filter((r) => r.firstMet)],
    ['永远不会忘的', records.filter((r) => r.pinned && !r.firstMet)],
    ['最初的日子', records.filter((r) => r.isInitial && !r.pinned)],
    ['和主人的记忆', records.filter((r) => (r.tags || []).includes('owner') && !r.isInitial && !r.pinned)],
    ['正在模糊的事', records.filter((r) => r.clarity === 'fuzzy' || r.clarity === 'trace')],
  ]
  const rest = records.filter((r) => !groups.some(([, g]) => g.includes(r)))

  const rowOf = (r) => ({
    title: String(r.title || r.text || '').slice(0, 40),
    subtitle: `${CLARITY_LABEL[r.clarity] || '清楚'} · 重要 ${r.importance ?? '?'}`,
    trailing: relTime(Date.parse(r.createdAt) || 0),
    icon: r.pinned ? 'pin' : r.isInitial ? 'sparkle' : 'note',
    tone: CLARITY_TONE[r.clarity],
    action: `memory.open`, // 点开看原文（action 会让行带箭头）
  })

  for (const [name, list] of groups) {
    if (!list.length) continue
    children.push({ type: 'text', text: `**${name}**（${list.length}）`, tone: 'muted' })
    children.push({ type: 'list', items: list.slice(0, 12).map(rowOf) })
  }
  if (rest.length) {
    children.push({ type: 'text', text: `**最近记得的**（${rest.length}）`, tone: 'muted' })
    children.push({ type: 'list', items: rest.slice(0, 20).map(rowOf) })
  }

  children.push({
    type: 'actions',
    items: [
      { label: '刷新', action: 'memory.refresh', icon: 'refresh', style: 'primary' },
      { label: '全量存档', action: 'memory.full', icon: 'archive' },
      { label: '导出', action: 'memory.export', icon: 'download' },
    ],
  })

  const c = st.counts || {}
  return {
    v: 1,
    type: 'stack',
    title: `记忆 ${records.length} 条 · ${st.percent ?? 0}%`,
    children,
    // 注：不写成 keyValue 计数块，面板已经很挤；计数放进 title 就够
    _counts: c,
  }
}

// ── 面板 3：目的（主动找我）──────────────────────────────────────────────────
/**
 * @param {object} s purpose-outreach.json：{ countToday, dailyMax, nextFireAt, drives, goals, pending, history, lastOutcome }
 */
export function purposePanel(s = {}) {
  const children = []
  const drives = s.drives || {}
  const NEED = { play: '想玩', learn: '想学', install: '想装', connect: '想陪', care: '关心', share: '分享', identity: '自我', create: '创作', consume: '体验' }
  const top = Object.entries(NEED)
    .map(([k, label]) => ({ label, value: Math.round((Number(drives[k]) || 0) * 100) }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 5)

  const next = Number(s.nextFireAt) || 0
  children.push({
    type: 'row',
    children: [
      { type: 'metric', label: '今天说过', value: `${s.countToday ?? 0}/${s.dailyMax ?? 2}`, caption: '主动找你的次数' },
      { type: 'metric', label: '下次', value: next ? relTime(next).replace('前', '后') : '未排', caption: s.lastOutcome || '' },
    ],
  })

  if (top.length && top.some((t) => t.value > 0)) {
    children.push({
      type: 'chart',
      kind: 'hbar',
      categories: top.map((t) => t.label),
      series: [{ name: '现在最想要', values: top.map((t) => t.value) }],
      unit: '%',
      caption: '这几个念头会随时间回落到默认值，也会因为看到的东西被推高',
    })
  }

  const goals = Array.isArray(s.goals) ? s.goals.slice(0, 4) : []
  if (goals.length) {
    children.push({ type: 'text', text: '**它惦记着的事**', tone: 'muted' })
    children.push({
      type: 'list',
      items: goals.map((g) => ({
        title: String(g.intent || g.text || '').slice(0, 50),
        subtitle: `${g.ownerLabel || g.owner || '自己'} · ${g.action || '?'} · 把握 ${Math.round((Number(g.confidence) || 0) * 100)}%`,
        trailing: (Number(g.risk) || 0) >= 0.5 ? '风险高' : '',
        tone: (Number(g.risk) || 0) >= 0.5 ? 'warn' : undefined,
      })),
    })
  } else {
    children.push({ type: 'callout', tone: 'info', text: '还没形成想做的事 —— 素材不够时它宁可不硬找话。' })
  }

  const pending = Array.isArray(s.pending) ? s.pending.slice(-3) : []
  if (pending.length) {
    children.push({ type: 'text', text: '**没说完的**', tone: 'muted' })
    children.push({ type: 'list', items: pending.map((p) => ({ title: String(p.text || '').slice(0, 50), icon: 'clock', trailing: relTime(p.createdAt) })) })
  }

  children.push({
    type: 'actions',
    items: [
      { label: '现在说一句', action: 'purpose.run', icon: 'send', style: 'primary' },
      { label: '先看看', action: 'purpose.preview', icon: 'search' },
    ],
  })

  return { v: 1, type: 'stack', title: `目的 · 今天 ${s.countToday ?? 0}/${s.dailyMax ?? 2}`, children }
}

// ── 状态条（emit 的 data，2KiB / 8 节点 / 3 层）──────────────────────────────
export function moodStrip(s = {}, c = {}) {
  const mood = Number(s.mood ?? c.moodBase ?? 70)
  const band = moodBand(mood)
  // 状态条 text ≤ 24 字
  return { type: 'stack', children: [{ type: 'text', text: `${band.label} ${Math.round(mood)}` }] }
}

export function stripData(s = {}, c = {}) {
  const mood = Number(s.mood ?? c.moodBase ?? 70)
  const band = moodBand(mood)
  return { text: `${band.label} ${Math.round(mood)}`, icon: band.icon, tone: band.tone }
}

// ── 工具卡：remember 的结果（只用最稳的 8 个组件）───────────────────────────
export function rememberCard(args = {}, value = {}) {
  const okFlag = value && value.ok !== false
  const text = String(args.text || '').slice(0, 200)
  const children = [
    {
      type: 'callout',
      tone: okFlag ? 'good' : 'warn',
      text: okFlag ? '记住了' : `没记住：${String(value?.message || '原因不明')}`,
    },
    { type: 'text', text },
  ]
  const facts = []
  if (args.importance !== undefined) facts.push(`重要度 ${args.importance}`)
  if (Array.isArray(args.tags) && args.tags.length) facts.push(`标签 ${args.tags.slice(0, 5).join('、')}`)
  if (args['事实键']) facts.push(`事实键 \`${args['事实键']}\``)
  if (args['取代']) facts.push(`取代了「${String(args['取代']).slice(0, 30)}」`)
  // ⚠️ 工具卡白名单只有 8 个组件（stack/row/text/metric/chart/compare/steps/callout），**没有 keyValue**
  //    compare 要求 2–4 张卡（不是 2–4 行），一两条事实用它反而画不出来 → 用一行 text + 分隔符最稳
  if (facts.length) children.push({ type: 'text', text: facts.join(' · '), tone: 'muted' })
  return { v: 1, type: 'stack', title: text.slice(0, 30) || '记忆', children }
}

// ── 自测 ────────────────────────────────────────────────────────────────────
function selftest() {
  const now = Date.now()
  const fakeMood = {
    mood: 72.4,
    dims: { happy: 0.6, steady: 0.3, sweet: 0.2, tender: 0.1, worry: 0, sad: 0, jealous: 0.05 },
    timeline: [
      { at: now - 60000, delta: 6, reason: '被夸了一句，心里飘了一下' },
      { at: now - 3600000, delta: -3, reason: '他说在忙，有点小失落' },
      { at: now - 7200000, delta: 0, reason: '' },
    ],
  }
  const fakeCfg = { label: '大肥鱼', selfName: '大肥鱼', ownerName: '小明', moodBase: 70, decayHalfHours: 3, injectMode: 'event', injectConfidence: 60 }
  const fakeMem = {
    records: [
      { id: 'a', text: '我最怕吵，写代码时别打断我', clarity: 'vivid', importance: 82, createdAt: new Date(now - 86400000).toISOString(), tags: ['owner', '偏好'], pinned: true, firstMet: true },
      { id: 'b', text: '答应过周末一起看那部片子', clarity: 'clear', importance: 70, createdAt: new Date(now - 3 * 86400000).toISOString(), tags: ['owner'] },
      { id: 'c', text: '随口提过想学吉他', clarity: 'fuzzy', importance: 35, createdAt: new Date(now - 20 * 86400000).toISOString(), tags: [] },
      { id: 'd', text: '第一次聊天是在一个下雨的晚上', clarity: 'vivid', importance: 100, createdAt: new Date(now - 40 * 86400000).toISOString(), tags: ['owner'], isInitial: true },
    ],
    status: { chars: 1840, warnChars: 60000, percent: 3.1, level: 0, counts: { total: 4, owner: 3 } },
  }
  const fakePurpose = {
    countToday: 1, dailyMax: 2, nextFireAt: now + 5400000, lastOutcome: 'sent',
    drives: { connect: 0.65, play: 0.28, learn: 0.12, care: 0.22, share: 0.2 },
    goals: [
      { intent: '想知道他面试后来怎么样了', ownerLabel: '主人', action: 'ask', confidence: 0.78, risk: 0.05 },
      { intent: '看到「养鱼游戏」，想拉他一起玩', ownerLabel: '群友', action: 'invite', confidence: 0.49, risk: 0.1 },
    ],
    pending: [{ text: '面试结果出来再问一次', createdAt: now - 86400000 }],
  }

  const cases = [
    ['心情面板', moodPanel(fakeMood, fakeCfg), 'panel'],
    ['记忆面板', memoryPanel(fakeMem), 'panel'],
    ['目的面板', purposePanel(fakePurpose), 'panel'],
    ['状态条视图', moodStrip(fakeMood, fakeCfg), 'strip'],
    ['remember 工具卡', rememberCard({ text: '我最怕吵，写代码时别打断我', importance: 0.8, tags: ['偏好', '工作'], 事实键: '她.工作习惯' }, { ok: true }), 'toolCard'],
  ]

  let failed = 0
  const paint = (c, s) => (process.stdout.isTTY ? `\u001b[${c}m${s}\u001b[0m` : s)
  for (const [name, view, budget] of cases) {
    // 去掉内部字段（下划线开头）再校验，避免被当成未知属性
    const clean = JSON.parse(JSON.stringify(view, (k, v) => (k.startsWith('_') ? undefined : v)))
    const r = validate(clean, budget)
    const head = `${name.padEnd(16)} ${String(r.bytes).padStart(6)}B / ${r.budget.bytes}B  节点 ${String(r.nodes).padStart(3)}/${r.budget.nodes}  层 ${r.depth}/${r.budget.depth}`
    if (r.ok) console.log('  ' + paint(32, '✓') + ' ' + head)
    else {
      failed += 1
      console.log('  ' + paint(31, '✗') + ' ' + head)
      for (const i of r.issues) console.log('      → ' + i.path + '：' + i.problem)
    }
  }
  console.log('')
  console.log(failed ? paint(31, `  ${failed} 个视图不合格`) : paint(32, '  全部视图在预算内，可以交给 App 渲染'))
  process.exit(failed ? 1 : 0)
}

if (process.argv[1] && process.argv[1].endsWith('views.mjs')) selftest()
