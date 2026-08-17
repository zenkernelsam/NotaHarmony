import { describe, it, expect } from '@ohos/hypium';
import {
  Canvas2DOffscreenRenderContext, Canvas2DStrokeRenderer,
  originalTapePatternPixelSize, originalTapePatternScaleBucket,
} from '../main/ets/core/adaptation/Canvas2DStrokeRenderer';
import {
  Canvas2DTextRenderer, TextCheckboxMarker,
} from '../main/ets/core/adaptation/Canvas2DTextRenderer';
import { ShapeCanvasRenderer } from '../main/ets/rendering/ShapeCanvasRenderer';
import {
  ElementType, ShapeArrowHead, ShapeElement, TextBlockElement,
} from '../main/ets/core/model/ElementTypes';
import { Point2D } from '../main/ets/core/model/GeometryTypes';
import {
  InkPathCommandType, InkStyle, RenderSpec, StrokeElementData, StrokePathPoint, TapePattern,
} from '../main/ets/core/model/StrokeTypes';

function pathPoint(x: number, y: number): StrokePathPoint {
  return {
    position: { x: x, y: y },
    widthFactor: 1,
    pressure: 1,
    altitudeAngleRadians: Math.PI / 2,
    azimuthUnitX: 1,
    azimuthUnitY: 0,
  };
}

function stroke(style: InkStyle, highlighter: boolean, y: number = 20,
  color: number = 0xFFFF0000): StrokeElementData {
  const spec: RenderSpec = {
    color: color,
    brushWidth: 10,
    inkStyle: style,
    isHighlighter: highlighter,
    isPencil: false,
  };
  return {
    id: 'renderer-style',
    pathPoints: [pathPoint(20, y), pathPoint(100, y)],
    cubicSegments: [],
    splatPoints: [],
    renderSpec: spec,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 15, top: y - 5, right: 105, bottom: y + 5 },
    maskPath: [],
    isFinished: true,
  };
}

function alphaAt(ctx: OffscreenCanvasRenderingContext2D, x: number, y: number): number {
  return ctx.getImageData(x, y, 1, 1).data[3];
}

function renderHighlighterAlpha(style: InkStyle, passes: number): number {
  const canvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
  const context: OffscreenCanvasRenderingContext2D =
    canvas.getContext('2d', new RenderingContextSettings(true));
  const renderContext: Canvas2DOffscreenRenderContext = new Canvas2DOffscreenRenderContext(context);
  const renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
  // Non-opaque source alpha proves that highlighter alpha is replaced, not multiplied.
  const value: StrokeElementData = stroke(style, true, 20, 0x40FF0000);
  for (let i: number = 0; i < passes; i++) {
    if (style === InkStyle.VARIABLE_WIDTH) {
      renderer.renderVariableWidthOutline(value, renderContext);
    } else {
      renderer.renderCenterPath(value, renderContext);
    }
  }
  return alphaAt(context, 60, 20);
}

function countColor(ctx: OffscreenCanvasRenderingContext2D, red: number,
  green: number, blue: number): number {
  const pixels: Uint8ClampedArray = ctx.getImageData(0, 0, 160, 80).data;
  let count: number = 0;
  for (let index: number = 0; index < pixels.length; index += 4) {
    if (pixels[index] === red && pixels[index + 1] === green && pixels[index + 2] === blue &&
      pixels[index + 3] > 0) {
      count++;
    }
  }
  return count;
}

