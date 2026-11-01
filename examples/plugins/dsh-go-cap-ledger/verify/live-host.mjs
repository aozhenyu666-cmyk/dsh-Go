// cap-ledger 的真实宿主验证：真 cordis 4.0.5 + 真 dsh-tools 注册表。
//
//   node --import ./verify/hooks.mjs verify/live-host.mjs
//
// 验的是三件事，每件都要求**真**证据而不是断言：
//   1. ctx.provide('dshGoCapabilityLedger') 真的把服务挂到了宿主上（root.get 可见）
//   2. cap_ledger_status 真的注册进了 dsh-tools 注册表（不是桩）
//   3. 别的插件（用本服务）登记的东西真的进了同一份台账，且六态各自分得开
import { bootRealHost, CAP_LEDGER_URL } from '../../dsh-go-bili/verify/host.mjs'

const say = (s) => console.log(s)
const { root, tools } = await bootRealHost()
const capLedger = await import(CAP_LEDGER_URL)

say('=== 宿主 ===')
say('cordis 4.0.5 Context: OK')
say('tools service.register: ' + (typeof tools?.register === 'function' ? 'OK' : 'MISSING'))

say('')
say('=== ① cap-ledger 加载并 provide 统一台账服务 ===')
const handle = capLedger.apply(root.extend({}), { ledgerPath: null })
const reg = handle.registry()
say('ctx.provide("dshGoCapabilityLedger") -> ' + (reg.provided ? 'OK' : 'FAILED: ' + reg.reason))
const service = root.get('dshGoCapabilityLedger')
say('root.get 可见 -> ' + (service ? 'YES' : 'NO') + ' | 接口版本 v=' + service?.v)

say('')
say('=== ② cap_ledger_status 真注册 ===')
const view = tools.view(undefined)
say('注册表可见工具: ' + [...view.visible.keys()].join(', '))
say('cap_ledger_status 真注册: ' + (view.visible.has('cap_ledger_status') ? 'YES（不是桩）' : 'NO'))

say('')
say('=== ③ 别的插件通过服务登记（六态各自分得开）===')
// 模拟 bili 那次登记 + 一次真实执行
service.register('dsh-go-bili', { installed: true, loaded: true, toolRegistered: true })
let d = service.get('dsh-go-bili')
say('刚登记完（还没跑过）:')
say('  installed=' + d.installed + ' loaded=' + d.loaded + ' toolRegistered=' + d.toolRegistered)
say('  available=' + d.available + ' executed=' + d.executed + ' verified=' + d.verified)
say('  headline: ' + d.headline)
say('  healthy=' + d.healthy + '  ← 没跑过就必须是 false')

service.record('dsh-go-bili', { ok: true, at: Date.now() })
d = service.get('dsh-go-bili')
say('跑成功一次之后:')
say('  executed=' + d.executed + ' verified=' + d.verified + ' healthy=' + d.healthy)
say('  headline: ' + d.headline)

service.record('dsh-go-bili', { ok: false, code: 'E_TIMEOUT', message: '超过 12000 ms', at: Date.now() })
d = service.get('dsh-go-bili')
say('再失败一次:')
say('  verified=' + d.verified + ' healthy=' + d.healthy + ' health=' + d.health)
say('  headline: ' + d.headline)
say('  lastRunOk=' + d.lastRunOk)

say('')
say('=== ④ 经 dsh-tools 执行管线真调用 cap_ledger_status ===')
const def = view.visible.get('cap_ledger_status')
const value = await def.execute({}, {})
say('ok=' + value.ok + ' | summary=' + JSON.stringify(value.summary))
for (const p of value.plugins) {
  say('  ' + p.plugin + ': installed=' + p.installed + ' loaded=' + p.loaded + ' toolRegistered=' + p.toolRegistered
    + ' lastRunOk=' + (p.lastRunOk === undefined ? 'never-ran' : p.lastRunOk) + ' healthy=' + p.healthy)
}
say('给模型的文字首行: ' + String(def.output.render({}, value)[0].text).split('\n')[0])
