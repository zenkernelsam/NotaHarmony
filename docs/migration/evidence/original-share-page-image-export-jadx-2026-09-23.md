# 原版分享面板 JPG/PNG 页栅格化导出 — jadx 证据（2026-09-23）

阶段：Phase 642。结论：原版分享面板（`b7d`/`v6d`）的 `s6d.JPG`/`s6d.PNG`
格式对所选页栅格化导出图像；Harmony 现以"当前页 ×2 栅格"子集点亮
两行，页选择集合与多文件分发登记为差异（ADR-0609）。

## 原版证据（decompiled_1.0.3）

### 格式枚举与图标

`defpackage/s6d.java`：`JPG(ui_share__chip_jpg, action_jpg, ..., atc(6))`、
`PNG(ui_share__chip_png, action_png, ..., atc(7))`；`atc` case6/7 渲染
`ui_designsystem__share_jpg`/`share_png` 图标。

### 页选择集合

`defpackage/v6d.java`：面板状态含 `Set l`（页选择集合）+ `int m`
（页数），`b7d` 在导出上报中比较 `l.size() != m` 判定部分页导出
——原版 JPG/PNG 支持页范围子集导出。

### 导出执行

`defpackage/y59.java` `b(s6d, List, Map, File, Set, String, boolean,
boolean, x09, Map, ff2)`：按格式导出执行体；JADX 未反编译
（`UnsupportedOperationException`），栅格化分辨率/分发细节不可见。
安卓侧经 `v6d.t` 的 `Intent` 走系统分享分发。

## Harmony 实现（本 Phase）

- `ThumbnailRenderer.renderPageCore` 抽出共享渲染体
  （纸面/PDF 背景/笔/文字/形状/图/公式全栈，缩略图同组渲染器）；
- `renderPageExport(noteId, persistence, page, theme, db, scale)`：
  输出尺寸 = `pagePixelSize × scale`，无边距/letterbox
  （`offset {0,0}`），独立栅格预算 `EXPORT_MAX_SIDE=4096` /
  `EXPORT_MAX_PIXELS=16M`（页缓存 2048/2M 预算不动）；
- `data/PageImageExporter.ets`：`image.ImagePacker.packToData`
  （`image/png` / `image/jpeg` q92，64MB 缓冲）→ 沙箱临时文件 →
  `DocumentViewPicker.save`（`.png`/`.jpg` 后缀）→ 分块复制 →
  临时文件清理——与 `NoteExporter.exportToFile` 同一管线范式；
- `EditorToolbar`：`ShareFormatRow` 增 `format` 参数；JPG/PNG 行点亮，
  NOTE/JPG/PNG 三行可点，LINK/PDF 继续置灰；
- `NotePage.shareCurrentPageAsImage(format)`：当前可见页
  （`pages[currentPageIndex]`）按 `PAGE_EXPORT_SCALE=2.0`
  （≈192dpi）亮主题栅格化——导出恒取笔记固有颜色，不受夜间模式
  影响；`pixelMap.release()`/`renderer.dispose()` 在 finally 兜底；
  结果复用 `export_done`/`export_failed` toast。

## 与原版的差异（ADR-0609 登记）

1. 页范围：原版支持面板内页选择集合 + 多文件分发；Harmony 当前仅导出
   当前可见页。
2. 分发通道：原版经安卓系统分享 Intent；Harmony 以 DocumentViewPicker
   保存对话框为原生对等物。
3. 栅格分辨率：原版 `y59.b` 未反编译不可考；Harmony 取 2×
   pagePixelSize（≈192dpi）。
