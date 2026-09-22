# ADR-0564 — 选区菜单 STYLE → 复用工具栏选区样式表面（dsc.STYLE/ux9）

- 状态：Accepted
- Phase 595；对齐 `dsc.STYLE`（ordinal 0）/`ux9`/`dhb`（decompiled_1.0.3）。

## 背景

原版选区菜单第一项 `dsc.STYLE`：以选中 ink 颜色为 HSV 种子弹出
样式选择表面（色板 + 宽度候选），应用写选中 ink 寄存器并记入
撤销。Harmony 的样式**功能**早已就位（`ColorPickerView`/`WidthSlider`
的 `selectionMode` + `modifySelectedInkRegisters` 撤销式应用），
缺的是选区菜单入口——菜单原本从 `COPY` 起排。

## 决策

1. `SelectionMenuAction.STYLE = 19`；`SelectionOverlay` 新增
   `@Prop canStyle`，`buildSelectionMenu()` 在 `COPY` 之前
   （dsc ordinal 0 位置）、仅 `canStyle` 且非导入租约时推入 STYLE 项。
2. `canStyle = selectedStrokeIds.length > 0 || selectedShapeIds.length > 0`
   ——与 `modifySelectedInkRegisters` 作用域一致（ink 选区才出现）。
3. `onSelectionMenuAction(STYLE)` 置
   `viewModel.showColorPicker = true; viewModel.showWidthSlider = true`
   ——打开工具栏 selectionMode 弹层（颜色 + 宽度同屏），应用走既有
   `onSelectionColor`/`onSelectionWidth` → `modifySelectedInkRegisters`
   通道：笔画 + 形状 + 撤销快照 + 荧光笔 alpha + 胶带宽度界 +
   铅笔宽度重建全部保留，不复制修改逻辑。

## 偏差（fail-closed 记录）

1. 原版 STYLE 表面为独立样式页（HSV 种子 + 预设样式选项）；
   Harmony 复用工具栏的颜色井 + 宽度滑块——候选集合不同，
   应用语义（改选中 ink 颜色/宽度、可撤销）等价。
2. 原版单表面；Harmony 颜色与宽度两个弹层同屏展开——功能覆盖
   相同，UI 组织不同。
3. 文本/数学/图片选区不出 STYLE（原版样式表面同样只面向 ink）；
   若原版对文本块提供字体样式项，属后续文本样式 Phase 范畴。

## 验证

- `docs/migration/replays/d02-original-selection-menu-order.mjs`
  更新：harmonyOrder/mapped 纳入 STYLE（首项）+ canStyle 门控 +
  STYLE→弹层分发 + selection_style 字符串断言（43 项）。
- 证据：`docs/migration/evidence/original-selection-menu-style-2026-09-23.md`。
