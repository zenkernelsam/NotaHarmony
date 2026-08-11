import { describe, it, expect } from '@ohos/hypium';
import { ShapeDetector } from '../main/ets/core/algorithm/ShapeDetector';
import { ElementType, EllipseElement, LineElement, OriginalShapeCreateMetadata, ShapeElement,
  PolygonElement, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { Point2D } from '../main/ets/core/model/GeometryTypes';
import { RecognitionResult } from '../main/ets/core/adaptation/RecognitionProvider';
import { prepareRecognizedShapes } from '../main/ets/core/model/ShapeRecognition';

function ellipsePoints(cx: number, cy: number, rx: number, ry: number,
  rotation: number, count: number = 120): Point2D[] {
  const result: Point2D[] = [];
  const cosRotation: number = Math.cos(rotation);
  const sinRotation: number = Math.sin(rotation);
  for (let i: number = 0; i <= count; i++) {
    const angle: number = i / count * Math.PI * 2;
    const localX: number = Math.cos(angle) * rx;
    const localY: number = Math.sin(angle) * ry;
    result.push({
      x: cx + localX * cosRotation - localY * sinRotation,
      y: cy + localX * sinRotation + localY * cosRotation,
    });
  }
  return result;
}

function close(actual: number, expected: number, tolerance: number = 0.001): boolean {
  return Math.abs(actual - expected) < tolerance;
}

function ellipseAngleDifference(actual: number, expected: number): number {
  let difference: number = actual - expected;
  while (difference >= Math.PI / 2) {
    difference -= Math.PI;
  }
  while (difference < -Math.PI / 2) {
    difference += Math.PI;
  }
  return Math.abs(difference);
}

export default function shapeDetectorTest() {
  describe('ShapeDetector', () => {
    it('fits the principal axis radii and bounds of a rotated ellipse', 0, () => {
      const detector: ShapeDetector = new ShapeDetector();
      const expectedRotation: number = Math.PI / 6;
      const result: RecognitionResult | null = detector.recognizeShape(
        ellipsePoints(240, 180, 100, 40, expectedRotation));
      expect(result !== null).assertTrue();
      expect(result?.elements[0].type).assertEqual(ElementType.ELLIPSE);
      const ellipse: EllipseElement = result!.elements[0] as EllipseElement;
      expect(close(ellipse.center.x, 240)).assertTrue();
      expect(close(ellipse.center.y, 180)).assertTrue();
      expect(close(ellipse.radiusX, 100)).assertTrue();
      expect(close(ellipse.radiusY, 40)).assertTrue();
      expect(ellipseAngleDifference(ellipse.rotationRadians, expectedRotation) < 0.001).assertTrue();
      const halfWidth: number = Math.sqrt(10000 * 0.75 + 1600 * 0.25);
      const halfHeight: number = Math.sqrt(10000 * 0.25 + 1600 * 0.75);
      expect(close(ellipse.bounds.left, 240 - halfWidth)).assertTrue();
      expect(close(ellipse.bounds.bottom, 180 + halfHeight)).assertTrue();
    });

    it('stabilizes circle rotation while preserving the observed diameter', 0, () => {
      const detector: ShapeDetector = new ShapeDetector();
      const result: RecognitionResult | null = detector.recognizeShape(
        ellipsePoints(100, 120, 50, 50, Math.PI / 3));
      expect(result?.elements[0].type).assertEqual(ElementType.ELLIPSE);
      const circle: EllipseElement = result!.elements[0] as EllipseElement;
      expect(circle.rotationRadians).assertEqual(0);
      expect(close(circle.radiusX, 50)).assertTrue();
      expect(close(circle.radiusY, 50)).assertTrue();
      expect(close(circle.bounds.left, 50)).assertTrue();
      expect(close(circle.bounds.bottom, 170)).assertTrue();
    });

    it('keeps a recognized line as the original LINE definition', 0, () => {
      const detector: ShapeDetector = new ShapeDetector();
      const points: Point2D[] = [];
      for (let i: number = 0; i <= 20; i++) {
        points.push({ x: i * 10, y: 30 + i * 0.1 });
      }
      const result: RecognitionResult | null = detector.recognizeShape(points);
      expect(result?.elements[0].type).assertEqual(ElementType.LINE);
      const line: LineElement = result!.elements[0] as LineElement;
      expect(line.start.x).assertEqual(0);
      expect(line.end.x).assertEqual(200);
      expect(line.controlPoint1 === null).assertTrue();
    });

    it('represents an open polyline as ordered LINE definitions without a closing edge', 0, () => {
      const points: Point2D[] = [
        { x: 0, y: 0 }, { x: 50, y: 0 }, { x: 100, y: 0 },
        { x: 100, y: 50 }, { x: 100, y: 100 },
      ];
      const result: RecognitionResult | null = new ShapeDetector().recognizeShape(points);
      expect(result !== null).assertTrue();
      expect(result!.elements.length).assertEqual(2);
      const first: LineElement = result!.elements[0] as LineElement;
      const second: LineElement = result!.elements[1] as LineElement;
      expect(first.type).assertEqual(ElementType.LINE);
      expect(first.start.x).assertEqual(0);
      expect(first.end.x).assertEqual(100);
      expect(second.start.x).assertEqual(100);
      expect(second.end.y).assertEqual(100);
    });

    it('keeps a closed outline as one POLYGON definition', 0, () => {
      const points: Point2D[] = [
        { x: 0, y: 0 }, { x: 100, y: 0 }, { x: 50, y: 80 }, { x: 0, y: 0 },
      ];
      const result: RecognitionResult | null = new ShapeDetector().recognizeShape(points);
      expect(result?.elements.length).assertEqual(1);
      expect(result?.elements[0].type).assertEqual(ElementType.POLYGON);
      const polygon: PolygonElement = result!.elements[0] as PolygonElement;
      expect(polygon.vertices.length).assertEqual(3);
      expect(polygon.isClosed).assertTrue();
    });

    it('rejects degenerate near-zero ellipses', 0, () => {
      const detector: ShapeDetector = new ShapeDetector();
      const result: RecognitionResult | null = detector.recognizeShape(
        [{ x: 1, y: 1 }, { x: 2, y: 1 }, { x: 1, y: 2 }, { x: 1, y: 1 }]);
      expect(result === null).assertTrue();
    });

    it('keeps multi-element recognition results atomic and ordered', 0, () => {
      const detector: ShapeDetector = new ShapeDetector();
      const lineResult: RecognitionResult = detector.recognizeShape(
        [{ x: 0, y: 0 }, { x: 80, y: 0 }, { x: 160, y: 0 }])!;
      const ellipseResult: RecognitionResult = detector.recognizeShape(
        ellipsePoints(100, 100, 40, 20))!;
      const reserved: OriginalShapeCreateMetadata = { timestamp: 20, siteId: 2, clientTime: 1000,
        pageTimestamp: 10, pageSiteId: 1, pageIndex: 0, pencilSeed: 7,
        averageForce: 0.5 };
      const shapes: ShapeElement[] = prepareRecognizedShapes(
        [lineResult.elements[0], ellipseResult.elements[0]], 'stroke', 0xFF123456, 7,
        2, 1, reserved);
      expect(shapes.length).assertEqual(2);
      expect(shapes[0].id).assertEqual('stroke:shape:0');
      expect(shapes[1].id).assertEqual('stroke:shape:1');
      expect(shapes[0].color).assertEqual(0xFF123456);
      expect(shapes[1].strokeWidth).assertEqual(7);
      expect(shapes[0].originalCreate === undefined).assertTrue();

      const single: ShapeElement[] = prepareRecognizedShapes(
        [lineResult.elements[0]], 'op:14:2', 0xFF123456, 7, 2, 1, reserved);
      expect(single[0].id).assertEqual('op:14:2');
      expect(single[0].originalTool).assertEqual(2);
      expect(single[0].originalStyle).assertEqual(1);
      expect(single[0].originalCreate?.averageForce).assertEqual(0.5);
      const variableWidth: ShapeElement[] = prepareRecognizedShapes(
        [lineResult.elements[0]], 'op:14:2', 0xFF123456, 7, 0, 0, reserved);
      expect(variableWidth[0].originalCreate === undefined).assertTrue();
    });

    it('rejects the entire recognition result when one element is unsupported', 0, () => {
      const unsupported: TextBlockElement = {
        id: 'text', type: ElementType.TEXT,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 10, bottom: 10 },
        richText: 'x', textOrigin: { x: 0, y: 0 }, blockWidth: 10, blockHeight: 10,
        rotationRadians: 0, contentLeftInset: 0, contentTopInset: 0,
        fontSize: 12, fontColor: 0xFF000000,
      };
      const detector: ShapeDetector = new ShapeDetector();
      const line: RecognitionResult = detector.recognizeShape(
        [{ x: 0, y: 0 }, { x: 80, y: 0 }, { x: 160, y: 0 }])!;
      const shapes: ShapeElement[] = prepareRecognizedShapes(
        [line.elements[0], unsupported], 'stroke', 0xFF000000, 4);
      expect(shapes.length).assertEqual(0);
    });
  });
}
