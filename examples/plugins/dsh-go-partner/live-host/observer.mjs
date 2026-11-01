/**
 * LIVE-HOST 观察器：挂在真宿主里，把「插件运行时到底读到了什么」暴露成只读路由。
 *
 * 只用公开服务（loader / configEditor / systemPrompt / webServer），
 * 不替换任何内部对象 —— 所以它看到的就是插件自己看到的。
 *
 * 路由：
 *   GET  /m3/state   插件的 entry 状态、运行时读到的 live 值、profile patch 里的 raw 值
 *   GET  /m3/prompt  真的拼一遍系统提示，只回 partner:* 那几段 + 工具名
 *   POST /m3/edit    走 ConfigEditor.edit()（**这就是原生设置表单最终调的那个 API**）
 */
export const name = 'm3-observer'
export const inject = ['loader', 'configEditor', 'systemPrompt']

const json = (res, status, body) => {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' })
  res.end(JSON.stringify(body))
}

export async function apply(ctx) {
  const findEntry = (id) => [...ctx.loader.entries()].find((e) => e.options.id === id)
  const read = (v) => (v && typeof v.get === 'function' ? v.get() : v)

  const state = () => {
    const entry = findEntry('partner')
    if (!entry) return { found: false }
    const cfg = entry.fiber?.config
    return {
      found: true,
      fiberState: entry.fiber?.state ?? null,
      hasConfigSchema: Boolean(entry.fiber?.runtime?.Config),
      // 运行时真实能读到的值（volatile 是引用，这里现取）
      live: cfg ? {
        style: read(cfg.persona?.style),
        personaEnabled: read(cfg.persona?.enabled),
        memoryEnabled: read(cfg.memory?.enabled),
        moodEnabled: read(cfg.mood?.enabled),
        toolsEnabled: read(cfg.tools?.enabled),
      } : null,
      // profile patch 里落盘的原始值
      raw: entry.options.config ?? null,
    }
  }

  ctx.inject(['webServer'], (sc) => {
    sc.webServer.register({ kind: 'exact', path: '/m3/state', handler: async (req, res) => { json(res, 200, state()); return true } })

    sc.webServer.register({
      kind: 'exact',
      path: '/m3/prompt',
      handler: async (req, res) => {
        try {
          const assembly = await ctx.systemPrompt.assemble({})
          const mine = (list) => (list || []).filter((s) => /^partner:/.test(s.name))
            .map((s) => ({ name: s.name, text: String(s.text || '') }))
          json(res, 200, {
            sections: mine(assembly.sections),
            contexts: mine(assembly.contexts),
            tools: (assembly.tools || []).map((t) => t.name),
          })
        } catch (error) { json(res, 500, { error: String(error && error.message) }) }
        return true
      },
    })

    sc.webServer.register({
      kind: 'exact',
      path: '/m3/edit',
      handler: async (req, res) => {
        const chunks = []
        for await (const c of req) chunks.push(c)
        let input = {}
        try { input = JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}') } catch {}
        const entry = findEntry('partner')
        if (!entry) { json(res, 404, { ok: false, error: 'no partner entry' }); return true }
        try {
          // ★ 和原生设置表单同一条路：ConfigEditor.edit() 校验 → 写 profile patch → Loader 协调
          await ctx.configEditor.edit(entry, (raw) => ({ ...raw, ...input }))
          json(res, 200, { ok: true, after: state() })
        } catch (error) {
          json(res, 500, { ok: false, error: String(error && error.message), after: state() })
        }
        return true
      },
    })
  })
}
