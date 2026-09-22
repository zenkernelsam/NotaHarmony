// Phase 604 — 裁剪会话期间图片按未裁剪全图渲染（itc.c showUncroppedImage /
//   TileSubmission.showUncropped 对齐）。
// Original evidence (decompiled_1.0.3/sources/defpackage):
//   itc.java:57 — Tap 选区第三字段 c = showUncroppedImage；
//     dhb case14 (CROP) → fvb.e(true) 置位，裁剪结束复位 false。
//   l0f.java:103 — TileSubmission.r = showUncropped；
//   m2f.java:109 — TiledRendererUpdate.j = showUncropped：
//     瓦片渲染收到未裁剪标记，裁剪中的图片块渲染整张原图，
//     使 draft 矩形可拖入已裁掉的域（domain 可超出当前块）。
// Harmony：imageCropVisible 期间对被裁剪图片传 session.sourceCrop 走
//   uncropped 渲染路径（intrinsic 单位 = 本地块坐标系，平移 -source.left/
//   -source.top 后按 intrinsic/oriented 缩放画全图）。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const RENDERER = 'note/src/main/ets/rendering/ImageCanvasRenderer.ets';
const GEOMETRY = 'note/src/main/ets/core/model/OriginalImageCropGeometry.ets';
const canvas = readFileSync(CANVAS, 'utf8');
const renderer = readFileSync(RENDERER, 'utf8');
const geometry = readFileSync(GEOMETRY, 'utf8');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 渲染器：uncropped 分支与裁剪分支并存 ---
const render = renderer.slice(renderer.indexOf('renderImage(element: ImageElement'),
  renderer.indexOf('renderImage(element: ImageElement') + 2600);
check(render.includes('uncroppedSourceCrop: Rect2D | null = null'),
  'renderImage accepts an optional uncropped source crop');
check(render.indexOf('if (uncroppedSourceCrop === null)') > 0,
  'cropped vs uncropped branch split present');
const uncropped = render.slice(render.indexOf('} else {'), render.indexOf('ctx.restore()'));
check(uncropped.includes('ctx.translate(-uncroppedSourceCrop.left, -uncroppedSourceCrop.top)'),
  'uncropped path offsets by -sourceCrop (domain origin, itc.c parity)');
check(uncropped.includes('element.intrinsicWidth / geometry.orientedWidth') &&
  uncropped.includes('element.intrinsicHeight / geometry.orientedHeight'),
  'uncropped path scales oriented pixels → intrinsic units');
check(uncropped.includes('ctx.translate(geometry.flipTranslateX, geometry.flipTranslateY)') &&
  uncropped.includes('ctx.transform(geometry.orientationTransform)'),
  'uncropped path keeps EXIF orientation + user flip order');
check(render.indexOf('ctx.rect(0, 0, element.blockWidth, element.blockHeight)') <
  render.indexOf('} else {'),
  'block-rect clip stays on the cropped path only (full image visible while cropping)');

// --- 画布：仅裁剪目标块走 uncropped 路径 ---
const renderCall = canvas.indexOf('this.imageRenderer.renderImage(element.data');
const imgBranch = canvas.slice(renderCall - 900, renderCall + 600);
check(imgBranch.includes('this.imageCropVisible && cropSession !== null'),
  'uncropped render gated on imageCropVisible + active session');
check(imgBranch.includes('cropSession.original.id === element.data.id'),
  'only the session target image renders uncropped');
check(imgBranch.includes('cropSession.sourceCrop'),
  'session.sourceCrop feeds the uncropped domain offset');
check(imgBranch.includes('loaded.orientationDegrees, loaded.mirroredHorizontally, uncroppedSource'),
  'call site passes uncroppedSource as the trailing renderImage arg');

// --- 几何不变量：draft 域可超出当前块（未裁剪渲染的前提） ---
check(geometry.includes('left: -source.left') && geometry.includes('right: element.intrinsicWidth - source.left'),
  'session.domain spans the whole intrinsic image around the crop');
check(geometry.includes('numbersNear(source.right - source.left, element.blockWidth)'),
  'crop source units share the local block space (required by the uncropped offset)');

console.log(`D02_ORIGINAL_IMAGE_UNCROPPED_RENDER_OK TOTAL=${n} FAILED=0`);
