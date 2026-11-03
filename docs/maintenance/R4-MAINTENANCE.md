# R4 长期维护档案

> 每次开始工作先读本文件。它不依赖任何会话记忆。
> 最后更新：2026-11-03 · 阶段一（建立基线与档案）

---

## 1. 上游与基准

| 项 | 值 |
|---|---|
| 上游仓库 | `https://github.com/ccch1mneyyy/dsh-Go`（remote 名 `upstream`） |
| 我们的仓库 | `https://github.com/aozhenyu666-cmyk/dsh-Go`（remote 名 `origin`，真 fork） |
| 上游 main | `8e36cdbf3b151ea819a53ecd88f7be91b497254a`（2026-11-03） |
| 我们 main | `bf01594471e11d7c1dbfe743a304a02d66068b29`（= 旧上游 1.0.4） |
| **分叉点** | `bf015944` —— R4 全部工作从这里切出 |

**关键度量（GitHub compare API 实测）**

```
上游 main 领先我们 main : 231 个提交 / 300 个文件
R4 领先分叉点         : 74 个提交 / 240 个文件
两者交集（潜在冲突）  : 14 个文件
```

---

## 2. R4 分支现状

| 分支 | 提交 | 说明 |
|---|---|---|
| `feat/p0-yishou-loop-2026-11-02` | `9bd93fb` | **最新**，含 P0-A（Yishou 交还验证） |
| `build/r4-phone-apk-2026-11-02` | `68525a3` | CI 构建 APK 的分支 |
| `integration/r4-p4-2026-11-02` | `086c2e7` | 阶段四集成（我停在 G4） |
| `fix/r4-device-prep-2026-11-02` | `16f8e1e` | G0–G3 |
| `fix/r4-snapshot-fix-2026-11-02` | `bf47bbf` | F0–F7（快照修复） |
| `fix/r4-wiring-2026-11-02` | `caeba65` | W0–W5（接线） |
| `fix/r4-phase4-2026-11-01` | `40c69eb` | 五个 P0 |
| `integration/r4-logic-closure-2026-11-01` | `868dc33` | 逻辑闭环 |
| `integration/r4-hardening-2026-11-01` | `ac04b38` | 加固 |
| `fix/r3-minute-input-on-1.0.4` | `f1423dc` | R3 发布版 |

**长期维护分支（建议）**：`r4/main`，从 `feat/p0-yishou-loop-2026-11-02` 建立。

---

## 3. R4 已有功能与源码位置

### 3.1 拦截内核（`loop/core/`，纯 Kotlin，可 JVM 测试）

| 功能 | 文件 |
|---|---|
| 拦截状态机、四扇放行门、训练题 | `core/Intercept.kt` |
| 决策纯函数 `InterceptRules.decide` | `core/Intercept.kt` |
| 事件截止（证明窗口 5s / 页面 TTL 10min） | `core/InterceptDeadline.kt` |
| 单一原子快照事务 | `core/InterceptRepository.kt` |
| 生产初始化工厂（快照 + 迁移） | `core/InterceptKernel.kt` |
| 旧数据迁移（四条一致性检查） | `core/InterceptMigration.kt` |
| 失败降级判定（D2） | `core/EnforcementOutcome.kt` |
| 主动交流六态 / 调度 | `core/CoreModel.kt` `core/Coordinator.kt` |
| Yishou 交还协议 v1 | `core/YishouProtocol.kt` |
| 界面仲裁（同一时刻一个 DSH 界面） | `core/SurfaceSlot.kt` |
| 账本与回执 | `core/Ledgers.kt` |

### 3.2 Android 适配层（`loop/intercept/`、`loop/proactive/`）

| 功能 | 文件 |
|---|---|
| 可见性证明、截止定时器、降级链 | `loop/intercept/InterceptRuntime.kt` |
| 拦截页（只渲染不裁决） | `loop/intercept/InterceptPageActivity.kt` |
| 拦截失败通知 | `loop/intercept/EnforcementAlert.kt` |
| 设置通道（status / pause / config） | `loop/intercept/InterceptPlugin.kt` |
| Yishou 交还页 | `loop/intercept/YishouPassActivity.kt` |
| 主动交流页与通知 | `loop/proactive/*` |

### 3.3 运行时（PRoot / DSH 引擎）

| 功能 | 位置 |
|---|---|
| 双 ABI 运行时构建 | `runtime/build-runtime.sh` |
| l2s 迁移（.98/.101 已验证，**.102 未验证**） | `app/.../runtime/L2sMigration.kt` |
| 直接启动 / 兼容启动判定 | `app/.../runtime/DirectLaunch.kt` |
| DSH 补丁 | `runtime/patches/*.diff` |
| 桥接插件 | `runtime/bridge/dsh-go-bridge` |

### 3.4 插件

