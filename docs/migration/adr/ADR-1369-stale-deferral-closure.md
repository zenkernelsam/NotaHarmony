# ADR-1369：遗留待办收尾（swipe 动作 / Prism4j 高亮 / lj3）+ SVG 导入 fail-closed

## 状态

Accepted — 2026-09（Phase 1434）

## 背景

修复总纲三笔"待核实/待后续"条目复查，外加一条在复查中浮出的真实轴
（SVG 图像导入）。原版证据见
`docs/migration/evidence/phase-1434-stale-deferral-closure.md`。

## 裁定

### (a) 便签卡滑动动作 —— 已移植，关闭遗留待办

原版 `wbn.java` 滑动揭示 favorite/unfavorite_outline + trash 两动作，
`qbn.g` 拖放修饰（`sd4.c()` 使能 + `z2` 抑制），删除走
`delete_note_message` 确认对话框。Harmony `LibraryPage.NoteSwipeActions`
提供同构两动作 + 三条相同 a11y 串 + `toggleNoteFavorite`/`confirmDelete`
回调，`isMultiSelecting` 门控等价于 `sd4.c()`/`z2` 抑制。**无差距**。

### (b) 代码块语言选择 + 语法高亮 —— 已移植，关闭遗留待办

原版 `o3i.c` 在 CODE_BLOCK 段落按 `programmingLanguage` 取 `ehd`
（Prism4j）语法分词，`ynh` 递归生成 token→颜色 span，`o3i.b` 40 项
token→`uog` 调色板，`vza` 26 语法支持集；仅渲染期覆盖，不写持久样式。
Harmony `CodeSyntaxHighlighter.ets` 为 Prism4j 引擎级移植（类级映射已
写进文件头），`Canvas2DTextRenderer` 渲染期接线，`TextBlockOverlay`
`buildCodeLanguageMenu`/`persistCodeBlockLanguage` 提供选择+持久化。
**无差距**。

### (c) `lj3 -24f` —— vendored 内部细节，不单列

`lj3`/`ufh`/`vfh` = caverock AndroidSVG vendored 解码链；`-24f` 是字体
度量换算实现细节，非应用行为契约。随 (d) 一并判清。

### (d) SVG 图像导入 —— fail-closed

原版：选图 Intent 广播 `image/*`（`cb:35`/`db:56`/`w0:31`），`ufh`
工厂按 MIME 或 `<svg` 嗅探接 `.svg`，`v4a` 映射 `svg/svgz`。
Harmony：`IMPORTED_IMAGE_SUFFIXES` 与 picker `fileSuffixFilters`
不含 `.svg`；ImageKit 不解码 SVG，平台无 SVG 光栅化 API，
移植等价物需 vendored 级矢量管线。

**决定**：不实现。选择器不广播 `.svg` = fail-closed（无可达坏路径）。
若未来需要，应独立立项评估第三方 SVG 光栅化方案。

## 已知差异

- 多窗口拖出（`orb`/`z7=isInMultiWindowMode`，SDK≥35）：Harmony 端无
  等价拖出导入面，平台边界，未列入（既有 ADR 已覆盖拖放导入语义）。
- `.svg` 文件在 Harmony 侧不可选（原版可导入为位图化图像元素）。

## 验证

- `d02-original-stale-deferral-closure.mjs`：13 checks 全绿。
- 全量 Replay 基线、`note@default`/`note@ohosTest` clean 构建：见
  `reports/phase-1434-stale-deferral-closure.md`。

## 交叉引用

- ADR-1341（NoteCoverSheet）、ADR-1361（shape strip）、ADR-1368（xapk split）
- 证据：`phase-1434-stale-deferral-closure.md`
