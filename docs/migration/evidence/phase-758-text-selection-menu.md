# 原版证据：文本选区菜单 tqe.a() 全量项（ActionMode）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 758 依据。承接 Phase 622 空白处长按照 [PASTE, SELECT_ALL]
  （`original-longpress-menu-items-2026-09-28.md`）。

## 1. 原版选区菜单（`yqa.f` / `r39.j` / `q39` / `tqe`）

`yqa.java:182-218`（`f(uub, i3a, tr1, z, xhc)`）：

- `z2 = ft3Var.a`（文本块可编辑态）前置；`z3` 分支走剪贴板动态项
  `rbb.m()`（Harmony 无同型载荷类，Phase 622 已登记边界）。
- 非 `z3` 常态：折叠 caret（`a2gVar3.equals(a2gVar)`）→
  `[PASTE, SELECT_ALL]`；**非折叠选区 → `tqe.a()` 全量枚举**。
- `tqe` 枚举序：CUT(0)/COPY(1)/PASTE(2)/SELECT_ALL(3)/LINK(4)/
  HIGHLIGHT(5)/REMOVE_HIGHLIGHT(6)。
- 过滤：`ordinal==2`(PASTE) 需 `hasPrimaryClip`；
  `ordinal==6`(REMOVE_HIGHLIGHT) 需 `z4 = eh5.b`
  （选区高亮态标志）。
- `q39.java:32-72`：`ActionMode.Callback` 把 `tqe` 项写进系统
  ActionMode（`menu.add(0, i2, i2, i)`），文案键
  `selection_menu_cut/copy/paste` + `text_selection_menu_select_all`
  + `text_selection_menu_link` + `selection_menu_highlight` /
  `remove_highlight`；点击回调 `d.invoke(itemId)`→`r39` 分发。
- `eh5.java`/`br2.g`：`eh5{iu1 色, boolean}` —— a=当前高亮色
  （默认 `gh5.a = iu1.i = 0xFFFFFF00` 黄），b=REMOVE_HIGHLIGHT 门。
  `cve:143`/`fm7:127`/`aa6:1023` 施加高亮时写 `eh5(color,true)`。

## 2. Harmony 对齐（Phase 758）

ArkUI `TextArea.editMenuOptions`（API12+，项目 compatibleSdk 21）：

| 原版 | Harmony |
|---|---|
| `q39` ActionMode：系统项 [Cut/Copy/Paste/Select All] + `tqe.a()` 尾部定制 | `onCreateMenu` 收到系统项，追加 `TextMenuItemId.of('text_link'|'text_highlight'|'highlight_remove')` —— 序对齐 tqe(4/5/6) |
| 折叠 caret 仅 [PASTE, SELECT_ALL] | `s===e` 时原样返回系统项（系统菜单自带） |
| `REMOVE_HIGHLIGHT` 受 `eh5.b` 门控 | `rangeIntersectsHighlight(s,e)`：选区与任一 `highlightColor` run 相交才产出 |
| HIGHLIGHT → `eh5.a` 当前高亮色 | `@State lastHighlightColor`（默认黄 = 调色板 `1716898048`，语义对齐 `iu1.i` 黄）→ `applyHighlightColor(last,s,e)` |
| LINK → 超链接 sheet | 选区置 `[range.start,range.end)` → `openLinkSheet()`（既有预填/Edit 态） |
| REMOVE_HIGHLIGHT → 清除选区高亮 | `applyHighlightColor(null,s,e)` + `normalizeCharRuns` |
| `eh5.a` 色追踪 | `toggleHighlightColor` 漏斗内 `lastHighlightColor=color`（调色板/最近色/HSV 三入口全覆盖） |

## 3. 有界偏差

- 原版菜单锚定选区包围盒（`onGetContentRect` → `nti.Z`）；
  ArkUI 系统编辑菜单自动锚定选区手柄——语义等价。
- `z3`/`rbb.m()` 剪贴板动态载荷项不可达（同 Phase 622 登记）。
- `eh5.b` 原版语义为"选区高亮态"近似判定；Harmony 用相交判定
  （任一重叠 run 即产出 REMOVE_HIGHLIGHT），粒度近似。
- 系统项序/图标由 HarmonyOS 控制——只对齐定制尾部三项。
