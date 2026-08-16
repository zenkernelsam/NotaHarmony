import { describe, it, expect } from '@ohos/hypium';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { ElementType, ImageElement, MathElement, PolygonElement,
  TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { PageElementKind, PageElementRef } from '../main/ets/core/model/PageElementOrder';
import {
  ClipboardCopyPreparation, ClipboardOriginalGroupPastePreview, ClipboardPasteResult, StrokeClipboard,
} from '../main/ets/rendering/StrokeClipboard';

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
      inkEffects: '3',
      inkEffectsTinted: false,
      inkEffectPhase: 7.5,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 10, bottom: top + 10 },
    maskPath: [{ x: left + 1, y: top + 1 }],
    isFinished: true,
  };
}

function withOriginalCreate(value: StrokeElementData): StrokeElementData {
  value.originalCreate = {
    timestamp: 100, siteId: 7, clientTime: 101,
    pageTimestamp: 10, pageSiteId: 2, pageIndex: 0, pencilSeed: 3,
  };
  return value;
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

function textBlock(id: string, left: number = 70, top: number = 80): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 100, bottom: top + 40 }, richText: id,
    textOrigin: { x: left, y: top }, blockWidth: 100, blockHeight: 40,
    rotationRadians: 0, contentLeftInset: 4, contentTopInset: 4,
    fontSize: 16, fontColor: 0xFF224466,
  };
}

function imageBlock(id: string, left: number = 180, top: number = 120): ImageElement {
  const bits: string[] = ['1', '2', '3', '4', '5', '6', '7', '8'];
  return {
    id: id, type: ElementType.IMAGE, transform: [1, 0, left, 0, 1, top, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 80, bottom: top + 60 },
    assetHash: bits.join(':'), assetHashBits: bits, fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 100, intrinsicWidth: 160, intrinsicHeight: 120,
    cropRect: { left: 10, top: 20, right: 150, bottom: 110 }, blockWidth: 80, blockHeight: 60,
    rotationRadians: 0, corner: 0, textWrap: 0, enableCaption: false, webUrl: null,
    imageFlippedHorizontally: true, imageFlippedVertically: false, positionLocked: false,
  };
}

function mathBlock(id: string, left: number = 260, top: number = 180): MathElement {
  return {
    id: id, type: ElementType.MATH, transform: [1, 0, left, 0, 1, top, 0, 0, 1],
    bounds: { left: left, top: top, right: left + 70, bottom: top + 40 }, latex: 'x^2+y^2',
    color: 0xFF102030, blockWidth: 70, blockHeight: 40, rotationRadians: 0,
    corner: 0, textWrap: 0, enableCaption: false, positionLocked: false,
  };
}

