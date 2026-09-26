# Phase 778 证据：原版 1.4.2 钢笔增强面（书法笔尖/笔刷样式标签/防抖）

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）
证据源：`decompiled_1.4.2`（strings.xml、`defpackage/{ox5,px5,s01,k9m,lnc,ij1,svi,ca3}.java`）；
`decompiled_1.0.3`（strings.xml、`defpackage/{e47,ba8}.java`）对照。
Replay：`docs/migration/replays/d02-original-pen-enhancements.mjs`
ADR：`ADR-0722-original-pen-enhancements.md`

## 1. 笔尖模型（1.4.2 新增）

`qx5` 为笔尖密封接口，两实现：

- `px5` — `Standard`（单例默认，`toString()="Standard"`）。
- `ox5` — `CalligraphyNib(nibAngle REAL, nibFlatness REAL)`。

`s01.f()`：PEN 工具且 `nibFlatness`（`mn7.c0()`）非空时构造
CalligraphyNib；angle 缺省 `1.5707963267948966`（π/2），flatness
缺省 `0.0`。`k9m`/`lnc` 渲染器将 (angle,flatness) 经 `jmc.b()`
转成书法笔画几何。

## 2. ToolStateEntity 列差（精确比对）

| 列 | 1.0.3 | 1.4.2 |
|---|---|---|
| `style` | INTEGER | **TEXT**（枚举序列化改字符串） |
| `nibAngle` | — | REAL（新） |
| `nibFlatness` | — | REAL（新） |
| `stabilization` | — | INTEGER（新） |
| `googleInkBrushPackId` | — | INTEGER（Phase 776 已登记） |
| `shapeKind` | — | TEXT（Phase 776 已登记） |
| `penLastStandardColorWellIndex` | — | INTEGER（Phase 776 已登记） |
| `tapePattern`/`selectionIsFreehand`/`eraserIsPartial` | 已存在（ba8 迁移补齐） | 沿用 |

## 3. 字符串差（1.0.3 全缺席）

```xml
ui_tools__calligraphy            Calligraphy
ui_tools__calligraphy_angle      Angle: %1$d°
ui_tools__calligraphy_flatness   Flatness: %1$.2f
ui_tools__brush_style_fixed      Fixed
ui_tools__brush_style_variable   Variable
ui_tools__brush_style_dashed     Dashed
ui_tools__brush_style_dotted     Dotted
ui_tools__stabilization          Stabilization
```

`ij1` 在钢笔选项面板渲染 Stabilization 行（`oye.w0` 取串 +
开关控件）；`svi` 的 SELECT 枚举 18 列证实全部列进入 DAO 读写。

## 4. Harmony 现状

- BrushStyle MONO/TAPER/DASH/DOT ↔ InkStyle FIXED_WIDTH/
  VARIABLE_WIDTH/DASH/DOTS 已移植（1.0.3 内部枚举面）。
- **无** nibAngle/nibFlatness/stabilization/书法笔尖概念。

## 5. 分类结论

- 书法笔尖（角度+扁度几何）+ 防抖开关：纯本地笔画几何/参数，
  **本地候选**（可移植，回移评审待定）。
- style INTEGER→TEXT：原版内部迁移，Harmony 无需对应。
- 笔刷样式本地化标签：随选择器 UI 一并属本地候选。
