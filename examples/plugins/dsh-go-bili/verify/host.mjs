// 真实宿主 + 真实网络验证（不是打桩）。
//
//   node --import ./verify/hooks.mjs verify/live-host.mjs
//
// 为什么需要 --import：
//   桌面版把 @deepseek-ai/dsh-tools 装在 Electron 的 app.asar 里。普通 node 子进程
//   看不见 asar（fs.existsSync → false，import → ERR_MODULE_NOT_FOUND），所以插件的
//   顶层 `import { defineTool } from '@deepseek-ai/dsh-tools'` 在裸 node 下必然失败，
//   测试也只能退化成 stub —— 那样「schema 能不能被真编译器接受」根本没验过。
//   hooks.mjs 用 node:module 的 registerHooks 把那个 specifier 指到 asar 内的真实文件；
//   然后在 Electron 的 node 里跑，asar 就读得到。
//
// 输出就是验收原文：注册日志、每次执行的耗时与错误码、统一台账的最终内容。
import { pathToFileURL } from 'node:url'

export const APP = 'C:/Users/敖震宇/AppData/Local/Programs/DeepSeek Harness/resources/app.asar/dsh/node_modules/@deepseek-ai/'
export const TOOLS_URL = pathToFileURL(APP + 'dsh-tools/lib/index.js').href
export const CORDIS_URL = pathToFileURL(APP + 'cordis/lib/index.js').href
export const CAP_LEDGER_URL = pathToFileURL('D:/code/R4/l-m2/examples/plugins/dsh-go-cap-ledger/lib/index.js').href
export const BILI_URL = pathToFileURL('D:/code/R4/l-m2/examples/plugins/dsh-go-bili/lib/index.js').href

/** 起一个真 cordis 根上下文 + 真 dsh-tools ToolRuntime。 */
export async function bootRealHost() {
  const cordis = await import(CORDIS_URL)
  const dshTools = await import(TOOLS_URL)
  const root = new cordis.Context()
  // ToolRuntime 构造时会往 systemPrompt 注册段落；给一个最小实现，不冒充完整宿主
  root.provide('systemPrompt', { tools: () => () => {}, section: () => () => {}, getSectionOrder: () => 100 })
  await root.plugin(dshTools.ToolRuntime, { mode: 'native' })
  return { cordis, dshTools, root, tools: root.get('tools') }
}
