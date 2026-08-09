import { describe, it, expect } from '@ohos/hypium';
import {
  Canvas2DOffscreenRenderContext, Canvas2DStrokeRenderer,
} from '../main/ets/core/adaptation/Canvas2DStrokeRenderer';
import {
  InkStyle, RenderSpec, StrokeElementData, StrokePathPoint,
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
  });
}
