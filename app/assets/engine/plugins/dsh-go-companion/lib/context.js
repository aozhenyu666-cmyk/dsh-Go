// dsh-go-companion · 每轮主动交流的上下文（只读）
//
// 心情、关系承诺、最近的回应方式都从现有文件/库读取；缺了就跳过，
// 不因为某个插件没装就让主动回合失败。

import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { createRequire } from 'node:module'

const require = createRequire(import.meta.url)
let DatabaseSync = null
try {
  ;({ DatabaseSync } = require('node:sqlite'))
} catch {
  DatabaseSync = null
}

/** feiyu-mood/state.json：{ moods: { key: { mood, ... } }, lastActive } */
export function readMood(home) {
  try {
    const file = join(home, 'feiyu-mood', 'state.json')
    if (!existsSync(file)) return null
    const raw = JSON.parse(readFileSync(file, 'utf8'))
    const moods = raw && raw.moods && typeof raw.moods === 'object' ? raw.moods : {}
    const key = typeof raw.lastActive === 'string' && raw.lastActive ? raw.lastActive : Object.keys(moods)[0]
    const state = key ? moods[key] : null
    const mood = Number(state && state.mood)
    if (!Number.isFinite(mood)) return null
    return { mood: Math.max(0, Math.min(100, Math.round(mood))) }
  } catch {
    return null
  }
}

/** 关系账本里 pending 的承诺，最多几条；只读。 */
export function readCommitments(home, now = Date.now(), limit = 3) {
  if (!DatabaseSync) return []
  const file = join(home, 'relationship', 'relationship.db')
  if (!existsSync(file)) return []
  let db = null
  try {
    db = new DatabaseSync(file)
    const rows = db.prepare(
      'SELECT id, statement, due_at, owner FROM commitments WHERE status = ? ORDER BY due_at ASC LIMIT ?',
    ).all('pending', Math.max(1, Math.min(5, limit)))
    return rows.map((r) => ({
      id: String(r.id || ''),
      statement: String(r.statement || '').slice(0, 160),
      owner: String(r.owner || ''),
      dueAt: String(r.due_at || ''),
    }))
  } catch {
    return []
  } finally {
    try {
      db?.close?.()
    } catch {
      // ignore
    }
  }
}

/** 最近一次主动交流之后，人是怎么回应的。 */
export function lastReplyClass(entries) {
  for (let i = entries.length - 1; i >= 0; i -= 1) {
    const e = entries[i]
    if (e && e.state === 'replied' && typeof e.replyClass === 'string') return e.replyClass
  }
  return ''
}
