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
| 5 | **关掉无障碍权限** → 开 B站 | 收到通知「这次没有拦住」+ 设置页红字 | 什么都没发生（B-1 复发） |
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
