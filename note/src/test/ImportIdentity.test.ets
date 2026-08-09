import { describe, it, expect } from '@ohos/hypium';
import { importedLegacyNoteId, importedPageNeedsRemap } from '../main/ets/data/ImportIdentity';

export default function importIdentityTest() {
  describe('ImportIdentity', () => {
    it('preserves a restored note identity and records the source for a copy', 0, () => {
      expect(importedLegacyNoteId('source', 'source') === null).assertTrue();
      expect(importedLegacyNoteId('source', 'copy')).assertEqual('source');
    });

    it('remaps page identities only for copies, global collisions, or duplicate assignments', 0, () => {
      expect(importedPageNeedsRemap(false, false, false)).assertFalse();
      expect(importedPageNeedsRemap(true, false, false)).assertTrue();
      expect(importedPageNeedsRemap(false, true, false)).assertTrue();
      expect(importedPageNeedsRemap(false, false, true)).assertTrue();
    });
  });
}
