// Phase 1449 — 1.4.2 s40.c/gsf.h/xnm.c/qmm.d 成员级选区铬件对齐。
// Original evidence (decompiled_1.4.2/sources/defpackage):
//   sen.java:1045-1052 — 分发仅 isf→sen.t、hsf→gsf.d；lsf/jsf 走 sen.d
//     早退：画布层不产外层界框。
//   s40.java:c — 成员级铬件循环：xnm.c 产成员框 + qmm.d 成员路径描边 +
//     gsf.h 外层铬件。
//   qmm.java:d — 笔画 mn7/形状 f5g 成员 → 实际路径以 gsf.a 蓝描边，
//     宽 t1h=min(m0(2dp)/zoom, strokeWidth/2)。
//   xnm.java:c — 图片 l97/文本 vvh 成员产 mp4 框（其余成员类型无框）。
//   gsf.java:c — mp4 框：2dp/zoom 实线描边，z&&!mp4.d() 时带柄。
//   gsf.java:h — lsf/hsf→不画；jsf→c(jsf.a(),2dp,e=#FFB3B3B3 灰)+柄；
//     isf→f(m) 组灰盒 + !h 时外柄。
//   mp4.java:d — cjm.h(实体锁) && POSITION_LOCKED → 框不带柄。
// Harmony：画布层 renderSelectionMemberChrome 承担成员轮廓/成员框/组灰盒；
//   覆盖层 selectionBorderless(lsf) 隐外框、selectionOuterGray(jsf) 灰实线
//   2dp、selectionHandlesHidden 按 xnm.c 可框性与锁态抑制手柄。
import { readFileSync } from 'node:fs';
import assert from 'node:assert';

const CANVAS = 'note/src/main/ets/ui/editor/NoteCanvasView.ets';
const OVERLAY = 'note/src/main/ets/ui/components/SelectionOverlay.ets';
const SHAPEGEO = 'note/src/main/ets/core/model/ShapeGeometry.ets';
const canvas = readFileSync(CANVAS, 'utf8').replace(/\r\n/g, '\n');
const overlay = readFileSync(OVERLAY, 'utf8').replace(/\r\n/g, '\n');
const shapeGeo = readFileSync(SHAPEGEO, 'utf8').replace(/\r\n/g, '\n');

let n = 0;
const check = (cond, msg) => { assert(cond, msg); n++; };

// --- 画布层成员级铬件函数存在且在元素层之上调用 ---
const chrome = canvas.slice(canvas.indexOf('private renderSelectionMemberChrome('),
  canvas.indexOf('private strokeMemberQuad('));
check(chrome.length > 500, 'renderSelectionMemberChrome implemented');
check(canvas.indexOf('this.renderSelectionMemberChrome();') >
  canvas.indexOf('this.renderLaserOverlay();') &&
  canvas.indexOf('this.renderSelectionMemberChrome();') <
  canvas.indexOf('this.renderSelectionTrailGhost();'),
  'member chrome drawn above content layer before sen-style bounds');
check(chrome.includes('this.selectionVisible') &&
  chrome.includes('this.selectionDrawing') && chrome.includes('this.isTextOnly'),
  'member chrome gated on selectionVisible/!selectionDrawing/!isTextOnly');

// --- qmm.d：笔画/形状成员实际路径描边，宽 min(2dp/zoom, strokeW·|M|/2) ---
check(chrome.includes('state.selectedStrokeIds') &&
  chrome.includes('traceMemberInkPath') &&
  chrome.includes('stroke.customPath') && chrome.includes('stroke.fillPath'),
  'stroke members: customPath/fillPath outline traced (qmm.d mn7.S() path)');
check(/Math\.min\(chromeW,\s*stroke\.renderSpec\.brushWidth \* scale \/ 2\)/.test(chrome),
  'stroke member width = min(2dp/zoom, brushWidth·scale/2) (t1h)');
check(chrome.includes('state.selectedShapeIds') &&
  chrome.includes('shapeWorldSubpaths(shape)'),
  'shape members: per-subpath world outline (qmm.d f5g branch)');
check(chrome.includes('Math.min(chromeW, shape.strokeWidth'),
  'shape member width = min(2dp/zoom, strokeWidth·scale/2)');
check(chrome.includes('SELECTION_OUTLINE_COLOR'),
  'member outlines stroked in gsf.a=#FF4278FF');

// --- xnm.c+gsf.c：图片/文本成员旋转实线框 ---
check(chrome.includes('state.selectedTextBlockIds') &&
  chrome.includes('textBlockWorldCorners(block)'),
  'text member boxes via textBlockWorldCorners (xnm.c vvh→mp4)');
check(chrome.includes('state.selectedImageIds') &&
  chrome.includes('imageBlockLocalBounds(image)') &&
  chrome.includes('strokeMemberQuad'),
  'image member boxes via local-bounds×transform (xnm.c l97→mp4)');
