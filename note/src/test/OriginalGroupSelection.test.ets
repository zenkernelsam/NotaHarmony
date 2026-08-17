import { describe, it, expect } from '@ohos/hypium';
import { OriginalSelectionGroup, resolveOriginalGroupSelection,
  OriginalGroupSelectionResult, OriginalSelectionLayerUnit,
  resolveOriginalGroupAuthoringMembers, resolveOriginalSelectedGroupLeaves,
  resolveOriginalSelectionLayerUnits } from
  '../main/ets/core/model/OriginalGroupSelection';

function group(id: string, timestamp: number, siteId: number,
  members: string[]): OriginalSelectionGroup {
  return { id: id, timestamp: timestamp, siteId: siteId, members: members };
}

export default function originalGroupSelectionTest() {
  describe('OriginalGroupSelection', () => {
    it('selects every leaf of the latest containing group', 0, () => {
      const result: OriginalGroupSelectionResult = resolveOriginalGroupSelection(
        ['a'], ['a', 'b', 'c'], [group('old', 10, 1, ['a', 'b']),
          group('new', 10, 2, ['a', 'c'])]);
      expect(result.groupIds.length).assertEqual(1);
      expect(result.groupIds[0]).assertEqual('new');
      expect(result.entityIds.indexOf('a') >= 0).assertTrue();
      expect(result.entityIds.indexOf('c') >= 0).assertTrue();
      expect(result.entityIds.indexOf('b') < 0).assertTrue();
    });

    it('walks to the top group and recursively expands nested leaves', 0, () => {
      const result: OriginalGroupSelectionResult = resolveOriginalGroupSelection(
        ['a'], ['a', 'b', 'c'], [group('inner', 10, 1, ['a', 'b']),
          group('outer', 20, 1, ['inner', 'c'])]);
      expect(result.groupIds[0]).assertEqual('outer');
      expect(result.entityIds.length).assertEqual(3);
      expect(result.entityIds.indexOf('b') >= 0).assertTrue();
      expect(result.entityIds.indexOf('c') >= 0).assertTrue();
    });

    it('falls back to the hit entity for missing and cyclic group state', 0, () => {
      const missing: OriginalGroupSelectionResult = resolveOriginalGroupSelection(
        ['a'], ['a'], [group('broken', 10, 1, ['a', 'missing'])]);
      expect(missing.groupIds.length).assertEqual(0);
      expect(missing.entityIds[0]).assertEqual('a');
      const cyclic: OriginalGroupSelectionResult = resolveOriginalGroupSelection(
        ['a'], ['a'], [group('one', 10, 1, ['a', 'two']),
          group('two', 11, 1, ['one'])]);
      expect(cyclic.groupIds.length).assertEqual(0);
      expect(cyclic.entityIds[0]).assertEqual('a');
    });

    it('separates recursively grouped leaves from a mixed selection', 0, () => {
      const groups: OriginalSelectionGroup[] = [group('inner', 10, 1, ['a', 'b']),
        group('outer', 20, 1, ['inner', 'c'])];
      const leaves: string[] | null = resolveOriginalSelectedGroupLeaves(
        ['outer'], ['a', 'b', 'c', 'direct'], groups);
      expect(leaves !== null).assertTrue();
      expect((leaves as string[]).length).assertEqual(3);
      expect((leaves as string[]).indexOf('direct')).assertEqual(-1);
      expect(resolveOriginalSelectedGroupLeaves(
        ['outer'], ['a', 'b'], groups) === null).assertTrue();
    });

    it('materializes contiguous top-level layer units and rejects corrupt ordering', 0, () => {
      const groups: OriginalSelectionGroup[] = [group('inner', 10, 1, ['a', 'b']),
        group('outer', 20, 1, ['inner', 'c'])];
      const units: OriginalSelectionLayerUnit[] | null =
        resolveOriginalSelectionLayerUnits(['direct', 'a', 'b', 'c', 'tail'], groups);
      expect(units !== null).assertTrue();
      expect((units as OriginalSelectionLayerUnit[]).length).assertEqual(3);
      expect((units as OriginalSelectionLayerUnit[])[1].id).assertEqual('outer');
      expect((units as OriginalSelectionLayerUnit[])[1].entityIds.join(','))
        .assertEqual('a,b,c');
      expect(resolveOriginalSelectionLayerUnits(
        ['a', 'direct', 'b', 'c'], groups) === null).assertTrue();
      expect(resolveOriginalSelectionLayerUnits(['a'], [
        group('one', 10, 1, ['a', 'two']), group('two', 11, 1, ['one']),
      ]) === null).assertTrue();
      expect(resolveOriginalSelectionLayerUnits(['same', 'a'], [
        group('same', 12, 1, ['a']),
      ]) === null).assertTrue();
    });

    it('authors direct entities and selected Groups as distinct member units', 0, () => {
      const groups: OriginalSelectionGroup[] = [group('inner', 10, 1, ['a', 'b']),
        group('outer', 20, 1, ['inner', 'c'])];
      const members: string[] | null = resolveOriginalGroupAuthoringMembers(
        ['a', 'b', 'c', 'direct'], ['outer'], groups);
      expect(members !== null).assertTrue();
      expect((members as string[]).join(',')).assertEqual('direct,outer');
      expect(resolveOriginalGroupAuthoringMembers(
        ['a', 'b'], ['outer'], groups) === null).assertTrue();
      expect(resolveOriginalGroupAuthoringMembers(
        ['a', 'b', 'c'], ['outer', 'outer'], groups) === null).assertTrue();
    });
  });
}
