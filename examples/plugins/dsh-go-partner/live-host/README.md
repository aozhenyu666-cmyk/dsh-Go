# 真宿主端到端（LIVE-HOST）

这套东西不是单元测试，是**真的把 DSH 引擎跑起来**，走一遍
「改 setting → 插件重新读 → 系统提示变化 → 重启后仍有效」。
R4 第三轮就是靠它抓到 4 个只有真宿主才会暴露的缺陷（见 R4-M3-CONFIG.md）。

## 它证明什么

| 断言 | 怎么证 |
|---|---|
| 宿主真的提供 `Config`（不是 undefined、不是自己塞的全局） | `GET /dsh-go/v1/plugin-config/partner` 返回 200 且带 22 个 schema 节点 |
| 表单改的值落进 profile patch | 改完直接读 `$DSH_HOME/profiles/<name>/cordis.patch.yml` |
| 插件运行时读到的是**同一个值** | 观察插件的 `entry.fiber.config`（volatile 引用现取） |
| 系统提示真的变了 | `systemPrompt.assemble({})` 里 `partner:persona` / `partner:mood` / `partner:hint` 的文本 |
| 重启后仍有效 | 杀掉进程、重新 spawn，再读一次 |
| memory / mood / tools / persona 四个开关各自生效 | 逐个改、逐个断言 |

## 怎么跑

前置：本机装了 DSH 桌面版（`DeepSeek Harness.exe`），并且有一份 `@deepseek-ai/schemastery`
能被 **Electron 以 node 身份**读到（桌面版自带，在 `resources/app.asar/dsh/node_modules` 里）。

```powershell
# 1) 搭一个临时 profile（把 partner 作为「用户安装的 bundle」挂进去，跟真装一样）
node live-host/setup.mjs --out D:\code\R4\m3-live --home D:\code\R4\m3-live\home

# 2) 跑端到端
node live-host/run.mjs --home D:\code\R4\m3-live\home --port 39551
```

输出是逐条 `PASS/FAIL`；任何一条 FAIL 都会让退出码非 0。

> `setup.mjs` 只写临时目录，**不动**你自己的 `~/.dsh`。
