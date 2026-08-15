import { describe, expect, it } from '@ohos/hypium';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead,
} from '../main/ets/core/model/ElementTypes';
import { InkPathCommand, InkPathCommandType, StrokeElementData } from
  '../main/ets/core/model/StrokeTypes';
import {
  OriginalShapePartialEraser, ShapePartialEraseReplacement,
} from '../main/ets/rendering/OriginalShapePartialEraser';

function filledRectangle(id: string = 'op:20:2'): PolygonElement {
  return {
    id: id, type: ElementType.POLYGON,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 20, bottom: 20 },
    vertices: [
      { x: 0, y: 0 }, { x: 20, y: 0 },
      { x: 20, y: 20 }, { x: 0, y: 20 },
    ],
    isClosed: true, color: 0xFF102030, strokeWidth: 2,
    fillColor: 0x6B405060, originalTool: 0, originalStyle: 1,
    originalCreate: {
      timestamp: 32, siteId: 2, clientTime: 1000,
      pageTimestamp: 16, pageSiteId: 2, pageIndex: 0,
      pencilSeed: 1234, averageForce: 0.75,
    },
  };
}

function lineShape(id: string = 'op:22:2'): LineElement {
  return {
    id: id, type: ElementType.LINE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: -10, right: 100, bottom: 20 },
    start: { x: 0, y: 0 }, controlPoint1: null, controlPoint2: null,
    end: { x: 100, y: 0 }, arrowHead: ShapeArrowHead.NONE,
    color: 0xFF102030, strokeWidth: 2, fillColor: null,
    originalTool: 0, originalStyle: 1,
  };
}

function maximumCenterX(remnants: StrokeElementData[]): number {
  let maximum: number = -Number.MAX_VALUE;
  for (const remnant of remnants) {
    for (const point of remnant.pathPoints) {
      maximum = Math.max(maximum, point.position.x);
    }
  }
  return maximum;
}

function minimumCenterX(remnants: StrokeElementData[]): number {
  let minimum: number = Number.MAX_VALUE;
  for (const remnant of remnants) {
    for (const point of remnant.pathPoints) {
      minimum = Math.min(minimum, point.position.x);
    }
  }
  return minimum;
}

