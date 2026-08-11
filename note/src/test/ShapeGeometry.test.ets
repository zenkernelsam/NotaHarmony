import { describe, it, expect } from '@ohos/hypium';
import { ShapeDetector } from '../main/ets/core/algorithm/ShapeDetector';
import { ElementType, EllipseElement, LineElement, PolygonElement,
  ShapeArrowHead, ShapeElement } from '../main/ets/core/model/ElementTypes';
import { Point2D, TransformMatrix } from '../main/ets/core/model/GeometryTypes';
import {
  cloneShapeElement, eraserPathHitsShape, lineRenderGeometry, LineRenderGeometry,
  transformShapeElements,
} from '../main/ets/core/model/ShapeGeometry';

function ellipse(id: string = 'ellipse'): EllipseElement {
  return {
    id: id, type: ElementType.ELLIPSE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 30, bottom: 40 },
    center: { x: 20, y: 30 }, radiusX: 10, radiusY: 10, rotationRadians: 0,
    color: 0xFF102030, strokeWidth: 2, fillColor: null,
  };
}

function polygon(id: string = 'polygon'): PolygonElement {
  return {
    id: id, type: ElementType.POLYGON,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 10, bottom: 10 },
    vertices: [{ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 5, y: 10 }],
    isClosed: true, color: 0xFF405060, strokeWidth: 2, fillColor: 0x33445566,
  };
}

function curvedArrow(id: string = 'arrow'): LineElement {
  return {
    id: id, type: ElementType.LINE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 120, bottom: 80 },
    start: { x: 0, y: 80 }, controlPoint1: { x: 40, y: 0 },
    controlPoint2: { x: 80, y: 0 }, end: { x: 120, y: 80 },
    arrowHead: ShapeArrowHead.SINGLE,
    color: 0xFF112233, strokeWidth: 4, fillColor: null,
  };
}

function straightArrow(): LineElement {
  const result: LineElement = curvedArrow('straight-arrow');
  result.start = { x: 0, y: 0 };
  result.controlPoint1 = null;
  result.controlPoint2 = null;
  result.end = { x: 120, y: 0 };
  return result;
}

