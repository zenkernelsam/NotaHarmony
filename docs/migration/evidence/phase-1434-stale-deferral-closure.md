# Phase 1434 — 遗留待办收尾裁定 + SVG 导入轴判定

## 背景

`修复总纲`/`修复总纲2`/`修复进展` 中记录了三笔"待后续核实"的条目。
逐项回到原版反编译证据复查，结论：**两笔已由既有实现覆盖（记录失鲜），
一笔是 vendored 库内部细节**；同时带出一条此前未单独裁决的真实轴
——原版接受 `image/*` 选图（含 `.svg`），Harmony 无 SVG 光栅化能力。

## 一、wbn 便签卡滑动动作 —— 已移植

### 原版证据（decompiled_1.4.2）

- `wbn.java`：便签卡滑动揭示星形（favorite/unfavorite_outline）与垃圾桶
  两枚动作按钮；附带 `favorite_note_swipe_action` /
  `unfavorite_note_swipe_action` / `delete_note_swipe_action`
  无障碍文案（标题占位符格式化）。
- `qbn.g`：卡片修饰符 = `sd4`（`dm9` 锚定拖放控制器）+ 点击 + 长按；
  `sd4.c()` 为拖放使能位。
- `t3n.a(dm9, ref, qh2, i)`：把控制器绑定到 Compose 手势效果；
  卡内 `z2`（`ftb != null`）亦抑制揭示背景。
- 删除路径走通用 `delete_note_message` 确认对话框（`urf`/`save` 同一语义），
  非"滑满即删"。

### Harmony 实现（既有）

- `note/src/main/ets/ui/pages/LibraryPage.ets`：`NoteSwipeActions(note)`
  —— 星形 + 垃圾桶、相同三条 a11y 串、动作回调 `toggleNoteFavorite`
  / `confirmDelete`；`isMultiSelecting` 时禁用滑动。
- 门控等价：原版 `sd4.c()`/`z2` 抑制揭示 ↔ Harmony `isMultiSelecting`
  禁用 swipeAction。

### 结论

**已实现等价**，修复总纲中"便签卡滑动动作待核实"属失鲜记录，本 Phase
予以正式收尾。

## 二、语言选择器 + 语法高亮 —— 已移植

### 原版证据

- `o3i.c`：CODE_BLOCK 段落 → `programmingLanguage` → `ehd`（Prism4j
  分词器 `matchGrammar`/`tokenize`/`grammar(name)`）→ `znh`/`s3i`
  语法树 → `ynh.a` 递归生成 `ny6(start,end,bni)` 颜色 span →
  `nb_highlight` 作用到文字布局；仅在布局/渲染期覆盖字符颜色，不写回
  持久样式 run。
- `vza.java`：语言别名解析 + 支持集（15 内建 + 11 惰性 = 26 种语法）。
- `o3i.b`：40 项 token→bni 类目→`uog` 颜色映射（GitHub-light 系）。

### Harmony 实现（既有）

- `note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets`：
  Prism4j 引擎完整移植（文件头逐类映射 ehd/mnc/zmi/zm6/chd/s3i/znh/
  rgm/c9n/ynh/o3i.b/vza），输出 `CodeStyleSpan{start,end,color}`。
- `note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets`：
  渲染期接线。
- `note/src/main/ets/ui/components/TextBlockOverlay.ets`：
  `caretCodeLanguage`/`buildCodeLanguageMenu`/`setCodeLanguage`/
  `persistCodeBlockLanguage` + `onCodeLanguageSelected` 回调链，
  选择语言后持久化并刷新。

### 结论

**已实现等价**（引擎级移植，含别名、内建/惰性语法、token 配色），
"语言选择器/语法高亮待后续"亦属失鲜记录。

## 三、lj3 `-24f` —— vendored 库内部细节

- `lj3.java` = 图像解码器工厂接口（`mj3 a(jng, r5c, g4e)`）；
  `ufh.java` 为其 SVG 实现（`com.caverock.androidsvg` vendored）。
- `-24f` 属于 AndroidSVG 字体度量换算的实现细节，并非应用级行为契约；
  随第四条 SVG 轴一并判清，不再单列。

## 四、SVG 图像导入轴 —— fail-closed

### 原版证据

- `ufh.java`：解码器工厂，命中 `image/svg+xml` MIME **或** 流内容
  `<svg` 嗅探 → 返回 `vfh`（AndroidSVG）解析器。
- `v4a.java:32-33`：`svg`/`svgz` → `image/svg+xml` 后缀→MIME 映射。
- `cb.java:35` / `db.java:56` / `w0.java:31` 等：系统选图 Intent 广播
  `image/*`（+`video/*`），`.svg` 经此可达导入管线。

### Harmony 现状

- `NoteImporter.ets`：`IMPORTED_IMAGE_SUFFIXES` 与 picker
  `fileSuffixFilters` 均为 `png/jpg/jpeg/webp/gif/heif/heic/tif/tiff`
  —— **不广播 `.svg`**；ImageKit `createImageSource` 不支持 SVG
  解码，无 vendored 级 SVG 光栅化器。

### 裁定

**fail-closed**：不引入第三方 SVG 解析器（vendored-library 体量、
需独立矢量光栅管线）；选择器不广播 `.svg`，用户无法选中 SVG 文件，
不存在"选中后静默失败"的坏路径。若后续需要，应作为独立大项立项
（含 AndroidSVG 等价物评估 + text/font 语义回归），不在本 Phase 范围。

## 验证

- 新增 Replay：`d02-original-stale-deferral-closure.mjs`（13 checks）。
- 全量基线、`note@default`、`note@ohosTest`：见 Report。
