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
 * @param {{config: object, now: number, topic: object|null, sentToday: number, sentLastHour?: number,
 *          lastAt: number, roll: number, silence?: {stage: string}, mutedUntil?: number}} input
 * @returns {{speak: boolean, reason: string, topic: object|null, nextCheckAt?: number, stage?: string}}
 */
export function plan(input) {
  const c = input.config || {}
  const now = Number(input.now) || Date.now()
  const tz = input.tz || DEFAULT_TZ
  const minGap = Math.max(0, Number(c.minGapMs) || 0)
  const fromTopic = Number(input.nextTopicAt) || 0
  const stage = String(input.silence?.stage || 'none')
  if (c.enabled === false) {
    return { speak: false, reason: 'disabled', topic: null, nextCheckAt: now + 6 * 3_600_000 }
  }
  // 他说"安静一小时""今天别找我"，就准时闭嘴，别再问。
  const muteUntil = Number(input.mutedUntil) || 0
  if (muteUntil > now) {
    return { speak: false, reason: 'muted', topic: null, nextCheckAt: muteUntil }
  }
  if (inQuiet(now, c.quietStart, c.quietEnd, tz)) {
    return { speak: false, reason: 'quiet', topic: null, nextCheckAt: quietEndAt(now, c.quietStart, c.quietEnd, tz) }
  }
  const dailyMax = Math.max(0, Number(c.dailyMax) || 0)
  if (dailyMax > 0 && Number(input.sentToday) >= dailyMax) {
    return { speak: false, reason: 'daily_max', topic: null, nextCheckAt: nextDayAt(now, tz) }
  }
  const hourlyMax = Math.max(0, Number(c.hourlyMax) || 0)
  if (hourlyMax > 0 && Number(input.sentLastHour) >= hourlyMax) {
    return { speak: false, reason: 'hourly_max', topic: null, nextCheckAt: now + 30 * 60_000 }
  }
  // 连续两次没接：这一轮停下，不再追。下次打开手机或第二天早上再说。
  if (stage === 'stop') {
    return { speak: false, reason: 'no-take', topic: null, nextCheckAt: now + 3 * 3_600_000, stage }
  }
  // 阶梯：没接球时换更轻的球 / 换渠道。它压过 minGap —— 5 分钟就是 5 分钟，
  // 否则 minGap（默认 30 分钟）一卡，阶梯根本走不到。
  if (stage === 'lighter' || stage === 'channel') {
    return { speak: true, reason: 'ladder-' + stage, topic: input.topic, nextCheckAt: now + 5 * 60_000, stage }
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
