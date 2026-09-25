# Phase 737 报告：app/initializers 尾项 + 高对比度文字 a11y 边界

- 日期：2026-09-25
- 性质：收口登记 + 新边界登记（无代码改动）
- ADR：ADR-0685
- 证据：`original-initializers-hct-jadx-2026-09-25.md`
- Replay：`d02-original-initializers-hct.mjs`

## 背景

Phase 736 关闭 NbApplication.onCreate 后，`app/` 包尚余两个
androidx.startup `g06` Initializer（`AppStartupInitializer`、
`LoggingInitializer`）与 `MissingNativeLibraryActivity`。本阶段逐项
审计并关闭 `app/` 包最后一个面。

## 新发现：高对比度文字（HCT）管线

原版把 Android `Settings.Secure high_text_contrast_enabled` 接入
墨迹渲染：

- `je5` ContentObserver 监听设置变更 → `ke5.a(context)` 重读
  原子标志；
- `ie5.a(bitmap)` 画布工厂在 HCT 开启时返回 `bh5`（`Canvas`
  子类，HCT 适配绘制路径），`vw7` 渲染分支亦消费该标志；
- `ie5.b` 记 "framework HCT path is broken on this device" 兜底。

HarmonyOS `@ohos.accessibility` 公开 API 无 HCT 查询能力
（仅有 accessibility/touchGuide/screenReader/touchMode/captions
事件与查询），也无墨迹层 Canvas 文字剥离机制 → **平台边界
fail-closed**，登记不移植。

## 其余登记项

| 项 | 处置 |
| --- | --- |
| `Rive.init` + `MissingNativeLibraryActivity` | Rive 运行时不打包（ADR-0663），.so 缺失态不存在 → 边界 |
| `backend_override` SharedPreferences | 内部后端环境覆盖后门 → fail-closed |
| `is1.j0`/`ec4`/`q36`/`iw2`/`hw2`/`lc4.e`/`v50`/`h6g`/`sl` | datastore/DI/协程内部管线 |
| `dependencies()` | androidx.startup 机制本身 → 平台机制 |

## 验证

- 专项 Replay：22 项断言。
- 无代码改动；全量套件 + 双 HAP 按协议复验。

## 已知差异

- HCT 开启用户的墨迹文字观感在 Harmony 侧无适配路径（无 API
  可接）；边界解除条件为 HarmonyOS 开放高对比度文字查询。
