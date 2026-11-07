// dsh-go-companion · 漠视阶梯
//
// 同一个发球不允许原样再发。没接球时按阶梯换打法，每一级都换内容、换角度：
//   5 分钟   换一个更轻、更具体的球（观点挑衅 → 小挑战 / 闲聊）
//   15 分钟  换渠道（浮层、语音念出来）。渠道是手机侧执行的：这里只把
//            stage='channel' 写进账本，plan.js 再按 voice 开关给出 channel='speech'，
//            手机读到它就用系统 TTS 念出来（Surface.SPEECH）。
//            插件不假装自己换了渠道。
//   连续 2 次没接  本轮停下，把"几点、哪类球被漠视了"记进账本，下次拿它当素材。
//
// shortcut: 只看账本里这条发球有没有回球，不区分"没看到"和"看到不理"——
// 两者对阶梯的选择其实一样（都要换更轻的球）。真要分开，得让 App 把
// displayed/dismissed 的 surface 一起报上来，账本现在没这个字段。

import { startOfDay } from './tz.js'

/** 阶梯：到点换到哪一级。 */
export const LADDER = [
  { atMs: 5 * 60_000, stage: 'lighter' },
  { atMs: 15 * 60_000, stage: 'channel' },
]

/** 连续这么多次没接，本轮就停下，不再追。 */
export const NO_TAKE_LIMIT = 2

/** "更轻"的球：小挑战和闲聊。观点挑衅、复盘这些更重，没接球时先不用。 */
export const LIGHTER_TYPES = ['challenge', 'chat']

/** 这一球有没有被接：同一 requestId 后来出现过 replied。 */
function answered(entries, requestId) {
  for (const e of entries) if (e && e.requestId === requestId && e.state === 'replied') return true
  return false
}

/** 账本里的发球，新→旧。 */
function serves(entries, sessionId) {
  const out = []
  for (let i = entries.length - 1; i >= 0; i -= 1) {
    const e = entries[i]
    if (!e || e.state !== 'generated' || !e.requestId) continue
    if (sessionId && e.sessionId && e.sessionId !== sessionId) continue
    out.push(e)
  }
  return out
}

/**
 * 现在该按哪一级走。
 *
 * @returns {{stage: 'none'|'wait'|'lighter'|'channel'|'stop', sinceMs: number, noTake: number, serveType: string}}
 *   none    最近这一球被接了，正常发球
 *   wait    发出去了还没到 5 分钟
 *   lighter 到 5 分钟了，换更轻的球
 *   channel 到 15 分钟了，换渠道
 *   stop    连续 NO_TAKE_LIMIT 次没接，停下
 */
export function silenceState(entries, { sessionId, now, ladder = LADDER, limit = NO_TAKE_LIMIT } = {}) {
  const at = Number(now) || Date.now()
  const list = serves(Array.isArray(entries) ? entries : [], sessionId)
  if (!list.length) return { stage: 'none', sinceMs: 0, noTake: 0, serveType: '' }

  // 一条接一条往回数：连着几条没接。
  let noTake = 0
  for (const s of list) {
    if (answered(entries, s.requestId)) break
    noTake += 1
  }
  const last = list[0]
  const sinceMs = Math.max(0, at - (Number(last.at) || 0))
  const serveType = String(last.serveType || '')
  // 最后这一球已经被接了：阶梯到此为止，别拿旧账继续催。
  if (answered(entries, last.requestId)) return { stage: 'none', sinceMs, noTake: 0, serveType }
  if (noTake >= limit) return { stage: 'stop', sinceMs, noTake, serveType }
  for (let i = ladder.length - 1; i >= 0; i -= 1) {
    if (sinceMs >= ladder[i].atMs) return { stage: ladder[i].stage, sinceMs, noTake, serveType }
  }
  return { stage: 'wait', sinceMs, noTake, serveType }
}

/** 被漠视的那类球少发、接住的类型多发。返回 type -> 权重（最小 1）。 */
export function serveWeights(entries) {
  const weight = {}
  for (const t of [...LIGHTER_TYPES, 'observe', 'memory', 'provoke', 'review']) weight[t] = 1
  const taken = new Set()
  for (const e of Array.isArray(entries) ? entries : []) {
    if (!e || e.state !== 'replied') continue
    if (e.requestId) taken.add(e.requestId)
  }
  for (const e of Array.isArray(entries) ? entries : []) {
    if (!e || e.state !== 'generated') continue
    const t = String(e.serveType || '')
    if (!(t in weight)) continue
    if (e.requestId && taken.has(e.requestId)) weight[t] += 1
    else weight[t] = Math.max(1, weight[t] - 1)
  }
  // 被漠视到 0 的类型给 1：少发，不是永不发。
  for (const t of Object.keys(weight)) weight[t] = Math.max(1, weight[t])
  return weight
}

const MUTE_HOUR = /安静(个|一|1)?(小时|钟头)|安静(一)?会|别烦我|闭嘴/
const MUTE_DAY = /(今天|今日)(就)?(别|不要|不用)(找|叫|烦|打扰)我/
const PUNCT = /[，。！？、；：""''《》（）()[\]{}<>·…—～~!?,.;:'"`\s]/g

/** 他说"安静一小时""今天别找我"就照做。返回应该静音到的时间（0 = 没说）。 */
function mutePhrase(text) {
  const s = String(text == null ? '' : text).replace(PUNCT, '')
  if (!s || s.length > 24) return null
  for (const re of [MUTE_DAY, MUTE_HOUR]) {
    const m = re.exec(s)
    if (!m) continue
    // 去掉这句命令本身，剩下的只能是"吧/了/哦"这种语气词。
    // "安静一小时的歌单我整理好了"不算在喊安静，只是刚好说了这几个字。
    if (s.length - m[0].length > 3) continue
    return re
  }
  return null
}

/**
 * 他说"安静一小时""今天别找我"就照做。返回应该静音到的时间（0 = 没说）。
 *
 * shortcut: 只认这两类说法，用正则在插件里直接判，不花模型、不占工具。
 * 说法要更多（"我先忙"、"晚点说"）就往 MUTE_HOUR/MUTE_DAY 里加。
 */
export function mutedUntil(text, now, { tz } = {}) {
  const re = mutePhrase(text)
  if (!re) return 0
  const at = Number(now) || Date.now()
  if (re === MUTE_DAY) return startOfDay(at, tz) + 86_400_000
  return at + 3_600_000
}

const VOICE_ON = /开(一下|上)?语音|用语音|念(出来|给我听)/
const VOICE_OFF = /关(掉|了)?语音|别念了|不用念|别出声/

/**
 * 他说"开语音 / 别念了"就照做。返回 true 开、false 关、null 没说。
 *
 * shortcut: 和 mutedUntil 一样用正则直接判，不花模型、不占工具；只认这几个说法。
 * 说法要更多就往 VOICE_ON / VOICE_OFF 里加。
 */
export function voiceSwitch(text) {
  const s = String(text == null ? '' : text).replace(PUNCT, '')
  if (!s || s.length > 24) return null
  // 和安静指令同一条规矩：去掉命令本身，剩下的只能是语气词。
  // "我打开了语音助手"不算在喊它念。
  for (const [re, on] of [[VOICE_OFF, false], [VOICE_ON, true]]) {
    const m = re.exec(s)
    if (!m) continue
    if (s.length - m[0].length > 3) continue
    return on
  }
  return null
}
