import { describe, expect, it } from '@ohos/hypium';
import { ElementType, ImageElement } from '../main/ets/core/model/ElementTypes';
import {
  eraserPathHitsImageBlock, imageAssetPackageMetadataMatches, originalAssetLookupKeys,
  originalAssetStorageHash, selectionPathHitsImageBlock, transformImageElements,
} from '../main/ets/core/model/ImageBlockGeometry';
import { ImageRenderGeometry, imageRenderGeometry } from '../main/ets/rendering/ImageCanvasRenderer';
import { imageAssetPackageEntry } from '../main/ets/data/ImageAssetPackageStore';
import {
  applyOriginalImageCropDraft, beginOriginalImageCrop, OriginalImageCropSession,
  resetOriginalImageCropDraft,
} from '../main/ets/core/model/OriginalImageCropGeometry';

function imageBlock(): ImageElement {
  const bits: string[] = ['0', '1', '72623859790382856', '18446744073709551615',
    '256', '65536', '4294967296', '9223372036854775808'];
  return {
    id: 'image', type: ElementType.IMAGE,
    transform: [1, 0, 10, 0, 1, 20, 0, 0, 1],
    bounds: { left: 10, top: 20, right: 210, bottom: 120 },
    assetHash: bits.join(':'), assetHashBits: bits, fileName: 'photo.png', mimeType: 'image/png',
    fileSize: 100, intrinsicWidth: 400, intrinsicHeight: 200,
    cropRect: { left: 100, top: 25, right: 300, bottom: 175 },
    blockWidth: 200, blockHeight: 75, rotationRadians: 0, corner: 0, textWrap: 0,
    enableCaption: false, webUrl: null, imageFlippedHorizontally: true,
    imageFlippedVertically: false, positionLocked: false,
  };
}

