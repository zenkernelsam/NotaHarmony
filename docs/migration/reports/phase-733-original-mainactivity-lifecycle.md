# Phase 733 报告：原版 MainActivity 生命周期方法尾审

- 日期：2026-09-25
- 性质：登记 + 平台/内部边界 fail-closed（无代码改动）
- ADR：ADR-0681
- 证据：`original-mainactivity-lifecycle-jadx-2026-09-25.md`
- Replay：`d02-original-mainactivity-lifecycle.mjs`

## 背景

Phase 731（ADR-0679）审计了 MainActivity 的清单声明属性。本阶段对
`MainActivity.java` 的全部覆写方法做方法级审计，使该文件在
「属性 + 方法」两个维度均完整关闭。

## 审计结论

| 覆写方法 | 原版行为 | 处置 |
| --- | --- | --- |
| `onNewIntent` | `hv7.i` 意图协程分发 | 已移植（LaunchActionIngress） |
| `onSaveInstanceState` | `showWhenLockedPolicy` 持久化 | ADR-0679 已登记 |
| `onProvideKeyboardShortcuts` | `kmi` 快捷键帮助组 | ADR-0668 已登记（平台边界） |
| `onResume`/`onPause` | 加速度计 `l4d` 注册/注销 | 摇晃调试菜单 → fail-closed |
| `onCreate`/`onResume`/`onDestroy` | `s3i` Play 更新监听全周期 | Play 边界 → fail-closed |
| `onDestroy` | `hd5`/`xod` identityHashCode 归属释放 | 结构差异，行为等价 |

## 新登记两项

### 1. 摇晃 → 内部调试菜单

- `l4d`：加速度计监听，合加速度 **≥ 2.7 g** 且 **1 s 防抖** 后回调。
- `kw2.a()`：经 `h96` 门控（登录邮箱限 gingerlabs.com /
  notability.com 域名）翻转调试面板显隐。
- `tw2` 枚举即菜单：Debug / Feature Flags / Preferences / Learn /
  Reset / Support Info / Analytics Events / Logs / Log Tags /
  Backend / Subscription。
- 判定：**Gingerlabs 内部开发工具，非用户功能**。Harmony 不订阅
  加速度计、不挂载调试面板 —— fail-closed。

### 2. Play 应用内更新（`s3i`）

- `s3i` 封装 `com.google.android.play.core.install.*`（AppUpdateManager
  / InstallStateUpdatedListener 族），以 `y46.PlayStore` 渠道门控。
- HarmonyOS 应用更新由 AppGallery 渠道 + 系统机制承担，无应用内
  API 对应物 —— 平台边界 fail-closed（字符串面已由 ADR-0664
  覆盖）。

## 验证

- 专项 Replay：39 项断言全绿。
- 全量 Desktop Replay：616/616 → 见下方复跑结果。
- 无 ArkTS 代码改动；双 HAP clean 构建按协议复验。

## 已知差异

- 摇晃手势在 Harmony 无任何映射（内部功能刻意不移植）。
- 调试菜单内部页面未复现（fail-closed 项）。
- `hd5`/`xod` 的 identityHashCode 归属守卫在 Harmony 由页面
  析构/自管生命周期替代，属结构性差异而非行为缺失。
