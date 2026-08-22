import { describe, it, expect } from '@ohos/hypium';
import { originalAssetStorageHash } from '../main/ets/core/model/ImageBlockGeometry';
import {
  AssetAvailabilityChange, AssetAvailabilityHub,
} from '../main/ets/data/AssetAvailabilityHub';
import { sha512Digest, sha512Hex } from '../main/ets/data/AssetDigest';

const ABC_SHA512: string =
  'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a' +
  '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f';
const ABC_HASH_WORDS: string[] = [
  '13437159724906033117', '3549153914273350092',
  '11708982488410547730', '11156354486412156426',
  '12160087498514076193', '13685311869319690806',
  '1074174911913938245', '11503403621103016490',
];

export default function assetArrivalTest() {
  describe('Original image asset arrival', () => {
    it('uses SHA-512 and preserves original uint64 little-endian storage order', 0, async () => {
      const digest: string = await sha512Hex(new Uint8Array([0x61, 0x62, 0x63]));
      expect(digest).assertEqual(ABC_SHA512);
      expect(originalAssetStorageHash(ABC_HASH_WORDS)).assertEqual(ABC_SHA512);
    });

    it('returns an independent SHA-512 byte snapshot', 0, async () => {
      const first: Uint8Array = await sha512Digest(new Uint8Array([0x61, 0x62, 0x63]));
      const second: Uint8Array = await sha512Digest(new Uint8Array([0x61, 0x62, 0x63]));
      expect(first.length).assertEqual(64);
      first[0] = 0;
      expect(second[0]).assertEqual(0xDD);
      expect(first[0] === second[0]).assertFalse();
    });

    it('publishes note generations and stops notifying after unsubscribe', 0, () => {
      const hub: AssetAvailabilityHub = new AssetAvailabilityHub();
      const changes: AssetAvailabilityChange[] = [];
      const listenerId: number = hub.subscribe((change: AssetAvailabilityChange): void => {
        changes.push(change);
      });
      const first: AssetAvailabilityChange = hub.publish(ABC_SHA512, ['note-a', 'note-a', 'note-b']);
      expect(changes.length).assertEqual(1);
      expect(first.noteIds.length).assertEqual(2);
      expect(hub.getNoteGeneration('note-a')).assertEqual(first.generation);
      expect(hub.getNoteGeneration('note-b')).assertEqual(first.generation);
      expect(hub.getNoteGeneration('missing')).assertEqual(0);
      hub.unsubscribe(listenerId);
      hub.publish(ABC_SHA512, ['note-a']);
      expect(changes.length).assertEqual(1);
      expect(hub.getNoteGeneration('note-a') > first.generation).assertTrue();
      hub.forgetNote('note-a');
      expect(hub.getNoteGeneration('note-a')).assertEqual(0);
      expect(hub.getNoteGeneration('note-b')).assertEqual(first.generation);
    });
  });
}
