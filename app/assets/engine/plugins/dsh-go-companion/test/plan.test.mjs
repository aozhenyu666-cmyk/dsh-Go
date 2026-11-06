import { test } from 'node:test'
import assert from 'node:assert/strict'
import { inQuiet, plan } from '../lib/plan.js'

// 这一组用例全部显式传时区：引擎在生产里跑 TZ=GMT，本机是 Asia/Shanghai，
// 只有钉死时区才能保证两种环境下结论一样。
const TZ = 'Asia/Shanghai'
const NOW = Date.parse('2026-11-05T20:00:00+08:00')
const topic = { id: 'topic:a', kind: 'unfinished', text: '面试结果' }

test('安静时段：跨零点与不启用', () => {
  assert.equal(inQuiet(Date.parse('2026-11-05T23:30:00+08:00'), 23, 8, TZ), true)
  assert.equal(inQuiet(Date.parse('2026-11-05T07:30:00+08:00'), 23, 8, TZ), true)
  assert.equal(inQuiet(Date.parse('2026-11-05T12:00:00+08:00'), 23, 8, TZ), false)
  assert.equal(inQuiet(NOW, 1, 1, TZ), false)
})

test('安静时段按传入时区算，不受进程 TZ 影响', () => {
  const at2330 = Date.parse('2026-11-05T23:30:00+08:00')
  // 同一个瞬间：上海是 23:30（安静），UTC 是 15:30（不安静）
  assert.equal(inQuiet(at2330, 23, 8, 'Asia/Shanghai'), true)
  assert.equal(inQuiet(at2330, 23, 8, 'UTC'), false)
  // 引擎实际就是跑在 GMT，这也是真机上偏 8 小时的那条路径
  assert.equal(inQuiet(at2330, 23, 8, 'Etc/GMT'), false)
})

test('时区非法或为空时回落到默认 Asia/Shanghai', () => {
  const at2330 = Date.parse('2026-11-05T23:30:00+08:00')
  assert.equal(inQuiet(at2330, 23, 8, 'Not/AZone'), true)
  assert.equal(inQuiet(at2330, 23, 8, ''), true)
})

test('关闭、安静、日上限、冷却、无话题都返回具体原因', () => {
  assert.equal(plan({ config: { enabled: false }, now: NOW, topic, roll: 0, tz: TZ }).reason, 'disabled')
  assert.equal(
    plan({ config: { enabled: true, quietStart: 19, quietEnd: 21 }, now: NOW, topic, roll: 0, tz: TZ }).reason,
    'quiet',
  )
  assert.equal(
    plan({ config: { enabled: true, dailyMax: 2 }, now: NOW, topic, sentToday: 2, roll: 0, tz: TZ }).reason,
    'daily_max',
  )
  assert.equal(
    plan({ config: { enabled: true, minGapMs: 3600000 }, now: NOW, topic, lastAt: NOW - 60000, roll: 0, tz: TZ })
      .reason,
    'cooldown',
  )
  assert.equal(plan({ config: { enabled: true }, now: NOW, topic: null, roll: 0, tz: TZ }).reason, 'no-topic')
})

test('nextCheckAt：安静结束、冷却结束、下一次话题到期', () => {
  const quiet = plan({ config: { enabled: true, quietStart: 19, quietEnd: 21 }, now: NOW, topic, roll: 0, tz: TZ })
  assert.equal(quiet.reason, 'quiet')
  assert.equal(quiet.nextCheckAt, Date.parse('2026-11-05T21:00:00+08:00'))

  const cool = plan({
    config: { enabled: true, minGapMs: 3_600_000 },
    now: NOW,
    topic,
    lastAt: NOW - 60_000,
    roll: 0,
    tz: TZ,
  })
  assert.equal(cool.reason, 'cooldown')
  assert.equal(cool.nextCheckAt, NOW - 60_000 + 3_600_000)

  const none = plan({
    config: { enabled: true },
    now: NOW,
    topic: null,
    nextTopicAt: NOW + 3 * 3_600_000,
    roll: 0,
    tz: TZ,
  })
  assert.equal(none.reason, 'no-topic')
  assert.equal(none.nextCheckAt, NOW + 3 * 3_600_000)
})

test('日上限的「明天零点」按手机时区算，不是 UTC 零点', () => {
  const at2330 = Date.parse('2026-11-05T23:30:00+08:00')
  const out = plan({
    config: { enabled: true, dailyMax: 1, quietStart: 0, quietEnd: 0 },
    now: at2330,
    topic,
    sentToday: 1,
    roll: 0,
    tz: TZ,
  })
  assert.equal(out.reason, 'daily_max')
  assert.equal(out.nextCheckAt, Date.parse('2026-11-06T00:00:00+08:00'))
})

test('掷骰：低于命中线才开口', () => {
  assert.equal(plan({ config: { enabled: true, diceThreshold: 60 }, now: NOW, topic, roll: 59, tz: TZ }).speak, true)
  assert.equal(plan({ config: { enabled: true, diceThreshold: 60 }, now: NOW, topic, roll: 60, tz: TZ }).speak, false)
  const ok = plan({ config: { enabled: true, diceThreshold: 100 }, now: NOW, topic, roll: 0, tz: TZ })
  assert.equal(ok.speak, true)
  assert.equal(ok.topic.id, 'topic:a')
})
