// bili.mjs 的纯逻辑测试：输入解析、网络错误码、结构规整。
// 全部用**注入的假 fetch**，不联网。
import assert from 'node:assert/strict'
import { test } from 'node:test'

import {
  BiliError, CODES, HINTS, callPeek, compact, failureOf, getJson, hhmmss,
  normalizeView, parseInput, peek, resolveFetch,
} from '../lib/bili.mjs'

const NOW = 1_700_000_000_000

/** 一条像 x/web-interface/view 的响应。 */
const VIEW_DATA = {
  bvid: 'BV1uv411q7Mv',
  aid: 243922477,
  title: '爆肝98小时！在MC中还原糖调小镇',
  desc: '相关游戏：Minecraft、しゅがてん！-sugarfull tempering\n制作名单：-落忆-',
  pic: 'http://i2.hdslb.com/bfs/archive/abc.jpg',
  duration: 314,
  pubdate: 1595203214,
  tid: 17,
  owner: { mid: 4390964, name: '落忆' },
  stat: { view: 5576839, danmaku: 128787, reply: 89521, like: 277783, coin: 40884, favorite: 127938, share: 29047 },
  pages: [
    { page: 1, part: '正片', duration: 314 },
    { page: 2, part: '花絮', duration: 90 },
  ],
}
const OK_BODY = { code: 0, message: 'OK', ttl: 1, data: VIEW_DATA }

/** 造一个假的 fetch：按 URL 决定返回什么。 */
const fakeFetch = (handler) => {
  const calls = []
  const impl = async (url, init) => {
    calls.push({ url: String(url), init })
    return handler(String(url), init, calls.length)
  }
  impl.calls = calls
  return impl
}

const jsonResponse = (body, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json' },
})

// ── 1. 输入解析 ─────────────────────────────────────────────────────────────
test('parseInput: BV 号 / av 号 / 链接 / 分P 都能认出来', () => {
  assert.deepEqual(parseInput('BV1uv411q7Mv'), { kind: 'bvid', value: 'BV1uv411q7Mv', raw: 'BV1uv411q7Mv' })
  assert.equal(parseInput('  BV1uv411q7Mv  ').value, 'BV1uv411q7Mv', '前后空格要去掉')
  assert.deepEqual(parseInput('https://www.bilibili.com/video/BV1uv411q7Mv'), {
    kind: 'bvid', value: 'BV1uv411q7Mv', raw: 'https://www.bilibili.com/video/BV1uv411q7Mv',
  })
  assert.deepEqual(parseInput('https://www.bilibili.com/video/BV1uv411q7Mv?p=2&t=30'), {
    kind: 'bvid', value: 'BV1uv411q7Mv', raw: 'https://www.bilibili.com/video/BV1uv411q7Mv?p=2&t=30', page: 2,
  })
  assert.deepEqual(parseInput('av243922477'), { kind: 'aid', value: 243922477, raw: 'av243922477' })
  assert.equal(parseInput('https://www.bilibili.com/video/av243922477').value, 243922477)
  assert.equal(parseInput('https://www.bilibili.com/video/x?aid=243922477').value, 243922477)
  assert.equal(parseInput('bv1uv411q7mv').kind, 'bvid', '小写 bv 也认（BV 前缀之外的部分大小写不敏感由正则兜住）')
})

test('parseInput: 短链单独标出来（要联网跟随跳转）', () => {
  assert.deepEqual(parseInput('b23.tv/abc123'), { kind: 'short', value: 'https://b23.tv/abc123', raw: 'b23.tv/abc123' })
  assert.equal(parseInput('https://b23.tv/abc123').value, 'https://b23.tv/abc123')
})

test('parseInput: 认不出来就抛 E_INPUT，不静默变成空查询', () => {
  for (const bad of ['', '   ', 'hello', 'https://example.com/video/123', null, undefined, 42]) {
    assert.throws(() => parseInput(bad), (error) => error instanceof BiliError && error.code === 'E_INPUT', String(bad))
  }
})

