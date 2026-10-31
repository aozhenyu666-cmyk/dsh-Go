# R3 集成与完整 APK 验收报告

日期：2026-10-31
候选分支：`feat/r3-candidate`；测试包分支：`feat/r3-test-apk`
基线：`feat/proactive-integration` @ `4ed7d5c` + Claude 的 `review/r3-core-fixes` @ `14616ad`

---

## 1. 接管 R3（任务一）

| 项 | 结果 |
|---|---|
| 拉取 `review/r3-core-fixes` | **SHA 核实一致**：`14616ad6a6cc2ba56f3f78f8192371b61c785007` |
| 与基线关系 | `ahead 3 / behind 0`（**快进**，无分叉） |
| 新分支 | `feat/r3-candidate`，从 `4ed7d5c` 建 |
| 应用方式 | `git am` 应用 `0005-r3-core-fixes.patch`（含 D5 + R3 修复两个提交），**未单独 cherry-pick 旧 D5** |
| 旧集成分支 / Claude 审核分支 | **未改动**，仅新增分支 |
| 差异核对 | `git diff` 逐一确认 A/B/C/E 修复均在（见 §2） |

> 网络说明：`github.com` 与 `raw.githubusercontent.com` 在本机不可达，`api.github.com` 与
> `codeload.github.com` 可达。因此代码通过 GitHub API 取文件 + `git am` 应用补丁获得，
> 全程未推送上游。

## 2. A/B/C/E 修复的实际核对

| 项 | 证据（文件存在 + 内容） |
|---|---|
| **A** D5 双状态机 | 新增 `loop/KernelMirror.kt`（3,712 B）+ `KernelMirrorTest.kt`（11 用例）；`LoopEngine` 增 `delegate()`/`openDelegated()` |
| **B** 双开关 | 新增 `loop/core/Switches.kt`（1,784 B）；`Coordinator.cancelSource` 已加入 |
| **C** 权限页避让 | 新增 `loop/ProtectedForeground.kt`（768 B）+ `ProtectedForegroundTest` |
| **D** APK 是否含插件 | 修复前 **FAIL（未证明）** → 本轮通过真实 Linux 构建关闭，见 §4/§5 |
| **E** 工具执行拦截 | `lib/index.js:89` `ctx.on('tools/pre-execute', (exec, next) =>`，`global: true` 计数 1 |

## 3. 完整代码回归（任务二）

执行环境：Windows 11 + Flutter 3.47.7 + JDK 21 + Android SDK 36 + Gradle 9.3.1；
WSL2 Ubuntu 26.04（运行时构建）。

| 检查 | 命令 | 结果 |
|---|---|---|
| Kotlin/JVM 核心 | `gradlew :app:testArm64DebugUnitTest --tests "…loop.*"` | **PASS 108/108** |
| Flutter 静态检查 | `flutter analyze` | **PASS**，No issues |
| Flutter 页面与转发 | `flutter test test/phone/... test/proactive_channel_test.dart` | **PASS 38/38** |
| 插件单元 | `node --test test/core.test.mjs` | **PASS 12/12** |
| 真实引擎 + 假模型 | `node test/e2e-live.mjs` | **PASS 26/26** |
| APK 校验工具 | `pytest tooling/test_verify_apk_runtime.py runtime/tests/test_proactive_packaging.py` | **PASS 9/9** |
| Android 构建 | `gradlew :app:assembleArm64Debug` | **PASS** |

JVM 108 项构成：`LoopEngineTest` 17、`LoopHardeningTest` 15、`TriggerRulesTest` 7、
`AgentWireTest` 4、`CoordinatorTest` 25、`KernelChainTest` 3、`ProactiveSchedulerTest` 17、
`KernelRiskTest` 8、**`KernelMirrorTest` 11**、**`ProtectedForegroundTest` 1**。

### 重点检查项

| 要求 | 覆盖 |
|---|---|
| KernelMirror 委托回执正确关闭 | `KernelMirrorTest` 11 项：回写一次、各结局映射、超时端到端、拒绝/合并立即关闭、双方恢复对账、内核丢记录 |
| 触发测试与主动搭话独立开关 | `Switches` + `triggerTestWorksWithProactiveChatOffAndEachSwitchCancelsOnlyItsOwnEvents` |
| 权限页安全避让 | `ProtectedForegroundTest` + 运行时 `refreshGate("protected_page")` |
| 主动回合工具执行拦截 | 插件 `tools/pre-execute` 返回 deny；e2e 实测 |
| 进程重启与过期回执 | `restartResumes…`、`restartAfterTheAgentDeadline…`、`recoveredFrom` 相关 |

