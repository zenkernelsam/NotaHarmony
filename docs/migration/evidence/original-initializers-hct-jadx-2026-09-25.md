# 原版 app/initializers + MissingNativeLibraryActivity + 高对比度文字管线审计证据（JADX，decompiled_1.0.3）

证据日期：2026-09-25
证据来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources`

继 NbApplication.onCreate（Phase 736）之后，本页关闭 androidx.startup
`g06` Initializer 入口与 `app/` 包最后一个组件
`MissingNativeLibraryActivity`，并登记发现的真实 a11y 边界。

## 1. `app/initializers/AppStartupInitializer.java`（androidx.startup `g06`）

`create()` 体逐项：

- `is1.j0 = new kd(nbApplication, 1)` —— 静态注入 application ref。
- `Rive.init$default(Rive.INSTANCE, nbApplication, …)` —— Rive 原生
  库初始化；失败双路径：日志 "Failed to initialize Rive" /
  "Rive native library missing"（后者经 `vv7.R(new xn7())` 结构化
  日志 + `xn7` map）。→ Rive 运行时边界（ADR-0663 系列已登记）。
- `xj2.A` ×4 —— `b60`/`c60`/`a60` 协程冷启动任务（混淆，消费面
  为 datastore/同步/分析管线）。
- `ec4(nbApplication)` + `q36` + `lc4.e = cq.g0(km4(yrd…))` ——
  DataStore/共享流装配。
- `iw2`/`hw2.e` —— 同上流式装配。
- **`ke5.b.compareAndSet` 分支：向 `Settings.Secure.getUriFor(
  "high_text_contrast_enabled")` 注册 `je5` ContentObserver，
  `ke5.a(context)` 立即初读** —— 见下第 3 节。
- `ie5.a.getValue()` —— 预热 HCT Canvas 工厂判定。
- `v50`/`h6g` —— DI 管理器协程。
- `Build.VERSION.SDK_INT >= 35` → `sl(nbApplication,null,2)` 协程 ——
  API-35（Android 15）条件初始化。
- `dependencies()` —— androidx.startup 依赖表。

## 2. `app/initializers/LoggingInitializer.java`

- 读 `SharedPreferences "backend_override"` 的 `url` 键
  （`lvd.d1` 规范化）—— **内部后端环境覆盖**（工程/测试后门）。
- 其余为日志/分析管线初始化（`dsf`/`e68`/`fm9`/`lr9`/`mm7`/
  `tl7`/`uc4`/`z5c` 等）+ `UserDataStoreInitializer`/
  `NoteEditorSettingsInitializer`/`HapticPreferencesInitializer`/
  `ThemeDataStoreInitializer` 依赖声明。

## 3. 高对比度文字（HCT）管线 —— 真实 a11y 边界

原版把 Android `Settings.Secure "high_text_contrast_enabled"`
接进墨迹渲染：

- `ke5`：`a` = HCT 标志原子位；`b` = observer 注册守卫；
  `a(context)` 读 Secure 设置，变化时打 RENDERER 日志
  （`high_contrast_text.enabled` 负载）。
- `je5`（ContentObserver，`a=0` 分支）：设置变更即回调
  `ke5.a(context)` 重读。
- `ie5.a(bitmap)`：画布工厂 —— `ke5.a.get()` 且 `a.getValue()`
  为 false 时返回 **`bh5`**（`Canvas` 子类，HCT 适配绘制路径），
  否则普通 `Canvas`；`ie5.b` 记录 "framework HCT path is broken
  on this device" 兜底。
- `vw7.java:821`：`ke5.a.get()` 参与渲染分支条件。

HarmonyOS 侧核查：`@ohos.accessibility`（SDK d.ts）公开 API 仅
`isOpenAccessibility`/`isOpenTouchGuide`/`isScreenReaderOpenSync`/
`getTouchModeSync`/`getCaptionsManager` + 状态变更事件 —
— **无高对比度文字查询公开 API**，亦无墨迹层 Canvas 文字
剥离机制。→ 平台边界 fail-closed，登记不移植。

## 4. `app/MissingNativeLibraryActivity.java`

- onCreate：`AlertDialog`，标题/文案
  `app__missing_native_library_title/message`，`setCancelable(false)`，
  唯一按钮 `android.R.string.ok` → `pu7(this,3)`。
- 触发链：Rive `.so` 缺失时由 startup 拉起。Harmony 不打 Rive
  运行时（ADR-0663），不存在 .so 缺失态 → 边界登记。

## 涉及原版符号

`AppStartupInitializer`、`LoggingInitializer`、
`MissingNativeLibraryActivity`；`defpackage`: `is1` `kd` `ec4`
`q36` `lc4` `rt2` `iw2` `hw2` `ke5` `je5` `ie5` `bh5` `vw7`
`v50` `h6g` `sl` `xn7` `vv7` `y50` `b60` `c60` `a60` `lvd`
`pu7` `fwe`；`Rive.init`、`MissingNativeLibraryActivity`、
`Settings.Secure "high_text_contrast_enabled"`。

## 未验证声明

- `bh5` 的具体绘制改写不可见（JADX 空体子类，逻辑在
  Canvas 原生层）；HCT 在墨迹上的观感差异未做像素级复现。
- `sl` SDK35 分支的具体初始化内容未展开（协程合成类）。