test('每个错误码都有人话和下一步提示（漏一条就等于让用户卡死）', () => {
  for (const code of Object.keys(CODES)) {
    if (code === 'OK') continue
    assert.equal(typeof HINTS[code], 'string', code + ' 缺 HINTS')
    assert.ok(HINTS[code].length > 0, code + ' 的 HINTS 是空的')
  }
})

// ── 2. 网络：四类失败各有码，不许静默 ────────────────────────────────────────
test('peek: 正常路径 —— 一次请求、结果规整成结构化 JSON', async () => {
  const f = fakeFetch(() => jsonResponse(OK_BODY))
  const r = await peek('BV1uv411q7Mv', { fetch: f, now: () => NOW })

  assert.equal(f.calls.length, 1, '只该请求一次')
  assert.match(f.calls[0].url, /^https:\/\/api\.bilibili\.com\/x\/web-interface\/view\?bvid=BV1uv411q7Mv$/)
  assert.equal(f.calls[0].init.headers['user-agent'].includes('bilibili'), false, '不带 cookie / 不冒充浏览器以外的东西')
  assert.equal(r.ok, true)
  assert.equal(r.code, 'OK')
  assert.equal(r.bvid, 'BV1uv411q7Mv')
  assert.equal(r.title, VIEW_DATA.title)
  assert.equal(r.author, '落忆')
  assert.equal(r.duration, 314)
  assert.equal(r.stats.view, 5576839)
  assert.equal(r.url, 'https://www.bilibili.com/video/BV1uv411q7Mv')
  assert.equal(r.fetchedAt, NOW)
  assert.equal(r.pubdate, new Date(1595203214 * 1000).toISOString())
  assert.equal(r.cover, 'https://i2.hdslb.com/bfs/archive/abc.jpg', 'http 封面统一升到 https')
  assert.equal(r.pages.length, 2)
})

test('peek: 分P 页码（?p=2）会带出当前那一 P', async () => {
  const f = fakeFetch(() => jsonResponse(OK_BODY))
  const r = await peek('https://www.bilibili.com/video/BV1uv411q7Mv?p=2', { fetch: f, now: () => NOW })
  assert.deepEqual(r.currentPage, { index: 2, title: '花絮', duration: 90 })
})

test('peek: 网络失败 -> E_NETWORK（带原始 message）', async () => {
  const f = fakeFetch(() => { throw new TypeError('fetch failed: getaddrinfo ENOTFOUND api.bilibili.com') })
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f }), (error) => {
    assert.ok(error instanceof BiliError)
    assert.equal(error.code, 'E_NETWORK')
    assert.match(error.message, /ENOTFOUND/)
    return true
  })
})

test('peek: 超时 -> E_TIMEOUT（不是 Network，也不是静默）', async () => {
  const f = fakeFetch(() => { throw Object.assign(new Error('timed out'), { name: 'TimeoutError' }) })
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f, timeoutMs: 50 }), (error) => error.code === 'E_TIMEOUT')
})

test('peek: 调用方取消 -> E_ABORTED（与超时分开，好排查）', async () => {
  const controller = new AbortController()
  const f = fakeFetch(() => { throw Object.assign(new Error('aborted'), { name: 'AbortError' }) })
  controller.abort()
  await assert.rejects(
    peek('BV1uv411q7Mv', { fetch: f, signal: controller.signal }),
    (error) => error.code === 'E_ABORTED',
  )
})

test('peek: HTTP 非 2xx -> E_HTTP（带状态码）', async () => {
  const f = fakeFetch(() => new Response('', { status: 503 }))
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f }), (error) => {
    assert.equal(error.code, 'E_HTTP')
    assert.match(error.message, /503/)
    return true
  })
})

test('peek: 返回的不是 JSON -> E_NOT_JSON（并带上拿到的那一小段）', async () => {
  const f = fakeFetch(() => new Response('<html>网关登录页</html>', { status: 200 }))
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f }), (error) => {
    assert.equal(error.code, 'E_NOT_JSON')
    assert.match(error.message, /网关登录页/)
    return true
  })
})

