// dsh-go-companion · 人格卡与两种模式
//
// 人格卡是"大肥鱼是谁"的可编辑部分：名字、口吻、口头禅、兴趣、和他的关系、
// 能说多狠、哪些话题不碰。存在插件配置里（/config 可改），发球时拼进 prompt。
//
// 两种模式决定"这一阵子怎么说话"，不改人设：
//   伙伴 partner  自然闲聊，偏闲聊/记忆回调，频率低，判球宽
//   教练 coach    偏观察/观点挑衅/小挑战，频率高，判球严

/** 人格卡字段与上限。只做能进 prompt 的部分。 */
export const PERSONA_FIELDS = {
  name: 40,
  voice: 200,
  catchphrase: 60,
  interests: 200,
  relation: 200,
  bite: 200,
  avoid: 200,
}

export const MODES = ['partner', 'coach']

/** 每种模式偏好的发球类型，按偏好排序。 */
export const MODE_SERVE = {
  partner: ['chat', 'memory', 'observe', 'challenge', 'review', 'provoke'],
  coach: ['observe', 'provoke', 'challenge', 'review', 'memory', 'chat'],
}

/** 模式对频率的影响：教练更勤，伙伴更松。倍数乘在 minGap 上。 */
export const MODE_GAP = {
  partner: 1.5,
  coach: 1,
}

export function modeOr(raw) {
  const m = String(raw || '').trim().toLowerCase()
  return MODES.includes(m) ? m : 'partner'
}

/** 洗一遍人格卡：只留认识的字段，各自限长。 */
export function cleanPersona(raw) {
  const out = {}
  if (!raw || typeof raw !== 'object') return out
  for (const [key, max] of Object.entries(PERSONA_FIELDS)) {
    const v = raw[key]
    if (typeof v !== 'string') continue
    const s = v.trim()
    if (s) out[key] = s.slice(0, max)
  }
  return out
}

/** 人格卡 + 模式拼成给模型的几行。空的部分不说，别给模型凑字数。 */
export function personaLines(persona, mode) {
  const p = cleanPersona(persona)
  const lines = []
  if (p.voice) lines.push('你的口吻：' + p.voice)
  if (p.catchphrase) lines.push('你偶尔会说的口头禅：' + p.catchphrase)
  if (p.interests) lines.push('你自己对这些有兴趣：' + p.interests)
  if (p.relation) lines.push('你和他' + '的关系：' + p.relation)
  if (p.bite) lines.push('你能说多狠：' + p.bite)
  if (p.avoid) lines.push('这些话题不碰：' + p.avoid)
  if (mode === 'coach') {
    lines.push('现在是教练模式：抓具体、给判断、不绕。夸要夸到点上，指出问题要给出下一步。')
  } else {
    lines.push('现在是伙伴模式：自然聊，别端着，也别每句都带任务。')
  }
  return lines
}

/** 模式偏好排序 + 最近用过的避开，给 serve.js 的 only 用（按偏好降级）。 */
export function modeServeOrder(mode) {
  return (MODE_SERVE[modeOr(mode)] || MODE_SERVE.partner).slice()
}

/** 按模式放宽/收紧最小间隔。 */
export function modeGap(minGapMs, mode) {
  const gap = Math.max(0, Number(minGapMs) || 0)
  const k = MODE_GAP[modeOr(mode)] || 1
  return Math.round(gap * k)
}

const TO_COACH = /(进|切|换|开)(入|到|成|回)?教练(模式)?/
const TO_PARTNER = /(进|切|换|开)(入|到|成|回)?(伙伴|朋友|日常)(模式)?/

/**
 * 他说"进入教练模式 2 小时"就切过去。返回 {mode, hours}，没说返回 null。
 *
 * shortcut: 只认"教练/伙伴 + 模式"这类说法，小时数可选（不给就是一直开着，
 * 直到他再说一次切回去）。按日程自动切换没做——那是设置里配时间段的事。
 */
export function modeSwitch(text) {
  const s = String(text == null ? '' : text).replace(/\s+/g, '')
  if (!s || s.length > 40) return null
  const coach = TO_COACH.test(s)
  const partner = TO_PARTNER.test(s)
  if (coach === partner) return null
  const hours = /(\d+)\s*(个)?(小时|钟头)/.exec(s)
  const n = hours ? Math.max(1, Math.min(24, Number(hours[1]))) : 0
  return { mode: coach ? 'coach' : 'partner', hours: n }
}

/** 现在实际是哪个模式：定时切换到点了就回到伙伴。 */
export function effectiveMode(config, now) {
  const until = Number(config?.modeUntil) || 0
  if (until > 0 && Number(now) >= until) return 'partner'
  return modeOr(config?.mode)
}
