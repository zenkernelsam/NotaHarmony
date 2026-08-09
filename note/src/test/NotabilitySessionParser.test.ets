import { describe, it, expect } from '@ohos/hypium';
import {
  assessNotabilityCurveFidelity, createNotabilityContentInventory, NotabilityContentInventory,
  NotabilitySession, resolveNotabilityPageCount, summarizeNotabilityContentLoss,
} from '../main/ets/data/NotabilitySessionParser';
import { ElementType } from '../main/ets/core/model/ElementTypes';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';

export default function notabilitySessionParserTest() {
  describe('NotabilitySessionParser', () => {
    it('does not report an intentionally blank note as partial content loss', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      expect(summarizeNotabilityContentLoss(inventory).length).assertEqual(0);
    });

    it('reports typed and media content with exact recovered and lost counts', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      inventory.textCharacters.found = 18;
      inventory.media.found = 2;
      const details: string[] = summarizeNotabilityContentLoss(inventory);
      expect(details.length).assertEqual(2);
      expect(details[0]).assertContain('发现 18 字符');
      expect(details[0]).assertContain('丢失 18 字符');
      expect(details[1]).assertContain('发现 2 项');
      expect(details[1]).assertContain('丢失 2 项');
    });

    it('reports quantified, degraded and structurally unknown shape loss', 0, () => {
      const inventory: NotabilityContentInventory = createNotabilityContentInventory();
      inventory.shapes.found = 4;
      inventory.shapes.recovered = 2;
      inventory.shapes.degraded = 1;
      inventory.shapes.unquantifiedLoss = true;
      const details: string[] = summarizeNotabilityContentLoss(inventory);
      expect(details.length).assertEqual(3);
      expect(details[0]).assertContain('丢失 2 个');
      expect(details[1]).assertContain('1 个');
      expect(details[2]).assertContain('数量未知');
    });

    it('uses the larger of content-derived pages and index hint', 0, () => {
      expect(resolveNotabilityPageCount(4, 2)).assertEqual(4);
      expect(resolveNotabilityPageCount(2, 5)).assertEqual(5);
      expect(resolveNotabilityPageCount(0, 0)).assertEqual(1);
    });

    it('marks unsupported curve attributes as degraded without inventing a mapping', 0, () => {
      const baseline = assessNotabilityCurveFidelity(
        3, [1, 1], [1, 1], [Math.PI / 2], [1], [0]);
      expect(baseline.degraded).assertFalse();

      const changed = assessNotabilityCurveFidelity(
        7, [1, 0.7], [1, 0.4], [0.8], [0.5], [0.5]);
      expect(changed.widthUnmapped).assertTrue();
      expect(changed.forceUnmapped).assertTrue();
      expect(changed.orientationUnmapped).assertTrue();
      expect(changed.styleUnmapped).assertTrue();
      expect(changed.degraded).assertTrue();
    });

    it('keeps imported line rectangle and rotated ellipse as semantic shapes in archive order', 0, () => {
      const session: NotabilitySession = semanticShapeSession();
      const pages = NotabilitySessionParser.toPageElements(session, 100);
      expect(pages.length).assertEqual(1);
      expect(pages[0].strokes.length).assertEqual(1);
      expect(pages[0].shapes.length).assertEqual(3);
      expect(pages[0].shapes[0].type).assertEqual(ElementType.LINE);
      expect(pages[0].shapes[1].type).assertEqual(ElementType.POLYGON);
      expect(pages[0].shapes[2].type).assertEqual(ElementType.ELLIPSE);
      expect(pages[0].elementOrder[0].kind).assertEqual(PageElementKind.SHAPE);
      expect(pages[0].elementOrder[1].kind).assertEqual(PageElementKind.STROKE);
      expect(pages[0].elementOrder[2].kind).assertEqual(PageElementKind.SHAPE);
      const ellipse = pages[0].shapes[2];
      if (ellipse.type === ElementType.ELLIPSE) {
        expect(Math.abs(ellipse.rotationRadians - Math.PI / 4) < 0.000001).assertTrue();
        expect(Math.abs(ellipse.radiusX - 20) < 0.000001).assertTrue();
        expect(Math.abs(ellipse.radiusY - 10) < 0.000001).assertTrue();
      }
    });
  });
}

function semanticShapeSession(): NotabilitySession {
  const inventory: NotabilityContentInventory = createNotabilityContentInventory();
  return {
    ok: true, error: '', noteName: 'semantic shapes', creationMillis: 0,
    sessionFormatVersion: 9, bundleVersion: '', handwritingLanguage: '',
    paper: { paperSize: 'letter', paperOrientation: 'portrait', paperIdentifier: '',
      lineStyle: '', sizingBehavior: '', layoutDevice: '' },
    pageWidthDoc: 100, pageHeightDoc: 150, pageCount: 1,
    curves: [{
      index: 0, uuid: 'curve', colorArgb: -16777216, width: 2, style: 3, options: 0,
      points: [{ x: 0, y: 0 }, { x: 3, y: 0 }, { x: 7, y: 0 }, { x: 10, y: 0 }],
      fractionalWidths: [1, 1], forces: [1, 1], altitudeAngles: [Math.PI / 2, Math.PI / 2],
      azimuthX: [1, 1], azimuthY: [0, 0], bounds: { left: 0, top: 0, right: 10, bottom: 0 },
      pageIndex: 0,
    }],
    shapes: [
      { index: 0, uuid: 'line', kind: 'line', zIndex: 0, colorArgb: -16777216, width: 2,
        style: 3, options: 0, anchors: [{ x: 0, y: 10 }, { x: 10, y: 10 }], cubics: [],
        isClosed: false, bounds: { left: 0, top: 10, right: 10, bottom: 10 }, pageIndex: 0 },
      { index: 1, uuid: 'rectangle', kind: 'rectangle', zIndex: 1, colorArgb: -16777216, width: 2,
        style: 3, options: 0, anchors: [{ x: 0, y: 20 }, { x: 10, y: 20 }, { x: 10, y: 30 },
          { x: 0, y: 30 }, { x: 0, y: 20 }], cubics: [], isClosed: true,
        bounds: { left: 0, top: 20, right: 10, bottom: 30 }, pageIndex: 0 },
      rotatedEllipseShape(),
    ],
    totalPoints: 4, inventory: inventory, warnings: [], missingAssets: [], unparsed: [], structureLog: '',
  };
}

function rotatedEllipseShape() {
  const c: number = Math.sqrt(0.5);
  const center = { x: 50, y: 50 };
  const u = { x: 20 * c, y: 20 * c };
  const v = { x: -10 * c, y: 10 * c };
  return {
    index: 2, uuid: 'ellipse', kind: 'circle', zIndex: 1, colorArgb: -16777216, width: 2,
    style: 3, options: 0,
    anchors: [
      { x: center.x + u.x, y: center.y + u.y },
      { x: center.x + v.x, y: center.y + v.y },
      { x: center.x - u.x, y: center.y - u.y },
      { x: center.x - v.x, y: center.y - v.y },
      { x: center.x + u.x, y: center.y + u.y },
    ],
    cubics: [], isClosed: true,
    bounds: { left: 30, top: 30, right: 70, bottom: 70 }, pageIndex: 0,
  };
}