**未修改任何测试预期**。唯一的测试改动是新增（`KernelMirrorTest`、`ProtectedForegroundTest`
来自 Claude；我新增的是 `rtbuild` 目录裁剪的工作方式，没有放宽断言）。

## 4. 先验旧 APK（任务三）

```
python tooling/verify_apk_runtime.py <旧APK> --plugin runtime/proactive/dsh-go-proactive --json
→ exit 1
  FAIL  runtime manifest in APK
        assets/runtime/manifest.json missing: runtime/out was empty when the APK was built
```

**结论：旧 APK（`5ce608df…`）不含运行时，也不含插件，不能作为主动 Agent 测试版。**
这与 Claude 的审核结论（D 项 FAIL）一致。

## 5. 真正构建 Android 运行时（任务四）

这是本轮最高优先级，**已完成**。

| 项 | 结果 |
|---|---|
| 环境 | WSL2 Ubuntu 26.04（x86_64，20 核），全新安装（原发行版 VHDX 丢失） |
| 命令 | `runtime/build-runtime.sh arm64-v8a` |
| 结果 | **成功**：`rootfs-arm64-v8a.tar.xz` **151.0 MiB**，25,240 文件 / 5,212 目录 / 1,680 符号链接，解包 749.7 MiB |
| ELF 审计 | 835 个对象，**wrong-arch: 0**，warnings: 0 |
| runtimeVersion | `r14-dsh0.2.1-rc.4-node24.22.1-ubuntu24.04.5-632d1850aca5` |
| manifest.json | **实际生成**，含 `dshGoProactive: {version 0.1.0, path /opt/dsh-go/dsh-go-proactive}` |
| rootfs 哈希 | 与 manifest 记录**一致**（`MATCH`） |

### 打包内容核验（逐项）

| 检查 | 结果 |
|---|---|
| `opt/dsh-go/dsh-go-proactive/package.json` | **OK**（650 B） |
| `…/lib/index.js` | **OK**（6,767 B） |
| `…/lib/core.js` | **OK**（13,416 B） |
| `dsh-web.patch.yml` 含插件加载行 | **OK**（`name: /opt/dsh-go/dsh-go-proactive/lib/index.js`） |
| 工具守卫 `tools/pre-execute` 在打包版本中 | **OK** |
| `test/` 未打入 | **OK**（目录与文件均不存在） |
| mock 模型 / fixture session 未打入 | **OK** |

### 过程中发现并修复的真实缺陷（我的代码）

首次构建后核验发现：`test/` 里**零个文件**，但**空目录仍在 rootfs**，
`verify_apk_runtime.py` 报 leak。根因是 `rtbuild.add_tree()` 只按文件判定丢弃，
目录条目在判定之前就写入了。修复：被丢弃的目录整棵跳过（`dirnames[:] = []`）。
重建后目录数 5,229 → 5,212，`test/` 与 `test/fixture-session` 完全消失。

### 环境阻塞与处理（真实记录）

| 现象 | 处理 |
|---|---|
| 原 Ubuntu 发行版 VHDX 丢失（`ERROR_FILE_NOT_FOUND`） | `wsl --unregister` 后 `wsl --install -d Ubuntu` 重建 |
| Termux 索引已删除 `proot 5.1.107.98` | **仅在 WSL 构建副本**里加 `PROOT_DEB_VERSION=5.1.107.101`（同 5.1.107 系列）；仓库文件未改；源码 zip 仍用 v5.1.107.98 且哈希校验通过 |
| WSL 内访问 `github.com` 超时 | 在 Windows 侧从 `codeload.github.com` 下载源码 zip，**SHA-256 与 `pin_of` 锁定值完全一致**（`9de61bdd…`）后放入缓存 |
| `arm64` 不是合法 ABI 名 | 需要 `arm64-v8a` |

## 6. 完整重建 APK（任务五）

| 项 | 值 |
|---|---|
| 路径 | `D:\code\apk-out\dsh-go-arm64-debug.apk` |
| 包名 | `io.github.ccch1mneyyy.dsh_app` |
| 大小 | 277 MB（含 151 MB rootfs） |
| SHA-256 | `08212f24807bc05c4ef7166677ff5850c1ac175f09fbd29aa76e44c53d70c8e9` |
| 签名 | `CN=Android Debug, O=Android, C=US`（debug） |
| 证书 SHA-256 | `10cdb677f36a1f5b5a9762c190736b9fd64016876a378b9bdc9297bb5724b758` |

