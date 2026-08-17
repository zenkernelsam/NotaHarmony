import { describe, it, expect } from '@ohos/hypium';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead, ShapeElement,
} from '../main/ets/core/model/ElementTypes';
import { ShapeHoldAdjustmentSession } from '../main/ets/core/model/ShapeHoldAdjustment';
import { TapePattern } from '../main/ets/core/model/StrokeTypes';

function line(id: string, startX: number, endX: number): LineElement {
  return {
    id: id, type: ElementType.LINE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: startX, top: -4, right: endX, bottom: 4 },
    start: { x: startX, y: 0 }, controlPoint1: { x: (startX + endX) / 2, y: 2 },
    controlPoint2: null, end: { x: endX, y: 0 }, arrowHead: ShapeArrowHead.SINGLE,
    color: 0xFF123456, strokeWidth: 4, fillColor: null,
    originalTool: 1, originalStyle: 1, originalTapePattern: TapePattern.GRID,
    originalSmartHighlight: true, originalForce: 0.6, originalInkEffects: '3',
    originalInkEffectsTinted: false,
    originalCreate: { timestamp: 7, siteId: 8, clientTime: 9, pageTimestamp: 10,
      pageSiteId: 11, pageIndex: 2, pencilSeed: 12, averageForce: 0.6 },
  };
}

function ellipse(): EllipseElement {
  return {
    id: 'ellipse', type: ElementType.ELLIPSE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 80, top: 90, right: 120, bottom: 110 },
    center: { x: 100, y: 100 }, radiusX: 20, radiusY: 10,
    rotationRadians: 0.4, color: 0xFF000000, strokeWidth: 3, fillColor: null,
    originalTool: 0, originalStyle: 1, originalSmartHighlight: true,
  };
}

function polygon(): PolygonElement {
  return {
    id: 'polygon', type: ElementType.POLYGON,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 6, bottom: 6 },
    vertices: [{ x: 0, y: 0 }, { x: 6, y: 0 }, { x: 0, y: 6 }],
    isClosed: true, color: 0xFF000000, strokeWidth: 2, fillColor: null,
  };
}

function close(actual: number, expected: number): boolean {
  return Math.abs(actual - expected) < 0.001;
}

export default function shapeHoldAdjustmentTest() {
  describe('ShapeHoldAdjustment', () => {
    it('moves a single LINE end from a stable first point and similarity-transforms controls', 0, () => {
      const session: ShapeHoldAdjustmentSession = new ShapeHoldAdjustmentSession();
      expect(session.begin([line('line', 0, 10)])).assertTrue();
      const initial: ShapeElement[] | null = session.update({ x: 20, y: 0 });
      expect(initial !== null).assertTrue();
      const unchanged: LineElement = initial![0] as LineElement;
      expect(unchanged.end.x).assertEqual(10);
      expect(unchanged.end.y).assertEqual(0);

      const adjusted: ShapeElement[] | null = session.update({ x: 20, y: 10 });
      expect(adjusted !== null).assertTrue();
      const result: LineElement = adjusted![0] as LineElement;
      expect(result.end.x).assertEqual(10);
      expect(result.end.y).assertEqual(10);
      expect(close(result.controlPoint1!.x, 3)).assertTrue();
      expect(close(result.controlPoint1!.y, 7)).assertTrue();
      expect(result.id).assertEqual('line');
      expect(result.arrowHead).assertEqual(ShapeArrowHead.SINGLE);
      expect(result.originalTapePattern).assertEqual(TapePattern.GRID);
      expect(result.originalInkEffects).assertEqual('3');
      expect(result.originalInkEffectsTinted).assertFalse();
      expect(result.originalCreate?.timestamp).assertEqual(7);
      expect(result.originalCreate?.averageForce).assertEqual(0.6);
    });

    it('applies the original 5 px gate then uniformly scales an ELLIPSE without losing rotation', 0, () => {
      const session: ShapeHoldAdjustmentSession = new ShapeHoldAdjustmentSession();
      expect(session.begin([ellipse()])).assertTrue();
      expect(session.update({ x: 103, y: 100 }) === null).assertTrue();
      const initial: ShapeElement[] | null = session.update({ x: 110, y: 100 });
      expect(initial !== null).assertTrue();
      const adjusted: ShapeElement[] | null = session.update({ x: 120, y: 100 });
      expect(adjusted !== null).assertTrue();
      const result: EllipseElement = adjusted![0] as EllipseElement;
      expect(result.center.x).assertEqual(100);
      expect(result.center.y).assertEqual(100);
      expect(result.radiusX).assertEqual(40);
      expect(result.radiusY).assertEqual(20);
      expect(result.rotationRadians).assertEqual(0.4);
      expect(result.originalSmartHighlight).assertTrue();
    });

    it('scales polygon vertices around their average anchor without cumulative drift', 0, () => {
      const session: ShapeHoldAdjustmentSession = new ShapeHoldAdjustmentSession();
      expect(session.begin([polygon()])).assertTrue();
      const initial: ShapeElement[] | null = session.update({ x: 12, y: 2 });
      expect(initial !== null).assertTrue();
      session.update({ x: 17, y: 2 });
      const adjusted: ShapeElement[] | null = session.update({ x: 22, y: 2 });
      expect(adjusted !== null).assertTrue();
      const result: PolygonElement = adjusted![0] as PolygonElement;
      expect(result.vertices[0].x).assertEqual(-2);
      expect(result.vertices[0].y).assertEqual(-2);
      expect(result.vertices[1].x).assertEqual(10);
      expect(result.vertices[1].y).assertEqual(-2);
      expect(result.vertices[2].x).assertEqual(-2);
      expect(result.vertices[2].y).assertEqual(10);
    });

    it('keeps a multi-definition result together around one aggregate anchor', 0, () => {
      const session: ShapeHoldAdjustmentSession = new ShapeHoldAdjustmentSession();
      expect(session.begin([line('left', -10, 0), line('right', 0, 10)])).assertTrue();
      session.update({ x: 10, y: 0 });
      const adjusted: ShapeElement[] | null = session.update({ x: 20, y: 0 });
      expect(adjusted?.length).assertEqual(2);
      const left: LineElement = adjusted![0] as LineElement;
      const right: LineElement = adjusted![1] as LineElement;
      expect(left.id).assertEqual('left');
      expect(left.start.x).assertEqual(-20);
      expect(left.end.x).assertEqual(0);
      expect(right.id).assertEqual('right');
      expect(right.start.x).assertEqual(0);
      expect(right.end.x).assertEqual(20);
    });

    it('rejects malformed geometry and reset prevents stale adjustment', 0, () => {
      const invalid: EllipseElement = ellipse();
      invalid.radiusX = Number.NaN;
      const session: ShapeHoldAdjustmentSession = new ShapeHoldAdjustmentSession();
      expect(session.begin([invalid])).assertFalse();
      expect(session.isActive()).assertFalse();
      expect(session.update({ x: 10, y: 10 }) === null).assertTrue();
      expect(session.begin([polygon()])).assertTrue();
      session.reset();
      expect(session.isActive()).assertFalse();
      expect(session.update({ x: 20, y: 2 }) === null).assertTrue();
    });
  });
}