| 插件 | 位置 |
|---|---|
| bili 视频查询 | `examples/plugins/dsh-go-bili` |
| 统一能力台账 | `examples/plugins/dsh-go-cap-ledger` |
| 人格/记忆/情绪 | `examples/plugins/dsh-go-partner` |

---

## 4. 自定义代码 vs 上游代码

**实测结论：R4 的内核与上游零重叠。**

上游 231 个提交里，以下路径**一次都没被改动**：

```
app/.../dsh_app/loop/core/          0 次
app/.../dsh_app/loop/intercept/     0 次
app/.../dsh_app/runtime/            0 次
runtime/build-runtime.sh            0 次
runtime/patches/                    0 次
app/lib/l10n/parts/intercept_*.arb  0 次
```

**14 个潜在冲突文件（两边都改过）**：

| 文件 | 性质 | 处理建议 |
|---|---|---|
| `app/lib/l10n/gen/*.dart`（3 个） | 生成文件 | 重新生成，不手工合 |
| `app/lib/l10n/app_{en,zh}.arb` | 生成文件 | 同上 |
| `app/lib/l10n/parts/phone_{en,zh}.arb` | 源 | 局部合并 |
| `app/android/app/build.gradle.kts` | 构建 | 保留 R4 flavor/签名，吸收上游依赖 |
| `app/android/app/src/main/AndroidManifest.xml` | 清单 | 保留 R4 组件，吸收上游新组件 |
| `MainActivity.kt` | 入口 | 局部合并 |
| `runtime/DshProcess.kt` | 运行时 | 局部合并 |
| `app/lib/app.dart` | Dart 入口 | 局部合并 |
| `.gitignore` / `THIRD_PARTY_NOTICES.md` | 杂项 | 取并集 |

---

## 5. APK 构建与签名

| 项 | 值 |
|---|---|
| 构建方式 | GitHub Actions `Build R4 Android APK (phone test)` |
| 触发分支 | push 到 `build/r4-phone-apk-2026-11-02`，或手动 dispatch |
| 工作流文件 | `.github/workflows/build-r4-phone-apk.yml` |
| 包名 | 独立 `.r4` 后缀（可与官方版、R3 `.mine` 并存） |
| 签名 | **云端临时调试签名**，换正式签名需卸载重装 |
| proot | **5.1.107.102**（`.101` 已从 Termux 下架） |
| 最新产物 | `r4-p4-build-4`，`dsh-go-r4-p4-arm64.apk` **183.3 MB** |
| 校验 | `verify_apk_runtime.py` PASS，rootfs sha256 与 manifest 一致 |

**构建流程**：

```bash
git push origin <r4-branch>:build/r4-phone-apk-2026-11-02
# CI: kernel 测试 + wiring 检查 → 构建 arm64 运行时 → 构建 APK → verify → 发布 Pre-release
```

---

## 6. 尚未解决的问题

| # | 问题 | 严重度 | 状态 |
|---|---|---|---|
| 1 | **上游 231 个提交尚未同步** | 高 | 本阶段处理 |
| 2 | **proot .102 的 l2s 迁移从未实测** | 高 | 未做（.98/.101 已验证） |
| 3 | **零真机证据**：`device-smoke.md` 9 条一条没跑 | 高 | 需要 arm64 手机 |
| 4 | P0-A（Yishou 交还）实现未经审查 | 中 | 未审 |
| 5 | APK 用临时调试签名 | 中 | 换正式签名需卸载重装 |
| 6 | 本机只有 x86_64 模拟器，无法验证 arm64 APK | 中 | 需要真机 |

---

## 7. 当前研发阶段

**阶段一：建立基线与档案（本文件）** —— 完成。

R4 功能已完整，APK 已能构建。**下一阶段是长期维护能力的建立**：同步上游、固化流程。

---

## 8. 下一条应该执行的任务

**命令二：建立上游更新与 R4 代码继承机制。**

具体：
1. 完成 `upstream` 的 fetch（本地对象尚缺 231 个提交）；
2. 建立长期维护分支 `r4/main`；
3. 试跑一次 `git merge upstream/main` 在临时分支上，量出真实冲突；
4. 把处理 14 个冲突文件的流程写进本文件。

---

## 9. 以后更新 APK 的流程（固化）

```
1. git fetch upstream
2. git log --oneline r4/main..upstream/main     # 上游新增了什么
3. git diff --stat r4/main...upstream/main      # 改了哪些文件
4. 在临时分支上 git merge upstream/main         # 只在冲突文件上动手
5. bash tooling/run-kernel-tests.sh              # 必须 OK + wiring OK
6. 回归：Flutter analyze、插件 node --test
7. 合入 r4/main，push 到 build/r4-phone-apk-2026-11-02 触发 CI
8. 校验 APK-SHA256.txt 后发布
```

