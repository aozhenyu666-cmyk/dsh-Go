# R4 第二阶段验收文档

**给验收人看的单页版。** 每条都写了「怎么自己验一遍」，不是让你信我的话。

- 集成分支：`integration/r4-hardening-2026-11-01`
- 集成分支 HEAD：`a2012dad7db48f957869dab3b720c75b0630dc11`
- 起点：上一轮集成 `2f88256`
- 完整技术报告：`R4-HARDENING-REPORT.md`（同仓库根目录，644 行）

---

## 一、三十秒结论

| 问题 | 答案 |
|---|---|
| 双 ABI 运行时建出来了吗？ | **是**，真建出来了，G1′ PASS |
| 有功能能在手机上跑吗？ | **不知道** —— adb 0 台设备，真机一次没碰 |
| 代码级功能闭环完整吗？ | 三条线完整（M1 拦截、M2 插件、M3 人格），两条有明确缺口 |
| 有回归吗？ | **没有**。970 = 970，逐条比对失败测试名 |
| 加新依赖了吗？ | **没有**，一行没加 |
| 能合 main 吗？ | 现在不建议 —— 真机验收之前不动 main |

---

## 二、验收清单（逐条可自查）

### A. 分支与保护（先验这个，一分钟）

| # | 检查 | 命令 | 期望 |
|---|---|---|---|
| A1 | 集成分支存在且 HEAD 对 | `git ls-remote origin refs/heads/integration/r4-hardening-2026-11-01` | `a2012da...` |
| A2 | main 没动 | `git ls-remote origin refs/heads/main` | `bf015944...` |
| A3 | R3 发布版没动 | `git ls-remote origin refs/heads/fix/r3-minute-input-on-1.0.4` | `f1423dc1...` |
| A4 | 上一轮集成没被覆盖 | `git ls-remote origin refs/heads/integration/r4-2026-11-01` | `2f88256...` |
| A5 | 四个原始研发分支没动 | `git ls-remote origin 'refs/heads/feat/r4-*'` | bili `2eb704d` / intercept `35ac53d` / partner `d166e92` |
| A6 | 无 Release / 无 APK | `gh release list` | 无新增 |
| A7 | 无强制推送痕迹 | `git log --oneline 2f88256..HEAD` | 6 个提交，都在上一条之上 |

### B. 构建（G1′，最关键）

| # | 检查 | 命令 | 期望 |
|---|---|---|---|
| B1 | 两个 ABI 目录存在 | `ls runtime/out/` | `arm64-v8a` `x86_64` `manifest.json` |
| B2 | manifest 双 ABI | `cat runtime/out/manifest.json` | `abis` 同时含两项 |
| B3 | G1′ 断言 | `python -I runtime/lib/rtbuild.py verify-outputs --out runtime/out --abi arm64-v8a x86_64` | `G1' PASS`，exit 0 |
| B4 | rootfs 哈希一致 | 上面那条会一起验 | PASS |
| B5 | 四个原生库架构对 | 同上 | PASS |
| B6 | rootfs 无非本架构 ELF | 构建日志 | `wrong-arch: 0`（835 个 ELF 对象） |
| B7 | 插件测试文件没混进运行时 | `tar -tf ...\|grep dsh-go-proactive/.*test` | 0 条 |

**本机实测输出（原文）**
```
PASS  arm64-v8a  abi=arm64-v8a  rootfs-arm64-v8a.tar.xz  ...  4 jniLibs
PASS  x86_64     abi=x86_64     rootfs-x86_64.tar.xz     ...  4 jniLibs
PASS  runtime/out/manifest.json  abis=['arm64-v8a', 'x86_64']
G1' PASS: runtime/out holds a real runtime bundle for arm64-v8a, x86_64
```

> ⚠️ **`runtime/out` 没有提交进仓库**（310 MB 构建产物）。工作副本在 `D:\code\R4\h-dev\runtime\out`，
> 需要时用 `PROOT_VERSION=5.1.107.101 bash runtime/build-runtime.sh` 重建。
> 你验收 B1–B7 时请在那个目录下跑。

### C. 测试（每条都能自己跑）

| # | 层 | 命令 | 实测 |
|---|---|---|---|
| C1 | 内核纯逻辑（JVM 离线） | `powershell -File D:\code\R4\hard-verify.ps1` | **PASS 172** |
| C2 | Android 感知编译 | `powershell -File D:\code\R4\hard-android.ps1` | **exit 0**（26 个 kt） |
| C3 | bili 插件 | `cd examples/plugins/dsh-go-bili; node --test` | **69 / 69** |
| C4 | cap-ledger | `cd examples/plugins/dsh-go-cap-ledger; node --test` | **42 / 42** |
| C5 | partner 插件 | `cd examples/plugins/dsh-go-partner; node --test` | **96 pass / 1 skip / 0 fail** |
| C6 | 运行时守卫 | `python -m unittest runtime.tests.test_verify_outputs` | **9 OK** |
| C7 | APK 校验器 | `cd tooling; python -m unittest test_verify_apk_runtime` | **8 OK** |
| C8 | Flutter 静态分析 | `flutter analyze` | **No issues found** |
| C9 | l10n 可重生成 | `python tool/l10n_merge.py --check` | **47 部件 / 5417 键** |
| C10 | 目标页面测试 | `flutter test test/phone/... test/intercept/...` | **+35 全过** |

