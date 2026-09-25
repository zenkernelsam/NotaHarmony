# 原版 MainActivity 生命周期方法审计证据（JADX，decompiled_1.0.3）

证据日期：2026-09-25
证据来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
目标文件：`sources/com/gingerlabs/notability/app/MainActivity.java`

ADR-0679 已审计清单属性（label/launchMode/windowSoftInputMode/showWhenLocked/
任务亲和/深链 skill 等声明式语义）。本页补完**方法级**生命周期面：
MainActivity 全部覆写方法逐项对源，确定每个钩子在原版的真实用途与
Harmony 对应处置。

## 方法级清单（MainActivity.java）

| 方法 | 原版行为（JADX 行） | 关键调用 | Harmony 处置 |
| --- | --- | --- | --- |
| `onCreate` | 组件装配 + `j().b(this.V)` 注册更新监听（279/368/392 行） | `s3i.b` Play AppUpdate 监听注册 | 见下「应用内更新」 |
| `onNewIntent` | `setIntent` + `k().i(intent)`（~539 行） | `hv7.i` 意图协程分发 | ✅ 已移植：`LaunchActionIngress`/Want 复投 |
| `onSaveInstanceState` | 持久化 `showWhenLockedPolicy` 布尔（~574 行起） | `bundle.putBoolean` | ✅ ADR-0679 已登记（锁屏上显示策略） |
| `onProvideKeyboardShortcuts` | `list.addAll(kmi.a(resources))`（552-557 行） | `kmi` 键盘快捷键帮助组 | ✅ ADR-0668 登记为 Android 系统快捷键面板边界 |
| `onResume` | 注册加速度计监听（`SensorManager.getDefaultSensor(1)` + `registerListener(l4d,…,3)`，562-569 行）；Play 渠道时 `j().a().addOnSuccessListener(x17(4))` 恢复更新提示（570-573 行） | `l4d` 摇晃检测；`s3i.a` | 见下「摇晃调试菜单」「应用内更新」 |
| `onPause` | `unregisterListener(l4d)`（546-548 行） | 仅注销传感器 | ✅ 语义对齐：Harmony 无该订阅 |
| `onDestroy` | `j().d(this.V)` 解绑更新监听；`hd5` 释放（identityHashCode 守卫）；`xod` SPen Quick Tools 释放（497-534 行） | `s3i.d`/`hd5`/`xod` | Play 更新边界 / SPen 已登记 ADR-0671 / `hd5` 见下 |

## 摇晃 → 内部调试菜单（`l4d` + `kw2` + `tw2` + `h96`）

`defpackage/l4d.java`：SensorEventListener 实现 —
- 只处理 `sensor.getType() == 1`（TYPE_ACCELEROMETER）。
- `sqrt(x²+y²+z²) / 9.80665 < 2.7f` 即返回 —— **加速度阈值 2.7 g**。
- `System.currentTimeMillis() - b < 1000` 即返回 —— **1 秒防抖**。
- 触发 `nu7(this,1)`：`hasWindowFocus()` 为真时 `kw2.a()`。

`defpackage/kw2.java`：`a()` 先经 `h96.a()` 门控，翻转 `asd b`
（调试面板显隐），并在隐藏时把 `asd d` 归位 `tw2.HOME`。

`defpackage/tw2.java`：枚举即调试菜单页面 ——
`HOME("Debug")`、`FEATURE_FLAGS("Feature Flags")`、`PREFERENCES`、
`LEARN`、`RESET`、`SUPPORT_INFO`、`ANALYTICS_EVENTS`、`LOGS`、
`LOG_TAGS`、`BACKEND`、`SUBSCRIPTION`。

`defpackage/h96.java`：门控集合 `c = {"gingerlabs.com","notability.com"}`，
`a()` 由登录账号邮箱域名（`ko4.f(yrd…)`）推出 —— **仅 Gingerlabs
内部账号可见**。

→ 结论：摇晃手势只是**面向 Gingerlabs 员工的内部调试入口**，非用户
功能。Harmony 不挂载（fail-closed：无加速度计订阅、无调试面板），
ADR-0681 登记。

## 应用内更新（`s3i`）

`defpackage/s3i.java`：import `com.google.android.play.core.install.*`
（`InstallException` 等），`xbj`/`bkh` 即 Play `AppUpdateManager`/
`InstallStateUpdatedListener` 族。生命周期：

- `onCreate`：`j().b(this.V)` 注册 InstallState 监听（392 行）。
- `onResume`：`j().a().addOnSuccessListener(x17(this,4))` ——
  检查是否有下载完成/进行中的更新并恢复提示（570-573 行）。
- `onDestroy`：`j().d(this.V)` 解绑监听（499 行）。
- 全部路径以 `((z46) i().R0.invoke()).a == y46.PlayStore` 渠道门控
  —— 非 Play 分发构建不启用。

→ 结论：**Play AppUpdate 平台边界**。HarmonyOS 应用更新由
AG（AppGallery）渠道与系统更新机制承担，无应用内 API 对应；
ADR-0681 登记为 fail-closed。

## `hd5` onDestroy 释放

`defpackage/hd5.java`：以 `System.identityHashCode(this)` 判定归属
Activity，命中时 `asd.k(null,FALSE)` 复位显隐、`j/k` 重置为
`qw3.I` 并 `xj2.A` 起协程清理。字段含 `em8`（绘图工具控制器）
与 RecyclerView 适配器，为库页/编辑器共享的 UI 控制器生命周期收尾。
Harmony 侧各页面通过 aboutToDisappear/组件析构自管，无全局
identityHashCode 所有者表 —— 结构性差异，无需移植。

## `xod`（SPen Quick Tools）释放

`xod.c` 同样以 identityHashCode 做归属守卫，非持有者 Activity 的
onDestroy 打日志忽略。SPen 依赖边界已由 ADR-0671 登记，本页仅
补生命周期挂载点证据。

## 涉及原版符号

`MainActivity.java`（app 包）；`defpackage`: `l4d` `nu7` `kw2` `tw2`
`h96` `s3i` `xbj` `bkh` `hd5` `xod` `qw3` `y46` `z46` `kmi` `hv7`；
`com.google.android.play.core.install.InstallException`。

## 未验证声明

调试菜单内部页面（Feature Flags 覆盖、日志查看等）的真实 UI 未在
Harmony 复现（fail-closed 项，无需复现）；摇晃阈值 2.7 g / 1 s 防抖
为 JADX 静态读数。
