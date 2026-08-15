import { describe, expect, it } from '@ohos/hypium';
import {
  OriginalPartialEraserPreviewPhase, OriginalPartialEraserTransientPreview,
} from '../main/ets/rendering/OriginalPartialEraserTransientPreview';

export default function originalPartialEraserTransientPreviewTest() {
  describe('OriginalPartialEraserTransientPreview', () => {
    it('keeps tool-5 preview transient through durable commit', 0, () => {
      const preview: OriginalPartialEraserTransientPreview =
        new OriginalPartialEraserTransientPreview();
      const token: number = preview.begin({ x: 10, y: 20 }, 20);
      expect(token > 0).assertTrue();
      expect(preview.getPhase()).assertEqual(OriginalPartialEraserPreviewPhase.TRACKING);
      expect(preview.append({ x: 10, y: 20 })).assertFalse();
      expect(preview.append({ x: 30, y: 40 })).assertTrue();
      const stroke = preview.getStroke();
      expect(stroke !== null).assertTrue();
      expect(stroke?.renderSpec.isPartialEraser).assertTrue();
      expect(stroke?.renderSpec.brushWidth).assertEqual(20);
      expect(stroke?.pathPoints.length).assertEqual(2);
      expect(stroke?.bounds.left).assertEqual(0);
      expect(stroke?.bounds.bottom).assertEqual(50);
      expect(stroke?.isFinished).assertFalse();

      expect(preview.finish()).assertEqual(token);
      expect(preview.getPhase()).assertEqual(OriginalPartialEraserPreviewPhase.AWAITING_COMMIT);
      expect(preview.append({ x: 50, y: 60 })).assertFalse();
      expect(preview.complete(token + 1)).assertFalse();
      expect(preview.getStroke() !== null).assertTrue();
      expect(preview.complete(token)).assertTrue();
      expect(preview.getPhase()).assertEqual(OriginalPartialEraserPreviewPhase.IDLE);
      expect(preview.getStroke() === null).assertTrue();
    });

    it('does not let a stale completion clear a newer gesture', 0, () => {
      const preview: OriginalPartialEraserTransientPreview =
        new OriginalPartialEraserTransientPreview();
      const first: number = preview.begin({ x: 1, y: 2 }, 10);
      expect(preview.finish()).assertEqual(first);
      const second: number = preview.begin({ x: 3, y: 4 }, 12);
      expect(second > first).assertTrue();
      expect(preview.complete(first)).assertFalse();
      expect(preview.getStroke()?.id).assertEqual(`transient-partial-eraser-${second}`);
      expect(preview.cancel(first)).assertFalse();
      expect(preview.cancel(second)).assertTrue();
      expect(preview.getStroke() === null).assertTrue();
    });

    it('fails the whole gesture instead of committing a truncated path', 0, () => {
      const preview: OriginalPartialEraserTransientPreview =
        new OriginalPartialEraserTransientPreview(2);
      preview.begin({ x: 0, y: 0 }, 8);
      expect(preview.append({ x: 1, y: 1 })).assertTrue();
      expect(preview.append({ x: 2, y: 2 })).assertFalse();
      expect(preview.isFailed()).assertTrue();
      expect(preview.getStroke() === null).assertTrue();
      expect(preview.finish() === null).assertTrue();
      expect(preview.getPhase()).assertEqual(OriginalPartialEraserPreviewPhase.IDLE);
    });

    it('rejects invalid preview geometry before rendering', 0, () => {
      const preview: OriginalPartialEraserTransientPreview =
        new OriginalPartialEraserTransientPreview();
      expect(() => preview.begin({ x: Number.NaN, y: 0 }, 8)).assertThrow();
      expect(() => preview.begin({ x: 0, y: 0 }, 0)).assertThrow();
      expect(() => new OriginalPartialEraserTransientPreview(0)).assertThrow();
    });
  });
}
