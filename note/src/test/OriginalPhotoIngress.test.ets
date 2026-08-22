import { describe, expect, it } from '@ohos/hypium';
import {
  isOversizedOriginalPhoto, isValidOriginalPhotoUri,
  ORIGINAL_PHOTO_MAX_BYTES, validateOriginalPhotoSelection,
} from '../main/ets/data/OriginalPhotoIngress';

export default function originalPhotoIngressTest() {
  describe('OriginalPhotoIngress', () => {
    it('accepts the original Android photo extension allowlist', 0, () => {
      expect(isValidOriginalPhotoUri('file:///media/a.png')).assertTrue();
      expect(isValidOriginalPhotoUri('content://x/IMG_1.JPG')).assertTrue();
      expect(isValidOriginalPhotoUri('file:///media/animated.webp')).assertTrue();
    });

    it('rejects missing hidden or unsupported extensions fail-closed', 0, () => {
      expect(isValidOriginalPhotoUri('file:///media/image')).assertFalse();
      expect(isValidOriginalPhotoUri('file:///media/.png')).assertFalse();
      expect(isValidOriginalPhotoUri('file:///media/image.bmp')).assertFalse();
      expect(isValidOriginalPhotoUri('')).assertFalse();
    });

    it('validates an ordered selection all-or-nothing like tf9', 0, () => {
      const valid: string[] = ['file:///a/1.jpg', 'file:///b/2.heic'];
      const invalid: string[] = ['file:///a/1.jpg', 'file:///b/2.bmp'];
      expect(validateOriginalPhotoSelection(valid)).assertTrue();
      expect(validateOriginalPhotoSelection(invalid)).assertFalse();
      expect(validateOriginalPhotoSelection([])).assertFalse();
    });

    it('uses the exact original bgj 100 MiB byte gate', 0, () => {
      expect(ORIGINAL_PHOTO_MAX_BYTES).assertEqual(104857600);
      expect(isOversizedOriginalPhoto(1)).assertFalse();
      expect(isOversizedOriginalPhoto(104857600)).assertFalse();
      expect(isOversizedOriginalPhoto(104857601)).assertTrue();
      expect(isOversizedOriginalPhoto(0)).assertTrue();
      expect(isOversizedOriginalPhoto(Number.MAX_SAFE_INTEGER + 1)).assertTrue();
    });
  });
}
