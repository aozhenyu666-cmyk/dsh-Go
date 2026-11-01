# R4 交付物地址与内容清单

**验收用索引。** 每条都是绝对路径，可以直接复制到资源管理器或命令行。

---

## 一、两个核心文档（先看这两个）

| 文档 | 绝对路径 | 大小 | 内容 |
|---|---|---|---|
| **验收单页** | `D:\code\R4\R4-ACCEPTANCE.md` | 12 KB | 验收清单 A/B/C/D 四组，每条带命令和期望输出 |
| **完整技术报告** | `D:\code\R4\R4-HARDENING-REPORT.md` | 31 KB | 644 行，17 节，含 G1′ 证据与 24 条真机清单 |

两份都在集成分支里（`git show HEAD:R4-ACCEPTANCE.md` 可在任何机器上取）。

---

## 二、代码在哪（工作副本）

**所有工作副本都在 `D:\code\R4\` 下，是同一个 git 仓库的 worktree（共享 .git）。**

| 目录 | 分支 | HEAD | 用途 |
|---|---|---|---|
| `D:\code\R4\hard` | `integration/r4-hardening-2026-11-01` | `b3eb3ef` | **本轮集成结果，验收看这个** |
| `D:\code\R4\h-m1` | `harden/m1` | `79bfdce` | M1 独立分支 |
| `D:\code\R4\h-m2` | `harden/m2` | `a6677bc` | M2 独立分支 |
| `D:\code\R4\h-m3` | `harden/m3` | `2694425` | M3 独立分支 |
| `D:\code\R4\h-dev` | `harden/dev` | `00cc94f` | DEV 独立分支 |
| `D:\code\R4\int` | `integration/r4-2026-11-01` | `2f88256` | 上一轮集成（对照用） |
| `D:\code\R4\wt-dev` | `fix/r3-minutes-merge` | `69e36ff` | **R3 基线对照树**（app/lib+app/test 与 `f1423dc1` 字节相同） |
| `D:\code\R4\wt-m1` `wt-m2` `wt-m3` | `feat/r4-*` | — | 上一轮三个原始研发分支 |
| `D:\code\R4\dsh-Go` | `main` | `bf01594` | 主克隆（只读参照） |

> ⚠️ 这些不是独立 clone。**删掉其中一个目录会让其他 worktree 失效。**
> 增删用 `git worktree add/remove`，不要用 `rm -rf`。

---

## 三、四个模块改了什么（精确到文件）

### M1 行为管理 — 提交 `4da00b5`（20 文件 +2344 −46）

**Kotlin（内核）**
```
D:\code\R4\hard\app\android\app\src\main\kotlin\io\github\ccch1mneyyy\dsh_app\
  loop\core\Intercept.kt              +197  训练题 InterceptDrill、一次一拦、非目标回归
  loop\core\SurfaceSlot.kt            +30   替换语义、陈旧释放守卫
```

**Kotlin（Android 适配层）**
```
  loop\intercept\InterceptPageActivity.kt  +109  倒计时 → 真训练题 UI
  loop\intercept\InterceptRuntime.kt        +17   暴露 drill / tapDrill
  loop\intercept\InterceptPlugin.kt         （未改，通道已够用）
```

**资源**
```
  res\values\intercept_strings.xml      +9    训练题文案（英）
  res\values-zh\intercept_strings.xml   +11   训练题文案（中）
```

**Dart（新文件）**
```
D:\code\R4\hard\app\lib\
  intercept\intercept_channel.dart      +326  类型化通道（status/setConfig/receipts/pause/resume）
  ui\phone\intercept_page.dart         +448  拦截设置页（目标增删、参数、暂停恢复、账本、回执）
  ui\phone\phone_control_screen.dart    +10   入口（在"主动搭话"下面一行）
```

**l10n（新部件）**
```
D:\code\R4\hard\app\lib\l10n\
  parts\intercept_zh.arb                +74   49 个键
  parts\intercept_en.arb                +74
  app_zh.arb / app_en.arb               （合并产物）
  gen\app_localizations*.dart          +548   重生成
```

**测试**
```
  test\kotlin\...\loop\core\InterceptDrillTest.kt        +115  新增 10 项
  test\kotlin\...\loop\core\InterceptChainTest.kt        +66   新增 3 项
  test\kotlin\...\loop\core\SurfaceSlotTest.kt           +29   替换语义 3 项
  app\test\intercept\intercept_channel_test.dart          +189  新增 10 项
```

### M2 插件生态 — 提交 `5f5f9c1`（2 文件 +28 −3）

```
D:\code\R4\hard\examples\plugins\dsh-go-cap-ledger\
  lib\ledger.mjs        +25  六态（新增 available / executed / failed，均为派生值）
  test\ledger.test.mjs  +3   STATES 断言 4 → 6
