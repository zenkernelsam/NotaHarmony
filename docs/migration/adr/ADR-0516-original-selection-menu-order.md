# ADR-0516 — 原版选区菜单顺序与缺失项补齐

状态：Accepted（Phase 544）

## 背景

原版选区菜单顺序由 `dsc` 枚举固定（STYLE/COPY/CUT/DUPLICATE/GROUP/
UNGROUP/SEND_FORWARD/SEND_BACKWARD/SEND_TO_FRONT/SEND_TO_BACK/
DELETE/CONVERT_*/EDIT_MATH/CROP/FIT_TO_PAGE/FLIP_H/FLIP_V/LOCK/
UNLOCK/DESELECT/MORE），`ux9` 按 ordinal 逐项映射。Harmony 旧序把
DELETE 提至第 3、GROUP/UNGROUP 沉至末尾，且缺 DUPLICATE 与
SEND_TO_FRONT/BACK 三项。

## 决策

1. `buildSelectionMenu` 按 dsc 序输出可移植子集；PASTE 保留在剪贴板
   簇位（原版为独立浮动 chip——登记适配）。
2. 新增 `SelectionMenuAction.DUPLICATE/SEND_TO_FRONT/SEND_TO_BACK`。
3. DUPLICATE = 内部 copy+paste 组合（`copySelectedToClipboard` +
   `pasteClipboard`，复位去抖窗）；覆写内部 strokeClipboard——登记。
4. SEND_TO_FRONT/BACK：`movePageElementRefsToExtreme`（与 one-step
   同款单元校验/组约束/相对序保持）+ `reorderSelectedToExtreme`
   （REORDER_ELEMENTS undo + BRING_FRONT/SEND_BACK hint）。
5. 标签对齐原版文案（Send forward/backward/to front/to back）。

## 验证

`d02-original-selection-menu-order.mjs` 38/38（dsc 声明序锚点 +
ux9 项锚点 + Harmony 子序列序验证 + 可执行 extreme-move 模型）；
全套 439/439；`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
