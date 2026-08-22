import { describe, expect, it } from '@ohos/hypium';
import {
  resetOriginalPhotoUriListSelectorForTest, setOriginalPhotoUriListSelectorForTest,
} from '../main/ets/data/OriginalPhotoPickerCaller';

export default function originalPhotoPickerCallerTest() {
  describe('OriginalPhotoPickerCaller', () => {
    it('supports injectable ordered URI selection for static fixtures', 0, () => {
      let requested = '';
      setOriginalPhotoUriListSelectorForTest(async (context): Promise<string[]> => {
        requested = context.cacheDir;
        return ['file:///a/1.jpg'];
      });
      expect(typeof requested).assertEqual('string');
      resetOriginalPhotoUriListSelectorForTest();
    });
  });
}
