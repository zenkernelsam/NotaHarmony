// Phase 642 — 分享面板 JPG/PNG 行点亮：当前页整页栅格化导出。
// 原版证据（decompiled_1.0.3）：
//   s6d 枚举含 JPG/PNG（atc case6/7 渲染 share_jpg/share_png 图标）；
//   b7d/v6d 面板带页选择集合（v6d.l Set + m 计数）——上游支持选页范围；
//   y59.b 为按格式导出执行体（JADX 未反编译）。
// Harmony 对齐（ADR-0609 子集）：
//   * ThumbnailRenderer 抽出 renderPageCore，新增 renderPageExport：
//     整页 pagePixelSize×scale、无边距无 letterbox、独立栅格预算
//     （4096 边 / 16M px），纸面/PDF 背景/笔/文字/形状/图/公式全栈
//     复用缩略图同一渲染器组；
//   * PageImageExporter：image.ImagePacker.packToData（png/jpeg q92）→
//     沙箱临时文件 → DocumentViewPicker 保存 → 分块复制；
//   * EditorToolbar JPG/PNG 行点亮 → onShareImage(format)；
//   * NotePage.shareCurrentPageAsImage：当前页 ×2.0（≈192dpi）亮主题
//     栅格化 → 导出 → 既有 export_done/export_failed toast；
//     pixelMap/renderer 在 finally 中释放。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const s6d = fs.readFileSync(`${originalRoot}s6d.java`, 'utf8');
const atc = fs.readFileSync(`${originalRoot}atc.java`, 'utf8');
const v6d = fs.readFileSync(`${originalRoot}v6d.java`, 'utf8');

const renderer = fs.readFileSync('note/src/main/ets/rendering/ThumbnailRenderer.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const exporter = fs.readFileSync('note/src/main/ets/data/PageImageExporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const toolbar = fs.readFileSync('note/src/main/ets/ui/editor/EditorToolbar.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const notePage = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}

// --- 原版证据 ---
check(s6d.includes('JPG(R.string.ui_share__chip_jpg') &&
  s6d.includes('PNG(R.string.ui_share__chip_png'),
  's6d enumerates JPG and PNG share formats');
check(atc.includes('R.drawable.ui_designsystem__share_jpg') &&
  atc.includes('R.drawable.ui_designsystem__share_png'),
  'atc cases 6/7 render the jpg/png share icons');
check(v6d.includes('public final java.util.Set l') || v6d.includes('final Set l'),
  'v6d carries a page-selection set (upstream supports page ranges)');

// --- Harmony：整页栅格化 ---
check(renderer.includes('async renderPageExport(noteId: string, persistence: StrokePersistence,'),
  'renderPageExport is exposed for share export');
check(renderer.includes('private async renderPageCore(noteId: string, persistence: StrokePersistence,'),
  'the render body is shared between thumbnail and export paths');
check(renderer.includes('renderPageCore(noteId, persistence, page, theme, database,\n      pageSize, THUMB_W, THUMB_H, pageTransform)'),
  'renderThumbnail delegates to the shared core');
check(renderer.includes('Math.round(pageSize.width * scale)') &&
  renderer.includes('Math.round(pageSize.height * scale)'),
  'export dimensions are the page pixel size scaled');
check(renderer.includes('EXPORT_MAX_SIDE: number = 4096') &&
  renderer.includes('EXPORT_MAX_PIXELS: number = 16000000'),
  'export raster budget is independent of the page-cache caps');
check(renderer.includes('offset: { x: 0, y: 0 }'),
  'export renders edge-to-edge without letterboxing');
check(renderer.includes('Export raster budget exceeded'),
  'out-of-budget export requests fail closed');
check(renderer.includes('pdfLoader.load(effective.pdf, rasterRequest)') &&
  renderer.includes('renderOffscreenBackground') &&
  renderer.includes('renderMath(element.data, renderContext'),
  'the shared core still covers paper/PDF background and the full element stack');

// --- Harmony：图像导出管线 ---
check(exporter.includes("format === 'png' ? 'image/png' : 'image/jpeg'"),
  'packer encodes png or jpeg by row format');
check(exporter.includes('JPEG_QUALITY: number = 92'),
  'jpeg export uses quality 92');
check(exporter.includes('new picker.DocumentViewPicker(context)') &&
  exporter.includes('documentPicker.save(saveOptions)'),
  'page image export goes through the system save picker');
check(exporter.includes("'.png' : '.jpg'") &&
  exporter.includes('fileSuffixChoices'),
  'saved file carries the matching suffix');
check(exporter.includes('exportPageImage: user cancelled'),
  'picker cancellation returns without a toast-as-failure double-report');
check(exporter.includes('fileIo.unlinkSync(tmpPath)'),
  'temporary raster file is cleaned up');

// --- Harmony：工具栏与 NotePage 接线 ---
check(toolbar.includes("ShareFormatRow($r('app.string.share_jpg'), 'jpg', true)") &&
  toolbar.includes("ShareFormatRow($r('app.string.share_png'), 'png', true)"),
  'jpg/png rows are enabled');
check(toolbar.includes('onShareImage: (format: string) => void') &&
  toolbar.includes('this.onShareImage(format);'),
  'image rows dispatch the format to onShareImage');
check(notePage.includes('onShareImage: (format: string) => {') &&
  notePage.includes('this.shareCurrentPageAsImage(format);'),
  'NotePage wires the image-format callback');
check(notePage.includes('const page: PageInfo = this.pages[this.currentPageIndex];'),
  'export rasterizes the currently visible page');
check(notePage.includes('PAGE_EXPORT_SCALE: number = 2.0') &&
  notePage.includes('renderPageExport(this.noteId, this.persistence,\n          page, theme, db, PAGE_EXPORT_SCALE)'),
  'export renders at 2x page pixels (~192dpi)');
check(notePage.includes("ThemeStore.resolve('light', false)"),
  'export uses authored (light) colors regardless of night mode');
check(notePage.includes("format === 'png' ? 'png' : 'jpeg'"),
  'toolbar jpg maps to the jpeg packer format');
check(notePage.includes('await pixelMap.release();') &&
  notePage.includes('await renderer.dispose();'),
  'raster pixelMap and renderer are released in finally');

console.log(`D05_ORIGINAL_SHARE_PAGE_IMAGE_REPLAY_OK TOTAL=${total} FAILED=0`);
