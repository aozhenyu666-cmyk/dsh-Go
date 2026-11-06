// 功能验收：每一个做过的插件功能，在真引擎上按手机的调用方式走一遍，核对效果和这一球真正带进 prompt 的内容。
import { readFileSync, writeFileSync, mkdirSync, appendFileSync, rmSync } from 'node:fs'
import { DatabaseSync } from 'node:sqlite'
import { rpc, route, sleep, ledger, waitResult, prompt } from './app.mjs'
const W = process.env.E2E_WORK
const H = W + '/home'
let failed = 0
function check(name, ok, detail) {
  console.log((ok ? '  ✓ ' : '  ✗ ') + name + (ok ? '' : '  ← ' + (typeof detail === 'string' ? detail : JSON.stringify(detail)).slice(0, 400)))
  if (!ok) failed += 1
}
async function waitFor(fn, ms = 15000) { const end = Date.now() + ms; while (Date.now() < end) { const v = fn(); if (v) return v; await sleep(200) } return null }
function prompts() { try { return readFileSync(W + '/prompts.jsonl', 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l)) } catch { return [] } }
const lastServePrompt = () => prompts().filter((p) => p.kind === 'serve').pop()?.text || ''
async function newSession(cfg = {}) {
  const c = await rpc('session/create', { request: { cwd: W } })
  const sid = c.body?.result?.value?.sessionId
  await route('POST', '/config', { sessionId: sid, mode: 'partner', drills: false, muteUntil: 0, quietStart: 3, quietEnd: 3, minGapMs: 60_000, ...cfg })
  return sid
}
async function serve(phone, label) {
  const id = 'req-' + label + '-' + Date.now()
  const r = await route('POST', '/request', { v: 1, requestId: id, eventId: 'evt-' + id, kind: 'random_chat', payload: {}, deadlineMs: 45000, phone })
  const res = r.status === 202 ? await waitResult(id) : null
  return { id, status: r.status, body: r.body, res, accepted: ledger().find((e) => e.requestId === id && e.state === 'accepted') }
}
async function say(sid, text) {
  const before = ledger().length
  await prompt(sid, text)
  // 等这句话的那一轮跑完（假模型 1.5 秒）再往下走
  await waitFor(() => readFileSync(W + '/llm.log', 'utf8').includes(text.slice(0, 8)), 10000)
  await sleep(2200)
  return ledger().slice(before)
}
/** 每段开始前清掉按"人"算的状态（账本、大脑、脾气）：额度、宽限、糊弄连击都是跨会话的，不清会互相干扰。 */
function reset() {
  for (const f of ['ledger.jsonl', 'brain.json', 'temper.json']) rmSync(H + '/companion/' + f, { force: true })
}
const app = (pkg, label, minutes, fun, extra = {}) => ({ app: pkg, label, minutes, fun, screenOn: true, local: '22:10', today: fun ? [{ app: pkg, label, minutes, fun }] : [], ...extra })
const bili = (m) => app('tv.danmaku.bili', '哔哩哔哩', m, true)
const game = (m) => app('com.tencent.tmgp.sgame', '王者荣耀', m, true)
const wechat = () => app('com.tencent.mm', '微信', 1, false)

// ---------------------------------------------------------------- A. 一球里到底带了什么
console.log('【A. 发球内容】')
reset()
let sid = await newSession()
{
  // 记忆：往记忆库钉一条事实（用记忆插件自己的表结构）
  const db = new DatabaseSync(H + '/fish-memory/fish-memory.sqlite')
  const cols = db.prepare('PRAGMA table_info(facts)').all().map((c) => c.name)
  const row = { id: 'fact_accept_cat', scope: 'global', text: '我养的猫叫毛毛（Maomao）。', importance: 5, pinned: 1, status: 'active', created_at: Date.now(), updated_at: Date.now(), key: '我的猫.名字', source: 'accept', hits: 0 }
  const use = cols.filter((c) => c in row)
  db.prepare(`INSERT OR REPLACE INTO facts (${use.join(',')}) VALUES (${use.map(() => '?').join(',')})`).run(...use.map((c) => row[c]))
  db.close()
  // 心情
  mkdirSync(H + '/feiyu-mood', { recursive: true })
  writeFileSync(H + '/feiyu-mood/state.json', JSON.stringify({ moods: { main: { mood: 41 } }, lastActive: 'main' }))
}
let s = await serve(bili(25), 'content')
check('发球成功', s.res?.state === 'generated', s.body)
let p = lastServePrompt()
check('带上现在开着的 App 和时长', /现在开着：哔哩哔哩，已经开了 25 分钟/.test(p), p.slice(0, 200))
check('不暴露包名', !/tv\.danmaku/.test(p), '')
check('带上记忆里的事实（毛毛）', /毛毛/.test(p), p)
check('带上心情（只影响语气）', /心情值 41\/100/.test(p), '')
check('关系库人格卡进了 prompt（底线）', /你的底线（绝不做）：.*不撒谎/.test(p), p.match(/你的.{0,80}/g))
check('有这一球的脸色', /这一球的脸色：/.test(p), '')
check('约定回话那一轮先听懂理由', /先把理由弄懂/.test(p), '')
check('做题默认关：不出题', !/思维题/.test(p) && s.accepted?.serveType !== 'drill', s.accepted)
check('账本记下水位/脸色', Number.isFinite(s.accepted?.tide) && !!s.accepted?.face, s.accepted)

