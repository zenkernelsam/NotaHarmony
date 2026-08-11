import { describe, expect, it } from '@ohos/hypium';
import { OriginalSelectionGroup } from '../main/ets/core/model/OriginalGroupSelection';
import {
  decodeOriginalClipboardPasteMutation, encodeOriginalClipboardPasteMutation,
  OriginalClipboardPasteMutation,
} from '../main/ets/data/OriginalClipboardPasteMutationCodec';
import { createPageMutation, PageMutationOpPayload } from '../main/ets/data/PageMutationOpCodec';
import { SearchSourceElement } from '../main/ets/data/SearchIndexPolicy';

export default function originalClipboardPasteMutationCodecTest() {
  describe('OriginalClipboardPasteMutationCodec', () => {
    it('round-trips bottom-up nested Groups and exact top selection roots', 0, () => {
      const mutation: OriginalClipboardPasteMutation = createMutation();
      const decoded: OriginalClipboardPasteMutation = decodeOriginalClipboardPasteMutation(
        encodeOriginalClipboardPasteMutation(mutation));

      expect(decoded.pageMutation.pageId).assertEqual('page-1');
      expect(decoded.pageMutation.afterElements.length).assertEqual(4);
      expect(decoded.groups.length).assertEqual(2);
      expect(decoded.groups[0].members.join(',')).assertEqual('op:14:2,op:15:2');
      expect(decoded.groups[1].members.join(',')).assertEqual('op:1e:3,op:16:2');
      expect(decoded.topGroupIds.join(',')).assertEqual('op:1f:3');
    });

    it('rejects non-insert mutations and non-canonical pasted entities', 0, () => {
      const replacement: OriginalClipboardPasteMutation = createMutation();
      replacement.pageMutation = createPageMutation('page-1', 7, 8,
        [element('op:a:1', 0, [1])], [element('op:a:1', 0, [9])]);
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(replacement); });

      const nonCanonical: OriginalClipboardPasteMutation = createMutation();
      nonCanonical.pageMutation.afterElements[0].elementId = 'clipboard-copy';
      nonCanonical.pageMutation.afterOrder[1].elementId = 'clipboard-copy';
      nonCanonical.groups[0].members[0] = 'clipboard-copy';
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(nonCanonical); });
    });

    it('rejects forward Group references duplicate parents and incorrect roots', 0, () => {
      const forwardReference: OriginalClipboardPasteMutation = createMutation();
      forwardReference.groups[0].members[0] = forwardReference.groups[1].id;
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(forwardReference); });

      const duplicateParent: OriginalClipboardPasteMutation = createMutation();
      duplicateParent.groups[1].members.push('op:14:2');
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(duplicateParent); });

      const wrongRoot: OriginalClipboardPasteMutation = createMutation();
      wrongRoot.topGroupIds = [wrongRoot.groups[0].id];
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(wrongRoot); });
    });

    it('rejects Group identity mismatch collisions and corrupt bytes', 0, () => {
      const mismatch: OriginalClipboardPasteMutation = createMutation();
      mismatch.groups[0].timestamp = 99;
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(mismatch); });

      const collision: OriginalClipboardPasteMutation = createMutation();
      collision.groups[0].id = 'op:14:2';
      collision.groups[0].timestamp = 20;
      collision.groups[0].siteId = 2;
      expectThrow((): void => { encodeOriginalClipboardPasteMutation(collision); });

      const encoded: Uint8Array = encodeOriginalClipboardPasteMutation(createMutation());
      expectThrow((): void => {
        decodeOriginalClipboardPasteMutation(encoded.slice(0, encoded.length - 1));
      });
      const trailing: Uint8Array = new Uint8Array(encoded.length + 1);
      trailing.set(encoded);
      expectThrow((): void => { decodeOriginalClipboardPasteMutation(trailing); });
    });
  });
}

function createMutation(): OriginalClipboardPasteMutation {
  const before: SearchSourceElement[] = [element('op:a:1', 0, [1])];
  const after: SearchSourceElement[] = [before[0], element('op:14:2', 0, [2]),
    element('op:15:2', 1, [3]), element('op:16:2', 2, [4]),
    element('op:17:2', 0, [5])];
  const pageMutation: PageMutationOpPayload = createPageMutation('page-1', 7, 8, before, after);
  const groups: OriginalSelectionGroup[] = [
    { id: 'op:1e:3', timestamp: 30, siteId: 3, members: ['op:14:2', 'op:15:2'] },
    { id: 'op:1f:3', timestamp: 31, siteId: 3, members: ['op:1e:3', 'op:16:2'] },
  ];
  return { pageMutation: pageMutation, groups: groups, topGroupIds: ['op:1f:3'] };
}

function element(elementId: string, kind: number, payload: number[]): SearchSourceElement {
  return { elementId: elementId, kind: kind, payload: new Uint8Array(payload) };
}

function expectThrow(block: () => void): void {
  let rejected: boolean = false;
  try {
    block();
  } catch (_error) {
    rejected = true;
  }
  expect(rejected).assertTrue();
}
