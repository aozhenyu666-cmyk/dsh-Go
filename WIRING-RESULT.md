# WIRING-RESULT

```
$ git ls-remote origin refs/heads/integration/r4-p4-2026-11-02
16f8e1e52605aed61fe64e64003c8de130ec9373	refs/heads/integration/r4-p4-2026-11-02
```

起点 `bf47bbf`。未 force push、未碰其他分支。

| 任务 | 改动文件 | 最后 3 行 | 状态 |
|---|---|---|---|
| **G0** | 无 | `OK (278 tests)` / `PASS` / `wiring OK` | **DONE** |
| **G1** | `core/Intercept.kt` `test/InterceptProductionPathTest.kt` | 红 `Tests run: 279, Failures: 1` · 绿 `OK (279 tests)` / `PASS` / `wiring OK` | **DONE** |
| **G2** | `intercept/InterceptRuntime.kt` `tooling/run-kernel-tests.sh` `tooling/device-smoke.md` | 红 `FAIL: …outside a FLAG_DEBUGGABLE gate`+`WIRING FAIL` · 绿 `OK (279 tests)` / `wiring OK` | **DONE** |
| **G3** | 分支 | `16f8e1e5… = refs/heads/integration/r4-p4-2026-11-02` | **DONE** |
| **G4** | `runtime/out/x86_64/`（未入库） | `x86_64 done: 158M … rc.4`；arm64 `error: Termux index no longer has proot 5.1.107.101 for aarch64` | **STOPPED(arm64 的 proot .101 已下架)** |
| **G5** | — | — | **STOPPED(G4 未完成；且本机只有 x86_64 模拟器，无 arm64 真机)** |

## G1 比指令单说的更严重

指令单说的是「transact 回滚没还原 charged\* 三个字段」，确实存在、已修。但只修它测试仍红，真因是：

```
onUnavailable { endOpen(...)                              // endOpen 在尾部清空 charged*
                state.copy(countToday = chargedCountToday)  // ← 永远读到 0
```

**每一次 NOT_SHOWN 退还的都是 0**，不只是提交失败之后。后果相同（countToday 归零、当日上限重置），
但发生在普通路径上；F2 之前没有重试，所以没人看见。现改为在 `endOpen` 之前读取。
## G2 一处偏离，已说明

指令单要求 `BuildConfig.DEBUG`。本项目 AGP 9.1.0 **默认不生成 BuildConfig**，启用需改 `build.gradle.kts`（不在可改清单内）。
改用 `ApplicationInfo.FLAG_DEBUGGABLE`：由 manifest build type 决定、运行时改不了，**意图不变（release 取不到该分支）**。
新增第 5 道检查约束该文件名只能出现在该判断附近；负向验收：删掉判断 → 测试全过但 `WIRING FAIL`；恢复 → `wiring OK`。

## G4 停下的原因（需要你决定）

| 检查 | 结果 |
|---|---|
| `binary-aarch64` 的 proot | 只有 **5.1.107.102** |
| `binary-x86_64` 的 proot | 同样只有 **5.1.107.102** |
| `proot_5.1.107.101_aarch64.deb` | **404** |
| `proot_5.1.107.102_aarch64.deb` | **200** |

x86_64 成功是因为本地缓存还留着 `.101` 的 deb；aarch64 没有这份缓存。

**x86_64 已完成**：`rootfs-x86_64.tar.xz` 157.4 MB，`libproot.so` 内 `strings` = `5.1.107.101`，
`rootfs ELF objects: 835, wrong-arch: 0, warnings: 0`。**arm64-v8a 为空**。

没有擅自改 `PROOT_VERSION`：升 .102 等于换 vendored 二进制，而 l2s 布局我只验过 `.98` 与 `.101`。
请明确二选一：**升到 .102 并重跑 l2s 迁移测试**，或**自行镜像 .101 的 deb**。
## 设备情况（影响 G5）

`adb devices` 非空，但唯一设备是 **x86_64 模拟器**（`ro.kernel.qemu=1`、`sdk_gphone64_x86_64`、API 34）。指令单要求 arm64 真机；模拟器验证不了 arm64 运行时，也代表不了真实 ROM 生命周期。
若接受「x86_64 模拟器 + x86_64 运行时」作为第一轮证据，请明确说，我会照做并标注为模拟器结果。

## 仍然不做

主动交流闭环、白名单撤销、hostdeps.mjs / rc.4、PRoot 夹具、D1–D7。
