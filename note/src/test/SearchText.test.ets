import { describe, it, expect } from '@ohos/hypium';
import { escapeSearchLike, foldSearchText } from '../main/ets/data/SearchText';

export default function searchTextTest() {
  describe('SearchText', () => {
    it('folds title and text queries consistently', 0, () => {
      expect(foldSearchText('Mixed CASE 中文')).assertEqual('mixed case 中文');
    });

    it('escapes every SQLite LIKE metacharacter', 0, () => {
      expect(escapeSearchLike('50%_done\\next')).assertEqual('50\\%\\_done\\\\next');
    });
  });
}
