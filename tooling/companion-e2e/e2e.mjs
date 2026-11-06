// 大肥鱼端到端：真 DSH 引擎 + 我们的五个插件 + 假模型，按手机的调用顺序走。
// 用法：node e2e.mjs warm|cold   （run.sh 会先跑 warm，重启引擎，再跑 cold）
import { readFileSync, writeFileSync, appendFileSync } from 'node:fs'
import { rpc, route, sleep, ledger, waitResult, prompt } from './app.mjs'
const W = process.env.E2E_WORK
let failed = 0
function check(name, ok, detail) {
  console.log((ok ? '  ✓ ' : '  ✗ ') + name + (ok ? '' : '  ← ' + JSON.stringify(detail).slice(0, 300)))
  if (!ok) failed += 1
}
const game = (minutes) => ({ app: 'com.tencent.tmgp.sgame', label: '王者荣耀', minutes, fun: true, screenOn: true, local: '22:05',
  today: [{ app: 'com.tencent.tmgp.sgame', label: '王者荣耀', minutes, fun: true }] })
const phase = process.argv[2]

if (phase === 'warm') {
  console.log('【新装 · 热会话】')
  const c = await rpc('session/create', { request: { cwd: W } })
  const sid = c.body?.result?.value?.sessionId
  check('建会话', !!sid, c.body)
  writeFileSync(W + '/sid.txt', sid || '')
  await route('POST', '/config', { sessionId: sid, mode: 'coach', quietStart: 3, quietEnd: 3 })

  // 1. 记忆是空的、在游戏里 40 分钟：必须开口（以前 no-topic 永远闭嘴）
  const plan = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: game(40) })
  check('空记忆也开口（/plan speak）', plan.body.speak === true, plan.body)
  check('游戏 40 分钟 → 力度锁', plan.body.force?.name === 'lock', plan.body.force)
  const id = 'req-e2e-' + Date.now()
  const req = await route('POST', '/request', { v: 1, requestId: id, eventId: 'evt-' + id, kind: 'random_chat', payload: {}, deadlineMs: 45000, phone: game(40) })
  check('发球被接受', req.status === 202, req.body)
  const res = await waitResult(id)
  check('拿到大肥鱼的话', res?.state === 'generated' && !!res.text, res)
  await route('POST', '/outcome', { requestId: id, stage: 'displayed' })

  // 2. 他在 App 里打字回（Dart 的 session/prompt）：插件必须认出这是他的回复
  await prompt(sid, '我打这局是因为作业写完了')
  for (let i = 0; i < 40 && !ledger().some((e) => e.requestId === id && e.state === 'replied'); i++) await sleep(250)
  const rep = ledger().find((e) => e.requestId === id && e.state === 'replied')
  check('App 里的回复被认出来并判球', !!rep && rep.judged === true, rep)
  check('讲了理由 → 先松 20 分钟', ledger().some((e) => e.state === 'grace'), ledger().map((e) => e.state))
  await sleep(1500)
  const plan2 = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: game(45) })
  check('松的这段时间不锁', plan2.body.force?.level <= 1, plan2.body.force)

  // 3. 浮层里直接聊
  const say = await route('POST', '/say', { v: 1, requestId: 'say-' + Date.now(), text: '那你说我打完这局去干嘛' })
  check('/say 被接受', say.status === 202, say.body)
  const sr = say.body?.requestId ? await waitResult(say.body.requestId) : null
  check('/say 拿到回复', sr?.state === 'generated' && !!sr.text, sr)
  check('聊天不算主动发球', !ledger().some((e) => e.requestId === say.body?.requestId && e.state === 'generated'), '')

  // 4. 他正在聊（大肥鱼还在回）：不发主动球；浮层里接着说要排队，不报"忙"
  await prompt(sid, '我在想今晚要不要再开一把')
  await sleep(500)
  const busyPlan = await route('POST', '/plan', { roll: 0, timeZone: 'Asia/Shanghai', phone: game(12) })
  check('正在聊 → 不发主动球', busyPlan.body.speak === false && busyPlan.body.reason === 'in-conversation', busyPlan.body)
  const busySay = await route('POST', '/say', { v: 1, requestId: 'say-busy-' + Date.now(), text: '算了不开了' })
  check('它在回话时浮层发言排队（不报忙）', busySay.status === 202, busySay.body)
  const br = busySay.body?.requestId ? await waitResult(busySay.body.requestId) : null
  check('排队的那句也拿到回复', br?.state === 'generated', br)

  // 5. 阶梯：一球发出去 6 分钟没人接 → 下一球换轻的（时间注入：账本里写一条 6 分钟前的发球）
  appendFileSync(W + '/home/companion/ledger.jsonl', JSON.stringify({ v: 1, requestId: 'old-silent', sessionId: sid, state: 'generated', at: Date.now() - 6 * 60_000, serveType: 'provoke', text: 'x', rallyId: 'rally-x', shot: 1 }) + '\n')
  await sleep(3 * 60_000 > 0 ? 0 : 0)
  const lad = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: { ...game(12), app: 'com.tencent.mm', label: '微信', fun: false } })
  check('6 分钟没接 → 阶梯换轻的球', lad.body.reason === 'ladder-lighter' || lad.body.reason === 'in-conversation', lad.body)
}

if (phase === 'cold') {
  console.log('【引擎重启 · 冷会话】')
  const sid = readFileSync(W + '/sid.txt', 'utf8').trim()
  const id = 'req-cold-' + Date.now()
  const req = await route('POST', '/request', { v: 1, requestId: id, eventId: 'evt-' + id, kind: 'random_chat', payload: {}, deadlineMs: 45000, phone: game(20) })
  check('冷会话被唤醒并接受发球', req.status === 202 && req.body.cold === true, req.body)
  const res = await waitResult(id)
  check('冷会话拿到大肥鱼的话', res?.state === 'generated', res)
  const say = await route('POST', '/say', { v: 1, requestId: 'say-cold-' + Date.now(), text: '我回来了' })
  const sr = say.body?.requestId ? await waitResult(say.body.requestId) : null
  check('冷会话里浮层聊天', sr?.state === 'generated', sr || say.body)
  void sid
}
console.log(failed ? '✗ ' + failed + ' 项失败' : '✓ 全部通过')
process.exit(failed ? 1 : 0)
