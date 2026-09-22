# Phase 539 — 原版 Favorite Color Well 编辑交互（Harmony 证据）

日期：2026-09-22
范围：`note/src/main/ets/ui/components/ColorPicker.ets`、`note/src/main/ets/ui/editor/EditorViewModel.ets`、双语言字符串、专项 replay。

## 原版证据链

Toolbox 事件词汇（`rh9` 事件族，`ti9` 统一 dispatch）：

| 事件 | 载荷 | dispatch 目标（ti9） | 语义 |
|---|---|---|---|
| `xg9` | `(a6f toolType, int index, mv6)` → `g0` | "OnAddColorClick" | 在索引处新增色井 |
| `bh9` | `pb4 well` → `z47` | "OnDeleteColorClick" | 删除色井 |
| `ah9` | `(wellId, wellIndex, newColor)` → `xh9` | "OnColorWellValueChange(wellId=…, wellIndex=…, newColor=…)" | 写井色 |
| `yg9` | — → `ku5` | "OnBrushColorClick" | 点选井取色 |

关键装配点（decompiled_1.0.3/sources/defpackage/）：

- `wj9.java` case 17：色轮/编辑器把当前编辑色写回色井——`new ah9(p7fVar.c, kkf.c0(((iu1) obj).a), p7fVar.b)`，事件携带 wellId + 编辑色 + 井序。
- `jm3.java`：`+` 入口 → `new xg9(a6fVar, index, mv6)`。
- `ys2.java`：逐工具菜单 → `new bh9(pb4Var)`。
- `tb4.java`：`UPDATE FavoriteColorWellEntity SET trayIndex = trayIndex - 1 WHERE trayIndex > ? AND toolType = ?`——删井后致密重编号。
- `vb4.java`：`DELETE FROM FavoriteColorWellEntity WHERE id = ?`。
- `qb4.java`：`FavoriteColorWellEntity(id, toolType, color, trayIndex)`。
- 原版字符串：`ui_tools__add_a_color` / `ui_tools__color_options` / `ui_tools__open_color_wheel` / `ui_tools__delete`。

## Harmony 落地

仓储层（Phase 532 已有，本阶段复核不变）：

- `ToolRepositoryImpl.setFavoriteColor(toolType, trayIndex, color)` upsert。
- `ToolRepositoryImpl.removeFavoriteColor` 内联 `tray_index > ? → -1` 致密化（与 `tb4` SQL 逐字对齐）。

VM（`EditorViewModel`）：

- `setFavoriteColorWell(index, color)` / `removeFavoriteColorWell(index)`（既有）——走 `activeToolType()` 的仓储写 + `favoriteColors` 重载。
- 新增 `addFavoriteColorWell()`：以 `favoriteColors.length` 为下一 trayIndex 写入当前 `brushColor`——对应原版 `+` 入口 `xg9(toolType, index)` 的追加语义。

UI（`ColorPickerView`）：

- 井点 `tap` → `setBrushColor(color, index)`（`yg9` 选择语义，既有）。
- 井点 `bindContextMenu(..., ResponseType.LongPress)` → `buildWellMenu(index)`：
  - “设为当前颜色” → `setFavoriteColorWell(index, brushColor)`（`ah9` 写井语义——原版由色轮回写，本移植以当前刷色为写入源，属已登记交互适配）。
  - “删除” → `removeFavoriteColorWell(index)`（`bh9` + `tb4` 致密化）。
- 网格尾部 `+` 虚线圆片 → `addFavoriteColorWell()`（`xg9` 追加），`accessibilityText = ui_tools__add_a_color`。
- 全部新回调在 `photoImportLeaseActive` 下 fail-closed；井点与 `+` 片均 `.enabled(!photoImportLeaseActive)`。

## 验证

- `d02-original-color-well-edit.mjs`：24 断言（原版事件/存储/字符串锚点 + Harmony 锚点 + 可执行增/写/删致密化模型）——TOTAL=24 FAILED=0。
- 全套 replay：434 PASS 0 FAIL。
- `note@default`、`note@ohosTest`：BUILD SUCCESSFUL（仅存量警告）。

## 登记差异

- 原版写井色经由色轮编辑器回传（`wj9` 将编辑器色打包进 `ah9`）；Harmony 长按菜单直接以当前 `brushColor` 写入——等价持久化路径，交互路径简化，已登记。
- 原版删除入口位于逐工具菜单；Harmony 收敛为井点长按上下文菜单（`bh9` 语义不变）。
