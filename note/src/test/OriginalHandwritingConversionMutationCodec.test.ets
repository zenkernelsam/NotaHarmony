import { describe, expect, it } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import {
  decodeOriginalHandwritingConversionMutation, encodeOriginalHandwritingConversionMutation,
  OriginalHandwritingConversionMutation,
} from '../main/ets/data/OriginalHandwritingConversionMutationCodec';
import { createPageMutation, replayPageMutation } from '../main/ets/data/PageMutationOpCodec';
import { encodePersistedElement } from '../main/ets/data/PersistedElementCodec';
import { SearchSourceElement } from '../main/ets/data/SearchIndexPolicy';

export default function originalHandwritingConversionMutationCodecTest() {
  describe('OriginalHandwritingConversionMutationCodec', () => {
    it('round-trips one mixed Ink-to-Text mutation', 0, () => {
      const mutation: OriginalHandwritingConversionMutation = createMutation();
      const decoded: OriginalHandwritingConversionMutation =
        decodeOriginalHandwritingConversionMutation(
          encodeOriginalHandwritingConversionMutation(mutation));

      expect(decoded.pageMutation.pageId).assertEqual('page-1');
      expect(decoded.pageMutation.beforeElements.length).assertEqual(2);
      expect(decoded.pageMutation.afterElements.length).assertEqual(1);
      expect(decoded.sourceStrokeIds.join(',')).assertEqual('op:a:1,op:b:1');
      expect(decoded.textId).assertEqual('op:c:2');
    });

    it('rejects truncated trailing and wrong-magic bytes', 0, () => {
      const encoded: Uint8Array = encodeOriginalHandwritingConversionMutation(createMutation());
      expectThrow((): void => {
        decodeOriginalHandwritingConversionMutation(encoded.slice(0, encoded.length - 1));
      });
      const trailing: Uint8Array = new Uint8Array(encoded.length + 1);
      trailing.set(encoded);
      expectThrow((): void => { decodeOriginalHandwritingConversionMutation(trailing); });
      const wrongMagic: Uint8Array = encoded.slice();
      wrongMagic[0] = 0;
      expectThrow((): void => { decodeOriginalHandwritingConversionMutation(wrongMagic); });
    });

    it('rejects wrong explicit IDs kinds and source membership', 0, () => {
      const wrongTextId: OriginalHandwritingConversionMutation = createMutation();
      wrongTextId.textId = 'op:d:2';
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(wrongTextId); });

      const wrongSourceId: OriginalHandwritingConversionMutation = createMutation();
      wrongSourceId.sourceStrokeIds[1] = 'op:d:2';
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(wrongSourceId); });

      const duplicateSource: OriginalHandwritingConversionMutation = createMutation();
      duplicateSource.sourceStrokeIds[1] = duplicateSource.sourceStrokeIds[0];
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(duplicateSource); });

      const wrongKind: OriginalHandwritingConversionMutation = createMutation();
      wrongKind.pageMutation.beforeElements[0].kind = PageElementKind.SHAPE;
      wrongKind.pageMutation.beforeOrder[0].kind = PageElementKind.SHAPE;
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(wrongKind); });
    });

    it('rejects payloads whose embedded kind or ID contradicts the wrapper', 0, () => {
      const sourcePayloadKind: OriginalHandwritingConversionMutation = createMutation();
      sourcePayloadKind.pageMutation.beforeElements[0].payload = encodePersistedElement({
        kind: 'text', data: text('op:a:1'),
      });
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(sourcePayloadKind); });

      const sourcePayloadId: OriginalHandwritingConversionMutation = createMutation();
      sourcePayloadId.pageMutation.beforeElements[0].payload = encodePersistedElement({
        kind: 'stroke', data: stroke('op:d:2'),
      });
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(sourcePayloadId); });

      const textPayloadKind: OriginalHandwritingConversionMutation = createMutation();
      textPayloadKind.pageMutation.afterElements[0].payload = encodePersistedElement({
        kind: 'stroke', data: stroke('op:c:2'),
      });
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(textPayloadKind); });

      const textPayloadId: OriginalHandwritingConversionMutation = createMutation();
      textPayloadId.pageMutation.afterElements[0].payload = encodePersistedElement({
        kind: 'text', data: text('op:d:2'),
      });
      expectThrow((): void => { encodeOriginalHandwritingConversionMutation(textPayloadId); });
    });

    it('rejects a stale source replay after any Ink byte changes', 0, () => {
      const mutation: OriginalHandwritingConversionMutation = createMutation();
      const staleBefore: SearchSourceElement[] = [
        strokeSource(stroke('op:a:1')), strokeSource(stroke('op:b:1')),
      ];
      staleBefore[0] = strokeSource(stroke('op:a:1', -15654349));
      expectThrow((): void => {
        replayPageMutation(staleBefore, mutation.pageMutation, true);
      });
    });
  });
}

function createMutation(): OriginalHandwritingConversionMutation {
  const before: SearchSourceElement[] = [
    strokeSource(stroke('op:a:1')), strokeSource(stroke('op:b:1')),
  ];
  const after: SearchSourceElement[] = [textSource(text('op:c:2'))];
  return {
    pageMutation: createPageMutation('page-1', 7, 8, before, after),
    sourceStrokeIds: ['op:a:1', 'op:b:1'], textId: 'op:c:2',
  };
}

function stroke(id: string, color: number = -16777216): StrokeElementData {
  return {
    id: id,
    pathPoints: [
      { position: { x: 0, y: 0 }, widthFactor: 1, pressure: 1,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
      { position: { x: 10, y: 0 }, widthFactor: 1, pressure: 1,
        altitudeAngleRadians: 1, azimuthUnitX: 1, azimuthUnitY: 0 },
    ],
    cubicSegments: [{ p0: { x: 0, y: 0 }, p1: { x: 3, y: 0 },
      p2: { x: 7, y: 0 }, p3: { x: 10, y: 0 } }],
    splatPoints: [], renderSpec: {
      color: color, brushWidth: 2, inkStyle: InkStyle.FIXED_WIDTH,
      isHighlighter: false, isPencil: false,
    },
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: -1, top: -1, right: 11, bottom: 1 },
    maskPath: [], isFinished: true,
  };
}

function text(id: string): TextBlockElement {
  return {
    id: id, type: ElementType.TEXT, transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 110, bottom: 60 }, richText: 'hello',
    textOrigin: { x: 0, y: 0 }, blockWidth: 100, blockHeight: 40,
    rotationRadians: 0, contentLeftInset: 5, contentTopInset: 3,
    contentRightInset: 5, contentBottomInset: 10,
    fontSize: 17, fontColor: -16777216, corner: 0, textWrap: 0,
    enableCaption: false, paper: null, resizesWidthToFitText: false,
    characterStyleRuns: [], paragraphStyleRuns: [], positionLocked: false,
  };
}

function strokeSource(value: StrokeElementData): SearchSourceElement {
  return { elementId: value.id, kind: PageElementKind.STROKE,
    payload: encodePersistedElement({ kind: 'stroke', data: value }) };
}

function textSource(value: TextBlockElement): SearchSourceElement {
  return { elementId: value.id, kind: PageElementKind.TEXT,
    payload: encodePersistedElement({ kind: 'text', data: value }) };
}

function expectThrow(block: () => void): void {
  let rejected: boolean = false;
  try {
    block();
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}