test('peek: 空响应体 -> E_NOT_JSON（不能当成 ok）', async () => {
  const f = fakeFetch(() => new Response('', { status: 200 }))
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f }), (error) => error.code === 'E_NOT_JSON')
})

test('peek: B站业务码 -404 -> E_BIZ（视频不存在不等于网络错）', async () => {
  const f = fakeFetch(() => jsonResponse({ code: -404, message: '啥都木有', ttl: 1 }))
  await assert.rejects(peek('BV1xx411c7mD', { fetch: f }), (error) => {
    assert.equal(error.code, 'E_BIZ')
    assert.match(error.message, /-404/)
    assert.match(error.message, /啥都木有/)
    return true
  })
})

test('peek: 有 code 但没有 data -> E_NO_DATA', async () => {
  const f = fakeFetch(() => jsonResponse({ code: 0, message: 'OK' }))
  await assert.rejects(peek('BV1uv411q7Mv', { fetch: f }), (error) => error.code === 'E_NO_DATA')
})

test('peek: 缺 fetch 依赖 -> E_NO_FETCH，报得明确', async () => {
  const saved = globalThis.fetch
  try {
    // 模拟「这个宿主没有 fetch」
    // eslint-disable-next-line no-global-assign
    globalThis.fetch = undefined
    await assert.rejects(peek('BV1uv411q7Mv'), (error) => {
      assert.equal(error.code, 'E_NO_FETCH')
      assert.match(error.message, /fetch/)
      return true
    })
    assert.throws(() => resolveFetch(undefined), (error) => error.code === 'E_NO_FETCH')
  } finally {
    globalThis.fetch = saved
  }
})

test('peek: 注入端口优先于全局 fetch（测试打桩才成立）', async () => {
  const saved = globalThis.fetch
  const f = fakeFetch(() => jsonResponse(OK_BODY))
  try {
    globalThis.fetch = () => { throw new Error('全局 fetch 不该被调用') }
    const r = await peek('BV1uv411q7Mv', { fetch: f, now: () => NOW })
    assert.equal(r.ok, true)
    assert.equal(f.calls.length, 1)
  } finally {
    globalThis.fetch = saved
  }
})

test('peek: 短链跟随跳转后认出 BV', async () => {
  const f = fakeFetch((url) => {
    if (url.startsWith('https://b23.tv/')) {
      return { ok: true, status: 200, url: 'https://www.bilibili.com/video/BV1uv411q7Mv?p=2', text: async () => '' }
    }
    return jsonResponse(OK_BODY)
  })
  const r = await peek('b23.tv/abc123', { fetch: f, now: () => NOW })
  assert.equal(f.calls.length, 2, '短链一次 + 详情一次')
  assert.equal(r.bvid, 'BV1uv411q7Mv')
  assert.equal(r.currentPage.index, 2, '跳转后的 ?p=2 也要认')
})

test('peek: 短链跳到非网页地址 -> E_INPUT（不乱跟随）', async () => {
  const f = fakeFetch(() => ({ ok: true, status: 200, url: 'javascript:alert(1)', text: async () => '' }))
  await assert.rejects(peek('b23.tv/abc123', { fetch: f }), (error) => error.code === 'E_INPUT')
})

// ── 3. 结果形状 ─────────────────────────────────────────────────────────────
test('normalizeView: 缺字段就不给那个键（不写 null，结果得是能声明的 JSON）', () => {
  const r = normalizeView({ bvid: 'BV1uv411q7Mv', title: 'x' }, { fetchedAt: NOW })
  assert.equal(r.ok, true)
  assert.equal(r.author, undefined)
  assert.equal(r.desc, undefined)
  assert.equal(r.pubdate, undefined, 'pubdate 是 0 / 缺失时不该给一个 1970 的时间')
  assert.deepEqual(r.stats, {})
  assert.equal(r.pages, undefined)
  assert.ok(JSON.stringify(r).length > 0)
  assert.equal(JSON.stringify(r).includes('null'), false, '结果里不该出现 null')
})

