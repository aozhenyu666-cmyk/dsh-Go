# dsh-go-companion

主动互动的**唯一决策与回合服务**。Android 负责唤醒和展示；这里决定“现在说不说、说什么、说给谁”，
并把每一步写进账本。

## 它做什么

1. 接收手机端的一次主动事件（`POST /request`），语义与旧 `dsh-go-proactive` 一致：
   `accepted → claimed → generated | failed | cancelled`。
2. **冷会话**：会话不活着时先 `sessionController.resolveAgent(sessionId)`，而不是直接拒绝；
   失败也不会新建会话。
3. **话题**：只读 `fish-memory.sqlite`，从「未完成话题（topics）→ 最近共同经历（episodes）」里选一个；
   `facts` 只取钉住/重要，最多 5 条做背景。
4. **prompt**：一个人格、一段话题、少量背景；明确禁止提“事件/系统/主动”、禁止工具、禁止“今天有什么计划”。
5. **账本**：`$DSH_HOME/companion/ledger.jsonl`，`requestId` 贯穿，记录每一步状态。
6. **本地决策**（`POST /plan`）：开关、安静时段、日上限、最小间隔、掷骰、话题选择；零模型。

## 路由（前缀 `/dsh-go-companion/v1`）

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/request` | 原生闹钟判定“到点”后调用；返回 202 accepted |
| GET | `/result?requestId&waitMs` | 长轮询（≤25s） |
| POST | `/cancel` | 撤回；晚到的文本不再交出 |
| POST | `/plan` | 本地决策，返回 `speak/reason/topic`；未命中不消耗模型 |
| POST | `/outcome` | `delivered / displayed / replied / substantive / dismissed` 回执 |
| GET | `/status` | 配置、活会话、计数、今日统计、最近 20 条账本、记忆库是否存在 |
| POST | `/config` | `sessionId`、开关、安静时段、日上限、间隔、掷骰线、冷会话开关、称呼 |

鉴权复用 `connection.requestRejection(req)`（与 `/api` 同等凭据）。

## 配置

`$DSH_HOME/companion/config.json`

```json
{
  "enabled": true,
  "sessionId": "session-…",
  "quietStart": 1,
  "quietEnd": 8,
  "dailyMax": 6,
  "minGapMs": 1800000,
  "diceThreshold": 60,
  "cooldownMs": 86400000,
  "allowColdSession": true,
  "owner": "主人",
  "self": "大肥鱼"
}
```

旧 `dsh-go-proactive` 设置过 `sessionId` 时，第一次加载会自动迁过来。

## P1.2：话题花园 / 跟进 / 连续性

话题不再只是“从记忆里捞一条”，而是 `$DSH_HOME/companion/topics.json` 里一份独立的清单：

- **生命周期**：`candidate → active → paused → 重新唤起 → done`；记忆库仍是事实/未完成话题的真源，只读。
- **来源**：`memory.topic`（未完成）、`memory.episode`（最近共同经历）、
  `relationship.commitment`（到期承诺）、`conversation`（正常聊天里发现）、`agent`（模型主动记下）。
- **生成类型**：`continue`（延续）、`share`（分享/吐槽）、`explore`（一起想）；
  连续两次追问后会优先换分享/探索，避免变成问卷。
- **去重**：标题 bigram 相似度 ≥ 0.7 合并；同一记忆话题 id 复用。
- **评分**：类型权重 + 兴趣 + 新鲜度 − 尝试次数 − 同类型疲劳；冷却、下次可问时间都参与过滤。
- **不强行开口**：`nextTopic()` 返回 null 就 `409 no-topic`，不发空泛问候。
- **跟进**：`substantive` 继续；`brief` 2h 后换轻的；`avoid` 12h；`refuse` 结束；
  `none` 最多两次（4h / 一周），之后开新周期。
- **连续性**：生成后保存 `lastSummary`，下次 prompt 带“上次聊到…”；
  用户换话题时旧话题保留为 `paused`，不丢。

正常聊天里，模型可以调用 `companion_topic` 工具（`add/list/done/pause`）把
“以后还想聊的事”放进花园；主动回合内工具仍被硬拦。

## 部署

作为内置插件放在 APK assets，由 `BuiltinPluginGuest` 每次启动铺到
`/opt/dsh-app/plugins/dsh-go-companion/`。原生 `AgentWire.PREFIX` 指向本插件；
旧 `dsh-go-proactive` 仍随 runtime 存在，但不再被调用。

## 验证

```bash
cd app/assets/engine/plugins/dsh-go-companion && node --test test/*.test.mjs   # 41 项
```

真机：设置 → 手机操控 → 主动搭话 → 开启（会自动选一个空闲会话）→「现在试一次」；
日志应出现 `[companion] loaded; session=…` 与 `[companion] routes /dsh-go-companion/v1`，
账本出现 `accepted → claimed → generated`。

## 边界

- 不读屏幕内容、不截图、不联网到外部服务；只读本机 SQLite。
- `generated` 只代表模型出了文字，不代表用户看到；送达/展示/回应由 `/outcome` 记录。
- 主动回合内禁用一切工具（`tools/pre-execute` 硬拦）。