```

### M3 人格记忆情绪 — 提交 `b06e5a5`（4 文件 +223 −24）

```
D:\code\R4\hard\examples\plugins\dsh-go-partner\
  lib\dims.mjs    +53   新增：七维唯一真相（DIMS / DIM_LABEL / DIM_VISIBLE_MIN / dimsOf）
  lib\views.mjs   +119  identityPanel() + 改用 dims.mjs
  lib\mood.mjs    +23   -24  改用 dims.mjs（先 import 再 re-export）
  lib\index.js    +55   -13  export const Config = undefined → 真 schema
```

### DEV 构建 — 提交 `592becf`（2 文件 +57 −11）

```
D:\code\R4\hard\runtime\
  lib\rtbuild.py        +13  修 machine 比较的类型错误（假 FAIL）
  build-runtime.sh      +55   fetch 重试加固（--retry-all-errors + 断点续传 + 备用镜像）
```

### 回归修复 — 提交 `5a41937`（1 文件 +3 −1）

```
D:\code\R4\hard\app\lib\ui\phone\intercept_page.dart    Icons.close → AppIcons.remove
```

---

## 四、运行时产物在哪（G1′ 的证据）

### 4.1 Windows 侧（验收 B 组请在这里跑）

```
D:\code\R4\h-dev\runtime\out\
├── manifest.json                              4 KB    abis = [arm64-v8a, x86_64]
├── arm64-v8a\
│   ├── build-report.json                     330 KB   835 个 ELF 审计，wrong-arch: 0
│   ├── assets\runtime\
│   │   ├── rootfs-arm64-v8a.tar.xz          151 MB   ← 主要产物
│   │   ├── manifest.json                      10 KB
│   │   └── licenses\                          proot / talloc / libandroid-shmem
│   └── jniLibs\arm64-v8a\
│       ├── libproot.so                      250 KB
│       ├── libproot-loader.so                20 KB
│       ├── libtalloc.so                      30 KB
│       └── libandroid-shmem.so               10 KB
└── x86_64\
    ├── build-report.json                     310 KB
    ├── assets\runtime\
    │   ├── rootfs-x86_64.tar.xz             157 MB
    │   ├── manifest.json
    │   └── licenses\
    └── jniLibs\x86_64\
        └── （同上 4 个 so）
```

**总计 310 MB。不在 git 里**（构建产物不入库）。

### 4.2 Linux 侧（构建发生的地方）

```
WSL Ubuntu:  /root/r4build/dsh-Go/runtime/
             ├── out/      310 MB   构建产物（已拷回 Windows）
             ├── .cache/   582 MB   下载缓存（镜像 tarball）
             └── .work/    1.1 GB   解包工作区
WSL 构建日志: /root/r4build/build.log
```

**WSL 磁盘**：950 GB 可用。C 盘只剩 1.5 GB，**所以一切产物都在 D 盘或 WSL 内部**。

---

## 五、验证脚本（可直接跑）

```
D:\code\R4\hard-verify.ps1        内核 172 项（JVM 离线，不需要设备/模拟器/引擎）
D:\code\R4\hard-android.ps1       Android 感知编译（真 android.jar + flutter.jar + 桩）
D:\code\R4\int-verify.ps1         上一轮的同一套（对照用）
D:\code\R4\r4-verify.ps1          第一轮写的通用版
```

跑法：
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\code\R4\hard-verify.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File D:\code\R4\hard-android.ps1
```

**必须带 `-ExecutionPolicy Bypass`**：.ps1 没有数字签名，直接 `&` 调用会被拦。

G1′ 那条：
```powershell
cd D:\code\R4\h-dev
python -I runtime/lib/rtbuild.py verify-outputs --out runtime/out --abi arm64-v8a x86_64
```

---

## 六、测试证据（原始日志，可核对）

| 日志 | 绝对路径 | 大小 | 内容 |
|---|---|---|---|
| 最终全量回归 | `D:\code\R4\HARD-full-ft2.log` | 3.6 MB | `+7330 ~370 −970`（图标修复后） |
| 第一次全量（有回归） | `D:\code\R4\HARD-full-ft.log` | 3.6 MB | `+7329 ~370 −971`（证明我确实先跑出了回归） |
| R3 基线对照 | `D:\code\R4\BASE-full-ft.log` | — | `+7320 ~370 −970` |
| Flutter analyze | `D:\code\R4\H-an.log` | — | `No issues found` |
| 目标页面测试 | `D:\code\R4\H-phone.log` | — | `+35 All tests passed` |
| 内核测试 | `D:\code\R4\hard-test.log` | — | `PASS 172 tests` |

**这两份全量日志加起来 7 MB，是"970 = 970"这个结论的原始依据。**

---

## 七、Git 地址

### 7.1 远端

```
https://github.com/aozhenyu666-cmyk/dsh-Go
```

### 7.2 本轮分支（都已推 origin）

| 分支 | SHA | 说明 |
|---|---|---|
| `integration/r4-hardening-2026-11-01` | **`b3eb3efa7d4a71451f137be0ea9934d7fc173047`** | **本轮集成结果** |
| `harden/m1` | `79bfdceb0c655186f3f00c0bd31a260d16e6c9ca` | M1 |
| `harden/m2` | `a6677bc0873123e9492033daceaa8977bfa522b9` | M2 |
| `harden/m3` | `26944251eb32125ce8e212e2c7545c483054da03` | M3 |
| `harden/dev` | `00cc94f8b07772c1191c82c9f8ff05cafa3ff3dc` | DEV |

