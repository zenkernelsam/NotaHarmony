# Phase 758：文本选区菜单定制项（tqe.a() 尾部三项）

> 日期：2026-09-28
> 证据：`docs/migration/evidence/phase-758-text-selection-menu.md`
> ADR：`docs/migration/adr/ADR-0706-text-selection-menu.md`
> Replay：`d02-original-text-selection-menu.mjs`（28 断言，全绿）

## 背景

原版文本编辑表面（`q39`/`r39`/`yqa.f`）在非折叠选区上弹自定义
ActionMode：系统四项 [Cut/Copy/Paste/Select All] 之后追加
`tqe.a()` 尾部三项 **LINK(4)/HIGHLIGHT(5)/REMOVE_HIGHLIGHT(6)**
——REMOVE_HIGHLIGHT 受 `eh5.b` 高亮态门控，HIGHLIGHT 施加
`eh5.a` 当前高亮色（默认 `iu1.i` 黄）。Phase 622 已移植空白处
长按照 [PASTE, SELECT_ALL]；文本内选区定制项此前缺位。

## 原版行为（decompiled_1.0.3）

- `yqa.java:182-218`：折叠 caret → [PASTE, SELECT_ALL]；非折叠 →
  `tqe.a()` 全量；过滤 ordinal2=PASTE（剪贴板）/ordinal6=
  REMOVE_HIGHLIGHT（`eh5.b`）。
- `q39.java`：ActionMode 回调，文案键
  `text_selection_menu_link`/`selection_menu_highlight`/
  `selection_menu_remove_highlight`。
- `eh5{iu1,bool}`：a=当前高亮色（默认黄），b=REMOVE 门。

## 实现（TextBlockOverlay.ets）

- `.editMenuOptions`（API12+）：`onCreateMenu` 系统项尾部追加
  三项定制 `TextMenuItemId.of`；折叠 caret/`photoImportLeaseActive`
  时原样返回。
- `rangeIntersectsHighlight`：相交判定 ≈ `eh5.b`。
- `@State lastHighlightColor`（默认调色板黄）=
  `eh5.a`；`toggleHighlightColor` 漏斗内更新。
- 分发：LINK→选区置 range→`openLinkSheet`；HIGHLIGHT→
  `applyHighlightColor(last)`；REMOVE→`applyHighlightColor(null)`；
  消费返回 true（`r39` finish 语义）。

## 偏差

- 锚定呈现交 ArkUI 系统选区菜单（语义等价）。
- `rbb.m()` 剪贴板动态载荷项 fail-closed（同 Phase 622 登记）。

## 验证

- 专项 Replay：28/28
- 全量 Desktop Replay：见提交记录
- `note@default` / `note@ohosTest` HAP：BUILD SUCCESSFUL
