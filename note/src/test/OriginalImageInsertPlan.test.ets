import { describe, expect, it } from '@ohos/hypium';
import {
  createOriginalImageInsertDraft, OriginalImageInsertAssetDraft,
  isOriginalNormalizedImageDimensions, originalImageDecodedDimensionsAreConsistent,
  originalImageOrientedDimensions, planOriginalImageInsertGeometry,
} from '../main/ets/core/model/OriginalImageInsertPlan';

export default function originalImageInsertPlanTest() {
  describe('OriginalImageInsertPlan', () => {
    it('keeps intrinsic CREATE_BLOCK size and stores the original fitted display scale', 0, () => {
      const draft = createOriginalImageInsertDraft(asset(400, 200),
        { x: 400, y: 500 }, 800, 1000, 1);
      expect(draft === null).assertFalse();
      expect(draft?.id).assertEqual('');
      expect(draft?.blockWidth).assertEqual(400);
      expect(draft?.blockHeight).assertEqual(200);
      expect(draft?.intrinsicWidth).assertEqual(400);
      expect(draft?.intrinsicHeight).assertEqual(200);
      expect(draft?.transform[0]).assertEqual(Math.fround(0.8));
      expect(draft?.transform[4]).assertEqual(Math.fround(0.8));
      expect(draft?.transform[2]).assertEqual(240);
      expect(draft?.transform[5]).assertEqual(420);
      expect(Math.abs((draft?.bounds.right ?? 0) - 560) < 0.001).assertTrue();
      expect(Math.abs((draft?.bounds.bottom ?? 0) - 580) < 0.001).assertTrue();
      expect(draft?.cropRect === null).assertTrue();
      expect(draft?.webUrl === null).assertTrue();
      expect(draft?.imageFlippedHorizontally).assertFalse();
      expect(draft?.imageFlippedVertically).assertFalse();
      expect(draft?.positionLocked).assertFalse();
    });

    it('centres first and clamps each display axis into the page', 0, () => {
      const topLeft = planOriginalImageInsertGeometry(
        400, 200, 800, 1000, 1, { x: 10, y: 10 });
      expect(topLeft?.displayWidth).assertEqual(320);
      expect(topLeft?.displayHeight).assertEqual(160);
      expect(topLeft?.origin.x).assertEqual(0);
      expect(topLeft?.origin.y).assertEqual(0);

      const bottomRight = planOriginalImageInsertGeometry(
        400, 200, 800, 1000, 1, { x: 790, y: 990 });
      expect(bottomRight?.origin.x).assertEqual(480);
      expect(bottomRight?.origin.y).assertEqual(840);
    });

    it('preserves Float32 width and height scale components from the displayed size', 0, () => {
      const geometry = planOriginalImageInsertGeometry(
        3, 297, 793.8, 1122.66, 1.37, { x: 100, y: 200 });
      expect(geometry === null).assertFalse();
      expect(geometry?.displayWidth).assertEqual(Math.fround(2.3593602180480957));
      expect(geometry?.displayHeight).assertEqual(Math.fround(233.57664489746094));
      expect(geometry?.scaleX === geometry?.scaleY).assertFalse();
      expect(geometry?.scaleX).assertEqual(Math.fround(
        (geometry?.displayWidth ?? 0) / 3));
      expect(geometry?.scaleY).assertEqual(Math.fround(
        (geometry?.displayHeight ?? 0) / 297));
    });

    it('keeps the original 3000px and EXIF-oriented ingress dimensions', 0, () => {
      expect(isOriginalNormalizedImageDimensions(3000, 1)).assertTrue();
      expect(isOriginalNormalizedImageDimensions(3001, 1)).assertFalse();
      expect(isOriginalNormalizedImageDimensions(10.5, 10)).assertFalse();
      const rotated = originalImageOrientedDimensions(400, 300, 'Right-top');
      expect(rotated?.width).assertEqual(300);
      expect(rotated?.height).assertEqual(400);
      expect(originalImageOrientedDimensions(400, 300, '7')?.width).assertEqual(300);
      expect(originalImageOrientedDimensions(400, 300, 'Top-left')?.width).assertEqual(400);
      expect(originalImageDecodedDimensionsAreConsistent(
        400, 300, 'Right-top', 300, 400)).assertTrue();
      expect(originalImageDecodedDimensionsAreConsistent(
        400, 300, 'Right-top', 400, 300)).assertTrue();
      expect(originalImageDecodedDimensionsAreConsistent(
        400, 300, 'Right-top', 200, 150)).assertFalse();
    });

    it('rejects invalid geometry MIME and AssetHash metadata', 0, () => {
      expect(planOriginalImageInsertGeometry(
        0, 10, 100, 100, 1, { x: 50, y: 50 }) === null).assertTrue();
      expect(planOriginalImageInsertGeometry(
        10, 10, 100, 100, 0, { x: 50, y: 50 }) === null).assertTrue();
      expect(planOriginalImageInsertGeometry(
        10, 10, 100, 100, 1, { x: Number.NaN, y: 50 }) === null).assertTrue();

      const badMime: OriginalImageInsertAssetDraft = asset(100, 50);
      badMime.mimeType = 'text/plain';
      expect(createOriginalImageInsertDraft(
        badMime, { x: 50, y: 50 }, 100, 100, 1) === null).assertTrue();
      const badHash: OriginalImageInsertAssetDraft = asset(100, 50);
      badHash.assetHashBits = ['1'];
      expect(createOriginalImageInsertDraft(
        badHash, { x: 50, y: 50 }, 100, 100, 1) === null).assertTrue();
      const oversized: OriginalImageInsertAssetDraft = asset(3001, 50);
      expect(createOriginalImageInsertDraft(
        oversized, { x: 50, y: 50 }, 100, 100, 1) === null).assertTrue();
    });
  });
}

function asset(width: number, height: number): OriginalImageInsertAssetDraft {
  return {
    assetHashBits: ['0', '1', '2', '3', '4', '5', '6', '7'],
    fileName: 'temp_image.png', mimeType: 'image/png', fileSize: 1024,
    intrinsicWidth: width, intrinsicHeight: height,
  };
}