### 7.3 受保护分支（本轮未动，可核对）

| 分支 | SHA | 期望 |
|---|---|---|
| `main` | `bf01594471e11d7c1dbfe743a304a02d66068b29` | 未动 ✅ |
| `fix/r3-minute-input-on-1.0.4`（R3 发布版） | `f1423dc11cb4d42ca67225011c6437d1abd0025f` | 未动 ✅ |
| `integration/r4-2026-11-01`（上一轮） | `2f88256cb83d6c21821c0278555471f9a979d5ae` | 未动 ✅ |
| `feat/r4-intercept-and-ack` | `35ac53d3e6283231ace0957e9cbb98c7293c76d1` | 未动 ✅ |
| `feat/r4-bili-plugin` | `2eb704d0aa93b1f04b05d55d949d3513f6371a20` | 未动 ✅ |
| `feat/r4-partner-plugin` | `d166e9269b3ff311d9d439bd67dd884b215313fd` | 未动 ✅ |

### 7.4 本轮 7 个提交（在 `2f88256` 之上）

```
b3eb3ef  docs: one-page acceptance sheet for round 2
a2012da  docs: R4 hardening report - G1' passes, four modules closed, zero regressions
5a41937  ui: name the remove affordance through AppIcons, not Icons.close
592becf  runtime: G1' actually passes, and the verifier stops failing honest builds
b06e5a5  partner: one source for the seven dimensions, real identity panel, real Config
5f5f9c1  cap-ledger: six states, and the bili plugin uses the same ledger
4da00b5  loop: make the intercept a real closed loop (training drill, settings page, one-at-a-time)
```

### 7.5 网络注意

**裸连 github 的 git 通道在本机是断的**，必须走本地代理：

```powershell
git -c http.proxy=http://127.0.0.1:7897 -c https.proxy=http://127.0.0.1:7897 fetch origin
git -c http.proxy=http://127.0.0.1:7897 -c https.proxy=http://127.0.0.1:7897 push origin <branch>
```

`gh api` 走另一条通道，不需要代理。

---

## 八、四份过程文档（复盘用）

```
D:\code\R4\R4-TRUTH.md                 8.6 KB   第一轮前的事实基线（分支血缘、环境、代理）
D:\code\R4\R4-INTEGRATION-REVIEW.md    9.1 KB   第一轮四模块交付的独立复核
D:\code\R4\R4-INTEGRATION-REPORT.md   15.2 KB   第一轮集成结果（11 项遗留来源）
D:\code\R4\R4-HARDENING-REPORT.md     30.9 KB   本轮完整报告（17 节）
D:\code\R4\R4-ACCEPTANCE.md           11.9 KB   本轮验收单页
```

## 九、派单与调研（可追溯当时怎么要求的）

```
D:\code\R4\briefs\harden-m1.md           M1 派单
D:\code\R4\briefs\harden-m2.md           M2 派单
D:\code\R4\briefs\harden-m3.md           M3 派单
D:\code\R4\briefs\harden-dev.md          DEV 派单
D:\code\R4\briefs\SCHEMASTERY-FINDING.md  Schemastery 决定性证据（宿主自带 3.18.5）
```

## 十、仓库内的相关文档

```
D:\code\R4\hard\docs\loop\ROUND4_ACK_AND_INTERCEPT.md      M1 设计：ACK 状态机 + 拦截链（含 mermaid）
D:\code\R4\hard\docs\build\runtime-and-abis.md             DEV 双 ABI 审计全文
D:\code\R4\hard\HANDOVER_WORKBODY.md                        交接文档
D:\code\R4\hard\R4-HARDENING-REPORT.md                     报告副本（已入库）
D:\code\R4\hard\R4-ACCEPTANCE.md                           验收副本（已入库）
```

---

## 十一、验收最快的三分钟路径

```powershell
# 1. 保护项（7 条，一次看完）
cd D:\code\R4\dsh-Go
git ls-remote origin refs/heads/main refs/heads/fix/r3-minute-input-on-1.0.4 refs/heads/integration/r4-2026-11-01 refs/heads/integration/r4-hardening-2026-11-01

# 2. G1'（一条命令看完六项判据）
cd D:\code\R4\h-dev
python -I runtime/lib/rtbuild.py verify-outputs --out runtime/out --abi arm64-v8a x86_64

# 3. 内核测试（172 项）
powershell -NoProfile -ExecutionPolicy Bypass -File D:\code\R4\hard-verify.ps1

# 4. 插件测试（69 + 42 + 96）
cd D:\code\R4\hard\examples\plugins\dsh-go-bili;       node --test
cd ..\dsh-go-cap-ledger; node --test
cd ..\dsh-go-partner;    node --test
```

想深挖任何一条，去 `R4-HARDENING-REPORT.md` 对应章节（§11 G1′ / §9 回归 / §10 Schemastery / §13 未解决 / §14 真机清单）。