export default function shapeGeometryTest() {
  describe('ShapeGeometry', () => {
    it('deep-clones ellipse and polygon owned geometry', 0, () => {
      const sourceEllipse: EllipseElement = ellipse();
      const ellipseCopy: ShapeElement = cloneShapeElement(sourceEllipse);
      sourceEllipse.center.x = 999;
      sourceEllipse.transform[2] = 999;
      sourceEllipse.bounds.left = 999;
      expect((ellipseCopy as EllipseElement).center.x).assertEqual(20);
      expect(ellipseCopy.transform[2]).assertEqual(0);
      expect(ellipseCopy.bounds.left).assertEqual(10);

      const sourcePolygon: PolygonElement = polygon();
      const polygonCopy: ShapeElement = cloneShapeElement(sourcePolygon);
      sourcePolygon.vertices[0].x = 999;
      expect((polygonCopy as PolygonElement).vertices[0].x).assertEqual(0);
      expect((polygonCopy as PolygonElement).fillColor).assertEqual(0x33445566);
    });

    it('deep-clones the original curved LINE definition', 0, () => {
      const source: LineElement = curvedArrow();
      const copy: LineElement = cloneShapeElement(source) as LineElement;
      source.controlPoint1!.x = 999;
      expect(copy.type).assertEqual(ElementType.LINE);
      expect(copy.controlPoint1!.x).assertEqual(40);
      expect(copy.arrowHead).assertEqual(ShapeArrowHead.SINGLE);
    });

    it('includes curved line and arrow geometry in transformed bounds', 0, () => {
      const translation: TransformMatrix = [1, 0, 25, 0, 1, 10, 0, 0, 1];
      const transformed: LineElement = transformShapeElements(
        [curvedArrow()], ['arrow'], translation)[0] as LineElement;
      expect(transformed.bounds.left >= 25).assertTrue();
      expect(transformed.bounds.right > 140).assertTrue();
      expect(transformed.bounds.bottom >= 90).assertTrue();
    });

    it('uses the original border-width arrow dimensions and trims the main path', 0, () => {
      const geometry: LineRenderGeometry = lineRenderGeometry(straightArrow());
      const scale: number = 4 / 7;
      const baseX: number = 120 - 46 * scale;
      const mainEnd: Point2D = geometry.mainPath[geometry.mainPath.length - 1];
      expect(Math.abs(mainEnd.x - baseX) < 0.001).assertTrue();
      expect(Math.abs(geometry.arrowHeadPath[0].x - baseX) < 0.001).assertTrue();
      expect(Math.abs(geometry.arrowHeadPath[0].y - 20 * scale) < 0.001).assertTrue();
      expect(geometry.arrowHeadPath[1].x).assertEqual(120);
      expect(Math.abs(geometry.arrowHeadPath[2].y + 20 * scale) < 0.001).assertTrue();
    });

    it('does not create an eraser-hit bridge between arrow subpaths', 0, () => {
      const arrow: LineElement = straightArrow();
      const baseX: number = 120 - 46 * 4 / 7;
      expect(eraserPathHitsShape([{ x: baseX, y: 20 / 7 * 2 }], arrow, 1)).assertFalse();
    });

    it('keeps semantic shape data while transforming matrix and bounds', 0, () => {
      const unselected: PolygonElement = polygon();
      const result: ShapeElement[] = transformShapeElements(
        [ellipse(), unselected], ['ellipse'], [2, 0, 5, 0, 3, 7, 0, 0, 1]);
      const transformed: EllipseElement = result[0] as EllipseElement;
      expect(transformed.type).assertEqual(ElementType.ELLIPSE);
      expect(transformed.radiusX).assertEqual(10);
      expect(transformed.transform[0]).assertEqual(2);
      expect(transformed.transform[4]).assertEqual(3);
      expect(transformed.bounds.left).assertEqual(25);
      expect(transformed.bounds.top).assertEqual(67);
      expect(transformed.bounds.right).assertEqual(65);
      expect(transformed.bounds.bottom).assertEqual(127);
      expect(result[1] === unselected).assertTrue();
      expect(result[1].id).assertEqual('polygon');
    });

    it('keeps position-locked Shapes immovable and whole-eraser safe', 0, () => {
      const locked: EllipseElement = ellipse('locked');
      locked.positionLocked = true;
      const transformed: ShapeElement = transformShapeElements(
        [locked], ['locked'], [1, 0, 50, 0, 1, 60, 0, 0, 1])[0];
      expect(transformed === locked).assertTrue();
      expect(transformed.transform[2]).assertEqual(0);
      expect(eraserPathHitsShape([{ x: 20, y: 30 }], locked, 20)).assertFalse();
    });

    it('recomputes bounds from semantic geometry across repeated rotations', 0, () => {
      const angle: number = Math.PI / 4;
      const rotation: TransformMatrix = [Math.cos(angle), -Math.sin(angle), 0,
        Math.sin(angle), Math.cos(angle), 0, 0, 0, 1];
      const first: ShapeElement = transformShapeElements([polygon()], ['polygon'], rotation)[0];
      const second: ShapeElement = transformShapeElements([first], ['polygon'], rotation)[0];
      expect(Math.round(second.bounds.left)).assertEqual(-10);
      expect(Math.round(second.bounds.top)).assertEqual(0);
      expect(Math.round(second.bounds.right)).assertEqual(0);
      expect(Math.round(second.bounds.bottom)).assertEqual(10);
    });

    it('uses transformed outline distance for eraser hits without inflating identity width', 0, () => {
      const line: PolygonElement = polygon('line');
      line.vertices = [{ x: 0, y: 0 }, { x: 10, y: 0 }];
      line.isClosed = false;
      line.bounds = { left: 0, top: 0, right: 10, bottom: 0 };
      expect(eraserPathHitsShape([{ x: 5, y: 1.9 }], line, 2)).assertTrue();
      expect(eraserPathHitsShape([{ x: 5, y: 2.1 }], line, 2)).assertFalse();
      line.transform = [2, 0, 10, 0, 2, 20, 0, 0, 1];
      expect(eraserPathHitsShape([{ x: 20, y: 22.9 }], line, 2)).assertTrue();
      expect(eraserPathHitsShape([{ x: 20, y: 23.1 }], line, 2)).assertFalse();
    });

    it('hits filled shape interiors but leaves unfilled interiors untouched', 0, () => {
      const filled: PolygonElement = polygon('filled');
      expect(eraserPathHitsShape([{ x: 5, y: 4 }], filled, 1)).assertTrue();
      filled.fillColor = null;
      expect(eraserPathHitsShape([{ x: 5, y: 4 }], filled, 1)).assertFalse();
    });

    it('preserves the drawn ellipse radius instead of shrinking by sqrt two', 0, () => {
      const points: Point2D[] = [];
      for (let i: number = 0; i < 64; i++) {
        const angle: number = i / 64 * Math.PI * 2;
        points.push({ x: 100 + Math.cos(angle) * 40, y: 80 + Math.sin(angle) * 20 });
      }
      const detected = new ShapeDetector().recognizeShape(points);
      expect(detected !== null).assertTrue();
      const detectedEllipse: EllipseElement = detected!.elements[0] as EllipseElement;
      expect(detectedEllipse.type).assertEqual(ElementType.ELLIPSE);
      expect(Math.round(detectedEllipse.radiusX)).assertEqual(40);
      expect(Math.round(detectedEllipse.radiusY)).assertEqual(20);
      expect(Math.round(detectedEllipse.bounds.right - detectedEllipse.bounds.left)).assertEqual(80);
      expect(Math.round(detectedEllipse.bounds.bottom - detectedEllipse.bounds.top)).assertEqual(40);
    });
  });
}
