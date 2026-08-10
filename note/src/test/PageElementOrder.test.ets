import { describe, it, expect } from '@ohos/hypium';
import {
  ElementType, ImageElement, MathElement, PolygonElement, TextBlockElement,
} from '../main/ets/core/model/ElementTypes';
import {
  appendPageElementRefs, hasStrokeAboveText, legacyPageElementOrder, materializePageElements, moveStrokeRefs,
  movePageElementRefs, normalizePageElementOrder, OrderedPageElement, PageElementKind, PageElementRef,
  removePageElementRefs, requiresUnifiedElementRender, samePageElementMembers, samePageElementOrder,
} from '../main/ets/core/model/PageElementOrder';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import { PageData, parsePage, serializePage } from '../main/ets/data/NotePackageSpec';

function stroke(id: string): StrokeElementData {
  return {
    id: id, pathPoints: [], cubicSegments: [], splatPoints: [],
    renderSpec: { color: 0, brushWidth: 1, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1], bounds: { left: 0, top: 0, right: 1, bottom: 1 },
    maskPath: [], isFinished: true,
  };
}

function shape(id: string): PolygonElement {
  return {
    id: id, type: ElementType.POLYGON, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 2, bottom: 2 },
    vertices: [{ x: 0, y: 0 }, { x: 2, y: 0 }, { x: 1, y: 2 }], isClosed: true,
    color: 0xFF010203, strokeWidth: 2, fillColor: 0x44010203,
  };
}

function text(id: string): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 1, bottom: 1 }, richText: id,
    textOrigin: { x: 0, y: 0 }, blockWidth: 1, blockHeight: 1, rotationRadians: 0,
    contentLeftInset: 0, contentTopInset: 0, fontSize: 12, fontColor: 0,
  };
}

function image(id: string): ImageElement {
  const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'];
  return {
    id: id, type: ElementType.IMAGE, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 },
    assetHash: bits.join(':'), assetHashBits: bits, fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 4294967295, intrinsicWidth: 200, intrinsicHeight: 100,
    cropRect: { left: 5, top: 10, right: 195, bottom: 90 },
    blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
    enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
    imageFlippedVertically: true, positionLocked: false,
  };
}

function math(id: string): MathElement {
  return {
    id: id, type: ElementType.MATH, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 70 },
    latex: 'x^2', color: 0xFF123456 | 0, blockWidth: 100, blockHeight: 50,
    rotationRadians: 0, corner: 0, textWrap: 0, enableCaption: false,
    positionLocked: false,
  };
}

