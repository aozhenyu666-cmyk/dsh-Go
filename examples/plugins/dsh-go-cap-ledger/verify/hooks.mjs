// 把 '@deepseek-ai/dsh-tools' 指到 asar 内的真实文件。
// 只影响本进程的模块解析，不改仓库里任何东西。
import { registerHooks } from 'node:module'
import { pathToFileURL } from 'node:url'

const TOOLS_URL = pathToFileURL(
  'C:/Users/敖震宇/AppData/Local/Programs/DeepSeek Harness/resources/app.asar/dsh/node_modules/@deepseek-ai/dsh-tools/lib/index.js',
).href

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === '@deepseek-ai/dsh-tools') return { url: TOOLS_URL, shortCircuit: true }
    return next(specifier, context)
  },
})
