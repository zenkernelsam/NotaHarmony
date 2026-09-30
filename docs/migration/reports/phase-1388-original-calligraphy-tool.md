# Phase 1388 — 1.4.2 CALLIGRAPHY 凿尖笔工具移植

## 目标

落地 ADR-1323 选定的首个 1.4.2 A 类（本地可移植）特性：CALLIGRAPHY 凿尖笔。
原版 `eti.java` 将其作为独立工具（PEN 与 PENCIL 之间的 ordinal 1），不是第五种
笔刷样式。实现"垂直切片"：工具枚举 → 数据模型 → nib 参数解码 → 凿尖渲染 →
工具箱接入。

## 原版证据

- `eti.java`：CALLIGRAPHY(1) 独立工具。
- `aj1.java:48`：默认 nib `angle=π/2、flatness=0.75、stabilization`；
  `foa.java` NARROW/WIDE 预设。
- `zmb.java:135-137`：升级 SQL 把 CALLIGRAPHY 插在 `pen.trayIndex+1`，
  color=-16777216、widthSize=1.0、nib(1.5707964,0.75)。
- `cc3.G()`：全新装默认 CALLIGRAPHY@Primary index1；`F()/I()` 无专属井。
- `xal.java`：ink op 中 nib 定点 uint16（angle·2π/65536、flatness/65535）。
- `ui_tools__calligraphy`="Calligraphy"；`ui_designsystem__calligraphy_*` 5 层图标。

## 实现

| 层 | 变更 |
|----|------|
| 枚举 | `ToolType.CALLIGRAPHY = 10` |
| 模型 | `ToolState`/`RenderSpec` 加可选 `nibAngle/nibFlatness` |
| 默认 | `createDefaultStates` 插 CALLIGRAPHY@Primary index1（pen 后），黑/width1.0/nib 默认 |
| 下发 | `getRenderSpec` 仅书法笔下发 nib + `VARIABLE_WIDTH` |
| 渲染 | `WidthOutlineBuilder.setNib/nibScale(Δ)=sqrt(cos²Δ+f²·sin²Δ)`，门控 null |
| 链路 | `Canvas2DStrokeRenderer`(3)+`StrokeSession`+`OriginalInkPartialEraser` 传 nib |
| 解码 | `decodeNibAngle/FlatnessUint16`；CreateInk/ModifyInk 写入 renderSpec |
| UI | 5 层 `calligraphy` glyph、`toolGlyphKey`/`COLOR_GLYPHS`、`toolTypeLabel`→calligraphy 串 |
| 整形 | `shapeDetectionAvailable` 纳入 CALLIGRAPHY |

## 渲染说明（近似非逐位）

原版凿尖宽度由 Google Ink 引擎内部生成，逐点曲线未暴露。Harmony 采用"椭圆凿尖
截面的方向投影"近似：沿 nibAngle 最粗、垂直最细（×flatness）、连续过渡。
门控 `nibAngle=null` → 既有工具逐位不变（零回归）。

## 边界 / 后续

- 旧笔画与所有非书法笔 `nibAngle=null` → 渲染不变。
- nib 角/扁率独立设置 UI（`calligraphy_angle/flatness` 滑杆、NARROW/WIDE 预设）
  未含本切片——固定默认凿尖，后续可扩展。

## 验证

- Replay fixture `d02-original-calligraphy-tool.mjs`：49 项绿。
- 全量 Desktop Replay 基线：见提交说明。
- note@ohosTest / note@default：clean 构建成功。

## 产出

- 证据 `phase-1388-original-calligraphy-tool.md`；ADR `ADR-1324`；
  Replay `d02-original-calligraphy-tool.mjs`。
