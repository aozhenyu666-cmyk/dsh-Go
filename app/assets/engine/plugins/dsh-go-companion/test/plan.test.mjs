import { test } from 'node:test'
import assert from 'node:assert/strict'
import { inQuiet, plan } from '../lib/plan.js'

const NOW = Date.parse('2026-11-05T20:00:00+08:00')
const topic = { id: 'topic:a', kind: 'unfinished', text: '面试结果' }

test('安静时段：跨零点与不启用', () => {
  assert.equal(inQuiet(Date.parse('2026-11-05T23:30:00+08:00'), 23, 8), true)
  assert.equal(inQuiet(Date.parse('2026-11-05T07:30:00+08:00'), 23, 8), true)
  assert.equal(inQuiet(Date.parse('2026-11-05T12:00:00+08:00'), 23, 8), false)
  assert.equal(inQuiet(NOW, 1, 1), false)
})

test('关闭、安静、日上限、冷却、无话题都返回具体原因', () => {
  assert.equal(plan({ config: { enabled: false }, now: NOW, topic, roll: 0 }).reason, 'disabled')
  assert.equal(plan({ config: { enabled: true, quietStart: 19, quietEnd: 21 }, now: NOW, topic, roll: 0 }).reason, 'quiet')
  assert.equal(plan({ config: { enabled: true, dailyMax: 2 }, now: NOW, topic, sentToday: 2, roll: 0 }).reason, 'daily_max')
  assert.equal(
    plan({ config: { enabled: true, minGapMs: 3600000 }, now: NOW, topic, lastAt: NOW - 60000, roll: 0 }).reason,
    'cooldown',
  )
  assert.equal(plan({ config: { enabled: true }, now: NOW, topic: null, roll: 0 }).reason, 'no-topic')
})

test('nextCheckAt：安静结束、冷却结束、下一次话题到期', () => {
  const quiet = plan({ config: { enabled: true, quietStart: 19, quietEnd: 21 }, now: NOW, topic, roll: 0 })
  assert.equal(quiet.reason, 'quiet')
  assert.equal(quiet.nextCheckAt, Date.parse('2026-11-05T21:00:00+08:00'))

  const cool = plan({ config: { enabled: true, minGapMs: 3_600_000 }, now: NOW, topic, lastAt: NOW - 60_000, roll: 0 })
  assert.equal(cool.reason, 'cooldown')
  assert.equal(cool.nextCheckAt, NOW - 60_000 + 3_600_000)

  const none = plan({ config: { enabled: true }, now: NOW, topic: null, nextTopicAt: NOW + 3 * 3_600_000, roll: 0 })
  assert.equal(none.reason, 'no-topic')
  assert.equal(none.nextCheckAt, NOW + 3 * 3_600_000)
})

test('掷骰：低于命中线才开口', () => {
  assert.equal(plan({ config: { enabled: true, diceThreshold: 60 }, now: NOW, topic, roll: 59 }).speak, true)
  assert.equal(plan({ config: { enabled: true, diceThreshold: 60 }, now: NOW, topic, roll: 60 }).speak, false)
  const ok = plan({ config: { enabled: true, diceThreshold: 100 }, now: NOW, topic, roll: 0 })
  assert.equal(ok.speak, true)
  assert.equal(ok.topic.id, 'topic:a')
})
