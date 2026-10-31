# 补丁包（导入你自己的 dsh-Go）

日期：2026-10-31
基线上游：`d38a39a`（DSH Go 1.0.2）
内容：Claude 的原型 + 内核 + R3 修复，以及我的工程集成与修复

---

## 1. 文件

```
D:\code\patch-pack\lean.patch
```

| 项 | 值 |
|---|---|
| 大小 | **678 KB** |
| 文件数 | **103**（39 个新增 + 修改） |
| 格式 | `git diff --binary`，纯 ASCII，可直接 `git apply` |
| SHA-256 | 见文末（由你本地核对） |

## 2. 为什么不是一份大补丁

原始 diff 是 28.9 MB / 154 文件，里面绝大部分是**噪音**，我把它们排除了：

| 排除项 | 原因 |
|---|---|
| `app/test/phone/goldens/`（34 张 PNG） | **上游本来就有**，不是我的改动；我当初下载时漏了、后补的 |
| `app/lib/l10n/app_{en,zh}.arb` | `l10n_merge.py` 每次整文件重写，14935 行全是噪音 |
| `app/lib/l10n/gen/`（3 个 .dart） | gen-l10n **生成物**，一条命令即可重建 |
| `projects/.../evidence/*.png` | 我的真机截图，5 MB，审核不需要 |
| `tooling/__pycache__/*.pyc` | 我跑测试误提交的垃圾（已从仓库删除并加 gitignore） |

**排除生成物的代价：应用补丁后必须跑一次 `l10n_merge.py`**，见第 3 节。我实测过，
不跑会报 126 个 `undefined_getter` 错误——这一步不能省。

## 3. 应用步骤（实测通过）

```bash
# 1. 在你自己的 dsh-Go 仓库里，从基线拉一个分支
git checkout -b feat/dsh-go-core d38a39a

# 2. 应用补丁
git apply --check /path/to/lean.patch     # 先干跑，应 exit 0
git apply /path/to/lean.patch

# 3. ⚠️ 必须重新生成 l10n（补丁里没有 gen 产物）
cd app
python3 tool/l10n_merge.py                # 需要 flutter/dart 在 PATH

# 4. 拉依赖 + 验证
flutter pub get
flutter analyze                           # 应该是 No issues found
```

### 已实测的结果

我在一个**干净的上游 `10c3519`（= d38a39a）worktree** 上完整走了一遍：

| 步骤 | 结果 |
|---|---|
| `git apply --check` | **exit 0** |
| `git apply` | **39 个文件变更，0 个 .rej** |
| 关键文件到位（KernelMirror/Switches/index.js/proactive_channel/proactive_page/verify_apk_runtime） | **全部 True** |
| `flutter pub get` | **exit 0** |
| `l10n_merge.py` 后 `flutter analyze` | **No issues found** |
| `flutter test`（loop + proactive 三件套） | **39/39 全过** |

## 4. 补丁里有什么

### Claude 的部分（原样应用，未改逻辑）

| 内容 | 位置 |
|---|---|
| 第一轮事件闭环原型（17 项测试） | `loop/*.kt`、`lib/loop/`、`lib/ui/phone/loop_test_page.dart` |
| 主动交互内核（66 项测试） | `loop/core/**`（Coordinator / ProactiveScheduler / AgentWire / CoreCodec / SnapshotStore） |
| Android 适配 | `loop/proactive/**`（ProactiveRuntime / ProactivePlugin / ProactivePageActivity / WakeAlarm） |
| DSH 宿主插件（12 项测试） | `runtime/proactive/dsh-go-proactive/` |
| R3 修复（A/B/C/E） | `KernelMirror.kt`、`Switches.kt`、`ProtectedForeground.kt`、`tools/pre-execute` 守卫 |

### 我的部分

