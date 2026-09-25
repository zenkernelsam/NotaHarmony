# ADR-0681: 原版 MainActivity 生命周期方法尾审（摇晃调试菜单 / Play 应用内更新）

- 状态：已接受（登记 + 平台边界 fail-closed）
- 日期：2026-09-25
- 阶段：Phase 733
- 证据：`docs/migration/evidence/original-mainactivity-lifecycle-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-mainactivity-lifecycle.mjs`

## 背景

ADR-0679（Phase 731）审计了 `AndroidManifest.xml` 中 MainActivity 的
声明式属性（launchMode、windowSoftInputMode、showWhenLocked、
taskAffinity、深链 skill）。本 ADR 补完该文件的**方法级生命周期**：
`onCreate`/`onNewIntent`/`onResume`/`onPause`/`onDestroy`/
`onSaveInstanceState`/`onProvideKeyboardShortcuts` 七个覆写方法
逐项对源，MainActivity.java 至此全量关闭。

## 原版行为

| 方法 | 原版行为 | 处置 |
| --- | --- | --- |
| `onNewIntent` | `k().i(intent)` → `hv7` 意图协程分发 | ✅ 已移植（LaunchActionIngress/Want 复投） |
| `onSaveInstanceState` | 持久化 `showWhenLockedPolicy` | ✅ ADR-0679 已登记 |
| `onProvideKeyboardShortcuts` | `kmi.a` 快捷键帮助组 | ✅ ADR-0668 边界登记 |
| `onResume`/`onPause` | 注册/注销加速度计 `l4d` | 摇晃调试菜单（见下） |
| `onResume`/`onCreate`/`onDestroy` | `s3i` Play 更新监听注册/恢复/解绑 | Play 边界（见下） |
| `onDestroy` | `hd5`/`xod` 归属守卫释放 | 结构性收尾 / SPen ADR-0671 |

### 摇晃 → 内部调试菜单

`l4d` 监听 TYPE_ACCELEROMETER：合加速度 ≥ 2.7 g 且距上次触发
≥ 1 s 时回调 `kw2.a()`（要求窗口持焦）。`kw2` 经 `h96` 门控
（登录邮箱 ∈ {gingerlabs.com, notability.com}）翻转调试面板显隐；
`tw2` 枚举给出页面集：`HOME("Debug")`、`FEATURE_FLAGS`、
`PREFERENCES`、`LEARN`、`RESET`、`SUPPORT_INFO`、
`ANALYTICS_EVENTS`、`LOGS`、`LOG_TAGS`、`BACKEND`、
`SUBSCRIPTION`。

### Play 应用内更新（`s3i`）

`s3i` 封装 Play `AppUpdateManager` 族（`com.google.android.play.core.
install.*`）：`onCreate` 注册 InstallState 监听，`onResume` 恢复
进行中的更新流程，`onDestroy` 解绑；全部以 `y46.PlayStore` 分发
渠道门控。

## 决策

1. **摇晃调试菜单：fail-closed 登记**。它是面向 Gingerlabs 内部账号
   的开发工具，不是用户功能；Harmony 不订阅加速度计、不挂载调试
   面板。若未来需要诊断入口，应走 Harmony 开发者菜单/HiLog 通道，
   而非复刻摇晃手势。
2. **Play 应用内更新：平台边界 fail-closed**。HarmonyOS 应用更新由
   AppGallery 渠道与系统更新机制承担，无应用内 API 对应物；原有
   `app__update_*` 字符串已在 ADR-0664（`app__` 尾项）随 Play 边界
   登记。
3. **`hd5`/`xod` 释放语义**：原版以 `System.identityHashCode` 做
   Activity 归属守卫。Harmony 各页面/控制器在 `aboutToDisappear`/
   析构中自管生命周期，无全局所有者表 —— 结构性差异，行为等价
   无需移植。SPen Quick Tools 本体已由 ADR-0671 登记。
4. 其余方法均已在此前阶段对齐或登记，本 ADR 仅补证据链闭合。

## Harmony 侧对应

- 无新增代码：两个目标面均为登记项。
- 已有对应物：`LaunchActionIngress`（onNewIntent）、ADR-0679
  （showWhenLocked/launchMode）、ADR-0668（kmi 快捷键面板）、
  ADR-0671（SPen 释放语义）、ADR-0664（Play 更新字符串边界）。

## 边界与限制

- 摇晃阈值 2.7 g / 1 s 防抖为 JADX 静态读数，未做真机复现（内部
  功能无需复现）。
- `h96` 域名门控依赖登录账号邮箱，Harmony 登录面整体 fail-closed
  （ADR-0662），调试菜单不可达是必然结果而非额外缺失。
- 未做模拟器/真机/Hypium 验证。
