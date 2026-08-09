import { describe, it, expect } from '@ohos/hypium';
import {
  assetMutationMutex, mergeNoteIds, parseAssetNoteIds,
} from '../main/ets/data/AssetRepositoryImpl';

function parseThrows(raw: string): boolean {
  try {
    parseAssetNoteIds(raw);
    return false;
  } catch (_error) {
    return true;
  }
}

export default function assetReferenceTest() {
  describe('Asset reference integrity', () => {
    it('merges shared note references without replacing existing order', 0, () => {
      const merged: string[] = mergeNoteIds(['note-a', 'note-b'], ['note-b', 'note-c']);
      expect(merged.length).assertEqual(3);
      expect(merged[0]).assertEqual('note-a');
      expect(merged[1]).assertEqual('note-b');
      expect(merged[2]).assertEqual('note-c');
    });

    it('rejects malformed reference snapshots instead of treating them as empty', 0, () => {
      expect(parseThrows('{}')).assertTrue();
      expect(parseThrows('["note-a",""]')).assertTrue();
      expect(parseThrows('not-json')).assertTrue();
      const parsed: string[] = parseAssetNoteIds('["note-a","note-a","note-b"]');
      expect(parsed.length).assertEqual(2);
      expect(parsed[0]).assertEqual('note-a');
      expect(parsed[1]).assertEqual('note-b');
    });

    it('serializes save and note-deletion mutations through the shared lock', 0, async () => {
      const order: string[] = [];
      let unblockFirst: (() => void) | null = null;
      const gate: Promise<void> = new Promise<void>((resolve: () => void) => {
        unblockFirst = resolve;
      });
      const save = assetMutationMutex.runExclusive(async (): Promise<void> => {
        order.push('save-start');
        await gate;
        order.push('save-end');
      });
      await Promise.resolve();
      const deleteNote = assetMutationMutex.runExclusive(async (): Promise<void> => {
        order.push('delete-note');
      });
      await Promise.resolve();
      expect(order.length).assertEqual(1);
      if (unblockFirst !== null) {
        unblockFirst();
      }
      await Promise.all([save, deleteNote]);
      expect(order.length).assertEqual(3);
      expect(order[0]).assertEqual('save-start');
      expect(order[1]).assertEqual('save-end');
      expect(order[2]).assertEqual('delete-note');
    });
  });
}