check(chrome.includes('strokeMemberQuad') &&
  canvas.includes('private strokeMemberQuad('),
  'member quads drawn as rotated rects (gsf.c path quad)');

// --- gsf.h f()：组灰盒 #FFB3B3B3 ---
check(chrome.includes("'#FFB3B3B3'") &&
  chrome.includes('state.selectedGroupIds') &&
  chrome.includes('memberUnionBounds(group.members)'),
  'group member boxes = gsf.h f() gray #FFB3B3B3 solid box');

// --- sen.d 早退：lsf 覆盖层无外框 ---
check(overlay.includes('@Prop selectionBorderless: boolean') &&
  overlay.includes('if (!this.selectionBorderless)'),
  'lsf outer border suppressed (gsf.h early return for lsf)');
check(canvas.includes('this.selectionBorderless = !state.supportsDeselectMode &&') &&
  canvas.includes('state.selectedGroupIds.length === 0'),
  'borderless = lsf (!isf && no groups)');

// --- gsf.h：jsf 灰实线 2dp 外盒 ---
check(overlay.includes('@Prop selectionOuterGray: boolean') &&
  overlay.includes("color: this.selectionOuterGray ? '#FFB3B3B3' : '#FF4278FF'"),
  'jsf outer box = e=#FFB3B3B3 gray solid (gsf.h jsf branch)');
check(overlay.includes('this.selectionDrawn || this.selectionOuterGray ? 2 : 4'),
  'jsf gray box is 2dp solid like drawn isf (gsf.c t1h 2dp/zoom)');
check(canvas.includes('this.selectionOuterGray = !state.supportsDeselectMode &&') &&
  canvas.includes('state.selectedGroupIds.length > 0'),
  'outerGray = jsf (!isf && has groups)');

// --- xnm.c/mp4.d：lsf 手柄仅未锁图片/文本成员 ---
check(overlay.includes('@Prop selectionHandlesHidden: boolean') &&
  overlay.includes('!this.selectionHandlesHidden'),
  'handles gated on selectionHandlesHidden prop');
check(canvas.includes('this.selectionHandlesHidden = this.selectionBorderless && !lsfBoxedUnlocked'),
  'lsf handles only for boxed (image/text) unlocked members (mp4.d gate)');
check(canvas.includes('text.positionLocked !== true') &&
  canvas.includes('!image.positionLocked'),
  'mp4.d() = positionLocked suppresses handles');

// --- ShapeGeometry：shapeWorldSubpaths 分路径世界坐标 ---
check(shapeGeo.includes('export function shapeWorldSubpaths(shape: ShapeElement): Point2D[][]'),
  'shapeWorldSubpaths export (subpath-preserving world outline)');

// --- Phase 1451 qmm.d cpfVar.g：lsf 形状成员顶点双层圆点 ---
// qmm.b z=lsf 支：f5g.U().b() 顶点 → 白 7.5dp/zoom(6·1.25)+蓝 6dp/zoom。
//   LINE → [start, 贝塞尔中点?, end]（m4g.b q89：o/0.5加权中点/n）；
//   POLYGON → 全部顶点（l4g.b=vpm.c0）；ELLIPSE → 4 基向点（k4g.b）。
check(chrome.includes('const lsf: boolean = !state.supportsDeselectMode') &&
  chrome.includes('memberCount === 1'),
  'vertex dots gated on lsf (z=msfVar instanceof lsf, single member)');
check(chrome.includes('shapeVertexDots(shape)') &&
  chrome.includes('7.5 / zoom') && chrome.includes('6.0 / zoom'),
  'vertex dots = white 7.5dp/zoom + blue 6dp/zoom two-tone circles');
check(canvas.includes('private shapeVertexDots(shape: ShapeElement): Point2D[]'),
  'shapeVertexDots helper maps f5g.U().b() vertex sets');
const dots = canvas.slice(canvas.indexOf('private shapeVertexDots('),
  canvas.indexOf('private shapeVertexDots(') + 2200);
check(dots.includes('ElementType.LINE') && dots.includes('shape.start') &&
  dots.includes('shape.end') && dots.includes('0.125') && dots.includes('0.375'),
  'LINE vertices = [start, bezier-mid(0.125/0.375 weights), end] (q89 o/mid/n)');
check(dots.includes('ElementType.POLYGON') && dots.includes('shape.vertices'),
  'POLYGON vertices = all shape.vertices (l4g.b=vpm.c0)');
check(dots.includes('ElementType.ELLIPSE') && dots.includes('rotationRadians') &&
  dots.includes('radiusX') && dots.includes('radiusY'),
  'ELLIPSE vertices = 4 cardinal points (k4g.b: ±rx/±ry rotated)');
check(dots.includes('transformMemberPoint(p, shape.transform)'),
  'vertex dots transformed to world space (element transform)');

console.log(`d02-original-member-chrome-render: ${n} checks OK`);
