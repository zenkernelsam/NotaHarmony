import { describe, expect, it } from '@ohos/hypium';
import { ElementType, ImageElement } from '../main/ets/core/model/ElementTypes';
import {
  imageAssetPackageMetadataMatches, originalAssetLookupKeys, originalAssetStorageHash,
} from '../main/ets/core/model/ImageBlockGeometry';
import { ImageRenderGeometry, imageRenderGeometry } from '../main/ets/rendering/ImageCanvasRenderer';
import { imageAssetPackageEntry } from '../main/ets/data/ImageAssetPackageStore';

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
  });
}
