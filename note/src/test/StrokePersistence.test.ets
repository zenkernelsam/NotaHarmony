import { describe, it, expect } from '@ohos/hypium';
import { InkStyle, StrokeElementData } from '../main/ets/core/model/StrokeTypes';
import {
  decodePersistedElement, encodePersistedElement, PersistedElement,
} from '../main/ets/data/StrokePersistence';

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
  });
}
