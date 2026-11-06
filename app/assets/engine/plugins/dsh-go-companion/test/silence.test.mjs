// P2：漠视阶梯 —— 时间和账本都注入，不靠真实等待。

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { LADDER, NO_TAKE_LIMIT, serveWeights, silenceState, mutedUntil, LIGHTER_TYPES } from '../lib/silence.js'
import { pickServeType } from '../lib/serve.js'

const T0 = 1793000000000

/** 一条发球 + 可选的一条回球。 */
function serve(requestId, at, serveType) {
  return { state: 'generated', requestId, sessionId: 's', at, serveType, text: '我猜你在躲申论' }
}

function reply(requestId, at) {
  return { state: 'replied', requestId, sessionId: 's', at, verdict: 'engaged' }
}

test('刚发出去还没到 5 分钟：等着，别再发', () => {
  const entries = [serve('r1', T0, 'observe')]
  const s = silenceState(entries, { sessionId: 's', now: T0 + 60_000 })
  assert.equal(s.stage, 'wait')
  assert.equal(s.noTake, 1)
})

test('5 分钟没回：换更轻的球', () => {
  const entries = [serve('r1', T0, 'observe')]
  const s = silenceState(entries, { sessionId: 's', now: T0 + LADDER[0].atMs })
  assert.equal(s.stage, 'lighter')
  assert.equal(s.serveType, 'observe', '要能看出上一球是哪一类')
})

test('15 分钟没回：换渠道', () => {
  const entries = [serve('r1', T0, 'observe')]
  const s = silenceState(entries, { sessionId: 's', now: T0 + LADDER[1].atMs })
  assert.equal(s.stage, 'channel')
})

test('接住了就不再走阶梯', () => {
  const entries = [serve('r1', T0, 'observe'), reply('r1', T0 + 60_000)]
  const s = silenceState(entries, { sessionId: 's', now: T0 + 30 * 60_000 })
  assert.equal(s.stage, 'none')
  assert.equal(s.noTake, 0)
})

test('连续两次没接：这一轮停下', () => {
  const entries = [serve('r1', T0, 'observe'), serve('r2', T0 + 20 * 60_000, 'chat')]
  const s = silenceState(entries, { sessionId: 's', now: T0 + 40 * 60_000 })
  assert.equal(s.stage, 'stop')
  assert.equal(s.noTake, NO_TAKE_LIMIT)
})

test('中间接过一次，连续计数就断了', () => {
  const entries = [serve('r1', T0, 'observe'), reply('r1', T0 + 60_000), serve('r2', T0 + 40 * 60_000, 'chat')]
  const s = silenceState(entries, { sessionId: 's', now: T0 + 41 * 60_000 })
  assert.equal(s.noTake, 1, '只数最后这一条没接的')
  assert.notEqual(s.stage, 'stop')
})

test('被漠视的类型降权，接住的升权，最低也是 1', () => {
  const entries = [
    serve('r1', T0, 'observe'),
    reply('r1', T0 + 1000),
    serve('r2', T0 + 2000, 'chat'),
    serve('r3', T0 + 3000, 'chat'),
  ]
  const w = serveWeights(entries)
  assert.ok(w.observe > 1, '接住过的类型权重该升')
  assert.equal(w.chat, 1, '连着被漠视两次已经到底，但不会变成 0')
})

test('没接球时只在轻球里挑', () => {
  for (const roll of [0, 25, 50, 75, 99]) {
    const t = pickServeType([], roll, { only: LIGHTER_TYPES })
    assert.ok(LIGHTER_TYPES.includes(t), 'roll=' + roll + ' 挑出了 ' + t)
  }
})

test('权重能改变挑中的类型', () => {
  // 签按候选顺序排：各一张时 roll 60% 落到第二张（chat）；
  // 给 challenge 三倍签，同样的 roll 就还在 challenge 上。
  const only = ['challenge', 'chat']
  const light = pickServeType([], 60, { only, weights: { challenge: 1, chat: 1 } })
  const heavy = pickServeType([], 60, { only, weights: { challenge: 3, chat: 1 } })
  assert.equal(light, 'chat')
  assert.equal(heavy, 'challenge', '签多的那个更容易被挑到')
})

test('“安静一小时”和“今天别找我”都能认出来', () => {
  const at = T0
  assert.equal(mutedUntil('安静一小时', at, { tz: 'Asia/Shanghai' }), at + 3_600_000)
  assert.equal(mutedUntil('你先安静会', at, { tz: 'Asia/Shanghai' }), at + 3_600_000)
  assert.equal(mutedUntil('今天别找我了', at, { tz: 'Asia/Shanghai' }) > at, true)
  assert.equal(mutedUntil('我在改简历', at, { tz: 'Asia/Shanghai' }), 0)
  assert.equal(mutedUntil('', at, { tz: 'Asia/Shanghai' }), 0)
})

test('太长的话不算在喊安静', () => {
  const long = '安静一小时的歌单我整理好了，等会发你，先别急着走，我还没说完呢真的没说完'
  assert.equal(mutedUntil(long, T0, { tz: 'Asia/Shanghai' }), 0)
})
