# 交付包（供审核 + 自行部署）

日期：2026-10-31
分支：`feat/r3-candidate` @ `22742d7`

---

## 1. APK 本体

| 项 | 值 |
|---|---|
| 路径 | `D:\code\apk-final\dsh-go-r3-arm64-debug-test.apk` |
| 包名 | **`io.github.ccch1mneyyy.dsh_app.test`** |
| 版本 | `1.0.2-test`（versionCode 10311321） |
| 大小 | 277 MB |
| SHA-256 | `3a2c24ea5a93d2e6e9d0d0db335d84ff1d2309d1b882cfc4f2fcd8f7a784c4fb` |
| 签名 | `CN=Android Debug, O=Android, C=US` |
| 证书 SHA-256 | `10cdb677f36a1f5b5a9762c190736b9fd64016876a378b9bdc9297bb5724b758` |

`verify_apk_runtime.py`：**exit 0，10/10 PASS**（运行时清单、插件名、启动带 `--patch`、
rootfs 在包内且哈希一致、插件三文件齐、加载配置含插件、`test/` 未打包、插件与仓库逐字节一致、
工具守卫在）。

## 2. ⚠️ 关键：这个包**不能覆盖**你手机上现有的 DSH Go

| | 你机上的 1.0.1 | 这个包 |
|---|---|---|
| 包名 | `io.github.ccch1mneyyy.dsh_app` | `…dsh_app.test` |
| 签名 | `CN=dsh-go, O=DSH-TUI`<br>`14371492…` | `CN=Android Debug`<br>`10cdb677…` |

三者都不同 → 它是**另一个 App**，与你的 1.0.1 **并存**。这正是当初为避免卸载正式版而选的路。

**如果你要的是「替换掉现有那个」**，需要你的正式签名密钥：

1. 把 `key.properties`（含 keystore 路径、别名、密码）放到 `app/android/`
2. 用 `flutter build apk --debug` 或 `--release` 构建（同包名）
3. 装上去就能覆盖 1.0.1，数据保留

**没有那把私钥，任何人也做不到覆盖。** 这是 Android 的设计。

## 3. 本次改动（相对上一版交付）

**间隔可自由输入**，不再是预设档位循环：

- 点「最短间隔」/「最长间隔」→ 弹输入框，填任意分钟数（1–10080）
- 超范围就在框里报错，**不会发到原生侧**
- 改最小值超过最大值时，最大值自动跟上（反之亦然）

顺带修掉两个真实 bug（都是测试跑出来的，不是猜的）：

1. 错误文案声明在 `StatefulBuilder` 内部 → 每次重建被重置，**提示永远不显示**
2. `TextEditingController` 在 `showDialog` 返回后立刻 dispose → 退场动画仍在读它，
   抛 `A TextEditingController was used after being disposed`（**你点间隔会直接崩**）

现在对话框是独立 `StatefulWidget`，自己管 controller。

## 4. 验证状态（如实标注）

| 项 | 状态 |
|---|---|
| JVM 108 项 | **PASS** |
| Flutter 页面/转发 38 项 | **PASS** |
| 主动搭话页 13 项（含新增的自由输入 3 项） | **PASS** |
| 插件单元 12 项 | **PASS** |
| 真实引擎 + 假模型 e2e 26 项 | **PASS** |
| `flutter analyze` | **无问题** |
| APK 内容校验 10 项 | **PASS** |
| **真机：安装、rootfs 解压、插件入包、路由鉴权、引擎运行、模型回复、页面渲染、会话列表、C 项权限页避让** | **PASS**（见 `R3_BUILD_REPORT.md` 真机一节） |
| **真机：主动搭话真实触发一次（Agent 回合 → 交互页 → 回执）** | **NOT_TESTED** |

最后一项就是留给你自己跑的那步：装好后打开主动搭话，把间隔设成 1 分钟，等它自己触发。

## 5. 部署步骤

```powershell
# 1) 装（与现有 1.0.1 并存，不覆盖）
adb install -r "D:\code\apk-final\dsh-go-r3-arm64-debug-test.apk"

# 2) 或直接拷 APK 到手机点安装
```

装完后在手机上：

1. 桌面会出现**第二个**「DSH Go」（同名，靠包名区分）
2. 系统设置 → 无障碍 → 会多一个 DSH 条目，**单独开启**
3. 打开测试包 → 设置 → 手机操控 → 主动搭话
4. 开开关，目标会话选一个活着的，间隔填 **1** 分钟
5. 等它自己触发，看回执

**注意**：两个包的桌面图标同名。想区分可以看「设置 → 应用 → 应用管理」里的包名，
测试包是 `…dsh_app.test`。

## 6. 卸载

```powershell
adb uninstall io.github.ccch1mneyyy.dsh_app.test
```

原 1.0.1 不受任何影响。

## 7. 代码位置

| 项 | 位置 |
|---|---|
| 分支 | https://github.com/aozhenyu666-cmyk/dsh-Go/tree/feat/r3-candidate |
| 提交 | `22742d7` |
| 离线 bundle | `D:\code\dshgo-r3.bundle`（需重导以含最新提交） |
| 真机证据 | `projects/18-dsh-go-core/evidence/device-*` |
| 完整报告 | `projects/18-dsh-go-core/R3_BUILD_REPORT.md` |

## 8. 审核要点（建议重点看）

1. `app/lib/ui/phone/proactive_page.dart` 的 `_MinutesDialog` 与 `_editMinutes`
2. `app/lib/update/update_config.dart` 的 `updatesEnabled`（测试包禁用更新）
3. `runtime/lib/rtbuild.py` 的目录裁剪（我修的 `test/` 空目录泄漏）
4. `loop/proactive/ProactiveRuntime.kt` 的 `holdAgent/flushHeldAgent`（端口未就绪时不判失败）
5. `loop/core/SnapshotStore.kt`（我改的备份 + 原子替换，Claude 的原文件）
