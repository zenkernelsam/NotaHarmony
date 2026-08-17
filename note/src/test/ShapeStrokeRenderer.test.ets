import { describe, it, expect } from '@ohos/hypium';
import {
  Canvas2DOffscreenRenderContext,
} from '../main/ets/core/adaptation/Canvas2DStrokeRenderer';
import { RenderContext, StrokeRenderer } from '../main/ets/core/adaptation/StrokeRenderer';
import {
  ORIGINAL_PENCIL_FALLBACK_SEED, PencilSplatGenerator,
} from '../main/ets/core/algorithm/PencilSplatGenerator';
import {
  ElementType, EllipseElement, LineElement, PolygonElement, ShapeArrowHead,
} from '../main/ets/core/model/ElementTypes';
import { lineRenderGeometry, LineRenderGeometry } from '../main/ets/core/model/ShapeGeometry';
import {
  ShapeStrokeGeometry, shapeStrokeGeometry,
} from '../main/ets/core/model/ShapeStrokeGeometry';
import {
  InkPathCommandType, PencilSplatPoint, RenderSpec, StrokeElementData, TapePattern,
} from '../main/ets/core/model/StrokeTypes';
import { ShapeCanvasRenderer } from '../main/ets/rendering/ShapeCanvasRenderer';

class RecordingStrokeRenderer implements StrokeRenderer {
  pencilCalls: PencilSplatPoint[][] = [];
  pencilSpecs: RenderSpec[] = [];
  tapeCalls: StrokeElementData[] = [];

  renderInkFill(_stroke: StrokeElementData, _ctx: RenderContext): void {
  }

  renderCustomPath(_stroke: StrokeElementData, _ctx: RenderContext): boolean {
    return false;
  }

  renderCenterPath(_stroke: StrokeElementData, _ctx: RenderContext): void {
  }

  renderVariableWidthOutline(_stroke: StrokeElementData, _ctx: RenderContext): void {
  }

  renderTapePattern(stroke: StrokeElementData, _ctx: RenderContext, _viewportZoom: number): void {
    this.tapeCalls.push(stroke);
  }

  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, _ctx: RenderContext): void {
    this.pencilCalls.push(splats);
    this.pencilSpecs.push(spec);
  }

  renderPartialEraser(_stroke: StrokeElementData, _ctx: RenderContext): void {
  }

  renderEraserMask(_stroke: StrokeElementData, _ctx: RenderContext): void {
  }
}

function canvasContext(): Canvas2DOffscreenRenderContext {
  const canvas: OffscreenCanvas = new OffscreenCanvas(240, 160);
  const context: OffscreenCanvasRenderingContext2D =
    canvas.getContext('2d', new RenderingContextSettings(true));
  return new Canvas2DOffscreenRenderContext(context);
}

function pencilArrow(id: string = 'pencil-arrow'): LineElement {
  return {
    id: id, type: ElementType.LINE,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: -10, top: -20, right: 130, bottom: 20 },
    start: { x: 0, y: 0 }, controlPoint1: null, controlPoint2: null,
    end: { x: 120, y: 0 }, arrowHead: ShapeArrowHead.SINGLE,
    color: 0xFF123456, strokeWidth: 4, fillColor: null,
    originalTool: 1, originalStyle: 1, originalForce: 0.6,
  };
}

function assertSplatEqual(actual: PencilSplatPoint, expected: PencilSplatPoint): void {
  expect(Math.abs(actual.x - expected.x) < 0.000001).assertTrue();
  expect(Math.abs(actual.y - expected.y) < 0.000001).assertTrue();
  expect(Math.abs(actual.rotation - expected.rotation) < 0.000001).assertTrue();
  expect(Math.abs(actual.scale - expected.scale) < 0.000001).assertTrue();
  expect(Math.abs(actual.opacity - expected.opacity) < 0.000001).assertTrue();
}

