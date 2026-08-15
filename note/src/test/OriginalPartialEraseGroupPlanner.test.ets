import { describe, expect, it } from '@ohos/hypium';
import { OriginalSelectionGroup } from '../main/ets/core/model/OriginalGroupSelection';
import {
  OriginalPartialEraseGroupPlan, planLocalPartialEraseGroups,
  planOriginalPartialEraseGroups,
  replayOriginalPartialEraseGroups,
} from '../main/ets/data/OriginalPartialEraseGroupPlanner';

function group(id: string, timestamp: number, members: string[]): OriginalSelectionGroup {
  return { id: id, timestamp: timestamp, siteId: 1, members: members };
}

export default function originalPartialEraseGroupPlannerTest() {
  describe('OriginalPartialEraseGroupPlanner', () => {
    it('uses the highest-identity parent and appends remnants after surviving members', 0, () => {
      const source: string = 'op:a:1';
      const low: OriginalSelectionGroup = group(
        'op:64:1', 100, [source, 'op:d:1']);
      const high: OriginalSelectionGroup = group(
        'op:c8:1', 200, ['op:e:1', source, 'op:f:1']);
      const plan: OriginalPartialEraseGroupPlan = planOriginalPartialEraseGroups(
        [low, high], [{ sourceId: source, remnantIds: ['op:b:1', 'op:c:1'] }]);

      expect(plan.beforeGroups.length).assertEqual(1);
      expect(plan.beforeGroups[0].id).assertEqual(high.id);
      expect(plan.afterGroups[0].members.join(','))
        .assertEqual('op:e:1,op:f:1,op:b:1,op:c:1');
      expect(plan.groups[0].members.join(',')).assertEqual(source + ',op:d:1');
      expect(plan.groups[1].members.join(','))
        .assertEqual('op:e:1,op:f:1,op:b:1,op:c:1');
    });

    it('recursively deletes empty Groups and removes them from their parent', 0, () => {
      const source: string = 'op:a:1';
      const leaf: OriginalSelectionGroup = group('op:64:1', 100, [source]);
      const parent: OriginalSelectionGroup = group('op:c8:1', 200, [leaf.id]);
      const root: OriginalSelectionGroup = group(
        'op:12c:1', 300, [parent.id, 'op:14:1']);
      const plan: OriginalPartialEraseGroupPlan = planOriginalPartialEraseGroups(
        [leaf, parent, root], [{ sourceId: source, remnantIds: [] }]);

      expect(plan.beforeGroups.map((value: OriginalSelectionGroup): string => value.id).join(','))
        .assertEqual('op:64:1,op:c8:1,op:12c:1');
      expect(plan.emptyGroups.map((value: OriginalSelectionGroup): string => value.id).join(','))
        .assertEqual('op:64:1,op:c8:1');
      expect(plan.afterGroups.length).assertEqual(1);
      expect(plan.afterGroups[0].id).assertEqual(root.id);
      expect(plan.afterGroups[0].members.join(',')).assertEqual('op:14:1');
      expect(plan.groups.length).assertEqual(1);
      expect(plan.groups[0].id).assertEqual(root.id);
      const undone: OriginalSelectionGroup[] | null = replayOriginalPartialEraseGroups(
        plan.groups, plan.beforeGroups, plan.afterGroups, false);
      expect(undone !== null).assertTrue();
      expect(undone?.map((value: OriginalSelectionGroup): string => value.id).join(','))
        .assertEqual('op:64:1,op:c8:1,op:12c:1');
      const redone: OriginalSelectionGroup[] | null = replayOriginalPartialEraseGroups(
        undone ?? [], plan.beforeGroups, plan.afterGroups, true);
      expect(redone !== null).assertTrue();
      expect(redone?.length).assertEqual(1);
      expect(redone?.[0].members.join(',')).assertEqual('op:14:1');
    });

    it('replays local Group snapshots symmetrically with draft remnant IDs', 0, () => {
      const source: string = 'op:a:1';
      const before: OriginalSelectionGroup[] = [
        group('op:64:1', 100, ['op:d:1', source]),
      ];
      const plan: OriginalPartialEraseGroupPlan = planOriginalPartialEraseGroups(
        before, [{ sourceId: source, remnantIds: [source + '#erase-0'] }]);
      const forward: OriginalSelectionGroup[] | null = replayOriginalPartialEraseGroups(
        before, plan.beforeGroups, plan.afterGroups, true);
      expect(forward !== null).assertTrue();
      expect(forward?.[0].members.join(','))
        .assertEqual('op:d:1,' + source + '#erase-0');
      const reverse: OriginalSelectionGroup[] | null = replayOriginalPartialEraseGroups(
        forward ?? [], plan.beforeGroups, plan.afterGroups, false);
      expect(reverse !== null).assertTrue();
      expect(reverse?.[0].members.join(',')).assertEqual('op:d:1,' + source);
      expect(replayOriginalPartialEraseGroups(
        before, plan.beforeGroups, plan.afterGroups, false) === null).assertTrue();
    });

    it('plans another local erase after a draft remnant entered the Group', 0, () => {
      const first: OriginalPartialEraseGroupPlan = planLocalPartialEraseGroups([
        group('op:9:1', 9, ['op:1:1']),
      ], [{ sourceId: 'op:1:1', remnantIds: ['op:1:1#erase-0'] }]);
      const second: OriginalPartialEraseGroupPlan = planLocalPartialEraseGroups(first.groups, [{
        sourceId: 'op:1:1#erase-0',
        remnantIds: ['op:1:1#erase-0#erase-0'],
      }]);
      expect(second.groups.length).assertEqual(1);
      expect(second.groups[0].members.join(','))
        .assertEqual('op:1:1#erase-0#erase-0');
    });
  });
}