export default function pageElementOrderTest() {
  describe('PageElementOrder', () => {
    it('migrates legacy arrays and repairs stale order refs deterministically', 0, () => {
      const strokes: StrokeElementData[] = [stroke('s1'), stroke('s2')];
      const texts: TextBlockElement[] = [text('t1')];
      const stale: PageElementRef[] = [
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 99 },
        { kind: PageElementKind.STROKE, elementId: 'missing', zIndex: 1 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 2 },
      ];
      const repaired: PageElementRef[] = normalizePageElementOrder(stale, strokes, texts);
      expect(repaired.length).assertEqual(3);
      expect(repaired[0].elementId).assertEqual('t1');
      expect(repaired[1].elementId).assertEqual('s1');
      expect(repaired[2].elementId).assertEqual('s2');
      expect(repaired[2].zIndex).assertEqual(2);
      expect(legacyPageElementOrder(strokes, texts)[2].elementId).assertEqual('t1');
    });

    it('materializes interleaved stroke and text payloads in z order', 0, () => {
      const order: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 0 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 1 },
        { kind: PageElementKind.STROKE, elementId: 's2', zIndex: 2 },
      ];
      const elements: OrderedPageElement[] = materializePageElements(order,
        [stroke('s1'), stroke('s2')], [text('t1')]);
      expect(elements[0].elementId).assertEqual('s1');
      expect(elements[1].kind).assertEqual(PageElementKind.TEXT);
      expect(elements[2].elementId).assertEqual('s2');
    });

    it('materializes and moves semantic shapes without losing mixed z order', 0, () => {
      const before: PageElementRef[] = [
        { kind: PageElementKind.SHAPE, elementId: 'p1', zIndex: 0 },
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 1 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 2 },
      ];
      const elements: OrderedPageElement[] = materializePageElements(
        before, [stroke('s1')], [text('t1')], [shape('p1')]);
      expect(elements[0].kind).assertEqual(PageElementKind.SHAPE);
      expect(elements[1].kind).assertEqual(PageElementKind.STROKE);
      expect(requiresUnifiedElementRender(before)).assertTrue();
      const after: PageElementRef[] = movePageElementRefs(before, [], ['p1'], true);
      expect(after[2].elementId).assertEqual('p1');
      expect(samePageElementMembers(before, after)).assertTrue();
    });

    it('normalizes and materializes images without changing mixed z order', 0, () => {
      const before: PageElementRef[] = [
        { kind: PageElementKind.IMAGE, elementId: 'i1', zIndex: 0 },
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 1 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 2 },
      ];
      const normalized: PageElementRef[] = normalizePageElementOrder(
        before, [stroke('s1')], [text('t1')], [], [image('i1')]);
      const elements: OrderedPageElement[] = materializePageElements(
        normalized, [stroke('s1')], [text('t1')], [], [image('i1')]);
      expect(elements.length).assertEqual(3);
      expect(elements[0].kind).assertEqual(PageElementKind.IMAGE);
      expect(elements[0].elementId).assertEqual('i1');
      expect(elements[1].elementId).assertEqual('s1');
      expect(requiresUnifiedElementRender(normalized)).assertTrue();
      const moved: PageElementRef[] = movePageElementRefs(normalized, [], [], true, [], ['i1']);
      expect(moved[2].elementId).assertEqual('i1');
      expect(samePageElementMembers(normalized, moved)).assertTrue();
    });

    it('normalizes and materializes MATH as an independent ordered element', 0, () => {
      const before: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 0 },
        { kind: PageElementKind.MATH, elementId: 'm1', zIndex: 1 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 2 },
      ];
      const normalized: PageElementRef[] = normalizePageElementOrder(
        before, [stroke('s1')], [text('t1')], [], [], [math('m1')]);
      const elements: OrderedPageElement[] = materializePageElements(
        normalized, [stroke('s1')], [text('t1')], [], [], [math('m1')]);
      expect(elements.length).assertEqual(3);
      expect(elements[1].kind).assertEqual(PageElementKind.MATH);
      expect(elements[1].elementId).assertEqual('m1');
      expect(elements[2].kind).assertEqual(PageElementKind.TEXT);
    });

    it('moves selected strokes across text and restores exact before order', 0, () => {
      const before: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 0 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 1 },
        { kind: PageElementKind.STROKE, elementId: 's2', zIndex: 2 },
      ];
      const after: PageElementRef[] = moveStrokeRefs(before, ['s1'], true);
      expect(after[2].elementId).assertEqual('s1');
      expect(samePageElementMembers(before, after)).assertTrue();
      expect(samePageElementOrder(before, after)).assertFalse();
      expect(samePageElementOrder(before, before)).assertTrue();
      expect(hasStrokeAboveText(before)).assertTrue();
      expect(hasStrokeAboveText(legacyPageElementOrder(
        [stroke('s1')], [text('t1')]))).assertFalse();
    });

    it('moves text together with mixed selected elements', 0, () => {
      const before: PageElementRef[] = [
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 0 },
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 1 },
        { kind: PageElementKind.SHAPE, elementId: 'p1', zIndex: 2 },
        { kind: PageElementKind.TEXT, elementId: 't2', zIndex: 3 },
      ];
      const after: PageElementRef[] = movePageElementRefs(before, ['s1'], [], true, ['t1']);
      expect(after[0].elementId).assertEqual('p1');
      expect(after[1].elementId).assertEqual('t2');
      expect(after[2].elementId).assertEqual('t1');
      expect(after[3].elementId).assertEqual('s1');
      expect(samePageElementMembers(before, after)).assertTrue();
    });

    it('appends and removes refs without disturbing remaining z order', 0, () => {
      let order: PageElementRef[] = legacyPageElementOrder([stroke('s1')], [text('t1')]);
      order = appendPageElementRefs(order, PageElementKind.STROKE, ['s2']);
      expect(order[2].elementId).assertEqual('s2');
      order = removePageElementRefs(order, PageElementKind.TEXT, ['t1']);
      expect(order.length).assertEqual(2);
      expect(order[1].elementId).assertEqual('s2');
      expect(order[1].zIndex).assertEqual(1);
    });

    it('rejects duplicate members in either side of an order transition', 0, () => {
      const valid: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 0 },
        { kind: PageElementKind.TEXT, elementId: 't1', zIndex: 1 },
      ];
      const duplicate: PageElementRef[] = [
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 0 },
        { kind: PageElementKind.STROKE, elementId: 's1', zIndex: 1 },
      ];
      expect(samePageElementMembers(valid, duplicate)).assertFalse();
      expect(samePageElementMembers(duplicate, valid)).assertFalse();
    });

    it('preserves interleaved element order through package serialization', 0, () => {
      const page: PageData = {
        pageId: 'page-1', pageIndex: 0, paperSize: 1, paperTemplate: 0, orientation: 0,
        elements: [
          { kind: 'stroke', data: { id: 's1' } },
          { kind: 'text', data: { id: 't1' } },
          { kind: 'stroke', data: { id: 's2' } },
        ],
      };
      const parsed: PageData | null = parsePage(serializePage(page));
      expect(parsed !== null).assertTrue();
      const first = parsed!.elements[0] as Record<string, Object>;
      const second = parsed!.elements[1] as Record<string, Object>;
      const third = parsed!.elements[2] as Record<string, Object>;
      expect(first.kind as string).assertEqual('stroke');
      expect(second.kind as string).assertEqual('text');
      expect(third.kind as string).assertEqual('stroke');
    });

    it('preserves semantic shape payload and order through package serialization', 0, () => {
      const sourceShape: PolygonElement = shape('p1');
      const page: PageData = {
        pageId: 'page-shape', pageIndex: 0, paperSize: 1, paperTemplate: 0, orientation: 0,
        elements: [
          { kind: 'shape', data: sourceShape },
          { kind: 'stroke', data: { id: 's1' } },
        ],
      };
      const parsed: PageData | null = parsePage(serializePage(page));
      expect(parsed !== null).assertTrue();
      expect(parsed!.elements[0].kind).assertEqual('shape');
      const data = parsed!.elements[0].data as Record<string, Object>;
      expect(data.id as string).assertEqual('p1');
      expect(data.type as number).assertEqual(ElementType.POLYGON);
      expect(data.fillColor as number).assertEqual(0x44010203);
      expect((data.vertices as Object[]).length).assertEqual(3);
      expect(parsed!.elements[1].kind).assertEqual('stroke');
    });

    it('preserves image metadata and order through package serialization', 0, () => {
      const sourceImage: ImageElement = image('i1');
      const page: PageData = {
        pageId: 'page-image', pageIndex: 0, paperSize: 1, paperTemplate: 0, orientation: 0,
        elements: [
          { kind: 'image', data: sourceImage },
          { kind: 'stroke', data: { id: 's1' } },
        ],
      };
      const parsed: PageData | null = parsePage(serializePage(page));
      expect(parsed !== null).assertTrue();
      expect(parsed!.elements[0].kind).assertEqual('image');
      const data = parsed!.elements[0].data as Record<string, Object>;
      expect(data.assetHash as string).assertEqual(sourceImage.assetHash);
      expect((data.assetHashBits as string[])[7]).assertEqual('18446744073709551615');
      expect(data.imageFlippedVertically as boolean).assertTrue();
      expect(parsed!.elements[1].kind).assertEqual('stroke');
    });

    it('preserves MATH identity, LaTeX, ARGB and order through package serialization', 0, () => {
      const sourceMath: MathElement = math('m1');
      const page: PageData = {
        pageId: 'page-math', pageIndex: 0, paperSize: 1, paperTemplate: 0, orientation: 0,
        elements: [
          { kind: 'stroke', data: stroke('s1') },
          { kind: 'math', data: sourceMath },
        ],
      };
      const parsed: PageData | null = parsePage(serializePage(page));
      expect(parsed !== null).assertTrue();
      expect(parsed!.elements.length).assertEqual(2);
      expect(parsed!.elements[1].kind).assertEqual('math');
      const restored: MathElement = parsed!.elements[1].data as MathElement;
      expect(restored.id).assertEqual('m1');
      expect(restored.latex).assertEqual('x^2');
      expect(restored.color).assertEqual(0xFF123456 | 0);
    });
  });
}