**C5 那 1 个 skip 是什么**：`real-dsh-tools.test.mjs`，需要 `DSH_TOOLS_DIR` 指向 `app.asar` 里的真
`@deepseek-ai/dsh-tools`。**不是失败，是这条通道在本机跑不了**。我没有删掉它假装"全绿"。

### D. 回归对照（这条最重要，防止"测试多了但功能坏了"）

| | 通过 | 跳过 | 失败 |
|---|---|---|---|
| R3 基线 | +7320 | ~370 | **−970** |
| 本轮 hardening | **+7330** | ~370 | **−970** |

- 净失败 **970 = 970**
- 通过数 **多 10 个**（正好是新增的 intercept 通道测试）
- 970 个失败是**本机字体 golden 基线问题**：R3 基线与本轮完全一样，按 `MAINTENANCE.md §9` 不动

**第一次跑是 −971，多 1 个，我没放过它。** 比对失败测试**名字**（不是只看数字），逮到我自己引入的回归：

> `intercept_page.dart` 用了 `Icons.close`，而仓库规定所有图标必须走 `AppIcons` 角色表
> （Material 图标字体没打包，`Icons.*` 在真机上会画成方块）。已改成 `AppIcons.remove`，提交 `5a41937`。

---

## 三、本轮改了什么（按模块）

| 模块 | 提交 | 规模 | 核心内容 |
|---|---|---|---|
| **M1 行为管理** | `4da00b5` | 20 文件 +2344 −46 | 训练题可判定、一次只拦一个、槽位仲裁、拦截设置页接真内核 |
| **M2 插件生态** | `5f5f9c1` | 2 文件 +28 −3 | cap-ledger 四态 → 六态 |
| **M3 人格记忆情绪** | `b06e5a5` | 4 文件 +223 −24 | 七维唯一真相、身份面板接真数据、Config 真 schema |
| **DEV 构建** | `592becf` | 2 文件 +57 −11 | 修校验器假 FAIL、构建重试加固 → G1′ 通 |
| 图标回归修复 | `5a41937` | 1 文件 +3 −1 | `Icons.close` → `AppIcons.remove` |
| 文档 | `a2012da` | 1 文件 +644 | `R4-HARDENING-REPORT.md` |

---

## 四、修掉的 4 个真实缺陷（不是文档层面）

验收时如果你想看"到底修了什么真东西"，看这四条：

### 1. 换目标 APP 会覆盖 openEventId（M1）
**症状**：B站拦截页还开着时打开抖音 → 旧的 eventId 被覆盖，**永远拿不到回执**；冷却和每日额度白扣；新目标静默放行。
**修法**：守卫内部先判"有没有一个还开着"，有就返回 `Allow(another_open)`，**什么都不消耗**。
**测试**：`openingAnotherTargetWhileOneIsOpenIsNotASecondInterception`

### 2. 同 owner 换 token 会卡死槽位（M1）
**症状**：两个页面都是 `singleInstance`，新 Presentation 复用同一个 Activity 只换 token → claim 被拒 → 报 surface_busy，但 Activity 其实已经换成新内容了，槽位还挂在旧 token 上没人释放 → **主动搭话把自己饿死**。
**修法**：同 owner 换 token 视为"替换"，可以接管；旧 token 的迟到 release 仍被陈旧守卫挡住。
**测试**：`a_new_token_from_the_same_owner_takes_the_slot_over` + `the_replaced_token_cannot_free_its_replacement`

### 3. 训练页只是倒计时（M1）
**症状**："训练通过" = "页面停留了 60 秒"。把手机放下再回来就通过了。
**修法**：由 eventId **确定性生成**一道数字排序题；守卫侧 `onReleased` 在未解完时返回 false；按错进度清零；进程被杀回来是**同一道题**不是更简单的。
**测试**：`InterceptDrillTest` 10 项

### 4. 校验器拿字符串比整数（DEV）—— 假 FAIL
**症状**：manifest 记了 `machine: "aarch64"`（字符串）和 `e_machine: 183`（整数），校验拿字符串去比 183 → **每一个诚实构建都报错**。
**意义**：这是上一轮那个"假 PASS"的孪生兄弟。**一个永远通不过的检查，和一个永远通过不了的检查一样没用。**
**修法**：比较 `e_machine`，无数字时才用 `EM_NAMES` 反查。

---

## 五、Schemastery 的决定（你上轮明确要求的）

