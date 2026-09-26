# Phase 798 证据：原版 1.4.2 依赖清单差与 multidex

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——依赖清单面收尾。
证据源：两版 XAPK→base.apk 内 `META-INF/*.version`、
`META-INF/*.kotlin_module`、classes*.dex 清单。
Replay：`docs/migration/replays/d02-original-dependency-manifest.mjs`
ADR：`ADR-0742-original-dependency-manifest.md`

## 1. androidx .version 差（129→130）

**唯一新增**：`androidx.ink_ink-storage`。

修正认知：AndroidX Ink 笔刷引擎并非 1.4.2 新增——
1.0.3 已含六件：ink-authoring/brush/geometry/
nativeloader/rendering/strokes。1.4.2 仅增 **ink-storage**
（笔刷包持久化库）——与 776 `googleInkBrushPackId` 列 +
762 `.brushpack` 资产构成闭环：**1.4.2 的笔刷包是可
持久化/可下载的 Google Ink brush family**。

## 2. dex 与模块面

- classes.dex：3 → 4（multidex 增长，混淆类膨胀 +
  新功能面所致）。
- kotlin_module：4 → 4（模块结构稳定）。
- META-INF 其余为 vendor LICENSE/NOTICE（无行为面）。

## 3. Harmony 侧对照

Harmony 无 Google Ink 引擎（自研笔触管线）；
`googleInkBrushPackId` 归属 776/762 版本差簇。
ink-storage 本体为 AndroidX 库，不移植。

## 4. 结论

依赖清单面闭合：唯一实质差为 ink-storage（归 762/776
笔刷包簇）；dex 数与模块数为打包事实。
至此 1.4.2 证据面七维闭合：字符串/资源/资产/包/
manifest/工件/依赖。