| 内容 | 要点 |
|---|---|
| **P0-01 显示判定** | 页面 decor 真正可见才算 SHOWN，不再 onCreate 就写 |
| **P1-01 无障碍诊断** | 新增 `LoopDiagnostics`，异常计数/最近错误上报到设置页 |
| **P1-02 存储可靠性** | `FileLoopStore` + `AtomicJsonFile`（**改的 Claude 文件**）改为备份 + 原子替换 + 坏文件隔离 |
| **D1 Dart 转发** | `lib/proactive/proactive_channel.dart`：request/poll/cancel，原始应答不解释，status 0 ≠ 失败 |
| **D2 通知兜底** | `NotificationPortImpl.kt`：独立渠道、每 token 随机 action、**永不报 Shown** |
| **D3 设置页** | 开关、**间隔可自由输入**、免打扰、每日上限、目标会话选择、状态、回执 |
| **D4 打包** | `rtbuild.py` 装插件进 rootfs + overlay 行；修复**空目录泄漏**（test/ 曾被打入） |
| **D5（待审）** | 单独补丁 `PATCHES/0004-d5-loop-to-kernel.patch`，**不含在这份主补丁里** |

### 三个必须知道的改动点（都在 `CLAUDE_REVIEW.md` 里）

1. `loop/core/SnapshotStore.kt` —— 我改了 Claude 的文件（同一替换缺陷）
2. `loop/proactive/ProactiveRuntime.kt` —— 加了 `holdAgent/flushHeldAgent`（端口未就绪时不判失败）
3. `loop/proactive/ProactivePageActivity.kt` —— `Shown` 改为可见性证明，不再靠 `onResume`

## 5. 应用后你要做的两件事

### ① 构建 Android 运行时（**必须**，否则 APK 里没有插件）

```bash
# 需要 Linux x86_64（我在 WSL2 Ubuntu 26.04 上验证过）
cd runtime
./build-runtime.sh arm64-v8a
```

产出 `runtime/out/arm64-v8a/assets/runtime/{manifest.json,rootfs-arm64-v8a.tar.xz}`。

⚠️ 我遇到一个上游依赖漂移：Termux 索引已删除 `proot 5.1.107.98`。我在**构建副本**里
把 deb 版本换成了 `5.1.107.101`（同 5.1.107 系列）才跑通。仓库里的 `build-runtime.sh`
我没有改——**你构建时大概率也会撞上这个**，处理方式见 `R3_BUILD_REPORT.md` 第 5 节。

### ② 用校验工具确认插件真的进去了

```bash
python3 tooling/verify_apk_runtime.py app-arm64-debug.apk \
  --plugin runtime/proactive/dsh-go-proactive --json
```

必须 **exit 0 且 10 项全 PASS**。我用它验证过：旧 APK（构建时 `runtime/out` 是空的）
直接 FAIL，这正是它存在的意义——`BUILD SUCCESSFUL` 不能证明插件在包里。

## 6. 还没验证的

| 项 | 状态 |
|---|---|
| 真机：安装、rootfs 解压、插件入包、路由 401、引擎运行、模型回复、页面渲染、会话列表、C 项权限页避让 | **PASS**（有证据，见 `R3_BUILD_REPORT.md`） |
| 真机：主动搭话真实触发一次（Agent 回合 → 交互页 → 回执） | **NOT_TESTED** |
| 完整 rootfs 构建在**你的**环境 | **NOT_TESTED**（我只在 WSL2 上跑过） |
| 远程主机（SSH/中转） | **NOT_TESTED** |

## 7. 核对清单

拿到后建议先做：

```bash
git apply --check lean.patch              # 必须 exit 0
grep -c "^diff --git" lean.patch          # 应该是 103
python3 tool/l10n_merge.py                # 必须跑
flutter analyze                           # 应该 No issues
flutter test test/phone/proactive_page_test.dart   # 应该 13/13
```

## 8. 相关文档

| 文件 | 内容 |
|---|---|
| `CLAUDE_REVIEW.md` | 需要 Claude 判断的 8 个具体问题（含我改他文件的地方） |
| `R3_BUILD_REPORT.md` | 完整构建与真机验证报告 |
| `VALIDATION_REPORT.md` | 测试证据总表 |
| `TASK_STATUS.md` | 逐项 PASS/PARTIAL/REVIEW_REQUIRED/NOT_TESTED |
| `ARCHITECTURE_FINAL.md` | 实际落地的两条链路与不变量 |
| `PATCHES/0004-d5-loop-to-kernel.patch` | D5 单独补丁（**待审，未含在主补丁**） |
