// Phase 1434 replay: 修复总纲 三笔遗留待办收尾判定
//   (a) wbn 便签卡滑动动作（favorite/unfavorite_outline + trash）已移植 NoteSwipeActions；
//   (b) 语言选择器 + 语法高亮已移植（buildCodeLanguageMenu + CodeSyntaxHighlighter）；
//   (c) lj3 -24f = vendored AndroidSVG 内部细节，随 SVG 导入轴 fail-closed 一并判清。
//   新裁定：原版 image/* 选择器可达 .svg（ufh AndroidSVG 解码 + v4a svg/svgz MIME 映射），
//   Harmony 无 SVG 光栅化器、文件选择器不广播 .svg —— fail-closed。
// 原版证据：sources/defpackage/wbn.java(星形+垃圾桶揭示)、qbn.g(sd4.c() 拖放门)、
//   t3n/dm9(锚定拖放控制器)、urf.java(save → confirmDelete 对话框语义 delete_note_message)、
//   ufh.java(image/svg+xml + <svg 嗅探)、v4a.java(svg/svgz MIME)、lj3.java(解码器工厂)、
//   ehd/ynh/o3i/vza(Prism4j 语法高亮链)。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');

// (1) 滑动动作已移植：NoteSwipeActions（favorite/unfavorite glyph + delete + 多选禁用）
const library = read('note/src/main/ets/ui/library/LibraryPage.ets');
assert.match(library, /NoteSwipeActions/, 'NoteSwipeActions 存在');
assert.match(library, /favorite_note_swipe_action|unfavorite_note_swipe_action/, 'favorite a11y');
assert.match(library, /delete_note_swipe_action/, 'delete a11y');
assert.match(library, /toggleNoteFavorite/, 'favorite 回调');
assert.match(library, /confirmDelete/, 'delete → confirmDelete（原版对话框语义）');

// (2) 语言选择器 + Prism4j 高亮已移植
const overlay = read('note/src/main/ets/ui/components/TextBlockOverlay.ets');
assert.match(overlay, /buildCodeLanguageMenu|caretCodeLanguage/, 'code language picker 存在');
assert.match(overlay, /onCodeLanguageSelected/, '语言选择回调');
const canvasView = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
assert.match(canvasView, /persistCodeBlockLanguage/, '语言持久化落库（ya8 lastCodeBlockLanguage）');
const hl = read('note/src/main/ets/core/adaptation/CodeSyntaxHighlighter.ets');
assert.match(hl, /CodeStyleSpan/, 'Prism4j 移植高亮器');
const canvas = read('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
assert.match(canvas, /CodeSyntaxHighlighter/, '渲染器接线');

// (3) SVG 导入 fail-closed：Harmony 选择器不广播 .svg
const importer = read('note/src/main/ets/data/NoteImporter.ets');
const suffixes = importer.match(/IMPORTED_IMAGE_SUFFIXES[^;]*;/s);
assert.ok(suffixes, 'IMPORTED_IMAGE_SUFFIXES 存在');
assert.ok(!suffixes[0].includes('svg'), '选择器不含 .svg（fail-closed，无伪造支持）');
const pickerFilter = importer.match(/fileSuffixFilters[^;]*;/s);
assert.ok(!pickerFilter || !pickerFilter[0].includes('svg'), 'picker filter 无 .svg');

// (4) 三笔遗留待办的文档收尾已落位
const adr = read('docs/migration/adr/ADR-1369-stale-deferral-closure.md');
assert.match(adr, /wbn|NoteSwipeActions/, 'ADR 覆盖 swipe');
assert.match(adr, /svg|AndroidSVG|ufh/, 'ADR 覆盖 SVG fail-closed');
assert.match(adr, /Prism4j|ehd|ynh/, 'ADR 覆盖语法高亮');

console.log('d02-original-stale-deferral-closure: OK (13 checks)');
