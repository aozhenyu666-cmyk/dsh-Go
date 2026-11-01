# R4-PHASE4-ACCEPTANCE-REPORT

**第四阶段 · 逻辑缺口闭合、崩溃一致性与真实宿主兼容**

- 基线：`integration/r4-logic-closure-2026-11-01` @ `868dc330d8495b7d41c887cd268329aad5e3ffb5`（开工前核对远端一致）
- 工作分支：`fix/r4-phase4-2026-11-01` @ **`9e410c1f023e8e0b7d5a608db57036f5ae54e388`**（已推 origin，非 force）
- 未动：`main` / R3 发布版 / 上一轮集成分支 / 四个原始研发分支（SHA 见 §7）
- 17 个 worktree 全部保留

---

## 1. 一句话结论

**五个 P0 里四个已完整修复（P0-1 / P0-2 / P0-3 / P0-5），P0-4 做到检测层（PARTIAL）。
阶段 A 的「仓库内可复现」已达成。没有任何 FAIL。真机仍为 NOT_TESTED —— adb 0 台。**

---

## 2. 五个 P0 的状态

| 编号 | 缺陷 | 状态 | 一句话 |
|---|---|---|---|
| **P0-1** | 事件永久悬挂 → 所有目标 APP 放行 | **PASS**（代码级） | 运行时用单调时钟挂一个定时器：5s 无证明 → NOT_SHOWN；10min → BLOCKED/page_ttl **且不放行** |
| **P0-2** | 结束后不重判前台 | **PASS**（代码级） | 六条结束路径全部要求宿主重读前台 |
| **P0-3** | NOT_SHOWN 仍扣冷却与额度 | **PASS** | 两条路径都退还；`onUnavailable` 还原旧值，`recover` 只退本次 |
| **P0-4** | guard/ledger 跨文件写入 | **PARTIAL** | 不一致**能检出**（`splitWrite`），但写入仍是两次 rename |
| **P0-5** | 未展示页面可走任何门 | **PASS** | 四扇门 + 两个动作全部要求展示证明；训练停留条件不再短路 |

---

## 3. 架构审查报告的核对结论

**不盲抄。逐条回代码确认：报告列的 5 个 P0 全部成立。**

| ID | 我核对的位置 | 成立 |
|---|---|---|
| P0-1 | 页面五条不结算路径 + `onForeground` 的 `Allow(already_open)` | 是 |
| P0-2 | 结算后无任何前台重判 | 是 |
| P0-3 | `Intercept.kt:468` 触发即盖章；`onUnavailable` 不回滚 | 是 |
| P0-4 | 两个 `AtomicJsonFile` 各自原子、合起来不原子 | 是 |
| P0-5 | `onReleased` 四个门无一检查 `openShownAt` | 是 |

**报告没点透、我补出来的一条**：训练停留条件是

```kotlin
if (config.trainingMs > 0L && shownAt != 0L && now - shownAt < config.trainingMs)
```

`shownAt == 0` 时整条件短路 → **未展示反而是最快通过训练的路径**。
这不只是「忽略证明」，是**把证明用反了**。

**报告里我不同意的部分**：报告把 191 当作既定事实引用。实际是 **190**（见 CHANGELOG A-2）。
那是我的错，不是报告的错——但它照抄了我的数字。

---

## 4. 开源参考的采用（详见 `evidence/phase4/OPEN-SOURCE-RESEARCH.md`）

| 项目 | 许可证 | 采用方式 |
|---|---|---|
| **Monk** | **Apache-2.0 / MIT 双许可**（`LICENSE-APACHE` 9723B、`LICENSE-MIT` 1072B；GitHub API 只报 Apache，以仓库文件为准） | **只借鉴设计，不复制代码** |
| **Nudge** | **GPL-3.0**（全文 35149B 已存证） | **一行代码都不进仓库**，只把它的真实问题转成我们自己的测试清单 |

Monk 具体借鉴的五点：`ForegroundGate` 的 lastForeground/pending/reevaluate 三态；
`InterceptRegistry` 的会话与视图解耦；`InterceptGate` 的 token 守卫；
`noteLaunchMiss/preferOverlay` 的启动失败计数；「定时器跑在 uptime 上，所以锁屏期间不会白等到期」。

**洁净室证据（可复核）**：

```
grep -ril 于仓库（*.kt/*.kts/*.java/*.dart）：
  astraedus 0 · OverlayLifecycle 0 · BlockLaunchGuard 0 · CooldownGate 0 · EmergencyPass 0
  mdportnov 0 · ForegroundGate 0 · InterceptRegistry 0 · InterceptGate 0 · preferOverlay 0
```

唯一出现 "nudge" 的 7 个文件是英文单词（如 `static const nudge = 3.0` 布局微调），与 Nudge 项目无关。

**因此本轮不修改 `THIRD_PARTY_NOTICES.md`。** 若将来改为逐段移植 Monk，必须先补许可声明、上游 commit 与修改说明。

---

## 5. 测试体系的真实状态

