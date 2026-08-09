import { describe, it, expect } from '@ohos/hypium';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { ElementType, PolygonElement } from '../main/ets/core/model/ElementTypes';
import { PageElementKind, PageElementRef } from '../main/ets/core/model/PageElementOrder';
import { ClipboardPasteResult, StrokeClipboard } from '../main/ets/rendering/StrokeClipboard';

function stroke(id: string, left: number = 10, top: number = 20): StrokeElementData {
  return {
    id: id,
    pathPoints: [{
      position: { x: left, y: top },
      widthFactor: 1,
      pressure: 0.5,
      altitudeAngleRadians: -1,
      azimuthUnitX: 0,
      azimuthUnitY: 0,
    }],
    cubicSegments: [{
      p0: { x: left, y: top },
      p1: { x: left + 2, y: top + 3 },
      p2: { x: left + 6, y: top + 7 },
      p3: { x: left + 10, y: top + 10 },
    }],
    splatPoints: [{ x: left + 4, y: top + 5, rotation: 0.4, scale: 0.8, opacity: 0.6 }],
    renderSpec: {
      color: 0xFF000000,
      brushWidth: 2,
      inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false,
      isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 10, bottom: top + 10 },
    maskPath: [{ x: left + 1, y: top + 1 }],
    isFinished: true,
  };
}

function shape(id: string, left: number = 40, top: number = 50): PolygonElement {
  return {
    id: id, type: ElementType.POLYGON,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 20, bottom: top + 20 },
    vertices: [
      { x: left, y: top }, { x: left + 20, y: top }, { x: left + 10, y: top + 20 },
    ],
    isClosed: true, color: 0xFF336699, strokeWidth: 3, fillColor: 0x44336699,
  };
}

export default function strokeClipboardTest() {
  describe('StrokeClipboard', () => {
    it('keeps a deep snapshot without mutating the copied document', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: StrokeElementData = stroke('source');
      expect(clipboard.copy([source], 'page-1')).assertTrue();
      source.pathPoints[0].position.x = 999;
      source.cubicSegments[0].p1.x = 999;
      source.splatPoints[0].opacity = 0;
      source.renderSpec.brushWidth = 999;
      source.transform[2] = 999;
      source.maskPath[0].x = 999;
      const pasted: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (_sourceId: string, sequence: number, index: number): string => `paste-${sequence}-${index}`);
      expect(pasted !== null).assertTrue();
      expect(pasted?.strokes[0].pathPoints[0].position.x).assertEqual(10);
      expect(pasted?.strokes[0].cubicSegments[0].p1.x).assertEqual(12);
      expect(pasted?.strokes[0].splatPoints[0].opacity).assertEqual(0.6);
      expect(pasted?.strokes[0].renderSpec.brushWidth).assertEqual(2);
      expect(pasted?.strokes[0].transform[2]).assertEqual(20);
      expect(pasted?.strokes[0].maskPath[0].x).assertEqual(11);
      expect(source.id).assertEqual('source');
    });

    it('creates fresh ids and increasing offsets for consecutive pastes', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('a'), stroke('b', 30, 40)], 'page-1')).assertTrue();
      const first: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (sourceId: string, sequence: number): string => `${sourceId}-${sequence}`);
      const second: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (sourceId: string, sequence: number): string => `${sourceId}-${sequence}`);
      expect(first?.pasteSequence).assertEqual(1);
      expect(first?.offset.x).assertEqual(20);
      expect(first?.strokes[0].id).assertEqual('a-1');
      expect(first?.strokes[1].id).assertEqual('b-1');
      expect(second?.pasteSequence).assertEqual(2);
      expect(second?.offset.x).assertEqual(40);
      expect(second?.strokes[0].id).assertEqual('a-2');
      expect(first?.sourcePageId).assertEqual('page-1');
    });

    it('keeps pasted content inside a smaller destination page', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('edge', 180, 180)], 'wide-page')).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(200, 200,
        (): string => 'new-edge');
      expect(result?.offset.x).assertEqual(2);
      expect(result?.offset.y).assertEqual(2);
      expect(result?.strokes[0].bounds.right).assertEqual(192);
      expect(result?.sourcePageId).assertEqual('wide-page');
    });

    it('rejects duplicate generated ids without consuming the paste sequence', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('a'), stroke('b')], 'page-1')).assertTrue();
      expect(clipboard.paste(800, 1100, (): string => 'duplicate') === null).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (_sourceId: string, sequence: number, index: number): string => `${sequence}-${index}`);
      expect(result?.pasteSequence).assertEqual(1);
    });

    it('deep-copies shape-only content and offsets its semantic geometry', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: PolygonElement = shape('shape-1');
      expect(clipboard.copy([], 'page-1', [source])).assertTrue();
      source.vertices[0].x = 999;
      source.transform[2] = 999;
      source.bounds.left = 999;
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (): string => 'shape-paste');
      expect(result?.strokes.length).assertEqual(0);
      expect(result?.shapes.length).assertEqual(1);
      expect(result?.shapes[0].id).assertEqual('shape-paste');
      expect((result?.shapes[0] as PolygonElement).vertices[0].x).assertEqual(40);
      expect(result?.shapes[0].transform[2]).assertEqual(20);
      expect(result?.shapes[0].bounds.left).assertEqual(60);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.SHAPE);
    });

    it('preserves mixed stroke and shape relative order while assigning fresh ids', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const order: PageElementRef[] = [
        { kind: PageElementKind.SHAPE, elementId: 'shape-1', zIndex: 0 },
        { kind: PageElementKind.STROKE, elementId: 'stroke-1', zIndex: 1 },
      ];
      expect(clipboard.copy([stroke('stroke-1')], 'page-1', [shape('shape-1')], order)).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100,
        (_sourceId: string, _sequence: number, index: number): string => `mixed-${index}`);
      expect(result?.elementOrder.length).assertEqual(2);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.SHAPE);
      expect(result?.elementOrder[0].elementId).assertEqual('mixed-0');
      expect(result?.elementOrder[1].kind).assertEqual(PageElementKind.STROKE);
      expect(result?.elementOrder[1].elementId).assertEqual('mixed-1');
      expect(result?.shapes[0].id).assertEqual('mixed-0');
      expect(result?.strokes[0].id).assertEqual('mixed-1');
    });
  });
}
