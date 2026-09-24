# Phase 673 证据 — 原版库内多选模式与批量笔记操作

日期：2026-09-24
前置：Phase 672（`e859cdbc`）

## 原版证据（decompiled_1.0.3）

### 多选状态机（pk9.java）

- `pk9 extends cs0`，持有两个 `asd`（StateFlow）：
  - `X` = 多选模式开关（Boolean）。
  - `Y` = 已选笔记 id 集（Set<ttf>，初值 `qw3.I` 空集）。
- `o(ttf)`：若 `X` 已为 true 直接返回；否则 CAS 循环把 `X`
  置 TRUE，然后调用 `r(ttf)` —— **长按进入多选并立即选中
  该笔记**。
- `r(ttf)`：CAS 循环读 `Y`，按 `do6.z(ttf, set)`（成员判定）
  从集里移除（`ys2.G`）或加入（`ys2.K`）—— 翻转选中。
- `p()`：CAS 循环把 `X` 置 FALSE，再把 `Y` 置 `qw3.I` ——
  **退出多选并清空选中集**。
- 另有 `V`（z0 型动作流，favorite 单点提交）、`T`（busy
  令牌，`z79.c(T,"Duplicate",1)` 防抖）。

### 单元格回调分派（tj9.java / xj9.java / d5j.java）

- `tj9.invoke` switch：
  - case 0 / case 6 → `pk9Var.o(w09Var.a)` —— **长按进多选**。
  - case 1 / case 5 → `pk9.V.k(null, o69(ttf))` —— 收藏切换。
  - case 3 / case 8 → `z79.c(T,"Duplicate",1)` 防抖后
    `zh9(4, null, pk9, ttf)` —— 复制。
  - case 2 / case 7 → `jk9(pk9, ttf, null, 1)`。
  - case 4 → `jk9(pk9, ttf, null, 0)`。
- `xj9` 组合单元格回调：长按槽 = tj9 case0/6。
- `d5j` = 单笔记溢出菜单（Rename / Favorite / Duplicate /
  Export / Show in folder / Move / Copy ID / Delete），
  **其中没有 Select 项** —— 多选入口不是菜单项。

### 顶栏与底栏（hof.java / l05.java / ek9.java / o94.java / lq7.java）

- `hof`：顶栏 Select All/Deselect All 标签按
  `((Set)gl8Var.getValue()).size() != list.size()` 切换 —
  覆盖不满 → Select All，覆盖满 → Deselect All；选中集为空
  时动作区不渲染（`isEmpty() → r(false)`）。
- `l05`：底栏动作区消费 `ek9` 派生态；`ek9.b` =
  actionsEnabled；`b2j.a(..., ek9.b, ...)` 把按钮 enabled
  绑到该字段；busy 时 `fj9` 渲染进度（`xri.a`）。
- `ek9`：多选派生模型 —— `a` = Select All 语义串、`b` =
  actionsEnabled、`e` = allSelectedAreFavorited（驱动
  Favorite/Unfavorite 翻转）。
- `o94`：勾选圈单元件（已选 checkmark_circle / 未选
  circle_empty_med_outline），a11y =
  `feature_library__select_note`。
- `lq7`：返回键消费者 —— 多选态返回 → `pk9.p`。
- Share 图标：`lc4.a(ac4.L)` 功能旗标门控（本实现登记
  fail-closed，归 Phase 674 多笔记分享）。

### 字符串（strings.xml / plurals.xml）

```
feature_library__select_all    = "Select All"
feature_library__deselect_all  = "Deselect All"
feature_library__select_note   = "Select Note"
feature_library__share         = "Share"
plurals feature_library__notes_selected
  one   = "%1$d Note Selected"
  other = "%1$d Notes Selected"
```

## Harmony 落点

`note/src/main/ets/ui/library/LibraryPage.ets`：

- `@State isMultiSelecting`（X）、`selectedNoteIds: string[]`（Y）、
  `multiSelectBusy`（busy 令牌）。
- `enterMultiSelect(id)`：守卫 `!pageActive || isMultiSelecting` →
  `isMultiSelecting=true; selectedNoteIds=[id]`（pk9.o 的
  `X→true + r(id)` 等价）。
- `toggleMultiSelectId(id)`：数组切片 + indexOf/splice/push
  翻转成员（pk9.r）。
- `exitMultiSelect()`：`X=false + Y=[]`（pk9.p）。
- `onBackPress()`：多选态消费返回键 → `exitMultiSelect()`（lq7）。
- `NoteCard`/`NoteListRow`：`LongPressGesture` → `enterMultiSelect`；
  多选态 `onClick` → `toggleMultiSelectId`；原长按
  `bindContextMenu` 改为 `⋯` 溢出按钮 `NoteMenuButton`（`bindMenu`）
  承载 `d5j` 单笔记菜单。
- `SelectCircle`：✓ 实心圈 / 空圈边框（o94 语义），
  a11y=`select_note`。
- `MultiSelectTopBar`：`allVisibleSelected()` 决定
  Deselect All/Select All（hof 的 size!=list.size 判定）+
  `%d Note(s) Selected` 计数 + Done → `exitMultiSelect`。
- `MultiSelectActionBar`：Duplicate / Favorite↔Unfavorite
  （`allSelectedFavorited()` = ek9.e）/ Delete；
  `enabled = count>0 && !busy`（ek9.b + hof 空集门控）；
  busy 时 `LoadingProgress`（xri.a）。
- `multiDuplicate`：逐笔记 `NoteExporter.exportNote` →
  `NoteImporter.importFromData` 无损往返（同单笔记
  duplicateNote 语义），完成后 `loadNotes` 重载 +
  `refreshRecentCardFeed` + 选中集剔除失效 id。
- `multiSetFavorite`：目标 = `!allSelectedFavorited()`，
  仅对 `favorite !== target` 的笔记调 `vm.toggleFavorite`
  （部分变基语义）。
- `multiDelete`：`confirmMultiDelete` 弹
  `delete_notes_message` 计数确认后逐笔记 `vm.deleteNote`
  （入 Recently Deleted）；删空自动 `exitMultiSelect`；
  结尾 `refreshThumbnails`。
- FAB `FabButton` 在多选态隐藏。

## 登记差异

1. `⋯` 溢出按钮：原版单元格有独立 ⋯ 图标（xj9 接线）开
   `d5j` 菜单；Harmony 以 `bindMenu` 等效承载（长按手势
   让位 `pk9.o` 多选进入）。
2. Share 图标：`lc4.a(ac4.L)` 旗标门控，且多笔记导出
   （s6d `_multi` 标签 + 多文件交付面）未就绪 —— 本期
   fail-closed，归 Phase 674。
3. 勾选圈用 ✓ 文本 + 边框圆近似 `checkmark_circle`/
   `circle_empty_med_outline` 图标（语义等价）。
4. 无 ttf→内部 id 转换层（原版 `ttf` 为 UUID 包装）；
   Harmony 笔记 id 直接是字符串。
