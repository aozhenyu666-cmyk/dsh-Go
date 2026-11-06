// dsh-go-companion · 回合（rally）
//
// 一次互动是一个回合：大肥鱼发球 → 人回球 → 大肥鱼判球 → 回击 …… 直到聊透或人去做事。
// 好坏只看每天打出多少个**有效回合**，不看发了几条消息。
//
// 回合状态不单独存盘：账本（ledger.jsonl）里每一条已经带了 rallyId 和 shot，
// 需要时从账本重建，进程重启也不会丢。

import { randomUUID } from 'node:crypto'

/** 超过这么久没有再动，就当上一轮已经收拍，下一次开口是新的一轮。 */
export const RALLY_WINDOW_MS = 2 * 3_600_000

/** 这两条状态各算打了一拍（发球、回球）；substantive 是给 replied 加的标签，不另算一拍。 */
const HITS = new Set(['generated', 'replied'])

/** 算「接住了」的判球结果。pushback（真反驳）是最好的球，也算法。 */
const ENGAGED = new Set(['engaged', 'pushback', 'substantive'])

export function newRallyId() {
  return 'rally-' + randomUUID().replace(/-/g, '').slice(0, 16)
}

function hitsOf(entries, rallyId) {
  let n = 0
  for (const e of entries) if (e && e.rallyId === rallyId && HITS.has(e.state)) n += 1
  return n
}

/**
 * 下一拍该挂在哪个回合、第几拍。
 *
 * 只看同一个会话：两个会话各自的回合不能串。窗口外的旧回合不再续。
 * 返回 { rallyId, shot }，调用方把这两项写进账本。
 */
export function nextShot(entries, { sessionId, now, windowMs = RALLY_WINDOW_MS } = {}) {
  const at = Number(now) || Date.now()
  let last
  for (const e of entries) {
    if (!e || !e.rallyId) continue
    if (sessionId && e.sessionId && e.sessionId !== sessionId) continue
    if (!last || Number(e.at) >= Number(last.at)) last = e
  }
  if (!last) return { rallyId: newRallyId(), shot: 1 }
  if (at - (Number(last.at) || 0) > windowMs) return { rallyId: newRallyId(), shot: 1 }
  return { rallyId: String(last.rallyId), shot: hitsOf(entries, last.rallyId) + 1 }
}

/**
 * 当天的回合统计。有效回合 = 至少两拍，且至少有一拍被判成接住了。
 *
 * shortcut: 只按当天内的拍数算，跨零点的回合会被拆成两个不完整的回合（都不算有效）。
 * 按天统计本来就是给人看的日指标，真需要跨零点连续时再改成按 rallyId 全量聚合。
 */
export function rallyStats(entries, dayStart) {
  const since = Number(dayStart) || 0
  const shots = new Map()
  const engaged = new Set()
  for (const e of entries) {
    if (!e || !e.rallyId || Number(e.at) < since) continue
    const id = String(e.rallyId)
    if (HITS.has(e.state)) shots.set(id, (shots.get(id) || 0) + 1)
    const verdict = String(e.verdict || e.replyClass || '')
    if (ENGAGED.has(verdict)) engaged.add(id)
  }
  let total = 0
  let effective = 0
  for (const [id, n] of shots) {
    total += 1
    if (n >= 2 && engaged.has(id)) effective += 1
  }
  return { total, effective }
}

/** 以这个回合已打出的拍数（没有就是 0）。 */
export function shotCount(entries, rallyId) {
  return rallyId ? hitsOf(entries, rallyId) : 0
}