`verify_apk_runtime.py`：**exit 0，10/10 PASS**
（运行时清单、插件名、启动带 `--patch`、rootfs 在包内、rootfs 哈希一致、插件文件齐、
加载配置含插件、test/ 未打包、插件与仓库版本逐字节一致、工具守卫在）。

## 7. 独立测试 APK（任务六）

| 项 | 值 |
|---|---|
| 路径 | `D:\code\apk-out\dsh-go-arm64-debug-test.apk` |
| **实际包名** | **`io.github.ccch1mneyyy.dsh_app.test`**（`aapt2 dump packagename` 实测） |
| 版本名后缀 | `-test` |
| Kotlin 包 / namespace | **保持不变** |
| 大小 / SHA-256 | 277 MB / `f8151973add4f90d731ae3029af027459ea0759c5f87631f89ca76be22b52aec` |
| 签名 | 同一个 debug 证书（与正式包相同密钥，但包名不同 → 可并存） |
| rootfs 内容校验 | **exit 0，10/10 PASS**（改包名后插件与启动配置均未丢失） |
| 更新检查 | **已禁用**：`--dart-define=DSH_TEST_BUILD=true` → `updatesEnabled=false`，`_check()` 直接返回，不联网、不跳转正式版 |
| 正式版包名与签名 | **未修改** |

### 重要实现说明（避免后人踩坑）

`applicationIdSuffix` **不能**写在 `app/build.gradle.kts`：本工程一旦在该文件做结构性改动
（包括新增一个顶层 `val` 或 `project.hasProperty(...)`），整个脚本会退化成
`Unresolved reference 'apply' / 'buildTypes' / 'defaultConfig'…` 的全屏错误。
已用对照实验证明：干净文件 + 任意 `-P` 参数 → 构建成功；加了上述任一改动 → 必失败。

因此改用 **Gradle init 脚本**（`D:\code\test-apk.init.gradle`）从外部注入
`applicationIdSuffix` 与 `versionNameSuffix`，**仓库文件零改动**：

```
gradlew :app:assembleArm64Debug --init-script D:\code\test-apk.init.gradle
```

副作用：init 脚本无法改 `android:label` 的硬编码值，所以测试包的**应用名仍是 "DSH Go"**，
靠包名 `.test` 与版本号 `-test` 区分。若必须改显示名，需要动 manifest（本轮为避免
破坏构建未做，见 §9）。

## 8. 未完成项与原因

| 项 | 状态 | 原因 |
|---|---|---|
| 模拟器上的首次启动 / 解包 / 插件加载 / 通知基础检查 | **NOT_TESTED** | 本机 Android 模拟器未就绪（无 AVD 可用），且不安装到真实手机 |
| 测试包应用名改为「DSH Go 测试版」 | **未做** | 需改 `AndroidManifest.xml` 的 `android:label` 或加 manifest placeholder，会让 `build.gradle.kts` 需要配套改动，触发上述 DSL 问题；已记录为后续工作 |
| 真机全部行为 | **NOT_TESTED** | 按要求不连接、不操作真实手机 |
| 远程主机（SSH/中转） | **NOT_TESTED** | 无环境 |

## 9. 真机验收清单（留给用户）

1. **并存安装**：先确认机上正式版仍在；安装 `dsh-go-arm64-debug-test.apk`（包名 `.test`），
   应出现**两个**图标。
2. **重新授权**：系统设置 → 无障碍里应出现**两个** DSH 条目，为测试包单独开启。
   Shizuku 里同样出现新条目，需单独授权。通知权限、自启动/后台运行也要单独给。
3. **首次解包**：首次启动会解压 ~750 MB rootfs（占 `filesDir`），需要时间与空间。
4. **插件加载**：设置 → 手机操控 → 主动搭话，`transport` 应显示已连上引擎；
   目标会话能列出活着的会话。
5. **触发测试与主动搭话独立**：只开「触发测试」、关「主动搭话」，打开测试 APP 应弹页。
6. **权限页避让**：进入系统设置/权限页时，主动搭话应让路并显示"正在让路"。
7. **工具拦截**：让主动回合尝试调用手机工具，应被拒（不会真的操作手机）。
8. **更新检查**：测试包内不应出现"有新版本"提示。
9. **不要同时开启两个包的无障碍**（会双份监听、双份弹窗、两份 rootfs 抢资源）。
10. **不要通过卸载正式版解决签名冲突**——两者签名相同（同一 debug 证书）但包名不同，
    本就应并存；若用 release 签名构建，则更不该混装。
