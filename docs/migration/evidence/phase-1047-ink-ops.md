# Phase 1047 证据 — 墨迹操作载荷（20 字段大表）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `dm2` CreateInk（20 字段，toString 实名）

`{page, origin, rotation:Float, scale:qed, tool:u16, style,
tapePattern, color, width, encodedCenterPath, encodedCustomPath,
encodedFillPath, fillColor, styleMap, zIndex, audioDuration,
nibAngle, nibFlatness, inkEffects, inkEffectsTinted}`

- 编码路径三段：center/custom/fill（`lv2.w/B/E` 向量）。
- `u16` = 工具枚举 8 值（byte）：
  PEN=0 PENCIL=1 HIGHLIGHTER=2 TAPE=3 WHOLE_ERASER=4
  PARTIAL_ERASER=5 SELECTION=6 LASER=7。

## `gd` AddPathElements

`{ink, encodedCenterPathElements(lv2.y),
encodedCenterPathEstimatedElements(lv2.z)}`——
校验逐一 `ddg.b(po4)` 校验路径点（`di7` 向量 slot6）。

## `wd8` ModifyInk（19 字段）

`{inks:list(lv2.M), page, origin, rotation, scale, style,
color, width, 三段编码路径(lv2.x/C/F), fillColor, styleMap,
zIndex, nibAngle, nibFlatness, tapePattern, inkEffects,
inkEffectsTinted}`——比 CreateInk 少 audioDuration、多 inks 列表。

## 校验（`a()` 实测）

- `dm2`：tool≠TAPE 时禁 tapePattern（"Cannot specify a
  TapePattern while Tool is not Tape"）；origin/rotation/
  scale/width 经 `ddg.k/l/j`。
- `gd`：逐点 `ddg.b(po4)`（azimuth/altitude/width/force）。
- `wd8`：inks>0（"Must specify more than 0 inks"）；
  禁置空 centerPath（"Should not be possible to nil out
  centerPath"）。

## `po4` = 触控笔采样点

普通类 `{t8a, b/c/d:long, f:float, g:double, h:long}`，
`s8a.b` 哨兵默认；`ddg.b` 校验 azimuth/altitude/width/force。

## HarmonyOS 决策

- 墨迹三段编码路径+20 字段语义保留；u16 8 工具 wire 对齐。
- po4 点校验（azimuth 单位向量、altitude≤π/2、width/force
  有限非负）逐条保留。

## 产出

- fixture `d02-ink-ops.mjs`（12 断言）。
- ADR-0991；中文报告。
