# Phase 595 — 选区菜单 STYLE → 选区样式表面（dsc.STYLE/ux9）

- 日期：2026-09-23
- 结果：已实现对齐（含 fail-closed 偏差记录）
- 证据：`docs/migration/evidence/original-selection-menu-style-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0564-original-selection-menu-style.md`
- Replay：`docs/migration/replays/d02-original-selection-menu-order.mjs`（更新至 43 项断言）

## 背景

原版 `dsc.STYLE`（ordinal 0）是选区菜单**第一项**：`ux9` 用
`selection_menu_style` 标签 + 轮廓图标构造，点击后以选中 ink
颜色为 HSV 种子弹出样式选择表面（颜色 + 宽度），`dhb` 分发把
样式写入选中 ink 寄存器并可撤销。

Harmony 的样式应用通道早已就位（`ColorPickerView`/`WidthSlider`
的 `selectionMode` → `onSelectionColor`/`onSelectionWidth` →
`modifySelectedInkRegisters`：笔画 + 形状 + 撤销 + 荧光笔/胶带/
铅笔特判），但选区菜单从 `COPY` 起排——`STYLE` 项缺失。

## 实现

- `SelectionMenuAction.STYLE = 19`；`SelectionOverlay` 新增
  `@Prop canStyle`；`buildSelectionMenu()` 在非租约分支内、`COPY`
  之前（dsc ordinal 0 位置）按 `canStyle` 推入 STYLE 项。
- `selectionCanStyle = 选中笔画>0 || 选中形状>0`——仅 ink 选区出现，
  与 `modifySelectedInkRegisters` 作用域一致。
- `onSelectionMenuAction(STYLE)` 置
  `viewModel.showColorPicker/showWidthSlider = true`——打开工具栏
  selectionMode 颜色 + 宽度弹层，复用既有应用通道，不复制修改逻辑。
- 字符串 `selection_style`（"Style"/"样式"）base + zh_CN。

## 偏差

见 ADR-0564 §偏差：表面形态（独立样式页 vs 工具栏弹层）与候选
集合不同，应用语义等价；文本块字体样式不在本项范围。

## 验证

- `node docs/migration/replays/d02-original-selection-menu-order.mjs` → 43/43。
- 全量 Desktop Replay、`note@default`、`note@ohosTest` 见 commit 记录。