// ---------------------------------------------------------------- B. 一句话指令
console.log('【B. 一句话指令】')
await say(sid, '安静一小时')
let pl = await route('POST', '/plan', { roll: 0, timeZone: 'Asia/Shanghai', phone: bili(30) })
check('"安静一小时" → /plan 不开口（muted）', pl.body.reason === 'muted', pl.body)
await route('POST', '/config', { muteUntil: 0 })
await say(sid, '切到严格模式')
let st = await route('GET', '/status')
check('"切到严格模式" → 教练模式', st.body.config?.mode === 'coach', st.body.config)
await say(sid, '温柔点')
st = await route('GET', '/status')
check('"温柔点" → 伙伴模式', st.body.config?.mode === 'partner', st.body.config)
await say(sid, '开始做题')
st = await route('GET', '/status')
check('"开始做题" → 做题打开', st.body.config?.drills === true, st.body.config)

// ---------------------------------------------------------------- C. 做题与"说他"
console.log('【C. 做题与说他】')
reset()
await route('POST', '/config', { mode: 'coach' })
let d1 = await serve(game(35), 'drill1')
p = lastServePrompt()
check('在游戏里 + 做题开 + 要锁 → 这一球是思维题', d1.accepted?.serveType === 'drill' && /思维题/.test(p), d1.accepted || d1.body)
check('思维题带合格线', /合格的回答必须是/.test(p), '')
const drill = d1.accepted?.drill
await say(sid, '挺久的吧')
const vr = ledger().find((e) => e.requestId === d1.id && e.state === 'replied')
check('糊弄的回答按合格线判成没过（brief）', vr?.verdict === 'brief', vr)
const judgeIn = prompts().filter((x) => x.kind === 'judge').pop()?.text || ''
check('判球时带上了合格线', /合格的回答必须是/.test(judgeIn), judgeIn.slice(0, 200))
let d2 = await serve(game(38), 'drill2')
p = lastServePrompt()
check('下一球先说他（引用他的原话、没过线）', /挺久的吧.*没过线/s.test(p), p.slice(0, 300))
check('同一类题重问', d2.accepted?.drill === drill, { before: drill, after: d2.accepted?.drill })
await say(sid, '别出题了')
st = await route('GET', '/status')
check('"别出题了" → 做题关闭', st.body.config?.drills === false, st.body.config)

// ---------------------------------------------------------------- D. 大脑：拉回来没有
console.log('【D. 大脑】')
reset()
sid = await newSession({ mode: 'partner' })
const pull = await serve(game(20), 'pull')
check('发球（在游戏里）', pull.res?.state === 'generated', pull.body)
console.log('    …等 31 秒（发出去 30 秒内离开不算数）')
await sleep(31_000)
await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
const pulled = ledger().filter((e) => e.state === 'pulled').pop()
check('切到微信 → 记一次"拉回来了"', pulled?.pulled === true, pulled)
const brain = JSON.parse(readFileSync(H + '/companion/brain.json', 'utf8'))
check('这张脸记了一分', Object.values(brain.faces || {}).some((c) => c.win >= 1), brain.faces)

