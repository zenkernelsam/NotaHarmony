# ADR-0640 — 原版库内多选模式（长按进入 + 批量操作）

日期：2026-09-24
状态：已实施（4 项文档化适配；多笔记分享继续登记至 Phase 674）

## 决策

把库页面从"长按弹单笔记上下文菜单"升级为原版的双通道
单元格语义：**长按 = 进入多选模式**（`pk9.o`），
**⋯ 溢出按钮 = 单笔记菜单**（`d5j`，改由 `bindMenu` 承载）。

多选状态对齐 `pk9` 的双 StateFlow 模型：

- `isMultiSelecting`（X）/ `selectedNoteIds`（Y）/
  `multiSelectBusy`（busy 令牌）。
- `enterMultiSelect(id)` = `o(ttf)`：`X→true` 后 `r(id)`
  立即选中长按项。
- `toggleMultiSelectId(id)` = `r(ttf)`：成员翻转。
- `exitMultiSelect()` = `p()`：`X→false` + 清空 `Y`。
- `onBackPress` 多选态消费返回键（`lq7` → `p()`）。

顶栏（`MultiSelectTopBar`，对齐 `hof`）：

- Select All / Deselect All 按 `allVisibleSelected()`
  （选中集 ⊇ 可见列表）切换标签。
- "%d Note(s) Selected" 单复数计数（`notes_selected` plural）。
- Done → `exitMultiSelect`。

底栏（`MultiSelectActionBar`，对齐 `l05`/`fj9`/`gj9`/`ek9`）：

- Duplicate / Favorite↔Unfavorite（`allSelectedFavorited`
  = `ek9.e`，全已收藏 → Unfavorite）/ Delete。
- `enabled = count>0 && !busy`（`ek9.b` + `hof` 空集门控）；
  busy 时 `LoadingProgress`（`xri.a`）。
- Delete 先弹 `delete_notes_message` 计数确认。

批量语义：

- Duplicate：逐笔记 export→import 无损往返（与单笔记
  duplicateNote 同一管线），完成后重载并剔除失效选中 id。
- Favorite：目标态 = `!allSelectedFavorited()`，只改
  `favorite !== target` 的笔记（部分变基，不盲翻全部）。
- Delete：逐笔记 `vm.deleteNote`（入 Recently Deleted），
  删空自动退出多选。

## 适配与差异

1. **`d5j` 菜单承载方式**：原版单元格以独立 ⋯ 图标开
   菜单；Harmony 原长按 `bindContextMenu` 让位多选进入，
   `d5j` 菜单改由 ⋯ 溢出按钮 `bindMenu` 承载 —— 语义
   等价，交互入口与原版一致（长按=多选、图标=菜单）。
2. **Share 图标 fail-closed**：原版底栏 Share 受
   `lc4.a(ac4.L)` 旗标门控；Harmony 多笔记导出交付面
   （多文件打包）未就绪，本期不渲染 Share 按钮，归
   Phase 674。
3. **勾选圈近似**：✓/边框圆文本近似 `o94` 的
   checkmark_circle/circle_empty_med_outline 图标。
4. **id 直用**：原版 `ttf` 为 UUID 包装；Harmony 笔记
   id 即字符串，无转换层。

## 验证

- `d02-original-library-multi-select.mjs`：44/44。
- 全量 Desktop Replay：558/558 绿。
- `note@ohosTest` / `note@default` 双 HAP clean 构建成功。
- 未做任何模拟器/真机/Hypium 验证（按约束）。
