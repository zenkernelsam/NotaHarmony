import { describe, it, expect } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import {
  appendPageElementRefs, hasStrokeAboveText, legacyPageElementOrder, materializePageElements, moveStrokeRefs,
  normalizePageElementOrder, OrderedPageElement, PageElementKind, PageElementRef,
  removePageElementRefs, samePageElementMembers, samePageElementOrder,
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

function text(id: string): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 1, bottom: 1 }, richText: id,
    textOrigin: { x: 0, y: 0 }, blockWidth: 1, blockHeight: 1, rotationRadians: 0,
    contentLeftInset: 0, contentTopInset: 0, fontSize: 12, fontColor: 0,
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
  });
}
