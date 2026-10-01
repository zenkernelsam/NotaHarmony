# Phase 1434 — 遗留待办收尾（swipe 动作 / Prism4j 高亮 / lj3）+ SVG 导入轴

## 范围

复查修复总纲三笔"待后续核实"记录，并对复查中浮出的 SVG 图像导入轴
作出正式裁定。本 Phase 为文档/裁决型（无实现改动）。

## 结论

### (a) wbn 便签卡滑动动作 —— 已交付（失鲜记录收尾）

- 原版：`wbn.java` 滑动揭示 favorite/unfavorite_outline + trash；
  `qbn.g` 修饰链（`sd4.c()` 拖放使能 + `z2` 抑制）；删除走
  `delete_note_message` 确认对话框。
- Harmony：Phase 1410 已交付 `LibraryPage.NoteSwipeActions`
  （56vp accent (un)favorite_outline + 56vp danger trash、三条
  `*_note_swipe_action` a11y 串、`toggleNoteFavorite`/`confirmDelete`
  回调、`isMultiSelecting` 禁滑）。
- 处理：修复总纲/总纲2/进展三处"留后续 Phase"加注收官注记。

### (b) 代码块语言选择 + 语法高亮 —— 已交付（失鲜记录收尾）

- 原版：`o3i.c` CODE_BLOCK→`programmingLanguage`→`ehd`（Prism4j）
  分词→`ynh` token span→`o3i.b` 40 项调色板；渲染期覆盖。
- Harmony：P687 `CODE_LANGUAGES`/`caretCodeLanguage`/`onCodeLanguageSelected`/
  `persistCodeBlockLanguage`（`NoteCanvasView`，ya8 lastCodeBlockLanguage
  持久化）；P1397/1398 `CodeSyntaxHighlighter.ets` Prism4j 引擎级移植
  + `Canvas2DTextRenderer` 接线。
- 处理：两处"语法高亮待后续/仍属缺口"加注收官注记。

### (c) `lj3 -24f` —— vendored 内部细节

`lj3`/`ufh`/`vfh` = caverock AndroidSVG 解码链；`-24f` 为字体度量换算
实现细节，非应用行为契约。随 (d) 判清。

### (d) SVG 图像导入 —— fail-closed（新裁定）

- 原版：选图 Intent 广播 `image/*`（`cb:35`/`db:56`/`w0:31`）；
  `ufh` 按 `image/svg+xml` MIME 或 `<svg` 嗅探接 SVG；
  `v4a` 后缀表 `svg`/`svgz`→`image/svg+xml`。`.svg` 可达导入。
- Harmony：`IMPORTED_IMAGE_SUFFIXES` 与 picker `fileSuffixFilters`
  不含 `.svg`；ImageKit 不支持 SVG 解码，平台无矢量光栅化 API；
  等价实现需 vendored 级 SVG 管线，超出单 Phase 体量。
- 裁定：fail-closed——不广播 `.svg` 即无可达坏路径（用户无法选中），
  无静默失败。若未来需要应独立立项。

## 交付物

- 证据：`docs/migration/evidence/phase-1434-stale-deferral-closure.md`
- ADR：`docs/migration/adr/ADR-1369-stale-deferral-closure.md`
- Replay：`docs/migration/replays/d02-original-stale-deferral-closure.mjs`
  （13 checks）
- 追踪文档：三处失鲜注记收官 + 本 Phase 条目。

## 验证

- 专项 fixture：13/13。
- 全量 Replay 基线：见提交（1284+1）。
- `note@default` / `note@ohosTest` clean 构建：均成功（文档型 Phase
  无实现改动，按验收标准仍跑全量）。

## 已知差异登记

- `.svg` 文件 Harmony 侧不可选（原版可导入并位图化）。
- 多窗口拖出（`orb`/`isInMultiWindowMode`，SDK≥35）为平台边界，
  不在本 Phase（拖放导入语义已有 ADR 覆盖）。
