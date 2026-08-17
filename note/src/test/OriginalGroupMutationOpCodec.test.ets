import { describe, expect, it } from '@ohos/hypium';
import { PageElementKind } from '../main/ets/core/model/PageElementOrder';
import {
  decodeOriginalGroupMutation, encodeOriginalGroupMutation, OriginalGroupMutationOpPayload,
} from '../main/ets/data/OriginalGroupMutationOpCodec';

export default function originalGroupMutationOpCodecTest() {
  describe('OriginalGroupMutationOpCodec', () => {
    it('round-trips Group state and both layered orders', 0, () => {
      const mutation: OriginalGroupMutationOpPayload = {
        pageId: 'page-1', beforeGroups: [],
        afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
          members: ['op:14:2', 'op:1e:3'] }],
        elementOrderBefore: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.SHAPE, elementId: 'op:1e:3', zIndex: 1 },
        ],
        elementOrderAfter: [
          { kind: PageElementKind.SHAPE, elementId: 'op:1e:3', zIndex: 0 },
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 1 },
        ],
      };
      const decoded: OriginalGroupMutationOpPayload = decodeOriginalGroupMutation(
        encodeOriginalGroupMutation(mutation));
      expect(decoded.pageId).assertEqual('page-1');
      expect(decoded.afterGroups[0].id).assertEqual('op:28:4');
      expect(decoded.afterGroups[0].members.join(',')).assertEqual('op:14:2,op:1e:3');
      expect(decoded.elementOrderAfter[0].elementId).assertEqual('op:1e:3');
      expect(decoded.elementOrderAfter[1].zIndex).assertEqual(1);
    });

    it('rejects membership changes duplicate members and no-op Group state', 0, () => {
      const base: OriginalGroupMutationOpPayload = {
        pageId: 'page-1', beforeGroups: [],
        afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
          members: ['op:14:2', 'op:1e:3'] }],
        elementOrderBefore: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.SHAPE, elementId: 'op:1e:3', zIndex: 1 },
        ],
        elementOrderAfter: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
        ],
      };
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
      base.elementOrderAfter = base.elementOrderBefore;
      base.afterGroups[0].members = ['op:14:2', 'op:14:2'];
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
      base.beforeGroups = base.afterGroups;
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
      base.beforeGroups = [];
      base.afterGroups[0].members = ['op:14:2', 'op:1e:3'];
      base.elementOrderBefore[0].zIndex = 9;
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
    });

    it('rejects cross-kind identity reuse and unsupported order kinds', 0, () => {
      const base: OriginalGroupMutationOpPayload = {
        pageId: 'page-1', beforeGroups: [],
        afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
          members: ['op:14:2'] }],
        elementOrderBefore: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.TEXT, elementId: 'op:14:2', zIndex: 1 },
        ],
        elementOrderAfter: [
          { kind: PageElementKind.TEXT, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 1 },
        ],
      };
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
      base.elementOrderBefore = [
        { kind: 0 as PageElementKind, elementId: 'op:14:2', zIndex: 0 },
      ];
      base.elementOrderAfter = base.elementOrderBefore;
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
      base.elementOrderBefore = [
        { kind: 6 as PageElementKind, elementId: 'op:14:2', zIndex: 0 },
      ];
      base.elementOrderAfter = base.elementOrderBefore;
      expect(() => encodeOriginalGroupMutation(base)).assertThrow();
    });

    it('rejects a Group identity colliding with an unaffected page entity', 0, () => {
      const mutation: OriginalGroupMutationOpPayload = {
        pageId: 'page-1', beforeGroups: [],
        afterGroups: [{ id: 'op:28:4', timestamp: 40, siteId: 4,
          members: ['op:14:2'] }],
        elementOrderBefore: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.TEXT, elementId: 'op:28:4', zIndex: 1 },
        ],
        elementOrderAfter: [
          { kind: PageElementKind.STROKE, elementId: 'op:14:2', zIndex: 0 },
          { kind: PageElementKind.TEXT, elementId: 'op:28:4', zIndex: 1 },
        ],
      };
      expect(() => encodeOriginalGroupMutation(mutation)).assertThrow();
    });
  });
}
