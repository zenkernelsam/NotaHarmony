# Phase 1425 证据：SHAPE 次级条种类选择器（iw4 case8 → qri.a + h5g.a/c）

## 原版证据链（decompiled_1.4.2）

### 次级条宿主

`iw4.java` case 8 为 SHAPE 工具的次级工具条构建分支，产出 `qri.a` 可展开
容器。`qri.a` 维护展开状态：折叠时渲染摘要控件，点击摘要（`jri` 回调）切换
为展开态；展开态随当前工具会话结束/工具切换复位。

### 折叠态：`h5g.c`

- 48×48 图标钮，内嵌当前 `r5g` 种类图标（`h5g.b` 的紧凑渲染形态）。
- 内容描述 = `ui_tools__shape_<kind>`（六个种类各自一条资源）。

### 展开态：`h5g.a` + `h5g.b`

- `h5g.a` 渲染一行六个 `h5g.b` 单元格，顺序即 `r5g` 枚举序：
  `RECTANGLE → ELLIPSE → DIAMOND → TRIANGLE → ARROW → LINE`。
- `h5g.b` 单元格：图标渲染 + 选中项以 accent 高亮（描边/底色），
  a11y 文本 = 对应 `ui_tools__shape_*`。
- 点击单元格把该 kind 写回当前 SHAPE 工具的持久化选择
  （`sri` 状态记录），展开态随后收起/保持至会话结束。

## Harmony 移植前缺口

- `ToolState.shapeKind`、`ShapeKind` 六值、`ShapeKindPicker`（工具箱设置面板
  内选择器）均已存在——**数据与设置面板路径完整**。
- 缺口：编辑器次级工具条没有任何 SHAPE 分支——`iw4` case8 对应的
  "编辑器内即点即换种类"交互缺失，用户必须进工具箱设置才能换形状。

## Harmony 实现（本期）

- `ShapeKindPicker.ets`：导出 `SHAPE_KIND_ORDER`（= `r5g` 序）与
  `ShapeKindSwatch`；swatch 新增 `compact` 模式——36dp 图标 + 2 边距
  （适配 40dp 次级条行高）、无文字标签、a11y 不变。
- `EditorViewModel.ets`：新增 `activeShapeToolId()`（解析激活 SHAPE 行；
  无 SHAPE 行返回 `''`，渲染期不抛）与 `setActiveShapeKind(kind)`
  （委托既有校验路径 `setToolShapeKind`）。
- `EditorToolbar.ets`：在 calligraphy 分支之后、普通笔刷样式按钮之前新增
  `isShapeActive()` 分支：
  - 折叠：`shapeKindExpandedFor !== activeShapeToolId()` → 仅渲染当前
    `activeShapeKind` 的 compact swatch；点击将 `shapeKindExpandedFor`
    置为当前 SHAPE 工具 id。
  - 展开：`ForEach(SHAPE_KIND_ORDER)` 六个 compact swatch，选中项
    accent 描边；点击调用 `setActiveShapeKind`。
  - 展开状态以工具 id 为键——切换到别的工具后旧 id 不再匹配，自然折叠，
    与 `qri.a` 会话复位语义一致。
  - 展开与选择均受 `photoImportLeaseActive` 门控；错误仅记日志不抛。

## 剩余边界（记入 ADR-1361）

- 原版 `ij1` 面板把凿尖参数（`aj1`：nibAngle=π/2、nibFlatness=0.75、
  stabilization=true）同样作用于 SHAPE 描边（`lnc.java:194` 经 `ox5`）。
  Harmony `ShapeCanvasRenderer` 目前用固定线宽/虚线描边，未接入凿尖几何——
  渲染差异记入 ADR，作为后续候选 Phase。
- 展开态在选中一个种类后保持展开直至工具切换；原版 `nri` 会话语义下
  选中即收起的精确时机在反编译中不可完全判定，Harmony 选择保持展开
  （连续换形状更顺手），属可辩护的适配。

## 回放

`docs/migration/replays/d02-original-shape-strip-kind-picker.mjs`（13 项断言）：
分支位置、折叠/展开两态、r5g 序、compact a11y、accent 选中、写回路径、
无 SHAPE 行不抛、lease 门控、设置面板路径不变。