// ---------------------------------------------------------------- E. 阶梯全程（时间注入）
console.log('【E. 阶梯】')
reset()
sid = await newSession({ mode: 'partner', minGapMs: 30 * 60_000 })
const inject = (rows) => appendFileSync(H + '/companion/ledger.jsonl', rows.map((r) => JSON.stringify({ v: 1, sessionId: sid, state: 'generated', text: 'x', serveType: 'provoke', ...r })).join('\n') + '\n')
inject([{ requestId: sid + '-a', at: Date.now() - 60_000, rallyId: 'r-' + sid }])
pl = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
check('刚发 1 分钟：闹钟定在 5 分钟那一级（不是 45 分钟冷却）', pl.body.reason === 'ladder-wait' && Math.abs(pl.body.nextCheckAt - (Date.now() + 4 * 60_000)) < 15_000, pl.body)
reset()
sid = await newSession({ mode: 'partner' })
inject([{ requestId: sid + '-a', at: Date.now() - 6 * 60_000 }])
pl = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
check('6 分钟没接 → 换轻球', pl.body.speak && pl.body.reason === 'ladder-lighter', pl.body)
const lighter = await serve(wechat(), 'lighter')
p = lastServePrompt()
check('轻球：类型在小挑战/闲聊里，prompt 认"没有回音"', ['challenge', 'chat'].includes(lighter.accepted?.serveType) && /没有回音/.test(p), lighter.accepted)
check('账本记阶梯级别 lighter', lighter.accepted?.silence === 'lighter', lighter.accepted)
reset()
sid = await newSession({ mode: 'partner' })
inject([{ requestId: sid + '-a', at: Date.now() - 16 * 60_000 }, { requestId: sid + '-b', at: Date.now() - 11 * 60_000, silence: 'lighter' }])
pl = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
check('第一球后 15 分钟还没接 → 换渠道', pl.body.reason === 'ladder-channel', pl.body)
inject([{ requestId: sid + '-c', at: Date.now() - 60_000, silence: 'channel' }])
pl = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
check('三球都没接 → 停下，3 小时后再看', pl.body.reason === 'no-take' && pl.body.nextCheckAt > Date.now() + 2.9 * 3_600_000, pl.body)

// ---------------------------------------------------------------- F. 水位、节奏、力度
console.log('【F. 水位与力度】')
reset()
sid = await newSession({ mode: 'coach', minGapMs: 30 * 60_000 })
const pClear = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: wechat() })
const pTrap = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: game(70) })
check('打游戏 70 分钟（严格）→ 赶出去', pTrap.body.force?.name === 'home', pTrap.body.force)
check('陷住时一分钟内再看', pTrap.body.nextCheckAt <= Date.now() + 61_000, pTrap.body)
check('在微信里 → 力度"说"、水位清醒', pClear.body.force?.name === 'talk' && pClear.body.tide?.band === 'clear', pClear.body)
await route('POST', '/config', { mode: 'partner' })
const pWarm = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: game(35) })
check('温和模式 35 分钟 → 还不锁（屏）', pWarm.body.force?.name === 'screen', pWarm.body.force)
await route('POST', '/config', { control: false, mode: 'coach' })
const pNoCtl = await route('POST', '/plan', { roll: 100, timeZone: 'Asia/Shanghai', phone: game(70) })
check('关掉控机权限 → 最多到浮层', pNoCtl.body.force?.name === 'screen', pNoCtl.body.force)
await route('POST', '/config', { control: true })

// ---------------------------------------------------------------- G. 时区与安静时段
console.log('【G. 时区】')
const shHour = Number(new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Shanghai', hour: 'numeric', hourCycle: 'h23' }).format(new Date()))
sid = await newSession({ quietStart: shHour, quietEnd: (shHour + 1) % 24 })
pl = await route('POST', '/plan', { roll: 0, timeZone: 'Asia/Shanghai', phone: wechat() })
check('按手机时区（上海 ' + shHour + ' 点）算安静时段', pl.body.reason === 'quiet', pl.body)
pl = await route('POST', '/plan', { roll: 0, timeZone: 'America/New_York', phone: wechat() })
check('换个时区就不在安静时段', pl.body.reason !== 'quiet', pl.body)

// ---------------------------------------------------------------- H. 设置页要的数据
console.log('【H. /status】')
st = await route('GET', '/status')
check('/status 有人格卡（关系库打底）', /不撒谎/.test(JSON.stringify(st.body.config?.personaEffective || st.body.personaEffective || '')), Object.keys(st.body))
await serve(wechat(), 'status')
st = await route('GET', '/status')
check('/status 有脾气底色（发过一球之后）', Number.isFinite(st.body.config?.temper?.edge), st.body.config?.temper)
check('/status 有大脑判断列表', Array.isArray(st.body.config?.beliefs), st.body.config?.beliefs)

console.log(failed ? '✗ ' + failed + ' 项失败' : '✓ 全部通过')
process.exit(failed ? 1 : 0)