export default function strokeClipboardTest() {
  describe('StrokeClipboard', () => {
    it('keeps a deep snapshot without mutating the copied document', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: StrokeElementData = stroke('source');
      source.renderSpec.isPartialEraser = true;
      expect(clipboard.copy([source], 'page-1')).assertTrue();
      source.pathPoints[0].position.x = 999;
      source.cubicSegments[0].p1.x = 999;
      source.splatPoints[0].opacity = 0;
      source.renderSpec.brushWidth = 999;
      source.renderSpec.inkEffects = '0';
      source.renderSpec.inkEffectsTinted = true;
      source.renderSpec.inkEffectPhase = -1;
      source.transform[2] = 999;
      source.maskPath[0].x = 999;
      const pasted: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 35, y: 45 },
        (_sourceId: string, sequence: number, index: number): string => `paste-${sequence}-${index}`);
      expect(pasted !== null).assertTrue();
      expect(pasted?.strokes[0].pathPoints[0].position.x).assertEqual(10);
      expect(pasted?.strokes[0].cubicSegments[0].p1.x).assertEqual(12);
      expect(pasted?.strokes[0].splatPoints[0].opacity).assertEqual(0.6);
      expect(pasted?.strokes[0].renderSpec.brushWidth).assertEqual(2);
      expect(pasted?.strokes[0].renderSpec.inkEffects).assertEqual('3');
      expect(pasted?.strokes[0].renderSpec.inkEffectsTinted).assertFalse();
      expect(pasted?.strokes[0].renderSpec.inkEffectPhase).assertEqual(7.5);
      expect(pasted?.strokes[0].renderSpec.isPartialEraser).assertTrue();
      expect(pasted?.strokes[0].transform[2]).assertEqual(20);
      expect(pasted?.strokes[0].maskPath[0].x).assertEqual(11);
      expect(source.id).assertEqual('source');
    });

    it('creates fresh ids while preserving the requested target for consecutive pastes', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('a'), stroke('b', 30, 40)], 'page-1')).assertTrue();
      const first: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 45, y: 55 },
        (sourceId: string, sequence: number): string => `${sourceId}-${sequence}`);
      const second: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 45, y: 55 },
        (sourceId: string, sequence: number): string => `${sourceId}-${sequence}`);
      expect(first?.pasteSequence).assertEqual(1);
      expect(first?.offset.x).assertEqual(20);
      expect(first?.strokes[0].id).assertEqual('a-1');
      expect(first?.strokes[1].id).assertEqual('b-1');
      expect(second?.pasteSequence).assertEqual(2);
      expect(second?.offset.x).assertEqual(20);
      expect(second?.strokes[0].id).assertEqual('a-2');
      expect(first?.sourcePageId).assertEqual('page-1');
    });

    it('drops the source create reservation and exposes only safe single-create candidates', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([withOriginalCreate(stroke('op:100:7'))], 'page-1')).assertTrue();
      expect(clipboard.singleOriginalCreateSource()?.kind).assertEqual(PageElementKind.STROKE);
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 35, y: 45 },
        (): string => 'op:200:7');
      expect(result?.strokes[0].originalCreate === undefined).assertTrue();

      expect(clipboard.copy([stroke('op:100:7')], 'page-1', [], [], [], [], [], [{
        id: 'op:101:7', timestamp: 101, siteId: 7, members: ['op:100:7'],
      }], ['op:101:7'])).assertTrue();
      expect(clipboard.singleOriginalCreateSource() === null).assertTrue();
      const styled: TextBlockElement = textBlock('op:300:7');
      styled.characterStyleRuns = [{ start: 0, end: 1, style: { bold: true } }];
      expect(clipboard.copy([], 'page-1', [], [], [styled])).assertTrue();
      expect(clipboard.singleOriginalCreateSource() === null).assertTrue();
    });

    it('deep-copies nested original Groups and commits Paste offsets only after durability', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const first: StrokeElementData = stroke('op:100:7');
      first.maskPath = [];
      const second: StrokeElementData = stroke('op:101:7', 30, 40);
      second.maskPath = [];
      const groups = [{
        id: 'op:102:7', timestamp: 102, siteId: 7,
        members: ['op:100:7', 'op:101:7'],
      }, {
        id: 'op:103:7', timestamp: 103, siteId: 7, members: ['op:102:7'],
      }];
      expect(clipboard.copy([first, second], 'page-1', [], [], [], [], [],
        groups, ['op:103:7'])).assertTrue();
      groups[0].members[0] = 'mutated';

      const preview: ClipboardOriginalGroupPastePreview | null =
        clipboard.prepareOriginalGroupPaste(800, 1100, { x: 45, y: 55 });
      expect(preview !== null).assertTrue();
      expect(preview?.paste.pasteSequence).assertEqual(1);
      expect(preview?.paste.offset.x).assertEqual(20);
      expect(preview?.paste.strokes[0].id).assertEqual('op:100:7');
      expect(preview?.paste.strokes[0].transform[2]).assertEqual(0);
      expect(preview?.paste.strokes[0].pathPoints[0].position.x).assertEqual(30);
      expect(preview?.groups[0].id).assertEqual('op:102:7');
      expect(preview?.groups[0].members[0]).assertEqual('op:100:7');
      expect(preview?.groups[1].id).assertEqual('op:103:7');
      expect(preview?.topGroupIds[0]).assertEqual('op:103:7');

      expect(clipboard.commitPreparedPaste(
        2, preview?.paste.clipboardRevision ?? -1)).assertFalse();
      expect(clipboard.prepareOriginalGroupPaste(800, 1100, { x: 45, y: 55 })?.paste.pasteSequence).assertEqual(1);
      expect(clipboard.commitPreparedPaste(
        1, preview?.paste.clipboardRevision ?? -1)).assertTrue();
      expect(clipboard.prepareOriginalGroupPaste(800, 1100, { x: 45, y: 55 })?.paste.pasteSequence).assertEqual(2);
      expect(clipboard.prepareOriginalGroupPaste(800, 1100, { x: 45, y: 55 })?.paste.offset.x).assertEqual(20);
    });

    it('rejects incomplete or multi-parent original Group snapshots without replacing content', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('safe')], 'page-1')).assertTrue();
      expect(clipboard.copy([stroke('op:100:7')], 'page-1', [], [], [], [], [], [{
        id: 'op:101:7', timestamp: 101, siteId: 7, members: ['missing'],
      }], ['op:101:7'])).assertFalse();
      expect(clipboard.size()).assertEqual(1);
      expect(clipboard.hasOriginalGroupGraph()).assertFalse();

      expect(clipboard.copy([stroke('op:100:7')], 'page-1', [], [], [], [], [], [{
        id: 'op:101:7', timestamp: 101, siteId: 7, members: ['op:100:7'],
      }, {
        id: 'op:102:7', timestamp: 102, siteId: 7, members: ['op:100:7'],
      }], ['op:101:7', 'op:102:7'])).assertFalse();
      expect(clipboard.size()).assertEqual(1);
    });

    it('does not publish a prepared Copy until the caller commits it', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('old')], 'page-1')).assertTrue();
      const preparation: ClipboardCopyPreparation | null = clipboard.prepareCopy(
        [stroke('new')], 'page-1');
      expect(preparation !== null).assertTrue();
      const oldPaste: ClipboardPasteResult | null = clipboard.paste(
        800, 1100, { x: 35, y: 45 }, (): string => 'old-paste');
      expect(oldPaste?.strokes[0].id).assertEqual('old-paste');
      expect(preparation !== null && clipboard.commitPreparedCopy(preparation)).assertTrue();
      const newPaste: ClipboardPasteResult | null = clipboard.paste(
        800, 1100, { x: 35, y: 45 }, (): string => 'new-paste');
      expect(newPaste?.strokes[0].id).assertEqual('new-paste');
    });

    it('keeps the previous clipboard when a Cut preparation is cancelled', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('old')], 'page-1')).assertTrue();
      const preparation: ClipboardCopyPreparation | null = clipboard.prepareCopy(
        [stroke('candidate')], 'page-1');
      expect(preparation !== null).assertTrue();
      if (preparation !== null) {
        clipboard.cancelPreparedCopy(preparation);
      }
      const pasted: ClipboardPasteResult | null = clipboard.paste(
        800, 1100, { x: 35, y: 45 }, (): string => 'still-old');
      expect(pasted?.strokes[0].id).assertEqual('still-old');
    });

    it('uses the requested target center instead of sequence-based geometry', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('source')], 'page-1')).assertTrue();
      const first: ClipboardPasteResult | null = clipboard.paste(
        800, 1100, { x: 100, y: 120 }, (): string => 'first');
      const second: ClipboardPasteResult | null = clipboard.paste(
        800, 1100, { x: 100, y: 120 }, (): string => 'second');
      expect(first?.offset.x).assertEqual(85);
      expect(first?.offset.y).assertEqual(95);
      expect(second?.offset.x).assertEqual(85);
      expect(second?.offset.y).assertEqual(95);
    });

    it('does not consume an ordinary Paste sequence until persistence accepts it', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('source')], 'page-1')).assertTrue();
      const rejected: ClipboardPasteResult | null = clipboard.preparePaste(
        800, 1100, { x: 100, y: 120 }, (): string => 'rejected');
      expect(rejected?.pasteSequence).assertEqual(1);
      const retry: ClipboardPasteResult | null = clipboard.preparePaste(
        800, 1100, { x: 100, y: 120 }, (): string => 'retry');
      expect(retry?.pasteSequence).assertEqual(1);
      expect(retry !== null && clipboard.commitPreparedPaste(
        retry.pasteSequence, retry.clipboardRevision)).assertTrue();
      expect(clipboard.preparePaste(800, 1100, { x: 100, y: 120 },
        (): string => 'next')?.pasteSequence).assertEqual(2);
    });

    it('rejects a prepared Paste after a newer Copy replaces the clipboard', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('old')], 'page-1')).assertTrue();
      const stale: ClipboardPasteResult | null = clipboard.preparePaste(
        800, 1100, { x: 100, y: 120 }, (): string => 'stale');
      expect(stale !== null).assertTrue();
      expect(clipboard.copy([stroke('new')], 'page-1')).assertTrue();
      expect(stale !== null && clipboard.commitPreparedPaste(
        stale.pasteSequence, stale.clipboardRevision)).assertFalse();
      expect(clipboard.preparePaste(800, 1100, { x: 100, y: 120 },
        (): string => 'fresh')?.pasteSequence).assertEqual(1);
    });

    it('ignores an unrelated malformed Group while copying an independent selection', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('independent')], 'page-1', [], [], [], [], [], [{
        id: 'broken', timestamp: 1, siteId: 1, members: [],
      }], [])).assertTrue();
      expect(clipboard.size()).assertEqual(1);
      expect(clipboard.copy([stroke('leaf')], 'page-1', [], [], [], [], [], [{
        id: 'reachable', timestamp: 2, siteId: 1, members: ['leaf'],
      }, {
        id: 'unrelated-broken', timestamp: 3, siteId: 1, members: [],
      }], ['reachable'])).assertTrue();
      expect(clipboard.hasOriginalGroupGraph()).assertTrue();
    });

    it('materializes original Ink and Shape paste offsets without transform registers', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const sourceStroke: StrokeElementData = stroke('op:100:7');
      sourceStroke.maskPath = [];
      sourceStroke.styleMap = [{
        backingPencilSeed: 3, backingPencilReferencePoint: { x: 5, y: 6 },
        backingDashPhase: 0, backingDashPeriod: 1,
      }];
      expect(clipboard.copy([sourceStroke], 'page-1')).assertTrue();
      const candidate = clipboard.singleOriginalCreateSource();
      expect(candidate?.stroke?.pathPoints[0].position.x).assertEqual(10);
      if (candidate?.stroke !== undefined) {
        candidate.stroke.pathPoints[0].position.x = 999;
      }
      const inkPaste: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 35, y: 45 },
        (): string => 'op:200:7', PageElementKind.STROKE);
      expect(inkPaste?.strokes[0].transform[2]).assertEqual(0);
      expect(inkPaste?.strokes[0].transform[5]).assertEqual(0);
      expect(inkPaste?.strokes[0].pathPoints[0].position.x).assertEqual(30);
      expect(inkPaste?.strokes[0].pathPoints[0].position.y).assertEqual(40);
      expect(inkPaste?.strokes[0].cubicSegments[0].p3.x).assertEqual(40);
      expect(inkPaste?.strokes[0].styleMap?.[0].backingPencilReferencePoint.x).assertEqual(25);
      expect(inkPaste?.strokes[0].bounds.left).assertEqual(30);

      const sourceShape: PolygonElement = shape('op:300:7');
      sourceShape.originalTool = 0;
      sourceShape.originalStyle = 1;
      expect(clipboard.copy([], 'page-1', [sourceShape])).assertTrue();
      const shapePaste: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 70, y: 80 },
        (): string => 'op:400:7', PageElementKind.SHAPE);
      expect(shapePaste?.shapes[0].transform[2]).assertEqual(0);
      expect((shapePaste?.shapes[0] as PolygonElement).vertices[0].x).assertEqual(60);
      expect((shapePaste?.shapes[0] as PolygonElement).vertices[0].y).assertEqual(70);
      expect(shapePaste?.shapes[0].bounds.left).assertEqual(60);

      const transformed: StrokeElementData = stroke('op:500:7');
      transformed.maskPath = [];
      transformed.transform = [0, -2, 100, 2, 0, 50, 0, 0, 1];
      transformed.bounds = { left: 40, top: 70, right: 80, bottom: 110 };
      expect(clipboard.copy([transformed], 'page-1')).assertTrue();
      const transformedPaste: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 80, y: 110 },
        (): string => 'op:600:7', PageElementKind.STROKE);
      expect(transformedPaste?.strokes[0].transform[0]).assertEqual(1);
      expect(transformedPaste?.strokes[0].pathPoints[0].position.x).assertEqual(80);
      expect(transformedPaste?.strokes[0].pathPoints[0].position.y).assertEqual(90);
      expect(transformedPaste?.strokes[0].renderSpec.brushWidth).assertEqual(4);
      expect(transformedPaste?.strokes[0].splatPoints[0].scale).assertEqual(1.6);
      expect(Math.abs((transformedPaste?.strokes[0].splatPoints[0].rotation ?? 0) -
        (0.4 + Math.PI / 2)) < 0.000001).assertTrue();
    });

    it('keeps pasted content inside a smaller destination page', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('edge', 180, 180)], 'wide-page')).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(200, 200, { x: 190, y: 190 },
        (): string => 'new-edge');
      expect(result?.offset.x).assertEqual(2);
      expect(result?.offset.y).assertEqual(2);
      expect(result?.strokes[0].bounds.right).assertEqual(192);
      expect(result?.sourcePageId).assertEqual('wide-page');
    });

    it('rejects duplicate generated ids without consuming the paste sequence', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      expect(clipboard.copy([stroke('a'), stroke('b')], 'page-1')).assertTrue();
      expect(clipboard.paste(800, 1100, { x: 35, y: 45 }, (): string => 'duplicate') === null).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 35, y: 45 },
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
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 70, y: 80 },
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
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 55, y: 65 },
        (_sourceId: string, _sequence: number, index: number): string => `mixed-${index}`);
      expect(result?.elementOrder.length).assertEqual(2);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.SHAPE);
      expect(result?.elementOrder[0].elementId).assertEqual('mixed-0');
      expect(result?.elementOrder[1].kind).assertEqual(PageElementKind.STROKE);
      expect(result?.elementOrder[1].elementId).assertEqual('mixed-1');
      expect(result?.shapes[0].id).assertEqual('mixed-0');
      expect(result?.strokes[0].id).assertEqual('mixed-1');
    });

    it('deep-copies text-only content and offsets transform without changing local origin', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: TextBlockElement = textBlock('text-1');
      expect(clipboard.copy([], 'page-1', [], [], [source])).assertTrue();
      source.textOrigin.x = 999;
      source.transform[2] = 999;
      source.bounds.left = 999;
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 140, y: 120 },
        (): string => 'text-paste');
      expect(result?.strokes.length).assertEqual(0);
      expect(result?.shapes.length).assertEqual(0);
      expect(result?.textBlocks.length).assertEqual(1);
      expect(result?.textBlocks[0].textOrigin.x).assertEqual(70);
      expect(result?.textBlocks[0].transform[2]).assertEqual(20);
      expect(result?.textBlocks[0].bounds.left).assertEqual(90);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.TEXT);
    });

    it('preserves stroke text and shape relative order in one paste action', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const order: PageElementRef[] = [
        { kind: PageElementKind.TEXT, elementId: 'text-1', zIndex: 0 },
        { kind: PageElementKind.SHAPE, elementId: 'shape-1', zIndex: 1 },
        { kind: PageElementKind.STROKE, elementId: 'stroke-1', zIndex: 2 },
      ];
      expect(clipboard.copy([stroke('stroke-1')], 'page-1', [shape('shape-1')], order,
        [textBlock('text-1')])).assertTrue();
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 185, y: 150 },
        (_sourceId: string, _sequence: number, index: number): string => `all-${index}`);
      expect(result?.elementOrder.length).assertEqual(3);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.TEXT);
      expect(result?.elementOrder[1].kind).assertEqual(PageElementKind.SHAPE);
      expect(result?.elementOrder[2].kind).assertEqual(PageElementKind.STROKE);
      expect(result?.textBlocks[0].id).assertEqual('all-0');
      expect(result?.shapes[0].id).assertEqual('all-1');
      expect(result?.strokes[0].id).assertEqual('all-2');
    });

    it('deep-copies image metadata and preserves four-kind z order', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: ImageElement = imageBlock('image-1');
      const order: PageElementRef[] = [
        { kind: PageElementKind.IMAGE, elementId: 'image-1', zIndex: 0 },
        { kind: PageElementKind.TEXT, elementId: 'text-1', zIndex: 1 },
      ];
      expect(clipboard.copy([], 'page-1', [], order, [textBlock('text-1')], [source])).assertTrue();
      source.assetHashBits[0] = '999';
      if (source.cropRect !== null) {
        source.cropRect.left = 999;
      }
      source.transform[2] = 999;
      const result: ClipboardPasteResult | null = clipboard.paste(800, 1100, { x: 185, y: 150 },
        (_sourceId: string, _sequence: number, index: number): string => `media-${index}`);
      expect(result?.images.length).assertEqual(1);
      expect(result?.images[0].assetHashBits[0]).assertEqual('1');
      expect(result?.images[0].cropRect?.left).assertEqual(10);
      expect(result?.images[0].transform[2]).assertEqual(200);
      expect(result?.images[0].bounds.left).assertEqual(200);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.IMAGE);
      expect(result?.elementOrder[1].kind).assertEqual(PageElementKind.TEXT);
    });

    it('deep-copies Math and preserves five-kind z order', 0, () => {
      const clipboard: StrokeClipboard = new StrokeClipboard();
      const source: MathElement = mathBlock('math-1');
      const order: PageElementRef[] = [
        { kind: PageElementKind.MATH, elementId: 'math-1', zIndex: 0 },
        { kind: PageElementKind.IMAGE, elementId: 'image-1', zIndex: 1 },
      ];
      expect(clipboard.copy([], 'page-1', [], order, [], [imageBlock('image-1')],
        [source])).assertTrue();
      source.transform[2] = 999;
      source.bounds.left = 999;
      source.latex = 'mutated';
      const result: ClipboardPasteResult | null = clipboard.paste(900, 1100, { x: 275, y: 190 },
        (_sourceId: string, _sequence: number, index: number): string => `math-${index}`);
      expect(result?.mathBlocks.length).assertEqual(1);
      expect(result?.mathBlocks[0].latex).assertEqual('x^2+y^2');
      expect(result?.mathBlocks[0].transform[2]).assertEqual(280);
      expect(result?.mathBlocks[0].bounds.left).assertEqual(280);
      expect(result?.elementOrder[0].kind).assertEqual(PageElementKind.MATH);
      expect(result?.elementOrder[1].kind).assertEqual(PageElementKind.IMAGE);
    });
  });
}
