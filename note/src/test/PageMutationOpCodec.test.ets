import { describe, it, expect } from '@ohos/hypium';
import { OpType } from '../main/ets/core/model/OpTypes';
import {
  classifyPageMutation, createPageMutation, decodePageMutationOp, encodePageMutationOp,
  PageMutationOpPayload, PageMutationReplayResult, replayPageMutation, replayPageMutationAtRevision,
} from '../main/ets/data/PageMutationOpCodec';
import { SearchSourceElement } from '../main/ets/data/SearchIndexPolicy';

export default function pageMutationOpCodecTest() {
  describe('PageMutationOpCodec', () => {
    it('round-trips and replays an insertion in both directions', 0, () => {
      const before: SearchSourceElement[] = [element('a', 1, [1])];
      const after: SearchSourceElement[] = [element('a', 1, [1]), element('b-中文', 2, [2, 3])];
      const mutation: PageMutationOpPayload = roundTrip(
        createPageMutation('page-1', 7, 8, before, after));

      expect(classifyPageMutation(mutation)).assertEqual(OpType.INSERT_ELEMENTS);
      const forward: PageMutationReplayResult = replayPageMutationAtRevision(before, 7, mutation, true);
      expect(forward.revision).assertEqual(8);
      assertElements(forward.elements, after);
      const reverse: PageMutationReplayResult = replayPageMutationAtRevision(after, 8, mutation, false);
      expect(reverse.revision).assertEqual(7);
      assertElements(reverse.elements, before);
    });

    it('replays deletion, replacement and layer order exactly', 0, () => {
      const before: SearchSourceElement[] = [element('a', 1, [1]), element('b', 2, [2]),
        element('c', 3, [3])];
      const after: SearchSourceElement[] = [element('c', 3, [3]), element('a', 1, [9])];
      const mutation: PageMutationOpPayload = roundTrip(
        createPageMutation('page-2', 0x100000000, 0x100000001, before, after));

      expect(classifyPageMutation(mutation)).assertEqual(OpType.REPLACE_ELEMENTS);
      expect(mutation.beforeElements.length).assertEqual(2);
      expect(mutation.afterElements.length).assertEqual(1);
      assertElements(replayPageMutation(before, mutation, true), after);
      assertElements(replayPageMutation(after, mutation, false), before);

      const deletion: PageMutationOpPayload = createPageMutation(
        'page-2', 9, 10, before, [before[0], before[2]]);
      expect(classifyPageMutation(deletion)).assertEqual(OpType.DELETE_ELEMENTS);
      assertElements(replayPageMutation(before, deletion, true), [before[0], before[2]]);
    });

    it('stores a pure reorder without duplicating element payloads', 0, () => {
      const before: SearchSourceElement[] = [element('a', 1, [1]), element('b', 2, [2])];
      const after: SearchSourceElement[] = [element('b', 2, [2]), element('a', 1, [1])];
      const mutation: PageMutationOpPayload = createPageMutation('page-3', 4, 5, before, after);

      expect(classifyPageMutation(mutation)).assertEqual(OpType.REORDER_ELEMENTS);
      expect(mutation.beforeElements.length).assertEqual(0);
      expect(mutation.afterElements.length).assertEqual(0);
      assertElements(replayPageMutation(before, mutation, true), after);
    });

    it('rejects stale replay, no-op mutations and corrupt bytes', 0, () => {
      const before: SearchSourceElement[] = [element('a', 1, [1])];
      const after: SearchSourceElement[] = [element('a', 1, [2])];
      const mutation: PageMutationOpPayload = createPageMutation('page-4', 1, 2, before, after);
      expectThrow((): void => { replayPageMutation([element('a', 1, [8])], mutation, true); });
      expectThrow((): void => { replayPageMutationAtRevision(before, 0, mutation, true); });
      expectThrow((): void => { createPageMutation('page-4', 1, 2, before, before); });
      expectThrow((): void => {
        createPageMutation('page-4', 1, 2, [element('a', 1, [1]), element('a', 1, [2])], after);
      });

      const contradictory: PageMutationOpPayload = createPageMutation('page-4', 1, 2, before, after);
      contradictory.afterElements = [];
      expectThrow((): void => { classifyPageMutation(contradictory); });

      const encoded: Uint8Array = encodePageMutationOp(mutation);
      expectThrow((): void => { decodePageMutationOp(encoded.slice(0, encoded.length - 1)); });
      const trailing = new Uint8Array(encoded.length + 1);
      trailing.set(encoded);
      expectThrow((): void => { decodePageMutationOp(trailing); });
    });

    it('uses one ID namespace across kinds and rejects invalid kind sentinels', 0, () => {
      const before: SearchSourceElement[] = [element('shared', 1, [1])];
      const after: SearchSourceElement[] = [element('shared', 2, [1])];
      const replacement: PageMutationOpPayload = createPageMutation(
        'page-kind', 2, 3, before, after);
      expect(classifyPageMutation(replacement)).assertEqual(OpType.REPLACE_ELEMENTS);
      assertElements(replayPageMutation(before, replacement, true), after);
      assertElements(replayPageMutation(after, replacement, false), before);

      expectThrow((): void => {
        createPageMutation('page-kind', 3, 4,
          [element('shared', 1, [1]), element('shared', 2, [2])], after);
      });
      expectThrow((): void => {
        createPageMutation('page-kind', 3, 4, [element('zero', 0, [1])], after);
      });
      expectThrow((): void => {
        createPageMutation('page-kind', 3, 4, [element('future', 6, [1])], after);
      });
    });
  });
}

function roundTrip(value: PageMutationOpPayload): PageMutationOpPayload {
  return decodePageMutationOp(encodePageMutationOp(value));
}

function element(elementId: string, kind: number, payload: number[]): SearchSourceElement {
  return { elementId: elementId, kind: kind, payload: new Uint8Array(payload) };
}

function assertElements(actual: SearchSourceElement[], expected: SearchSourceElement[]): void {
  expect(actual.length).assertEqual(expected.length);
  for (let i: number = 0; i < expected.length; i++) {
    expect(actual[i].elementId).assertEqual(expected[i].elementId);
    expect(actual[i].kind).assertEqual(expected[i].kind);
    expect(actual[i].payload.length).assertEqual(expected[i].payload.length);
    for (let byte: number = 0; byte < expected[i].payload.length; byte++) {
      expect(actual[i].payload[byte]).assertEqual(expected[i].payload[byte]);
    }
  }
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
