# Phase 1388 — 1.4.2 CALLIGRAPHY 凿尖笔工具（垂直切片）

## 来源证据（decompiled_1.4.2）

### 工具枚举 `defpackage/eti.java`
1.4.2 工具枚举在 PEN 与 PENCIL 之间插入 `CALLIGRAPHY(1)`，末尾新增 `SHAPE(14)`：
```
PEN(0) CALLIGRAPHY(1) PENCIL(2) HIGHLIGHTER(3) TEXT(4) ERASER(5)
SELECT(6) MEDIA(7) RECORD(8) POINTER(9) LASER(10) REVIEW(11)
RULER(12) ZOOM(13) SHAPE(14)
```
→ CALLIGRAPHY 是**独立工具**，不是第五种笔刷样式。

### 默认 nib `defpackage/aj1.java:48`
`CalligraphySelection`/`aj1` 默认构造：`nibAngle=π/2（1.5707964f）`、
`nibFlatness=0.75f`、`stabilization=true`。
- `nibAngle` = 凿尖"最粗运笔方向"（弧度）。
- `nibFlatness` ∈ (0,1] = 窄宽比；1=圆头（无方向差），越小方向差越强。

### nib 预设枚举 `defpackage/foa.java`
```
foa.NARROW(0) / foa.WIDE(1)   — 两个扁率预设（窄/宽凿尖）
```

### 升级/默认播种 `defpackage/zmb.java:135-137` + `cc3.java`
升级 SQL（`calligraphy_seed`）把 CALLIGRAPHY 插在 **`pen.trayIndex + 1`**：
```sql
INSERT INTO ToolStateEntity (tray_owner_id,toolType,trayIndex,color,
  selectedColorWellIndex,widthSize,selectedWidthSizeWellIndex,
  nibAngle,nibFlatness,stabilization)
SELECT tray_id,'CALLIGRAPHY',anchor+1,-16777216,0,1.0,0,1.5707964,0.75,1
```
`cc3.G()` 全新装默认同样 `CALLIGRAPHY@Primary index 1`（`eti.G` + `new aj1()`），
`color=-16777216`、`widthSize=1.0f`。

**色井/宽井**：`cc3.F()`（FavoriteColorWell）与 `cc3.I()`（WidthSizeWell）种子
列表中均**无 `eti.G`(CALLIGRAPHY) 行** → 原版书法笔无专属预设井，仅默认
color=黑、width=1.0。

### ink 量化 `defpackage/xal.java`
CreateInk/ModifyInk 的 nib 字段以定点 uint16 序列化（`g(d,range,signed)`）：
- `nibAngle`：signed=true、range=2π → `raw = round(angle·65536/2π)`，
  解码 `angle = raw·2π/65536`。
- `nibFlatness`：signed=false、range=1 → `raw = round(f·65535)`，
  解码 `f = raw/65535`。

### 标签 / 图标
- `ui_tools__calligraphy` = "Calligraphy"（strings.xml:2051）。
- `ui_tools__calligraphy_angle` = "Angle: %1$d°"；`ui_tools__calligraphy_flatness` = "Flatness: %1$.2f"（设置页 nib 滑杆）。
- 工具箱图标 = 5 层 `ui_designsystem__calligraphy_{fill,outline,highlight,shadow,overlay}`（24×24，描边 1.25）。

## 渲染说明（近似，非逐位）

原版凿尖宽度最终由 **Google Ink** 笔刷引擎内部计算（`CalligraphyNib(angle,flatness)` → brush pack），
其逐点曲线/roll 模型未在反编译代码中暴露。**Harmony 采用几何近似**：
```
radius = baseHalfWidth(widthFactor, baseWidth) · nibScale(Δ)
nibScale(Δ) = sqrt(cos²Δ + f²·sin²Δ)，Δ = 运笔方向 − nibAngle
```
沿 nibAngle 运笔最粗（=1）、垂直最细（=flatness），中间连续过渡——与"椭圆凿尖
截面的方向投影"一致。`nibAngle=null` 时 `nibScale≡1`，非书法笔渲染逐位不变。

## Harmony 落地（本 Phase）

| 层 | 变更 |
|----|------|
| 枚举 | `ToolType.CALLIGRAPHY = 10`（BrushTypes.ets） |
| 模型 | `ToolState.nibAngle/nibFlatness`、`RenderSpec.nibAngle/nibFlatness`（可选 null） |
| 默认 | `createDefaultStates` 插 CALLIGRAPHY@Primary index1（pen 后），color=-16777216、width=1.0、nib(π/2,0.75)；无专属井 |
| 下发 | `getRenderSpec` 仅 CALLIGRAPHY 下发 nib + `InkStyle.VARIABLE_WIDTH` |
| 渲染 | `WidthOutlineBuilder.setNib/nibScale` 调制半径；`Canvas2DStrokeRenderer`(3 处)+`StrokeSession`+`OriginalInkPartialEraser` 传 nib |
| 解码 | `OriginalInkPathCodec.decodeNibAngle/FlatnessUint16`；CreateInk/ModifyInk 写入 renderSpec |
| UI | `TOOL_GLYPHS['calligraphy']`（5 层）+ `toolGlyphKey` 映射 + `COLOR_GLYPHS` 着色 + `toolTypeLabel`→`calligraphy` 串（base "Calligraphy"/zh "书法笔"） |
| 整形 | `shapeDetectionAvailable` 纳入 CALLIGRAPHY（笔族） |

## 边界
- 旧笔画/非书法笔 `nibAngle=null` → 渲染逐位不变。
- nib 角/扁率滑杆（`calligraphy_angle/flatness` 设置页）本切片未含独立 UI——走默认凿尖；后续可加 nib 预设选择。

## 验证
- `node docs/migration/replays/d02-original-calligraphy-tool.mjs` → 49 checks。
- 全量 Replay 基线 1241 个 fixture；`note@ohosTest` + `note@default` 双构建。
