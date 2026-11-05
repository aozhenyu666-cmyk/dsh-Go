// dsh-go-companion · 本地决策（零模型）
//
// 原生闹钟只负责“到点检查”；这里回答四个问题：开没开、静不静、额度够不够、掷骰中没中。
// 未命中不消耗模型，这是“高频但不烧钱”的关键。

import { randomInt } from 'node:crypto'

export function minuteOfDay(now) {
  const d = new Date(now)
  return d.getHours() * 60 + d.getMinutes()
}

export function inQuiet(now, startHour, endHour) {
  const start = Number.isFinite(Number(startHour)) ? Math.round(Number(startHour)) : 1
  const end = Number.isFinite(Number(endHour)) ? Math.round(Number(endHour)) : 8
  if (start === end) return false
  const m = minuteOfDay(now)
  const a = start * 60
  const b = end * 60
  return a < b ? m >= a && m < b : m >= a || m < b
}

/**
 * @param {{config: object, now: number, topic: object|null, sentToday: number, lastAt: number, roll: number}} input
 * @returns {{speak: boolean, reason: string, topic: object|null}}
 */
export function plan(input) {
  const c = input.config || {}
  const now = Number(input.now) || Date.now()
  if (c.enabled === false) return { speak: false, reason: 'disabled', topic: null }
  if (inQuiet(now, c.quietStart, c.quietEnd)) return { speak: false, reason: 'quiet', topic: null }
  const dailyMax = Math.max(0, Number(c.dailyMax) || 0)
  if (dailyMax > 0 && Number(input.sentToday) >= dailyMax) return { speak: false, reason: 'daily_max', topic: null }
  const minGap = Math.max(0, Number(c.minGapMs) || 0)
  if (minGap > 0 && Number(input.lastAt) > 0 && now - Number(input.lastAt) < minGap) {
    return { speak: false, reason: 'cooldown', topic: null }
  }
  if (!input.topic) return { speak: false, reason: 'no-topic', topic: null }
  const threshold = Math.min(100, Math.max(0, Number(c.diceThreshold ?? 60)))
  const roll = Number.isFinite(Number(input.roll)) ? Number(input.roll) : randomInt(1000) / 10
  if (roll >= threshold) return { speak: false, reason: 'dice', topic: null }
  return { speak: true, reason: 'ok', topic: input.topic }
}