export default function rendererStyleTest() {
  describe('RendererStyle', () => {
    it('renders DASH with butt caps and DOTS with round caps at the same width', 0, () => {
      const dashCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const dashContext: OffscreenCanvasRenderingContext2D =
        dashCanvas.getContext('2d', new RenderingContextSettings(true));
      const renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
      renderer.renderCenterPath(stroke(InkStyle.DASH, false),
        new Canvas2DOffscreenRenderContext(dashContext));

      const dotsCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const dotsContext: OffscreenCanvasRenderingContext2D =
        dotsCanvas.getContext('2d', new RenderingContextSettings(true));
      renderer.renderCenterPath(stroke(InkStyle.DOTS, false),
        new Canvas2DOffscreenRenderContext(dotsContext));

      expect(alphaAt(dashContext, 16, 20)).assertEqual(0);
      expect(alphaAt(dashContext, 25, 20)).assertEqual(255);
      expect(alphaAt(dashContext, 45, 20)).assertEqual(0);
      expect(alphaAt(dotsContext, 16, 20) > 0).assertTrue();
      expect(alphaAt(dotsContext, 30, 20)).assertEqual(0);
      expect(alphaAt(dotsContext, 40, 20) > 0).assertTrue();
    });

    it('matches fixed and variable width highlighter alpha with source-over overlap', 0, () => {
      const fixedSingle: number = renderHighlighterAlpha(InkStyle.FIXED_WIDTH, 1);
      const variableSingle: number = renderHighlighterAlpha(InkStyle.VARIABLE_WIDTH, 1);
      expect(fixedSingle).assertEqual(107);
      expect(variableSingle).assertEqual(107);

      const fixedDouble: number = renderHighlighterAlpha(InkStyle.FIXED_WIDTH, 2);
      const variableDouble: number = renderHighlighterAlpha(InkStyle.VARIABLE_WIDTH, 2);
      expect(fixedDouble).assertEqual(variableDouble);
      expect(Math.abs(fixedDouble - 169) <= 1).assertTrue();
    });

    it('applies the original style-map phase to dashed Ink', 0, () => {
      const baseCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const baseContext: OffscreenCanvasRenderingContext2D =
        baseCanvas.getContext('2d', new RenderingContextSettings(true));
      const shiftedCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const shiftedContext: OffscreenCanvasRenderingContext2D =
        shiftedCanvas.getContext('2d', new RenderingContextSettings(true));
      const renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
      const shifted: StrokeElementData = stroke(InkStyle.DASH, false);
      shifted.styleMap = [{
        backingPencilSeed: 123,
        backingPencilReferencePoint: { x: 0, y: 0 },
        backingDashPhase: 15,
        backingDashPeriod: 30,
      }];
      renderer.renderCenterPath(stroke(InkStyle.DASH, false),
        new Canvas2DOffscreenRenderContext(baseContext));
      renderer.renderCenterPath(shifted, new Canvas2DOffscreenRenderContext(shiftedContext));
      expect(alphaAt(baseContext, 30, 20)).assertEqual(255);
      expect(alphaAt(shiftedContext, 30, 20)).assertEqual(0);
    });

    it('renders Shape DASH and DOTS with original fixed-width spacing', 0, () => {
      const value: ShapeElement = {
        id: 'shape-style', type: ElementType.LINE,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 15, top: 15, right: 105, bottom: 25 },
        start: { x: 20, y: 20 }, controlPoint1: null, controlPoint2: null,
        end: { x: 100, y: 20 }, arrowHead: ShapeArrowHead.NONE, color: 0xFFFF0000,
        strokeWidth: 10, fillColor: null, originalStyle: 2,
      };
      const renderer: ShapeCanvasRenderer = new ShapeCanvasRenderer(new Canvas2DStrokeRenderer());
      const dashCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const dashContext: OffscreenCanvasRenderingContext2D =
        dashCanvas.getContext('2d', new RenderingContextSettings(true));
      renderer.renderShape(value, new Canvas2DOffscreenRenderContext(dashContext));
      expect(alphaAt(dashContext, 16, 20)).assertEqual(0);
      expect(alphaAt(dashContext, 25, 20)).assertEqual(255);
      expect(alphaAt(dashContext, 45, 20)).assertEqual(0);

      value.originalStyle = 3;
      const dotsCanvas: OffscreenCanvas = new OffscreenCanvas(120, 40);
      const dotsContext: OffscreenCanvasRenderingContext2D =
        dotsCanvas.getContext('2d', new RenderingContextSettings(true));
      renderer.renderShape(value, new Canvas2DOffscreenRenderContext(dotsContext));
      expect(alphaAt(dotsContext, 16, 20) > 0).assertTrue();
      expect(alphaAt(dotsContext, 30, 20)).assertEqual(0);
      expect(alphaAt(dotsContext, 40, 20) > 0).assertTrue();
    });

    it('quantizes Tape pattern cells by the original viewport zoom bucket', 0, () => {
      expect(originalTapePatternScaleBucket(0.25)).assertEqual(2);
      expect(originalTapePatternScaleBucket(1)).assertEqual(2);
      expect(originalTapePatternScaleBucket(1.249)).assertEqual(2);
      expect(originalTapePatternScaleBucket(1.25)).assertEqual(3);
      expect(originalTapePatternScaleBucket(1.749)).assertEqual(3);
      expect(originalTapePatternScaleBucket(1.75)).assertEqual(4);
      expect(originalTapePatternScaleBucket(8)).assertEqual(16);
      expect(originalTapePatternScaleBucket(20)).assertEqual(16);
      expect(originalTapePatternScaleBucket(Number.NaN)).assertEqual(2);
      expect(originalTapePatternScaleBucket(Number.POSITIVE_INFINITY)).assertEqual(2);
      expect(originalTapePatternPixelSize(8, 2)).assertEqual(8);
      expect(originalTapePatternPixelSize(8, 3)).assertEqual(12);
      expect(originalTapePatternPixelSize(11.313708, 16)).assertEqual(91);
    });

    it('clips all original Tape overlays to the stroke and leaves PLAIN unpatterned', 0, () => {
      const patterns: TapePattern[] = [TapePattern.STRIPES, TapePattern.GRID,
        TapePattern.DOTS, TapePattern.STARS, TapePattern.FLOWERS, TapePattern.HEARTS,
        TapePattern.WAVES, TapePattern.CHECKERS];
      const renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
      for (const pattern of patterns) {
        const canvas: OffscreenCanvas = new OffscreenCanvas(160, 80);
        const context: OffscreenCanvasRenderingContext2D =
          canvas.getContext('2d', new RenderingContextSettings(true));
        const value: StrokeElementData = stroke(InkStyle.FIXED_WIDTH, false);
        value.renderSpec.brushWidth = 20;
        value.renderSpec.tapePattern = pattern;
        renderer.renderTapePattern(value, new Canvas2DOffscreenRenderContext(context));
        expect(countColor(context, 255, 255, 255) > 0).assertTrue();
        if (pattern === TapePattern.FLOWERS) {
          expect(countColor(context, 255, 0, 0) > 0).assertTrue();
        }
        expect(alphaAt(context, 60, 2)).assertEqual(0);
      }
      const plainCanvas: OffscreenCanvas = new OffscreenCanvas(160, 80);
      const plainContext: OffscreenCanvasRenderingContext2D =
        plainCanvas.getContext('2d', new RenderingContextSettings(true));
      const plain: StrokeElementData = stroke(InkStyle.FIXED_WIDTH, false);
      plain.renderSpec.tapePattern = TapePattern.PLAIN;
      renderer.renderTapePattern(plain, new Canvas2DOffscreenRenderContext(plainContext));
      expect(countColor(plainContext, 255, 255, 255)).assertEqual(0);

      const customCanvas: OffscreenCanvas = new OffscreenCanvas(160, 80);
      const customContext: OffscreenCanvasRenderingContext2D =
        customCanvas.getContext('2d', new RenderingContextSettings(true));
      const custom: StrokeElementData = stroke(InkStyle.FIXED_WIDTH, false);
      custom.renderSpec.tapePattern = TapePattern.CHECKERS;
      custom.customPath = [
        { type: InkPathCommandType.MOVE_TO, points: [{ x: 20, y: 10 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 40, y: 10 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 40, y: 30 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 20, y: 30 }] },
        { type: InkPathCommandType.LINE_TO, points: [{ x: 20, y: 10 }] },
      ];
      renderer.renderTapePattern(custom, new Canvas2DOffscreenRenderContext(customContext));
      expect(alphaAt(customContext, 24, 12) > 0).assertTrue();
      expect(alphaAt(customContext, 60, 20)).assertEqual(0);
    });

    it('renders original rich-text character and paragraph style runs', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(160, 80);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const element: TextBlockElement = {
        id: 'rich-text', type: ElementType.TEXT, richText: 'AB',
        characterStyleRuns: [{ start: 0, end: 2, style: {
          bold: true, foregroundColor: 0xFFFF0000 | 0, highlightColor: 0xFF00FF00 | 0,
          underline: true,
        } }],
        paragraphStyleRuns: [{ start: 0, end: 2, style: {
          alignment: 2, indentLevel: 1, decoratorStyle: 1, lineSpacing: 1.5,
        } }],
        textOrigin: { x: 0, y: 0 }, blockWidth: 140, blockHeight: 60,
        rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
        fontSize: 20, fontColor: 0xFF000000 | 0,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 140, bottom: 60 },
      };
      new Canvas2DTextRenderer().renderText(element,
        new Canvas2DOffscreenRenderContext(context));
      expect(countColor(context, 0, 255, 0) > 20).assertTrue();
      expect(countColor(context, 255, 0, 0) > 0).assertTrue();
      expect(alphaAt(context, 4, 12)).assertEqual(0);
    });

    it('clips transformed Text content to the original local Block size', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(80, 60);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const element: TextBlockElement = {
        id: 'clipped-text', type: ElementType.TEXT, richText: 'W',
        characterStyleRuns: [{ start: 0, end: 1, style: {
          highlightColor: 0xFF00FF00 | 0,
        } }],
        textOrigin: { x: 0, y: 0 }, blockWidth: 40, blockHeight: 20,
        rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
        contentRightInset: 4, contentBottomInset: 4,
        fontSize: 30, fontColor: 0xFF000000 | 0,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 40, bottom: 20 },
      };
      new Canvas2DTextRenderer().renderText(element,
        new Canvas2DOffscreenRenderContext(context));
      expect(alphaAt(context, 5, 10) > 0).assertTrue();
      expect(alphaAt(context, 5, 25)).assertEqual(0);
    });

    it('measures resize-to-fit width with the same Canvas font metrics as rendering', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(200, 80);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const element: TextBlockElement = {
        id: 'fit-text', type: ElementType.TEXT, richText: 'WW\nI',
        textOrigin: { x: 0, y: 0 }, blockWidth: 20, blockHeight: 60,
        rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
        fontSize: 20, fontColor: 0xFF000000 | 0, resizesWidthToFitText: true,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 20, bottom: 60 },
      };
      const renderer: Canvas2DTextRenderer = new Canvas2DTextRenderer();
      const measured: number = renderer.measureNaturalWidth(element,
        new Canvas2DOffscreenRenderContext(context));
      context.font = '20px sans-serif';
      expect(measured).assertEqual(Math.ceil(context.measureText('WW').width + 8));
    });

    it('hits original checkbox markers from shared wrapped and transformed layout', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(240, 180);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const element: TextBlockElement = {
        id: 'checkbox-hit', type: ElementType.TEXT, richText: 'ABCDEFGHIJKLMN\nB',
        paragraphStyleRuns: [
          { start: 0, end: 15, style: { decoratorStyle: 3, isChecked: false } },
          { start: 15, end: 16, style: { decoratorStyle: 3, isChecked: true } },
        ],
        textOrigin: { x: 0, y: 0 }, blockWidth: 70, blockHeight: 140,
        rotationRadians: Math.PI / 2, contentLeftInset: 4, contentTopInset: 4,
        contentRightInset: 4, fontSize: 20, fontColor: 0xFF000000 | 0,
        transform: [0, -1, 120, 1, 0, 10, 0, 0, 1],
        bounds: { left: -20, top: 10, right: 120, bottom: 80 },
      };
      const renderer: Canvas2DTextRenderer = new Canvas2DTextRenderer();
      const renderContext: Canvas2DOffscreenRenderContext =
        new Canvas2DOffscreenRenderContext(context);
      const markers: TextCheckboxMarker[] = renderer.checkboxMarkers(element, renderContext);
      expect(markers.length).assertEqual(2);
      expect(markers[0].codePointIndex).assertEqual(0);
      expect(markers[1].codePointIndex).assertEqual(15);
      const local: Point2D = markers[1].center;
      const world: Point2D = { x: 120 - local.y, y: 10 + local.x };
      expect(renderer.hitCheckboxMarker(element, renderContext, world)).assertEqual(15);
      const outsideLocal: Point2D = { x: local.x + markers[1].radius * 1.51, y: local.y };
      const outsideWorld: Point2D = { x: 120 - outsideLocal.y, y: 10 + outsideLocal.x };
      expect(renderer.hitCheckboxMarker(element, renderContext, outsideWorld) === null).assertTrue();
    });

    it('draws original circular checkbox markers without platform glyphs', 0, () => {
      const canvas: OffscreenCanvas = new OffscreenCanvas(160, 80);
      const context: OffscreenCanvasRenderingContext2D =
        canvas.getContext('2d', new RenderingContextSettings(true));
      const element: TextBlockElement = {
        id: 'checkbox-vector', type: ElementType.TEXT, richText: 'A\nB',
        paragraphStyleRuns: [
          { start: 0, end: 2, style: { decoratorStyle: 3, isChecked: false } },
          { start: 2, end: 3, style: { decoratorStyle: 3, isChecked: true } },
        ],
        textOrigin: { x: 0, y: 0 }, blockWidth: 150, blockHeight: 70,
        rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
        contentRightInset: 4, fontSize: 20, fontColor: 0xFF000000 | 0,
        transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 150, bottom: 70 },
      };
      const renderer: Canvas2DTextRenderer = new Canvas2DTextRenderer();
      const renderContext: Canvas2DOffscreenRenderContext =
        new Canvas2DOffscreenRenderContext(context);
      const markers: TextCheckboxMarker[] = renderer.checkboxMarkers(element, renderContext);
      renderer.renderText(element, renderContext);
      expect(markers.length).assertEqual(2);
      expect(Math.round(markers[0].center.x)).assertEqual(17);
      expect(alphaAt(context, Math.round(markers[0].center.x),
        Math.round(markers[0].center.y))).assertEqual(0);
      expect(alphaAt(context, Math.round(markers[1].center.x),
        Math.round(markers[1].center.y)) > 0).assertTrue();
      expect(countColor(context, 255, 255, 255) > 0).assertTrue();
    });
  });
}
