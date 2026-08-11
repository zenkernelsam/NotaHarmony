import { describe, it, expect } from '@ohos/hypium';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import {
  decodePersistedElement, encodePersistedElement, PersistedElement,
} from '../main/ets/data/StrokePersistence';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import { ElementType, ImageElement } from '../main/ets/core/model/ElementTypes';
import {
  handwritingSourceChanged, pageSnapshotChanged, SearchSourceElement,
} from '../main/ets/data/SearchIndexPolicy';

export default function strokePersistenceTest() {
  describe('StrokePersistence payload codec', () => {
    it('round-trips snapshot JSON as UTF-8 BLOB bytes', 0, () => {
      const stroke: StrokeElementData = {
        id: 'stroke-1',
        pathPoints: [],
        cubicSegments: [],
        splatPoints: [],
        renderSpec: {
          color: -16777216,
          brushWidth: 12,
          inkStyle: InkStyle.FIXED_WIDTH,
          isHighlighter: false,
          isPencil: false,
          inkEffects: '18446744073709551615',
          inkEffectsTinted: false,
          inkEffectPhase: -3.25,
        },
        transform: { a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0 },
        bounds: { x: 1, y: 2, width: 3, height: 4 },
        maskPath: [],
        isFinished: true,
      };
      const source: PersistedElement = { kind: 'stroke', data: stroke };
      const bytes: Uint8Array = encodePersistedElement(source);
      const restored: PersistedElement = decodePersistedElement(bytes);
      const restoredStroke: StrokeElementData = restored.data as StrokeElementData;

      expect(bytes.length > 0).assertTrue();
      expect(restored.kind).assertEqual('stroke');
      expect(restoredStroke.id).assertEqual('stroke-1');
      expect(restoredStroke.renderSpec.inkStyle).assertEqual(InkStyle.FIXED_WIDTH);
      expect(restoredStroke.renderSpec.inkEffects).assertEqual('18446744073709551615');
      expect(restoredStroke.renderSpec.inkEffectsTinted).assertFalse();
      expect(restoredStroke.renderSpec.inkEffectPhase).assertEqual(-3.25);
      expect(restoredStroke.bounds.width).assertEqual(3);
    });

    it('rejects malformed snapshot bytes', 0, () => {
      let rejected: boolean = false;
      try {
        decodePersistedElement(new Uint8Array([0x7B]));
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('round-trips original image metadata without sharing decoded arrays', 0, () => {
      const bits: string[] = ['0', '1', '2', '3', '4', '5', '6', '18446744073709551615'];
      const image: ImageElement = {
        id: 'image-1', type: ElementType.IMAGE,
        transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
        bounds: { left: 10, top: 20, right: 110, bottom: 70 },
        assetHash: bits.join(':'), assetHashBits: bits, fileName: '图片.png', mimeType: 'image/png',
        fileSize: 4294967295, intrinsicWidth: 200, intrinsicHeight: 100,
        cropRect: { left: 5, top: 10, right: 195, bottom: 90 },
        blockWidth: 100, blockHeight: 50, rotationRadians: 0, corner: 0, textWrap: 0,
        enableCaption: false, webUrl: null, imageFlippedHorizontally: false,
        imageFlippedVertically: true, positionLocked: false,
      };
      const restored: PersistedElement = decodePersistedElement(
        encodePersistedElement({ kind: 'image', data: image }));
      const restoredImage: ImageElement = restored.data as ImageElement;
      restoredImage.assetHashBits[0] = '99';
      restoredImage.transform[2] = 999;

      expect(restored.kind).assertEqual('image');
      expect(restoredImage.assetHash).assertEqual(image.assetHash);
      expect(restoredImage.fileSize).assertEqual(4294967295);
      expect(image.assetHashBits[0]).assertEqual('0');
      expect(image.transform[2]).assertEqual(10);
    });

    it('preserves imported ink text across no-op and non-ink-only saves', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text-old', PageElementKind.TEXT, [3])];
      const unchanged: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text-new', PageElementKind.TEXT, [9]),
        sourceElement('shape', PageElementKind.SHAPE, [4])];

      expect(handwritingSourceChanged(current, unchanged)).assertFalse();
    });

    it('invalidates imported ink text after stroke bytes or order change', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2])];
      const changedStroke: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 3])];
      const addedStroke: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('stroke-2', PageElementKind.STROKE, [4])];

      expect(handwritingSourceChanged(current, changedStroke)).assertTrue();
      expect(handwritingSourceChanged(current, addedStroke)).assertTrue();
    });

    it('suppresses only byte-identical ordered page snapshots', 0, () => {
      const current: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [3])];
      const same: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [3])];
      const reordered: SearchSourceElement[] = [sourceElement('text', PageElementKind.TEXT, [3]),
        sourceElement('stroke', PageElementKind.STROKE, [1, 2])];
      const textChanged: SearchSourceElement[] = [sourceElement('stroke', PageElementKind.STROKE, [1, 2]),
        sourceElement('text', PageElementKind.TEXT, [4])];

      expect(pageSnapshotChanged(current, same)).assertFalse();
      expect(pageSnapshotChanged(current, reordered)).assertTrue();
      expect(pageSnapshotChanged(current, textChanged)).assertTrue();
    });
  });
}

function sourceElement(elementId: string, kind: number, bytes: number[]): SearchSourceElement {
  return { elementId: elementId, kind: kind, payload: new Uint8Array(bytes) };
}
