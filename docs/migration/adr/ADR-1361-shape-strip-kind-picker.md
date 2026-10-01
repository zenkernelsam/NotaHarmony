# ADR-1361：SHAPE 次级条种类选择器（iw4 case8 / qri.a / h5g）移植裁决

- 状态：Accepted
- 关联：ADR-1339（SHAPE 工具本体）、ADR-1343（凿尖工具次级条）、
  evidence `phase-1425-shape-strip-kind-picker.md`

## 背景

原版 1.4.2 SHAPE 工具的次级工具条是 `qri.a` 可展开容器：折叠态渲染
`h5g.c`（当前种类 48×48 图标钮），点击后展开为 `h5g.a` 六种类图标行
（`h5g.b` 单元格，accent 高亮，`ui_tools__shape_*` a11y，顺序 =
`r5g` 枚举序）。Harmony 此前只在工具箱设置面板内提供
`ShapeKindPicker`，编辑器内无即点即换入口。

## 决定

在 `EditorToolbar` 新增 SHAPE 分支（calligraphy 之后、笔刷样式行之前）：

- 折叠态渲染当前 `activeShapeKind` 的 compact `ShapeKindSwatch`
  （36dp 图标、无文字、`shape_*` a11y）。
- 点击折叠钮把 `@State shapeKindExpandedFor` 置为当前 SHAPE 工具 id →
  展开为 `SHAPE_KIND_ORDER` 六格行，选中项 accent 描边。
- 选择经 `EditorViewModel.setActiveShapeKind` → `setToolShapeKind`
  持久化到 `ToolState.shapeKind`，与设置面板共用同一数据路径。
- 展开状态以工具 id 为键：工具切换即自然失配折叠，对齐 `qri.a`
  会话复位语义。
- `photoImportLeaseActive` 门控展开与选择；无 SHAPE 行时
  `activeShapeToolId()` 返回 `''`，渲染期不抛。

## 适配说明

- 单元格尺寸：原版 48×48；Harmony 次级条行高 40，故 compact swatch =
  36dp 图标 + 2 边距，触控目标约 40×40。属行高适配，非语义差异。
- 选中后保持展开直至工具切换。原版 `nri` 会话的"选中即收起"精确时机
  在反编译中不可完全判定；保持展开利于连续换形状，为可辩护适配。
- a11y 完整对齐：六个 `ui_tools__shape_*` 标签逐一映射。

## 渲染边界（经 Phase 1426 纠错后确认：无缺口）

初版误判：曾以为原版 SHAPE 描边经 `ox5(aj1.a, aj1.b)` 应用凿尖几何。
更正后的证据链：SHAPE 工具状态 `psi` **没有** `aj1` 字段
（psi.f = r5g 种类）；`cc3.H()` 默认样式表给 `eti.T`（SHAPE）的
`zsi.h` 恒为 null；`lnc.u()` 因此落到 `k9m.b()` 的 `px5` 支 =
`jmc.c(f01, d)`——均匀宽圆头路径（`ox5`/`jmc.b` 凿尖支仅在
`aj1` 非空的 CALLIGRAPHY 来源元素上命中）。Harmony `strokeShape`
的固定 `setLineWidth` + round cap/join + DASH/DOTS 线型即
`px5.a` Standard 语义的精确对等——**无渲染缺口**。

## 验证

`d02-original-shape-strip-kind-picker.mjs` 13 项断言全绿；
全量 Replay 基线 + note@default + clean note@ohosTest 见 Phase 1425 报告。
