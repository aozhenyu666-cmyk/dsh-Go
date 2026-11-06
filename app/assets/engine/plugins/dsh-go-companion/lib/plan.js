// dsh-go-companion · 本地决策（零模型）
//
// 原生闹钟只负责“到点检查”；这里回答四个问题：开没开、静不静、额度够不够、掷骰中没中。
// 未命中不消耗模型，这是“高频但不烧钱”的关键。

import { randomInt } from 'node:crypto'
import { DEFAULT_TZ, atLocalHour, minuteOfDay as zoneMinuteOfDay, startOfDay } from './tz.js'

export function minuteOfDay(now, tz = DEFAULT_TZ) {
  return zoneMinuteOfDay(now, tz)
}

export function inQuiet(now, startHour, endHour, tz = DEFAULT_TZ) {
  const start = Number.isFinite(Number(startHour)) ? Math.round(Number(startHour)) : 1
  const end = Number.isFinite(Number(endHour)) ? Math.round(Number(endHour)) : 8
  if (start === end) return false
  const m = zoneMinuteOfDay(now, tz)
  const a = start * 60
  const b = end * 60
  return a < b ? m >= a && m < b : m >= a || m < b
}

function quietEndAt(now, startHour, endHour, tz) {
  const end = Number.isFinite(Number(endHour)) ? Math.round(Number(endHour)) : 8
  return atLocalHour(now, end, tz)
}

function nextDayAt(now, tz) {
  return startOfDay(now, tz) + 86_400_000
}

/**
 * @param {{config: object, now: number, topic: object|null, sentToday: number, lastAt: number, roll: number}} input
 * @returns {{speak: boolean, reason: string, topic: object|null}}
 */
export function plan(input) {
  const c = input.config || {}
  const now = Number(input.now) || Date.now()
  const tz = input.tz || DEFAULT_TZ
  const minGap = Math.max(0, Number(c.minGapMs) || 0)
  const fromTopic = Number(input.nextTopicAt) || 0
  if (c.enabled === false) {
    return { speak: false, reason: 'disabled', topic: null, nextCheckAt: now + 6 * 3_600_000 }
  }
  if (inQuiet(now, c.quietStart, c.quietEnd, tz)) {
    return { speak: false, reason: 'quiet', topic: null, nextCheckAt: quietEndAt(now, c.quietStart, c.quietEnd, tz) }
  }
  const dailyMax = Math.max(0, Number(c.dailyMax) || 0)
  if (dailyMax > 0 && Number(input.sentToday) >= dailyMax) {
    return { speak: false, reason: 'daily_max', topic: null, nextCheckAt: nextDayAt(now, tz) }
  }
  if (minGap > 0 && Number(input.lastAt) > 0 && now - Number(input.lastAt) < minGap) {
    return { speak: false, reason: 'cooldown', topic: null, nextCheckAt: Number(input.lastAt) + minGap }
  }
  if (!input.topic) {
    return {
      speak: false,
      reason: 'no-topic',
      topic: null,
      nextCheckAt: fromTopic > now ? fromTopic : now + 6 * 3_600_000,
    }
  }
  const threshold = Math.min(100, Math.max(0, Number(c.diceThreshold ?? 60)))
  const roll = Number.isFinite(Number(input.roll)) ? Number(input.roll) : randomInt(1000) / 10
  if (roll >= threshold) {
    return { speak: false, reason: 'dice', topic: null, nextCheckAt: now + Math.max(minGap, 30 * 60_000) }
  }
  return { speak: true, reason: 'ok', topic: input.topic, nextCheckAt: now + Math.max(minGap, 30 * 60_000) }
}