**决定：不引入依赖。宿主本来就支持。**

上一轮我建议"为了原生表单破例引入 schemastery"——**这个建议是错的**，你让我先验证是对的决定。

| 证据 | 位置 |
|---|---|
| 宿主自带 schemastery | `~/.dsh/profiles/desktop/node_modules/@deepseek-ai/schemastery` → **3.18.5** |
| 宿主有完整表单引擎 | `app/lib/ui/engine_settings/schema_form.dart:6-8` → "schemaSections lays out **any plugin's** namespace by itself" |
| 有第三方插件配置页 | `app/lib/ui/plugins/config/plugin_config_page.dart` + `plugin_config_layout.dart` |
| 有读写通路 | `app/lib/state/plugin_config/plugin_config_bridge.dart` → `GET/POST /dsh-go/v1/plugin-config` |
| 有设计文档 | `docs/design/plugin-config.md`（PLUGIN-CONFIG 契约） |
| 有先例 | `dsh-bili-subagent` 把 schemastery 列为 optional peer，并用 `!z ? undefined : z.object({...})` |

上一轮那句注释 **"零依赖所以画不出表单" 因果说反了** —— 真实原因是**导出了 `undefined`**，宿主拿不到 schema。

现在改成真 schema，用**真实的** schemastery 3.18.5 解析通过（uid 59），**一行依赖没加**。

**未验证**：表单在真机上长什么样。这条是 **NOT_TESTED**，需要设备。

---

## 六、四态定级

### PASS（14 项）
M1 ACK 五态 · M1 两本账独立 · M1 一次只拦一个 · M1 训练可判定 · M1 槽位统一仲裁 ·
M1 拦截设置页接真内核 · M2 六态台账 · M3 七维同源 · M3 身份面板接真数据 · M3 Config 可被宿主解析 ·
DEV G1′ 双 ABI · DEV 校验器不再假 FAIL · 完整回归零新增失败 · 零新增第三方依赖

### PARTIAL（4 项）— 都是我自己标的，不是掩盖

| 项 | 到了哪 | 差哪 |
|---|---|---|
| 拦截白名单 | 能读、能展示 | **没有增删 UI**（内核支持写，页面这轮没做） |
| 台账统一 | 六态已建、契约清晰 | bili 与 cap-ledger **未合并成一次写入**，缺宿主跨插件状态能力 |
| PROOT 版本 | 双 ABI 用 `.101` 建成 | `.101` 改了 l2s 布局，**默认值故意保持 `.98`**，需真机验迁移 |
| 训练题 | 有可判定题型、失败不放行 | 只有数字排序一种，没难度/内容分级 |

### FAIL
**无。**

### NOT_TESTED（6 类）
真机/模拟器全部渲染与交互 · APK 打包与真包校验 · 原生表单真机截图 · `dsh plugin add` 加载 ·
`real-dsh-tools` 那 1 个 skip · PROOT `.101` × `L2sMigration` 真机迁移

---

## 七、这一轮最重要的更正

**上一轮报告写「WSL 挂了（E_UNEXPECTED），本机无法构建」。这个判断是错的。**

```
$ wsl -d Ubuntu -- uname -a
  wsl: Failed to translate 'E:\VMware\bin\'     ← Windows PATH 里有个 Linux 不存在的路径
  Linux LAPTOP-HANAC4Q6 6.6.87.2-microsoft-standard-WSL2 ... x86_64 GNU/Linux
  exit=0                                          ← 命令其实跑成功了
```

真因是 **Windows PATH 携带 `E:\VMware\bin\`**，导致 `wsl.exe` 打印告警并以非 0 退出，**但 Linux 命令正常执行**。

把这条误读成"环境坏了"，让上一轮把一个**本机可解**的问题记成了硬阻塞。这一轮我亲自复核推翻了它，
然后在同一台机器上真建出了两个 ABI。

**教训**：报"环境阻塞"之前，先确认输出到底是命令失败还是包装器失败。

---

## 八、建议你验收时按这个顺序

1. **先跑 A 组**（7 条，一分钟）—— 确认没人动过不该动的分支
2. **再跑 B3 一条**（`verify-outputs`）—— 一条命令看完 G1′ 六项判据
3. **再跑 C1 + C5**（内核 172 + partner 97）—— 代码级质量
4. **最后看 D 组**（回归对照）—— 确认测试多了但没坏
5. **§六 PARTIAL 那 4 条，逐条问我"为什么没做完"** —— 我给的答案在报告 §13

---

## 九、下一阶段需要你提供的

**只有一件：一台 ARM64 手机连上 adb。**

有了它，按 `R4-HARDENING-REPORT.md` §14.3 的 **24 条**走一遍，就能回答那个还没人回答的问题：
**"它到底能不能用。"**

在那之前，任何"已经能在手机上跑"的说法都不成立——**我不会那么说。**
