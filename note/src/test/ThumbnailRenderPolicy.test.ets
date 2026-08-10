import { describe, it, expect } from '@ohos/hypium';
import {
  fitPageInThumbnail, limitThumbnailNoteIds, prioritizeThumbnailNoteIds, thumbnailCacheKey,
  ThumbnailPageTransform,
} from '../main/ets/rendering/ThumbnailRenderPolicy';

export default function thumbnailRenderPolicyTest() {
  describe('ThumbnailRenderPolicy', () => {
    it('fits portrait and landscape pages without changing aspect ratio', 0, () => {
      let transform: ThumbnailPageTransform = fitPageInThumbnail(794, 1123, 300, 400, 8);
      expect(transform.scale > 0).assertTrue();
      expect(transform.offset.x >= 8).assertTrue();
      expect(transform.offset.y >= 8).assertTrue();
      expect(794 * transform.scale <= 284.000001).assertTrue();
      expect(1123 * transform.scale <= 384.000001).assertTrue();

      transform = fitPageInThumbnail(1123, 794, 300, 400, 8);
      expect(Math.abs(transform.offset.x - 8) < 0.000001).assertTrue();
      expect(transform.offset.y > 8).assertTrue();
    });

    it('includes both paper theme colors in the cache identity', 0, () => {
      const base: string = thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#E0E0E0');
      expect(base === thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#E0E0E0')).assertTrue();
      expect(base === thumbnailCacheKey('page:a4:grid:1', '#262626', '#3A3A3A')).assertFalse();
      expect(base === thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#CCCCCC')).assertFalse();
    });

    it('invalidates cache identity when an image asset becomes available', 0, () => {
      const pending: string = thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#E0E0E0', 0);
      const local: string = thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#E0E0E0', 12);
      expect(pending === local).assertFalse();
      expect(local === thumbnailCacheKey('page:a4:grid:1', '#FFFFFF', '#E0E0E0', 12)).assertTrue();
    });

    it('caps retained note ids for large libraries', 0, () => {
      const ids: string[] = [];
      for (let i: number = 0; i < 100; i++) {
        ids.push(`note-${i}`);
      }
      const retained: string[] = limitThumbnailNoteIds(ids, 64);
      expect(retained.length).assertEqual(64);
      expect(retained[0]).assertEqual('note-0');
      expect(retained[63]).assertEqual('note-63');
    });

    it('prioritizes newly visible notes while retaining a strict capacity', 0, () => {
      const ids: string[] = [];
      for (let i: number = 0; i < 100; i++) {
        ids.push(`note-${i}`);
      }
      const retained: string[] = prioritizeThumbnailNoteIds(ids,
        ['note-70', 'note-65', 'missing', 'note-70'], 64);
      expect(retained.length).assertEqual(64);
      expect(retained[0]).assertEqual('note-70');
      expect(retained[1]).assertEqual('note-65');
      expect(retained.indexOf('missing')).assertEqual(-1);
    });

    it('rejects invalid page or thumbnail geometry', 0, () => {
      let rejected: boolean = false;
      try {
        fitPageInThumbnail(0, 100, 300, 400, 8);
      } catch (_e) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