export default function shapeStrokeRendererTest() {
  describe('ShapeStrokeRenderer', () => {
    it('preserves native LINE cubics and uses four rotated Ellipse cubics', 0, () => {
      const line: LineElement = pencilArrow('cubic');
      line.arrowHead = ShapeArrowHead.NONE;
      line.controlPoint1 = { x: 20, y: 50 };
      line.controlPoint2 = { x: 80, y: -30 };
      const lineGeometry: ShapeStrokeGeometry = shapeStrokeGeometry(line);
      expect(lineGeometry.components.length).assertEqual(1);
      expect(lineGeometry.components[0].cubicSegments.length).assertEqual(1);
      expect(lineGeometry.components[0].cubicSegments[0].p1.x).assertEqual(20);
      expect(lineGeometry.components[0].cubicSegments[0].p2.y).assertEqual(-30);
      expect(lineGeometry.components[0].pathCommands[1].type)
        .assertEqual(InkPathCommandType.CUBIC);

      line.arrowHead = ShapeArrowHead.SINGLE;
      const arrowGeometry: ShapeStrokeGeometry = shapeStrokeGeometry(line);
      const sampledArrow: LineRenderGeometry = lineRenderGeometry(line);
      expect(arrowGeometry.components.length).assertEqual(2);
      expect(arrowGeometry.components[0].pathCommands[1].type)
        .assertEqual(InkPathCommandType.CUBIC);
      expect(arrowGeometry.components[0].cubicSegments.length).assertEqual(1);
      const trimmedEnd = arrowGeometry.components[0].cubicSegments[0].p3;
      const sampledEnd = sampledArrow.mainPath[sampledArrow.mainPath.length - 1];
      expect(Math.abs(trimmedEnd.x - sampledEnd.x) < 0.000001).assertTrue();
      expect(Math.abs(trimmedEnd.y - sampledEnd.y) < 0.000001).assertTrue();
      expect(trimmedEnd.x < line.end.x).assertTrue();

      const ellipse: EllipseElement = {
        id: 'ellipse', type: ElementType.ELLIPSE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 80, bottom: 40 },
        center: { x: 40, y: 20 }, radiusX: 40, radiusY: 20,
        rotationRadians: Math.PI / 4, color: 0xFF000000,
        strokeWidth: 3, fillColor: null, originalForce: 0.25,
      };
      const ellipseGeometry: ShapeStrokeGeometry = shapeStrokeGeometry(ellipse);
      expect(ellipseGeometry.force).assertEqual(0.25);
      expect(ellipseGeometry.components[0].cubicSegments.length).assertEqual(4);
      expect(ellipseGeometry.components[0].pathPoints.length).assertEqual(5);
      expect(ellipseGeometry.components[0].closed).assertTrue();
      const first = ellipseGeometry.components[0].pathPoints[0].position;
      const last = ellipseGeometry.components[0].pathPoints[4].position;
      expect(Math.abs(first.x - last.x) < 0.000001).assertTrue();
      expect(Math.abs(first.y - last.y) < 0.000001).assertTrue();
    });

    it('uses stored force, resets the fixed Pencil seed for the arrow, and reuses cache', 0, () => {
      const shape: LineElement = pencilArrow();
      const recorder: RecordingStrokeRenderer = new RecordingStrokeRenderer();
      const renderer: ShapeCanvasRenderer = new ShapeCanvasRenderer(recorder);
      renderer.renderShape(shape, canvasContext());
      expect(recorder.pencilCalls.length).assertEqual(2);
      expect(recorder.pencilSpecs[0].isPencil).assertTrue();

      const geometry: ShapeStrokeGeometry = shapeStrokeGeometry(shape);
      for (let index: number = 0; index < geometry.components.length; index++) {
        const generator: PencilSplatGenerator = new PencilSplatGenerator({ spacing: 4 });
        generator.reset(ORIGINAL_PENCIL_FALLBACK_SEED);
        const expected: PencilSplatPoint[] = generator.generate(
          geometry.components[index].cubicSegments, geometry.components[index].pathPoints);
        expect(recorder.pencilCalls[index].length).assertEqual(expected.length);
        expect(expected.length > 0).assertTrue();
        assertSplatEqual(recorder.pencilCalls[index][0], expected[0]);
      }

      const firstMain: PencilSplatPoint[] = recorder.pencilCalls[0];
      const firstArrow: PencilSplatPoint[] = recorder.pencilCalls[1];
      renderer.renderShape(shape, canvasContext());
      expect(recorder.pencilCalls[2] === firstMain).assertTrue();
      expect(recorder.pencilCalls[3] === firstArrow).assertTrue();
    });

    it('renders Highlighter Shape pixels with the original alpha override', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(240, 160);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const shape: LineElement = {
        id: 'highlighter-shape', type: ElementType.LINE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 10, top: 60, right: 230, bottom: 100 },
        start: { x: 20, y: 80 }, controlPoint1: null, controlPoint2: null,
        end: { x: 220, y: 80 }, arrowHead: ShapeArrowHead.NONE,
        color: 0xFF336699, strokeWidth: 20, fillColor: null,
        originalTool: 2, originalStyle: 1,
      };
      new ShapeCanvasRenderer(new RecordingStrokeRenderer()).renderShape(
        shape, new Canvas2DOffscreenRenderContext(context));
      expect(context.getImageData(120, 80, 1, 1).data[3]).assertEqual(107);
    });

    it('closes legacy Polygon state but keeps Tape as a non-rendered Shape register', 0, () => {
      const shape: PolygonElement = {
        id: 'tape-shape', type: ElementType.POLYGON,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 5, top: 5, right: 105, bottom: 65 },
        vertices: [{ x: 10, y: 10 }, { x: 100, y: 10 }, { x: 50, y: 60 }],
        isClosed: false, color: 0xFFCC8844, strokeWidth: 12, fillColor: null,
        originalTool: 3, originalStyle: 1, originalTapePattern: TapePattern.HEARTS,
      };
      const recorder: RecordingStrokeRenderer = new RecordingStrokeRenderer();
      new ShapeCanvasRenderer(recorder).renderShape(shape, canvasContext());
      expect(shape.originalTapePattern).assertEqual(TapePattern.HEARTS);
      expect(recorder.tapeCalls.length).assertEqual(0);
      expect(shapeStrokeGeometry(shape).components[0].closed).assertTrue();
    });
  });
}