export default function imageBlockRenderingTest() {
  describe('Original image asset and rendering geometry', () => {
    it('encodes the original 64-byte local asset filename byte-for-byte', 0, () => {
      const block: ImageElement = imageBlock();
      const expected: string = '0000000000000000' + '0100000000000000' +
        '0807060504030201' + 'ffffffffffffffff' + '0001000000000000' +
        '0000010000000000' + '0000000001000000' + '0000000000000080';
      expect(originalAssetStorageHash(block.assetHashBits)).assertEqual(expected);
      const keys: string[] = originalAssetLookupKeys(block);
      expect(keys.length).assertEqual(2);
      expect(keys[0]).assertEqual(expected);
      expect(keys[1]).assertEqual(block.assetHash);
      expect(imageAssetPackageEntry(block)).assertEqual(`assets/${expected}`);
    });

    it('maps intrinsic crop coordinates through a downsampled bitmap', 0, () => {
      const geometry: ImageRenderGeometry | null = imageRenderGeometry(imageBlock(), 200, 100);
      expect(geometry === null).assertFalse();
      const resolved: ImageRenderGeometry = geometry as ImageRenderGeometry;
      expect(resolved.cropPixels.left).assertEqual(50);
      expect(resolved.cropPixels.top).assertEqual(12.5);
      expect(resolved.cropPixels.right).assertEqual(150);
      expect(resolved.cropPixels.bottom).assertEqual(87.5);
      expect(resolved.scaleX).assertEqual(2);
      expect(resolved.scaleY).assertEqual(1);
      expect(resolved.flipTranslateX).assertEqual(200);
      expect(resolved.flipScaleX).assertEqual(-1);
      expect(resolved.flipTranslateY).assertEqual(0);
      expect(resolved.flipScaleY).assertEqual(1);
    });

    it('rejects conflicting metadata for one package asset identity', 0, () => {
      const first: ImageElement = imageBlock();
      const same: ImageElement = imageBlock();
      same.id = 'same-asset';
      same.mimeType = 'IMAGE/PNG';
      expect(imageAssetPackageMetadataMatches(first, same)).assertTrue();
      same.fileSize++;
      expect(imageAssetPackageMetadataMatches(first, same)).assertFalse();
      same.fileSize--;
      same.mimeType = 'image/jpeg';
      expect(imageAssetPackageMetadataMatches(first, same)).assertFalse();
    });

    it('rejects an empty crop after clamping to decoded bounds', 0, () => {
      const block: ImageElement = imageBlock();
      block.cropRect = { left: 500, top: 0, right: 600, bottom: 10 };
      expect(imageRenderGeometry(block, 200, 100) === null).assertTrue();
    });

    it('transforms editable images while preserving asset and crop metadata', 0, () => {
      const block: ImageElement = imageBlock();
      const transformed: ImageElement = transformImageElements(
        [block], [block.id], [1, 0, 30, 0, 1, 40, 0, 0, 1])[0];
      expect(transformed.transform[2]).assertEqual(40);
      expect(transformed.transform[5]).assertEqual(60);
      expect(transformed.bounds.left).assertEqual(40);
      expect(transformed.bounds.top).assertEqual(60);
      expect(transformed.assetHashBits[2]).assertEqual(block.assetHashBits[2]);
      expect(transformed.cropRect?.left).assertEqual(100);
      expect(block.transform[2]).assertEqual(10);
      block.positionLocked = true;
      expect(transformImageElements([block], [block.id],
        [1, 0, 30, 0, 1, 40, 0, 0, 1])[0] === block).assertTrue();
    });

    it('uses the transformed block rectangle for object eraser hits', 0, () => {
      const block: ImageElement = imageBlock();
      expect(eraserPathHitsImageBlock([{ x: 0, y: 70 }, { x: 50, y: 70 }], block, 4)).assertTrue();
      expect(eraserPathHitsImageBlock([{ x: -50, y: -50 }], block, 2)).assertFalse();
      block.positionLocked = true;
      expect(eraserPathHitsImageBlock([{ x: 50, y: 70 }], block, 4)).assertFalse();
    });

    it('uses inverse local geometry for scaled image selection and erasing', 0, () => {
      const block: ImageElement = imageBlock();
      block.transform = [4, 0, 0, 0, 1, 0, 0, 0, 1];
      expect(eraserPathHitsImageBlock([{ x: 200, y: 78 }], block, 8)).assertFalse();
      expect(eraserPathHitsImageBlock([{ x: 200, y: 75.5 }], block, 8)).assertTrue();
      expect(selectionPathHitsImageBlock([
        { x: 100, y: 10 }, { x: 300, y: 10 },
        { x: 300, y: 60 }, { x: 100, y: 60 },
      ], block)).assertTrue();
    });

    it('applies a rotated and scaled intrinsic crop with the original origin shift', 0, () => {
      const block: ImageElement = canonicalCropBlock();
      const session: OriginalImageCropSession | null = beginOriginalImageCrop(block);
      expect(session === null).assertFalse();
      const cropped: ImageElement | null = applyOriginalImageCropDraft(
        session as OriginalImageCropSession, { left: 20, top: 10, right: 160, bottom: 130 });
      expect(cropped === null).assertFalse();
      const result: ImageElement = cropped as ImageElement;
      expect(result.cropRect?.left).assertEqual(120);
      expect(result.cropRect?.top).assertEqual(35);
      expect(result.cropRect?.right).assertEqual(260);
      expect(result.cropRect?.bottom).assertEqual(155);
      expect(result.blockWidth).assertEqual(140);
      expect(result.blockHeight).assertEqual(120);
      expect(result.transform[2]).assertEqual(-20);
      expect(result.transform[5]).assertEqual(60);
      expect(block.transform[2]).assertEqual(10);
      expect(block.cropRect?.left).assertEqual(100);
    });

    it('resets an existing crop draft to the full intrinsic image domain', 0, () => {
      const block: ImageElement = canonicalCropBlock();
      const session: OriginalImageCropSession = beginOriginalImageCrop(block) as OriginalImageCropSession;
      const reset = resetOriginalImageCropDraft(session);
      const restored: ImageElement = applyOriginalImageCropDraft(session, reset) as ImageElement;
      expect(reset.left).assertEqual(-100);
      expect(reset.top).assertEqual(-25);
      expect(reset.right).assertEqual(300);
      expect(reset.bottom).assertEqual(175);
      expect(restored.cropRect?.left).assertEqual(0);
      expect(restored.cropRect?.right).assertEqual(400);
      expect(restored.blockWidth).assertEqual(400);
      expect(restored.blockHeight).assertEqual(200);
      expect(restored.transform[2]).assertEqual(85);
      expect(restored.transform[5]).assertEqual(-180);
    });

    it('rejects locked, sheared, invalid, and inconsistent crop models', 0, () => {
      const locked: ImageElement = canonicalCropBlock();
      locked.positionLocked = true;
      expect(beginOriginalImageCrop(locked) === null).assertTrue();
      const sheared: ImageElement = canonicalCropBlock();
      sheared.transform = [1, 0.25, 10, 0, 1, 20, 0, 0, 1];
      expect(beginOriginalImageCrop(sheared) === null).assertTrue();
      const invalid: ImageElement = canonicalCropBlock();
      invalid.cropRect = { left: -1, top: 0, right: 100, bottom: 50 };
      expect(beginOriginalImageCrop(invalid) === null).assertTrue();
      const inconsistent: ImageElement = canonicalCropBlock();
      inconsistent.blockHeight = 75;
      expect(beginOriginalImageCrop(inconsistent) === null).assertTrue();
    });
  });
}

function canonicalCropBlock(): ImageElement {
  const block: ImageElement = imageBlock();
  block.transform = [0, -3, 10, 2, 0, 20, 0, 0, 1];
  block.blockWidth = 200;
  block.blockHeight = 150;
  block.bounds = { left: -440, top: 20, right: 10, bottom: 420 };
  return block;
}