export default function originalShapePartialEraserTest() {
  describe('OriginalShapePartialEraser', () => {
    it('turns a split filled Shape into Ink remnants with explicit outline and fill paths', 0, () => {
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(4).erase(
          [{ x: 10, y: -5 }, { x: 10, y: 25 }], [filledRectangle()]);
      expect(replacements.length).assertEqual(1);
      expect(replacements[0].sourceShape.id).assertEqual('op:20:2');
      expect(replacements[0].remnants.length >= 2).assertTrue();
      for (const remnant of replacements[0].remnants) {
        expect(remnant.customPath !== null && remnant.customPath !== undefined).assertTrue();
        expect(remnant.fillPath !== null && remnant.fillPath !== undefined).assertTrue();
        expect(remnant.fillColor).assertEqual(0x6B405060);
        expect(remnant.renderSpec.isPencil).assertFalse();
      }
    });

    it('keeps locked or untouched Shapes out of the replacement plan', 0, () => {
      const locked: PolygonElement = filledRectangle('op:21:2');
      locked.positionLocked = true;
      expect(new OriginalShapePartialEraser(4).erase(
        [{ x: 10, y: -5 }, { x: 10, y: 25 }], [locked]).length).assertEqual(0);
      expect(new OriginalShapePartialEraser(4).erase(
        [{ x: 100, y: 100 }], [filledRectangle()]).length).assertEqual(0);
    });

    it('preserves native quadratic center segments after clipping a curved Line', 0, () => {
      const line: LineElement = lineShape('op:22:2');
      line.end = { x: 20, y: 0 };
      line.controlPoint1 = { x: 10, y: 20 };
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(2).erase(
          [{ x: 10, y: -5 }, { x: 10, y: 15 }], [line]);
      expect(replacements.length).assertEqual(1);
      let hasCurvedCubic: boolean = false;
      for (const remnant of replacements[0].remnants) {
        for (const segment of remnant.cubicSegments) {
          const dx: number = segment.p3.x - segment.p0.x;
          const dy: number = segment.p3.y - segment.p0.y;
          const cross1: number = dx * (segment.p1.y - segment.p0.y) -
            dy * (segment.p1.x - segment.p0.x);
          const cross2: number = dx * (segment.p2.y - segment.p0.y) -
            dy * (segment.p2.x - segment.p0.x);
          hasCurvedCubic = hasCurvedCubic || Math.abs(cross1) > 0.0001 ||
            Math.abs(cross2) > 0.0001;
        }
      }
      expect(hasCurvedCubic).assertTrue();
    });

    it('uses the native oval instead of a sampled polygon for Ellipse clipping', 0, () => {
      const ellipse: EllipseElement = {
        id: 'op:23:2', type: ElementType.ELLIPSE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 5, right: 20, bottom: 15 },
        center: { x: 10, y: 10 }, radiusX: 10, radiusY: 5,
        rotationRadians: 0, color: 0xFF102030, strokeWidth: 2,
        fillColor: null, originalTool: 0, originalStyle: 1,
      };
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(2).erase(
          [{ x: 10, y: 0 }, { x: 10, y: 20 }], [ellipse]);
      expect(replacements.length).assertEqual(1);
      let hasDrawableCommand: boolean = false;
      let hasInvalidCoordinate: boolean = false;
      for (const remnant of replacements[0].remnants) {
        const commands: InkPathCommand[] = remnant.customPath ?? [];
        for (const command of commands) {
          hasDrawableCommand = hasDrawableCommand || command.type !== InkPathCommandType.MOVE_TO;
          for (const point of command.points) {
            hasInvalidCoordinate = hasInvalidCoordinate ||
              !Number.isFinite(point.x) || !Number.isFinite(point.y);
          }
        }
      }
      expect(hasDrawableCommand).assertTrue();
      expect(hasInvalidCoordinate).assertFalse();
    });

    it('applies the original Ellipse rotation around its local center', 0, () => {
      const ellipse: EllipseElement = {
        id: 'op:27:2', type: ElementType.ELLIPSE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 7, top: 0, right: 13, bottom: 20 },
        center: { x: 10, y: 10 }, radiusX: 10, radiusY: 3,
        rotationRadians: Math.PI / 2, color: 0xFF102030, strokeWidth: 2,
        fillColor: null, originalTool: 0, originalStyle: 1,
      };
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(2).erase([{ x: 10, y: 19 }], [ellipse]);
      expect(replacements.length).assertEqual(1);
    });

    it('closes a Polygon like original xai even when a legacy flag says open', 0, () => {
      const polygon: PolygonElement = filledRectangle('op:26:2');
      polygon.vertices = [{ x: 0, y: 0 }, { x: 20, y: 0 }, { x: 20, y: 20 }];
      polygon.isClosed = false;
      polygon.fillColor = null;
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(2).erase([{ x: 10, y: 10 }], [polygon]);
      expect(replacements.length).assertEqual(1);
    });

    it('keeps the full Line center path when only the native arrowhead is clipped', 0, () => {
      const line: LineElement = lineShape('op:24:2');
      line.arrowHead = ShapeArrowHead.SINGLE;
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(1).erase([{ x: 90, y: 4.4 }], [line]);
      expect(replacements.length).assertEqual(1);
      expect(maximumCenterX(replacements[0].remnants) > 99.999).assertTrue();
    });

    it('does not expand center clipping by half the Shape border width', 0, () => {
      const line: LineElement = lineShape('op:25:2');
      line.strokeWidth = 10;
      const replacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(2).erase([{ x: 50, y: 5.5 }], [line]);
      expect(replacements.length).assertEqual(1);
      expect(minimumCenterX(replacements[0].remnants) < 0.001).assertTrue();
      expect(maximumCenterX(replacements[0].remnants) > 99.999).assertTrue();
    });
  });
}
