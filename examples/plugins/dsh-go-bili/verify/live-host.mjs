// 真跑：真 cordis + 真 dsh-tools 注册表 + 真 api.bilibili.com。
//
//   node --import ./verify/hooks.mjs verify/live-host.mjs
//
// 这个文件和 test/*.test.mjs 的分工：
//   test/*.test.mjs      fetch 打桩 —— 验逻辑分支、错误码、视图预算，不联网
//   verify/live-host.mjs 真联网   —— 验「真注册 / 真调到 / 真拿到数据 / 真实耗时」
// 两边都要跑；只跑打桩测试就宣称「插件能用」是过度声明。
import { bootRealHost, CAP_LEDGER_URL, BILI_URL } from './host.mjs'

const out = []
const say = (s) => { console.log(s); out.push(s) }

const started = Date.now()
const { dshTools, root, tools } = await bootRealHost()
say('=== 宿主 ===')
say('cordis 4.0.5 Context: OK')
say('dsh-tools ' + (typeof dshTools.defineTool === 'function' ? 'defineTool OK' : 'MISSING'))
say('tools service.register: ' + (typeof tools?.register === 'function' ? 'OK' : 'MISSING'))

const capLedger = await import(CAP_LEDGER_URL)
const bili = await import(BILI_URL)

// ① 统一台账：cap-ledger provide 服务
say('')
say('=== ① cap-ledger 加载 ===')
const capHandle = capLedger.apply(root.extend({}), { ledgerPath: null })
const reg = capHandle.registry()
say('ctx.provide("dshGoCapabilityLedger") -> ' + (reg.provided ? 'OK' : 'FAILED: ' + reg.reason))
say('root.get 可见 -> ' + (root.get('dshGoCapabilityLedger') ? 'YES' : 'NO'))

// ② bili 真注册
say('')
say('=== ② bili 加载（真 dsh-tools 注册表）===')
const biliHandle = bili.apply(root.extend({}), { ledgerPath: null })
say('toolRegistered = ' + biliHandle.toolRegistered())
if (biliHandle.registerError() !== undefined) say('registerError = ' + biliHandle.registerError())
const view = tools.view(undefined)
say('注册表可见工具: ' + [...view.visible.keys()].join(', '))
say('peek_bili_video 真注册: ' + (view.visible.has('peek_bili_video') ? 'YES（不是桩）' : 'NO'))
say('统一台账接上: ' + JSON.stringify(biliHandle.unified()))

// ③ 真网络
say('')
say('=== ③ 真实网络执行 ===')
for (const [label, input] of [
  ['公开 BV', 'BV1uv411q7Mv'],
  ['视频 URL', 'https://www.bilibili.com/video/BV1uv411q7Mv'],
  ['格式对但不存在', 'BV1zz411c7mZ'],
  ['认不出的输入', '这句话没有视频'],
]) {
  const t = Date.now()
  const v = await biliHandle.peek(input)
  const ms = Date.now() - t
  if (v.ok) {
    say(`[${label}] ok=true code=${v.code} 耗时=${ms}ms`)
    say('  标题: ' + v.title)
    say('  UP: ' + v.author + ' | 播放: ' + v.stats?.view + ' | 点赞: ' + v.stats?.like + ' | 弹幕: ' + v.stats?.danmaku)
    say('  时长: ' + v.duration + 's | 发布: ' + v.pubdate + ' | 分区: ' + v.tid)
    say('  bvid=' + v.bvid + ' aid=' + v.aid)
  } else {
    say(`[${label}] ok=false code=${v.code} 耗时=${ms}ms`)
    say('  message: ' + v.message)
    say('  hint: ' + v.hint)
  }
}

// ④ 统一台账最终态
say('')
say('=== ④ 统一台账（一份，两个插件都写它）===')
const unified = root.get('dshGoCapabilityLedger')
say('summary: ' + JSON.stringify(unified.summary()))
for (const [name, entry] of Object.entries(unified.all().plugins)) {
  const d = unified.get(name)
  say(`  ${name}`)
  say(`    installed=${d.installed} loaded=${d.loaded} toolRegistered=${d.toolRegistered}`)
  say(`    available=${d.available} executed=${d.executed} verified=${d.verified}`)
  say(`    runs=${entry.runs} fails=${entry.fails} headline="${d.headline}"`)
}

// ⑤ 经 dsh-tools 执行管线
say('')
say('=== ⑤ 经 dsh-tools 执行管线真调用 ===')
const def = view.visible.get('peek_bili_video')
const t5 = Date.now()
const result = await def.execute({ id: 'BV1uv411q7Mv' }, { signal: AbortSignal.timeout(30000) })
say('execute 耗时: ' + (Date.now() - t5) + 'ms | ok=' + result.ok + ' code=' + result.code)
say('给模型的文字首行: ' + String(def.output.render({}, result)[0].text).split('\n')[0])
const meta = def.output.presentationMeta({ id: 'x' }, result)
say('工具卡: 键=' + Object.keys(meta).join(',') + ' 字节=' + Buffer.byteLength(JSON.stringify(meta)) + ' 根类型=' + meta['dsh-go/view']?.type)

say('')
say('总耗时: ' + (Date.now() - started) + 'ms')