**禁止**：`reset --hard`、`clean -fd`、force push、整份重写冲突文件。
---

## 10. 上游同步方案（命令二产出）

### 10.1 现状定性

```
             bf015944 (旧上游 1.0.4)  ← 分叉点
              /                    \
   74 提交   /                      \  231 提交
            /                        \
   r4/main (9bd93fb)          upstream/main (8e36cdbf)
```

**两边都在同一个点上往前走了**，没有一方包含另一方。

### 10.2 上游 231 个提交里改了什么（按性质归类）

| 类别 | 代表提交 | 与 R4 关系 |
|---|---|---|
| 新增 WebFiles 插件 | `MainActivity` +1 行注册 | 无冲突，直接继承 |
| 刷新率 / Live Update | `app.dart`、`MainActivity` 重构 | R4 只 +4/+3 行，局部合并 |
| **PRoot 临时目录回收** | `4ac19eef fix(runtime): reclaim abandoned PRoot glue directories safely` | **与 R4 关注的同一区域**，需重点验证 |
| PRoot 启动错误分类 | `8fe1c1cd` | 与 R4 的 `DirectLaunch` 相邻，需验证 |
| Node 解析器修复 | `DshProcess` +NODE_OPTIONS | 与 R4 的 `DshProcess` +6 行可能同段 |
| 背景输入 / 触摸回执 | `bbf4fc26` `05f12f05` | 无冲突 |
| 会话与连接修复 | `df9931e6` `2a703754` | 无冲突 |
| conscrypt 2.5.3→2.8.0 | `build.gradle.kts` | R4 的 +41 行是 flavor/签名，不同段 |
| CI 流水线精简 | `05723f7b` | 与 R4 的 APK workflow 并存 |

### 10.3 冲突面实测

| 文件 | 上游 | R4 | 判断 |
|---|---|---|---|
| `MainActivity.kt` | +45 −9 | +3 −0 | **易**（不同区域） |
| `DshProcess.kt` | +32 −15 | +6 −1 | **中**（可能同段，需人工看） |
| `AndroidManifest.xml` | +13 −0 | +63 −0 | **易**（都是新增） |
| `build.gradle.kts` | +1 −1 | +41 −0 | **易** |
| `app.dart` | +13 −2 | +4 −0 | **易** |
| `app_{en,zh}.arb` | +235/+352 | 少量 key | **中**（需重新生成） |
| `l10n/gen/*`、`l10n/parts/phone_*` | +0 −0 | — | **无冲突**（上游无实质改动） |
| `.gitignore` `THIRD_PARTY_NOTICES.md` | +7 −1 / +2 −2 | 少量 | **易**（取并集） |

### 10.4 同步流程（写入本文件，长期有效）

```bash
# 0) 每次开工先读本文件，再确认状态
git -C <repo> fetch upstream            # 若失败见 §10.5

# 1) 看清上游新增
git log --oneline r4/main..upstream/main
git diff --stat r4/main...upstream/main

# 2) 在临时分支上试合并，不直接动 r4/main
git switch -c tmp/upstream-sync-<date> r4/main
git merge upstream/main                 # 冲突只出现在 §10.3 列出的文件

# 3) 冲突处理规则
#    - l10n/gen/*.dart 与 app_*.arb：不手工合，改 parts 后重新生成
#        python app/tool/l10n_merge.py
#    - AndroidManifest / build.gradle.kts / .gitignore：取并集，两边条目都保留
#    - MainActivity / app.dart / DshProcess：逐 hunk 合并，两边的新增都保留
#    - 任何 loop/core、loop/intercept、runtime/build-runtime.sh 的冲突 = 异常，停下报告

# 4) 回归（顺序不能省）
bash tooling/run-kernel-tests.sh         # 必须 OK + wiring OK
cd app && flutter analyze lib
cd examples/plugins/dsh-go-bili && node --test

# 5) 合入并构建
git branch -f r4/main tmp/upstream-sync-<date>
git push origin r4/main
git push origin r4/main:build/r4-phone-apk-2026-11-02   # 触发 CI
```

### 10.5 fetch 失败的应对（实测记录）

本机 `git fetch upstream` 多次在连接阶段停滞（CPU 0、无输出），而：

- `Test-NetConnection github.com:443` → True
- `gh api` 与 `curl` 到 GitHub API → 正常
- `codeload` tarball → 可下载但慢（120s / 2.9MB）

**替代方案（已验证可用）**：用 GitHub API 取差异，不必本地 fetch：

```powershell
curl GitHub Compare API: /repos/<owner>/<repo>/compare/<base>...<head>?per_page=250
# 返回 files[].patch，可直接看每个文件的真实改动
```

本文件 §10.2/§10.3 的全部结论就是这样得出的。

若一定要本地 merge，需要先用 `git bundle` 或换个网络环境把 231 个对象取回来。
