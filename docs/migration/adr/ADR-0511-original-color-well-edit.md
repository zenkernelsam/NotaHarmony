# ADR-0511 — 原版 Favorite Color Well 编辑交互

状态：Accepted（Phase 539）

## 背景

Phase 532 落地了色井持久化（`favorite_color_well` 表 + `setFavoriteColor`/`removeFavoriteColor` + VM 写/删方法），但 UI 只剩“点选取色”，原版的长按编辑、删除、`+` 追加交互缺失。Phase 538 完成便签卡文件夹色片后，本阶段补齐该遗留项。

## 原版语义（证据）

- 事件族 `rh9`：`xg9` OnAddColorClick(toolType, index)、`bh9` OnDeleteColorClick(pb4)、`ah9` OnColorWellValueChange(wellId, wellIndex, newColor)、`yg9` OnBrushColorClick；`ti9` 统一 dispatch 至 `g0`/`z47`/`xh9`/`ku5`。
- `wj9`：色轮编辑把颜色回写井——构造 `ah9(wellId, 编辑色, wellIndex)`。
- `tb4`：删除后 `trayIndex > 删除位 → -1` 致密化；`vb4` 删行。
- `qb4`：实体 `(id, toolType, color, trayIndex)`；井按工具类型 + 托盘序持久化。

## 决策

1. 井点保留 tap→`setBrushColor(color, index)`（`yg9`）。
2. 井点新增长按上下文菜单（`bindContextMenu` + `ResponseType.LongPress`）：
   - “设为当前颜色”→ `setFavoriteColorWell(index, brushColor)`，对应 `ah9` 的写井路径；写入源取当前刷色而非嵌套色轮，登记为交互适配（持久化语义一致）。
   - “删除”→ `removeFavoriteColorWell(index)`，仓储侧致密化与 `tb4` SQL 逐字对齐。
3. 井网格尾部追加虚线 `+` 圆片 → `addFavoriteColorWell()`，以 `favoriteColors.length` 为 trayIndex 写入当前 `brushColor`，对应 `xg9` 追加语义。
4. 所有新回调在 `photoImportLeaseActive` 下 fail-closed，UI 同步 `.enabled(false)`。

## 后果

- 色井交互与原版事件语义一一对应（选/写/删/增）；未发现原版井数上限，追加不封顶。
- 写井色不经色轮（原版经 `wj9` 回写）——登记差异；若后续引入独立色轮页可再对齐为 `ah9` 事件路径。

## 验证

- `d02-original-color-well-edit.mjs`：24/24。
- 全套 replay 434/434；`note@default` + `note@ohosTest` BUILD SUCCESSFUL。
