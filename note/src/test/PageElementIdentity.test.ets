import { describe, it, expect } from '@ohos/hypium';
import { reserveNotePageElementIds } from '../main/ets/data/PageElementIdentity';

export default function pageElementIdentityTest() {
  describe('PageElementIdentity', () => {
    it('reserves one note-wide identity namespace across pages', 0, () => {
      const reserved: Set<string> = new Set<string>();
      expect(reserveNotePageElementIds(reserved, ['stroke', 'text'])).assertTrue();
      expect(reserveNotePageElementIds(reserved, ['shape', 'image'])).assertTrue();
      expect(reserved.size).assertEqual(4);
    });

    it('rejects a cross-page ID regardless of payload kind', 0, () => {
      const reserved: Set<string> = new Set<string>();
      expect(reserveNotePageElementIds(reserved, ['shared'])).assertTrue();
      expect(reserveNotePageElementIds(reserved, ['shared'])).assertFalse();
      expect(reserved.size).assertEqual(1);
    });

    it('rejects an invalid page atomically without reserving its other IDs', 0, () => {
      const reserved: Set<string> = new Set<string>();
      expect(reserveNotePageElementIds(reserved, ['existing'])).assertTrue();
      expect(reserveNotePageElementIds(reserved, ['new', 'existing'])).assertFalse();
      expect(reserved.has('new')).assertFalse();
      expect(reserveNotePageElementIds(reserved, ['new'])).assertTrue();
      expect(reserveNotePageElementIds(reserved, ['duplicate', 'duplicate'])).assertFalse();
      expect(reserveNotePageElementIds(reserved, [''])).assertFalse();
    });
  });
}