| 项 | 结果 |
|---|---|
| 仓库内入口 | **有** —— `tooling/run-kernel-tests.sh`（自动发现测试类） |
| 内核 | **21 类 / 217 项 / 全过** |
| 插件 | bili 80 · cap-ledger 50 · partner 110(+1 skip) |
| python 守卫 | 9 + 8 |
| Android 感知编译 | **exit 0**（27 源文件） |
| Android 单测**执行** | **NOT_TESTED** —— 仓库无 `gradlew`（Flutter 模板的 .gitignore 忽略它） |
| L2s 迁移（另跑） | **28/28**（WSL 非 root） |
| Flutter 全量 | **本轮未跑** —— 未改任何 Dart；不搬用上轮数字 |

### 两条测量纪律

1. **191 是错的，真实 190**：旧硬编码名单里有仓库中不存在的 `ProtectedForegroundTest`。现在数字由脚本发现，不手写。
2. **「970 = 970」作废**：同一 commit 两次全量跑失败集合就不同。上一轮已改为三次采样 + 逐名差集，本轮不重新采样也不搬旧数字。

---

## 6. 未完成与 NOT_TESTED（完整）

### PARTIAL

| 项 | 差什么 |
|---|---|
| **P0-4 原子写** | 检测已做，**写入仍是两次 rename**。下一步：单一快照文件 + 旧数据迁移 + 写失败回滚 |
| **Gradle 单测** | 仓库无 `gradlew`；未修（需提交 wrapper 或受控 distribution） |
| **Flutter 本轮口径** | 未跑（未改 Dart）；若需本轮数字须按阶段 G 三次采样 |

### NOT_TESTED（全部因「没有设备」或「须先获批」）

| 项 | 原因 |
|---|---|
| 真机 / 模拟器全部交互 | adb 0 台 |
| P0-1 的五条悬挂路径 | 需要真机 ROM 行为才能复现 |
| P0-2 的「最近任务切回」 | 同上 |
| P0-5 的证明失败场景 | 需要真机悬浮窗/分屏 |
| APK 打包与真包校验 | 本轮禁止构建 APK |
| 双 ABI 运行时构建 | 任务书要求**先报资源并获批**，本轮未申请 |
| 旧 .98 升级到 .101 的迁移 | 需要一台已装 .98 的手机 |
| 阶段 C/D/E/F/G | **未开始**（见 §9） |

---

## 7. 保护项核对

| 项 | 期望 | 实测 |
|---|---|---|
| `main` | 不动 | `bf01594471e11d7c1dbfe743a304a02d66068b29` 是 |
| R3 发布版 | 不动 | `f1423dc11cb4d42ca67225011c6437d1abd0025f` 是 |
| 上一轮集成 | 不动 | `868dc330d8495b7d41c887cd268329aad5e3ffb5` 是 |
| hardening 分支 | 不动 | `ac04b388b7ebe8c400a5907c9116797e7d539eda` 是 |
| 四个原始研发分支 | 不动 | 是 |
| force push | 无 | 是 |
| 删除 worktree | 无 | 17 个全在 |
| Release / APK / 装机 | 无 | 是 |

## 8. 本阶段提交

```
9e410c1  loop: after an interception ends, judge what is in front again            (P0-2)
432811a  loop: the runtime ends an interception, not the page                      (P0-1 接线)
63e3b40  loop: an interception must always end, and the page cannot be the one ...  (P0-1 策略)
558a3b4  loop: a page nobody saw cannot open the app, pause anything, or be an exit (P0-5)
4bfa378  loop: the guard and the ledger can disagree, so say so instead of guessing (P0-4 检测)
ad823c6  loop: a page that was never shown stops costing the person a block        (P0-3)
f2c5f97  tests: make the kernel suite runnable from the repository itself          (阶段 A)
```

---

## 9. 停下来等审核（按任务书）

**本轮到此为止，不继续推进阶段 C/D/E/F/G。** 理由：

1. 任务书要求「连续两轮修改仍未解决的问题立即停止」——P0-4 只做了检测层，属未完成；
2. **有 4 个策略问题需要负责人拍板**（`R4-PHASE4-CONFIG-CONFIRMATION.md` §8）：
   - D3：删按钮后 `RELEASE_RULE` 枚举保留还是一起删
   - D5：`EXITED` 那行规则（不扣冷却 / 不给放行 / 立即再拦）是否确认
   - D6：「指定会话」= 事件记录的会话还是当前会话
   - D7：「直接回复」观测方式 A（宿主事件）还是 B（下次进入比对）
3. 阶段 C/D 直接依赖 D3/D5/D6/D7；阶段 E 需要在 rc.4 非 Electron 宿主上跑，本轮未做；
4. 阶段 F 需要**先报资源并获批**才能跑双 ABI 构建。

**下一步等你**：一是回答 4 个问题；二是若同意，我先做 P0-4 的原子写与阶段 E（插件真实兼容）；
三是阶段 F 的构建资源报告我会单独出。

**不要把这轮读成「R4 已完成」。** 拦截的可靠性在真机上一行都还没跑过。