# Harmony 证据：选区命令上下文门禁补审

日期：2026-08-25
范围：`note/src/main/ets/ui/editor/NoteCanvasView.ets`

## 结论

未发现新的行为缺陷。Math 编辑、图片裁剪和 Ink 批量命令都在入口从当前 SelectionTool/capability 派生目标，
没有以 `selectionVisible` 或工具栏显示寄存器替代真实选择身份。

## Harmony 源码事实

- `selectionCanEditMath` 在 `updateSelectionOverlay()` 中要求：
  恰好一个 Math ID、零个 stroke/shape/text/image/group、Math block 存在且 `decodeOperationId() !== null`。
- `startMathEditing()` 再次检查 `selectionCanEditMath`，随后从 `selectedMathIds` 解析 Math，
  再验证存在性和 canonical identity。
- `startImageCrop()` 调用 `canCropImageSelection()`；该函数拒绝任何非图片实体，要求恰好一张图片，
  并通过 `beginOriginalImageCrop()` 建立 session。
- `modifySelectedInkRegisters()` 要求 `loaded`、非 history busy 且 `viewModel.isSelectionActive()`；
  命令目标来自 `selectionTool.getState().selectedStrokeIds/selectedShapeIds`。

## 原版对照

- `itc.java` 是 `Tap(selectedId=..., id=..., showUncroppedImage=...)` 单元素选中状态。
- `dhb.java` case 13 在 Edit Math 时从 `itc.a` 取 block ID，读取当前 note 对象，确认其为 Math 后才发布
  `x08(blockId, initialLatex)`；随后 `xsc.s()` 回到空闲。
- `v07.java` case 20 的 style popover 使用当前 `nsc.ShowStylePopover(sections, initialColor)` 与当前 `xsc`/`ktc`
  组合派生回调；`zh9.java` / `wj9.java` case 12 再从 `Set<qo5>` 过滤可修改对象。

因此“临时编辑器保留概念选区”与“命令必须从当前 selection 派生目标”并不矛盾：编辑器期间隐藏交互层，
但身份仍在控制器中；命令执行时仍以控制器状态为准。

## 审计加强

聚焦 Replay 新增：

- Math 编辑 gate 必须检查 `!this.selectionCanEditMath`。
- Ink command guard 必须检查 history busy、loaded 和 Selection tool。
- stroke/shape 目标必须从 `SelectionTool.getState()` 构建，不得使用显示寄存器。
- 非选区工具或空 IDs 的模拟命令返回 false。

本阶段无生产代码变更。