test('normalizeView: 明显不是视频数据 -> E_NO_DATA', () => {
  assert.throws(() => normalizeView(null), (e) => e.code === 'E_NO_DATA')
  assert.throws(() => normalizeView({ title: 'x' }), (e) => e.code === 'E_NO_DATA')
  assert.throws(() => normalizeView({ bvid: 'BV1uv411q7Mv' }), (e) => e.code === 'E_NO_DATA')
})

test('normalizeView: 分P 最多留 20 个（面板/卡片不超预算）', () => {
  const pages = Array.from({ length: 40 }, (_, i) => ({ page: i + 1, part: 'p' + (i + 1), duration: 10 }))
  const r = normalizeView({ bvid: 'BV1uv411q7Mv', title: 'x', pages }, { fetchedAt: NOW })
  assert.equal(r.pages.length, 20)
  assert.equal(r.pages[19].index, 20)
})

test('failureOf: 任何异常都变成带 code + hint 的结果，不裸奔', () => {
  const plain = failureOf(new Error('boom'), NOW)
  assert.equal(plain.ok, false)
  assert.equal(plain.code, 'E_INTERNAL')
  assert.match(plain.message, /boom/)
  assert.equal(typeof plain.hint, 'string')
  assert.equal(plain.fetchedAt, NOW)

  const coded = failureOf(new BiliError('E_BIZ', 'code=-404'), NOW)
  assert.equal(coded.code, 'E_BIZ')
  assert.equal(coded.hint, HINTS.E_BIZ)
})

test('callPeek: 成功和失败都是 ok 字段明确的结果，从不抛', async () => {
  const ok = await callPeek('BV1uv411q7Mv', { fetch: fakeFetch(() => jsonResponse(OK_BODY)), now: () => NOW })
  assert.equal(ok.ok, true)

  const bad = await callPeek('not a bv', { now: () => NOW })
  assert.equal(bad.ok, false)
  assert.equal(bad.code, 'E_INPUT')
  assert.equal(bad.hint, HINTS.E_INPUT)

  const netErr = await callPeek('BV1uv411q7Mv', { fetch: fakeFetch(() => { throw new Error('x') }), now: () => NOW })
  assert.equal(netErr.ok, false)
  assert.equal(netErr.code, 'E_NETWORK')
})

