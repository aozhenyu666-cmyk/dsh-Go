# 真机自检清单

前提：APK 已装、无障碍已授权、至少配一个目标 APP（下称 B站）。

```bash
adb logcat -c && adb logcat -s DshIntercept:V DshLoop:V &
```

| # | 操作 | 期望 | 算失败 |
|---|---|---|---|
| 1 | 打开 B站 | 日志 `ready: ... snapshot=true`，拦截页出现 | 无 `snapshot=true`；或不出现且无日志 |
| 2 | 拦截页中熄屏 → 从锁屏进抖音 | 抖音被拦；回执 EXITED/NOT_SHOWN，不悬挂 | 抖音可用；或活跃拦截卡住 |
| 3 | 拦截页中 → 最近任务 → 切回 B站 | B站**再次**被拦 | B站可正常浏览（P0-2 绕过） |
| 4 | 开发者选项开「不保留活动」→ 开 B站 → 回桌面 → 再开 | 有 NOT_SHOWN 类回执，无悬挂；再开仍被拦 | B站直接可用 |
| 5 | **制造一次启动失败**（见下）→ 开 B站 | 收到通知「这次没有拦住」，点它能打开 App；设置页顶部红字；回执里**没有** BLOCKED | 没通知 / 点通知没反应 / 出现 BLOCKED |
| 6 | 拦截页中 `am force-stop` → 重开 | 回执 NOT_SHOWN 或 BLOCKED，计数与回执一致 | 有计数没回执；或活跃拦截卡死 |
| 7 | 拦截页点「紧急退出」→ 立刻开 B站 | **再次被拦** | B站可用（exit 成为绕过路径） |
| 8 | 答对训练题 → 放行 → 等 `releaseMs` 过期 → 再开 | 过期后重新被拦 | 过期后仍无限可用 |

第 5 和第 6 两条最重要：它们分别验证 W2 的通知接线和 W1 的崩溃恢复，
而这两件事在 JVM 上无法证明。

```bash
# 存储：全新安装应只有快照；升级用户应保留旧文件但 mtime 不再变
adb shell run-as io.github.ccch1mneyyy.dsh_app ls -l files/loop/intercept/
adb shell run-as io.github.ccch1mneyyy.dsh_app cat files/loop/intercept/intercept.snapshot.json
```

**期望**：快照含 `schemaVersion`/`config`/`guardState`/`ledgerState`/`appliedEventIds`；
全新安装无 `guard.json`/`ledger.json`；升级后两个旧文件在但 mtime 停止更新。

**算失败**：升级后仍只有两个旧文件（迁移没跑）；或 `guard.json` mtime 还在更新（仍走两次写）。

### 第 5 条怎么做（只在调试版）

关掉无障碍是**测不了**这条的：无障碍关闭后 App 根本看不见你打开了 B站，既不会拦也不会失败，
那条通知永远不会出现。所以调试版提供了人为制造启动失败的开关：

```bash
adb shell run-as io.github.ccch1mneyyy.dsh_app \
  touch files/loop/intercept/debug-fail-start
# 然后打开 B站，观察通知与设置页
adb shell run-as io.github.ccch1mneyyy.dsh_app \
  rm files/loop/intercept/debug-fail-start      # 测完必须删掉
```

**期望**：通知标题「这次没有拦住」，正文含 `foreground_unreadable` 或 `still_in_front`；
点通知能打开 App；设置页顶部出现红字；回执里没有 BLOCKED（这次没有拦住，不该记成拦住了）。

**算失败**：没有通知；点通知没反应；回执里出现 BLOCKED。

这个开关只在 `FLAG_DEBUGGABLE` 为真时生效，release 构建读不到它。

| # | 操作 | 记录什么 |
|---|---|---|
| 9 | 关掉无障碍 → 打开拦截设置页 | **只记录实际看到什么**：界面上有没有提示「无障碍未连接、拦截不工作」 |
