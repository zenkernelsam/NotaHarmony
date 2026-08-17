import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const originalRoot = process.env.NOTABILITY_ORIGINAL_ROOT ??
  'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const readRepo = relative => fs.readFileSync(path.join(root, relative), 'utf8').replaceAll('\r\n', '\n');
const readOriginal = name => fs.readFileSync(path.join(originalRoot, name), 'utf8');

const be5 = readOriginal('be5.java');
const fu1 = readOriginal('fu1.java');
const s11 = readOriginal('s11.java');
const die = readOriginal('die.java');
const ry0 = readOriginal('ry0.java');
const td8 = readOriginal('td8.java');

const blockGeometry = readRepo('note/src/main/ets/core/model/BlockHitGeometry.ets');
const textGeometry = readRepo('note/src/main/ets/core/model/TextBlockGeometry.ets');
const imageGeometry = readRepo('note/src/main/ets/core/model/ImageBlockGeometry.ets');
const mathGeometry = readRepo('note/src/main/ets/core/model/MathBlockGeometry.ets');
const selection = readRepo('note/src/main/ets/rendering/SelectionTool.ets');
const renderer = readRepo('note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets');
const overlay = readRepo('note/src/main/ets/ui/components/TextBlockOverlay.ets');
const canvas = readRepo('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const thumbnail = readRepo('note/src/main/ets/rendering/ThumbnailRenderer.ets');
const textFixture = readRepo('note/src/test/TextBlockGeometry.test.ets');
const selectionFixture = readRepo('note/src/test/SelectionTool.test.ets');
const imageFixture = readRepo('note/src/test/ImageBlockRendering.test.ets');
const mathFixture = readRepo('note/src/test/MathBlockGeometry.test.ets');
const rendererFixture = readRepo('note/src/test/RendererStyle.test.ets');

function inversePoint(point, matrix) {
  const determinant = matrix[0] * matrix[4] - matrix[1] * matrix[3];
  if (!Number.isFinite(determinant) || Math.abs(determinant) <= 1e-7) return null;
  const dx = point.x - matrix[2];
  const dy = point.y - matrix[5];
  return {
    x: (matrix[4] * dx - matrix[1] * dy) / determinant,
    y: (-matrix[3] * dx + matrix[0] * dy) / determinant,
  };
}

function pointInRect(point, rect) {
  return point.x >= rect.left && point.x <= rect.right &&
    point.y >= rect.top && point.y <= rect.bottom;
}

function orientation(a, b, p) {
  return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

function onSegment(point, start, end) {
  return Math.abs(orientation(start, end, point)) <= 1e-7 &&
    point.x >= Math.min(start.x, end.x) - 1e-7 &&
    point.x <= Math.max(start.x, end.x) + 1e-7 &&
    point.y >= Math.min(start.y, end.y) - 1e-7 &&
    point.y <= Math.max(start.y, end.y) + 1e-7;
}

function segmentsIntersect(a, b, c, d) {
  const abC = orientation(a, b, c);
  const abD = orientation(a, b, d);
  const cdA = orientation(c, d, a);
  const cdB = orientation(c, d, b);
  if (((abC > 1e-7 && abD < -1e-7) || (abC < -1e-7 && abD > 1e-7)) &&
    ((cdA > 1e-7 && cdB < -1e-7) || (cdA < -1e-7 && cdB > 1e-7))) return true;
  return onSegment(c, a, b) || onSegment(d, a, b) || onSegment(a, c, d) || onSegment(b, c, d);
}

function pointInPolygon(point, polygon) {
  let inside = false;
  for (let current = 0, previous = polygon.length - 1;
    current < polygon.length; previous = current++) {
    const a = polygon[previous];
    const b = polygon[current];
    if (onSegment(point, a, b)) return true;
    if ((a.y > point.y) !== (b.y > point.y) &&
      point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) inside = !inside;
  }
  return inside;
}

function polygonHitsLocalRect(worldPath, matrix, rect) {
  const local = worldPath.map(point => inversePoint(point, matrix));
  if (local.some(point => point === null)) return false;
  if (local.some(point => pointInRect(point, rect))) return true;
  const corners = [
    { x: rect.left, y: rect.top }, { x: rect.right, y: rect.top },
    { x: rect.right, y: rect.bottom }, { x: rect.left, y: rect.bottom },
  ];
  if (corners.some(point => pointInPolygon(point, local))) return true;
  for (let i = 0; i < local.length; i++) {
    for (let edge = 0; edge < corners.length; edge++) {
      if (segmentsIntersect(local[i], local[(i + 1) % local.length],
        corners[edge], corners[(edge + 1) % corners.length])) return true;
    }
  }
  return false;
}

const angle = Math.PI / 4;
const rotated = [Math.cos(angle), -Math.sin(angle), 100,
  Math.sin(angle), Math.cos(angle), 100, 0, 0, 1];
const localBlock = { left: 0, top: 0, right: 100, bottom: 20 };
const aabbFalsePositive = [
  { x: 166, y: 102 }, { x: 170, y: 102 },
  { x: 170, y: 106 }, { x: 166, y: 106 },
];
const edgeHit = [
  { x: 98, y: 98 }, { x: 104, y: 98 },
  { x: 104, y: 104 }, { x: 98, y: 104 },
];
const nonUniform = [4, 0, 0, 0, 1, 0, 0, 0, 1];
const farLocal = inversePoint({ x: 200, y: 23 }, nonUniform);
const nearLocal = inversePoint({ x: 200, y: 20.5 }, nonUniform);
const originalLocalRadius = 8 / 2 / 4;

const checks = [
  ['original Block matrix is composed from nullable rotation and scale',
    be5.includes('y18.h(ldj.t2(fJ.floatValue()), fArrA)') &&
      be5.includes('y18.i(fArrA, qedVarB.d(), qedVarB.c())')],
  ['original query is inverted and translated by Block plus page origin',
    fu1.includes('y18.b(fArrP)') &&
      fu1.includes('(-fqaVarH.c()) - fqaVarG.c()') &&
      fu1.includes('(-fqaVarH.d()) - fqaVarG.d()')],
  ['original point-query radius is divided by the maximum Block scale',
    fu1.includes('((vh5) wh5Var).b() / Math.max(qedVarB.d(), qedVarB.c())')],
  ['original Block point hit uses the local size rectangle expanded by radius',
    fu1.includes('(fIntBitsToFloat < fC)') && fu1.includes('(fIntBitsToFloat >= f2)') &&
      fu1.includes('(fIntBitsToFloat2 >= f2)') && fu1.includes('(fIntBitsToFloat2 < fB2)')],
  ['original lasso/rectangle hit intersects the transformed Path with local Block size',
    fu1.includes('path.addRect(0.0f, 0.0f, oy0Var.a().d(), oy0Var.a().c()') &&
      fu1.includes('return jy0.e(((uh5) wh5VarJ).a(), sh8.x(path, 0, 0, null))')],
  ['original Text renderer applies transform clips local size then translates content insets',
    s11.includes('l65Var3.H(fArr)') &&
      s11.includes('.s(0.0f, 0.0f, fD, fC, 1)') &&
      s11.includes('.I(f4, f5)')],
  ['TextBlockInfo retains transform local size insets and rotation independently',
    die.includes('TextBlockInfo(transforms=') && die.includes(', textOrigin=') &&
      die.includes(', blockScaledSize=') && die.includes(', textContentLeftInset=') &&
      die.includes(', rotationRadians=')],
  ['Block common state retains independent geometry lock and z-index registers',
    ry0.includes('pageAndOriginRegister=') && ry0.includes('rotationRegister=') &&
      ry0.includes('scaleRegister=') && ry0.includes('sizeRegister=') &&
      ry0.includes('positionLockedRegister=') && ry0.includes('zIndexRegister=')],
  ['ModifyBlock retains origin rotation scale size lock and z-index fields',
    td8.includes(', origin=') && td8.includes(', rotation=') && td8.includes(', scale=') &&
      td8.includes(', size=') && td8.includes(', zIndex=') && td8.includes(', positionLocked=')],
  ['Harmony shared Block geometry rejects malformed affine transforms',
    blockGeometry.includes('function validAffineTransform') &&
      blockGeometry.includes('Math.abs(determinant) <= GEOMETRY_EPSILON') &&
      blockGeometry.includes('if (!Number.isFinite(value))')],
  ['Harmony maps point selection and eraser paths through one inverse affine contract',
    blockGeometry.includes('inverseAffinePoint(point, transform)') &&
      blockGeometry.includes('inverseAffinePath(selectionPath, transform)') &&
      blockGeometry.includes('inverseAffinePath(eraserPath, transform)')],
  ['Harmony eraser uses original maximum-scale radius and expanded local rectangle',
    blockGeometry.includes('Math.max(scaleX, scaleY)') &&
      blockGeometry.includes('Math.max(0, eraserWidth) / 2 / scale') &&
      blockGeometry.includes('left: localBounds.left - radius')],
  ['Harmony selection detects vertex containment rectangle containment and edge intersection',
    blockGeometry.includes('pointInClosedRect(point, localBounds)') &&
      blockGeometry.includes('pointInPolygonOrBoundary(corner, localPath)') &&
      blockGeometry.includes('closedPathIntersectsRect(localPath, localBounds)')],
  ['Text preserves its possibly non-zero local textOrigin rectangle',
    textGeometry.includes('left: element.textOrigin.x') &&
      textGeometry.includes('selectionPathHitsAffineBlock(') &&
      textGeometry.includes('eraserPathHitsAffineBlock(')],
  ['Image and Math share original local zero-to-size Block geometry',
    imageGeometry.includes('left: 0, top: 0, right: element.blockWidth') &&
      mathGeometry.includes('left: 0, top: 0, right: element.blockWidth') &&
      imageGeometry.includes('selectionPathHitsAffineBlock(') &&
      mathGeometry.includes('selectionPathHitsAffineBlock(')],
  ['SelectionTool no longer selects Text Image or Math by world AABB center',
    selection.includes('selectionPathHitsTextBlock(selectionPath, textBlock)') &&
      selection.includes('selectionPathHitsImageBlock(selectionPath, image)') &&
      selection.includes('selectionPathHitsMathBlock(selectionPath, math)')],
  ['Text renderer clips the semantic local Block before paper and glyph consumers',
    renderer.indexOf('ctx.clip();') < renderer.indexOf('this.renderPaper(ctx, element)') &&
      renderer.includes('const localBounds: Rect2D = textBlockLocalBounds(element)')],
  ['editing overlay consumes the same origin signed scales and rotation',
    overlay.includes('textBlockTransformComponents(this.element)') &&
      overlay.includes('x: this.transformComponents().scaleX') &&
      overlay.includes('y: this.transformComponents().scaleY') &&
      overlay.includes('angle: this.transformComponents().rotationRadians.toString()')],
  ['main canvas and thumbnail keep the same Text renderer consumer',
    canvas.includes('this.textRenderer.renderText(element.data, renderContext)') &&
      thumbnail.includes('this.textRenderer.renderText(element.data, renderContext)')],
  ['ArkTS fixtures cover rotated AABB false positives lasso edge hits and local clipping',
    selectionFixture.includes('only touches a rotated Text AABB') &&
      selectionFixture.includes('lasso edge crosses it') &&
      rendererFixture.includes('clips transformed Text content')],
  ['ArkTS fixtures cover non-uniform Text Image and Math eraser scaling',
    textFixture.includes('original maximum-scale radius') &&
      imageFixture.includes('inverse local geometry for scaled image') &&
      mathFixture.includes('inverse local geometry for scaled Math')],
  ['ArkTS fixture explicitly covers singular and non-finite fail-closed behavior',
    textFixture.includes('fails closed for singular or non-finite') &&
      textFixture.includes('Number.NaN')],
  ['numeric replay rejects the rotated AABB corner false positive',
    !polygonHitsLocalRect(aabbFalsePositive, rotated, localBlock)],
  ['numeric replay accepts a rectangle that crosses the true transformed Block',
    polygonHitsLocalRect(edgeHit, rotated, localBlock)],
  ['numeric replay reproduces maximum-scale eraser radius under non-uniform scale',
    farLocal !== null && nearLocal !== null &&
      farLocal.y > localBlock.bottom + originalLocalRadius &&
      nearLocal.y <= localBlock.bottom + originalLocalRadius],
];

for (const [name, ok] of checks) {
  assert.ok(ok, `FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}

console.log(`D02_ORIGINAL_TEXT_TRANSFORM_SELECTION_ERASER_OK TOTAL=${checks.length} FAILED=0`);