test('getJson: 浏览器形状的 UA / Referer；默认不带 cookie，只有显式给匿名指纹才带', async () => {
  const f = fakeFetch(() => jsonResponse({ code: 0 }))
  await getJson('https://api.bilibili.com/x/web-interface/view?bvid=BV1uv411q7Mv', { fetch: f, timeoutMs: 1000 })
  const init = f.calls[0].init
  assert.equal(typeof init.headers['user-agent'], 'string')
  // 自造 UA 会被 B站风控判 -412（真机实测）。必须是浏览器形状的。
  assert.match(init.headers['user-agent'], /^Mozilla\/5\.0 .*Chrome\//, init.headers['user-agent'])
  assert.equal(init.headers.referer, 'https://www.bilibili.com/')
  assert.equal('cookie' in init.headers, false, '默认不登录、不带 cookie')

  // 显式传入的只有匿名设备号（不是账号 cookie）
  const g = fakeFetch(() => jsonResponse({ code: 0 }))
  await getJson('https://x', { fetch: g, timeoutMs: 1000, cookie: 'buvid3=abc' })
  assert.equal(g.calls[0].init.headers.cookie, 'buvid3=abc')
})

// ── 4. 展示小工具 ───────────────────────────────────────────────────────────
test('compact / hhmmss：大数与时长', () => {
  assert.equal(compact(999), '999')
  assert.equal(compact(5576839), '557.7万')
  assert.equal(compact(120000000), '1.2亿')
  assert.equal(compact(12345), '1.2万')
  assert.equal(compact(undefined), '?')
  assert.equal(hhmmss(314), '5:14')
  assert.equal(hhmmss(3725), '1:02:05')
  assert.equal(hhmmss(undefined), '?')
})

// ── 5. -412 风控：真实网络才暴露的那条路径 ────────────────────────────────────
// 实测（2026-11-01，本机直连 api.bilibili.com）：
//   无 cookie 的 x/web-interface/view -> HTTP 200 + {"code":-412,"message":"request was banned"}
//   自造 UA "dsh-go-bili-peek/0.1"    -> 同样 -412（与 BV 号无关）
//   带 finger/spi 发的匿名 buvid3      -> 立刻 {"code":0}
// 下面这几条把这个行为钉住，免得以后有人把 fallback 删掉还以为单测是绿的。
const bannedResponse = () => jsonResponse({ code: -412, message: 'request was banned', ttl: 1 })
const spiResponse = () => jsonResponse({ code: 0, message: 'ok', data: { b_3: 'B3-ANON', b_4: 'B4-ANON' } })

test('peek: 第一次被 -412 挡了 -> 取匿名指纹重试一次就成功', async () => {
  let viewHits = 0
  const f = fakeFetch((url, init) => {
    if (url.includes('/finger/spi')) return spiResponse()
    viewHits += 1
    const cookie = init?.headers?.cookie
    return cookie === undefined ? bannedResponse() : jsonResponse(OK_BODY)
  })

  const value = await peek('BV1uv411q7Mv', { fetch: f, now: () => NOW, anonymousCookie: true })
  assert.equal(value.ok, true)
  assert.equal(value.bvid, 'BV1uv411q7Mv')
  assert.equal(viewHits, 2, '被挡一次、带指纹重试一次')
  const spi = f.calls.find((c) => c.url.includes('/finger/spi'))
  assert.ok(spi, '应该去取了匿名设备号')
  const retryCall = f.calls.filter((c) => c.url.includes('web-interface/view'))[1]
  assert.match(String(retryCall.init.headers.cookie), /buvid3=/, '重试必须带匿名 buvid3')
  assert.equal('buvid4' in retryCall.init.headers ? true : /buvid4/.test(retryCall.init.headers.cookie), true)
})

test('peek: 带了指纹还是 -412 -> E_BANNED（不是 E_BIZ，也不是怪 BV 号）', async () => {
  const f = fakeFetch((url) => (url.includes('/finger/spi') ? spiResponse() : bannedResponse()))
  const value = await callPeek('BV1uv411q7Mv', { fetch: f, now: () => NOW, anonymousCookie: true })
  assert.equal(value.ok, false)
  assert.equal(value.code, 'E_BANNED')
  assert.match(value.hint, /网络|IP|风控/)
  assert.ok(CODES.E_BANNED.length > 0)
})

test('peek: 正常路径不该多打请求（懒补，不是每次都取指纹）', async () => {
  const f = fakeFetch((url) => (url.includes('/finger/spi') ? spiResponse() : jsonResponse(OK_BODY)))
  await peek('BV1uv411q7Mv', { fetch: f, now: () => NOW, anonymousCookie: true })
  assert.equal(f.calls.length, 1, '一次成功就只有一个请求')
  assert.equal(f.calls.some((c) => c.url.includes('/finger/spi')), false, '没被挡就不该去取指纹')
})

test('peek: anonymousCookie=false 时一次都不去打指纹接口（可预测的网络行为）', async () => {
  const f = fakeFetch((url) => (url.includes('/finger/spi') ? spiResponse() : bannedResponse()))
  const value = await callPeek('BV1uv411q7Mv', { fetch: f, now: () => NOW, anonymousCookie: false })
  assert.equal(value.code, 'E_BANNED')
  assert.equal(f.calls.some((c) => c.url.includes('/finger/spi')), false)
})

test('peek: 指纹接口自己挂了也不影响主流程的错误归类', async () => {
  const f = fakeFetch((url) => {
    if (url.includes('/finger/spi')) throw new TypeError('spi down')
    return bannedResponse()
  })
  const value = await callPeek('BV1uv411q7Mv', { fetch: f, now: () => NOW, anonymousCookie: true })
  assert.equal(value.code, 'E_BANNED', '被挡还是被挡，别把手指纹的失败当成视频不存在')
})
