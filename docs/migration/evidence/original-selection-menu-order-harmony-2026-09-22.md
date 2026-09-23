# Phase 544 — 原版选区菜单顺序与缺失项补齐（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/components/SelectionOverlay.ets`、
`NoteCanvasView.ets`、`PageElementOrder.ets`、双语言字符串、专项 replay。

## 原版证据链（decompiled_1.0.3）

`dsc.java` 枚举声明序即菜单序（`ux9` 按 `dscVar.ordinal()` 逐项映射
`r68` 菜单元素）：

```
0 STYLE, 1 COPY, 2 CUT, 3 DUPLICATE, 4 GROUP, 5 UNGROUP,
6 SEND_FORWARD, 7 SEND_BACKWARD, 8 SEND_TO_FRONT, 9 SEND_TO_BACK,
10 DELETE, 11 CONVERT_TO_MATH, 12 CONVERT_TO_TEXT, 13 EDIT_MATH,
14 CROP, 15 FIT_TO_PAGE, 16 FLIP_HORIZONTALLY, 17 FLIP_VERTICALLY,
18 LOCK, 19 UNLOCK, 20 DESELECT, 21 MORE
```

- `ux9.java` case 分支逐项生成 `r68(label, icon)`，list 来自外部传入的
  `List<dsc>`——顺序即枚举序。
- `v49.java:115`：`selection_menu_paste` 是独立的浮动粘贴 chip，
  不属于 `dsc` 菜单列表。
- `q39.java` 是文本选择 ActionMode（`tqe`：CUT/COPY/PASTE/SELECT_ALL/
  LINK/HIGHLIGHT/REMOVE_HIGHLIGHT）——不同表面，不在本范围。

Harmony 旧序：Copy, Cut, **Delete**, SendFwd, SendBwd, Paste, FlipH,
FlipV, Crop, EditMath, Lock, Group, Ungroup, Done——Delete 错位至第 3
（原版第 10），Group/Ungroup 错位至末尾（原版第 4/5），缺
DUPLICATE / SEND_TO_FRONT / SEND_TO_BACK。

## Harmony 落地

`buildSelectionMenu` 现按 dsc 序输出可移植子集：
Copy → Cut → **Duplicate**(新) → [Paste]* → Group → Ungroup →
Send forward → Send backward → **Send to front**(新) →
**Send to back**(新) → Delete → Edit math → Crop → Flip H → Flip V →
Lock/Unlock → Done(Deselect)。

- **DUPLICATE**：`duplicateSelected` = `copySelectedToClipboard` +
  `pasteClipboard(selectionPasteTarget())` 组合；先复位
  `lastPasteRequestTime` 去抖窗（duplicate 为单次有意动作，非快速
  连贴）。内部 `strokeClipboard` 被覆写——登记（原版专用 duplicate
  op 不可静态复原）。
- **SEND_TO_FRONT/BACK**：新增 `movePageElementRefsToExtreme`
  （与 `movePageElementRefsOneStep` 同套 selected-unit 校验；仅非组
  单元移动，保持两个分区相对序）+ `reorderSelectedToExtreme`
  （同款 undo REORDER_ELEMENTS + `OriginalZOrderCommand.BRING_FRONT`/
  `SEND_BACK` 原版 z-order hint——编解码早已支持两值）。
- 标签对齐原版："Send forward"/"Send backward"（原 Harmony 为
  "Bring Forward"/"Send Backward"）。
- *Paste 保留在菜单内（剪贴板簇位）为登记适配——原版为浮动 chip。

## 差异登记

- STYLE/CONVERT_TO_MATH/CONVERT_TO_TEXT/MORE：样式面板经工具栏
  承载、手写识别无对应实现——登记。
- FIT_TO_PAGE：升级结论——原版 dhb case15 即
  `throw new NotImplementedError(0)`，上游为死项，省略即 parity
  （Phase 633 证据 original-fit-to-page-stub-2026-09-28）。
- Paste 浮动 chip → 菜单项（登记）。
- DUPLICATE 复用内部剪贴板（原版为专用 op）。
