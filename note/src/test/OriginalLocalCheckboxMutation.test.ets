import { describe, it, expect } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import {
  planOriginalLocalCheckboxMutation, toggleOriginalCheckboxAt,
} from '../main/ets/data/OriginalLocalCheckboxMutation';
import { StoredCharacter } from '../main/ets/data/OriginalInsertTextOperation';
import {
  decodeOriginalUpdateCheckbox, encodeOriginalUpdateCheckbox,
  OriginalUpdateCheckboxPayload,
} from '../main/ets/data/OriginalUpdateCheckboxOperation';

export default function originalLocalCheckboxMutationTest() {
  describe('Original local UpdateCheckbox', () => {
    it('toggles only checkbox paragraph starts and keeps the source immutable', 0, () => {
      const before: TextBlockElement = checkboxText();
      const first: TextBlockElement | null = toggleOriginalCheckboxAt(before, 0);
      expect(first === null).assertFalse();
      expect(first?.paragraphStyleRuns?.[0].style.isChecked).assertTrue();
      expect(before.paragraphStyleRuns?.[0].style.isChecked).assertFalse();
      expect(toggleOriginalCheckboxAt(before, 1) === null).assertTrue();
      const second: TextBlockElement | null = toggleOriginalCheckboxAt(before, 2);
      expect(second === null).assertFalse();
      expect(second?.paragraphStyleRuns?.[2].style.isChecked).assertFalse();
    });

    it('maps Unicode code-point paragraph starts to stable character identities', 0, () => {
      const before: TextBlockElement = checkboxText();
      const after: TextBlockElement = toggleOriginalCheckboxAt(before, 2) as TextBlockElement;
      const plan = planOriginalLocalCheckboxMutation(characters(), before, after);
      expect(plan === null).assertFalse();
      expect(plan?.location.timestamp).assertEqual(102);
      expect(plan?.location.siteId).assertEqual(7);
      expect(plan?.location.index).assertEqual(2);
      expect(plan?.isChecked).assertFalse();
      const changedText: TextBlockElement = toggleOriginalCheckboxAt(before, 0) as TextBlockElement;
      changedText.richText = 'X\nB';
      expect(planOriginalLocalCheckboxMutation(
        characters(), before, changedText) === null).assertTrue();
    });

    it('round-trips canonical type-28 true and omitted false payloads', 0, () => {
      const checked: OriginalUpdateCheckboxPayload = {
        textField: { timestamp: 20, siteId: 2 },
        location: { timestamp: 102, siteId: 7, index: 2 }, isChecked: true,
      };
      const decodedTrue: OriginalUpdateCheckboxPayload =
        decodeOriginalUpdateCheckbox(encodeOriginalUpdateCheckbox(checked));
      expect(decodedTrue.textField.timestamp).assertEqual(20);
      expect(decodedTrue.location.index).assertEqual(2);
      expect(decodedTrue.isChecked).assertTrue();
      checked.isChecked = false;
      const encodedFalse: Uint8Array = encodeOriginalUpdateCheckbox(checked);
      const decodedFalse: OriginalUpdateCheckboxPayload = decodeOriginalUpdateCheckbox(encodedFalse);
      expect(decodedFalse.isChecked).assertFalse();
      expect(encodedFalse[40]).assertEqual(0);
    });
  });
}

function checkboxText(): TextBlockElement {
  return {
    id: 'op:20:2', type: ElementType.TEXT,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 100, bottom: 60 },
    richText: '\uD83D\uDE00\nB', textOrigin: { x: 0, y: 0 },
    blockWidth: 100, blockHeight: 60, rotationRadians: 0,
    contentLeftInset: 5, contentTopInset: 3, fontSize: 17, fontColor: -16777216,
    characterStyleRuns: [],
    paragraphStyleRuns: [
      { start: 0, end: 1, style: { decoratorStyle: 3, isChecked: false } },
      { start: 1, end: 2, style: { decoratorStyle: 3 } },
      { start: 2, end: 3, style: { decoratorStyle: 3, isChecked: true } },
    ],
  };
}

function characters(): StoredCharacter[] {
  return [
    { identity: { timestamp: 100, siteId: 7, index: 0 }, parent: null,
      scalar: 0x1F600, visible: true, visibilityWinner: null },
    { identity: { timestamp: 101, siteId: 7, index: 1 },
      parent: { timestamp: 100, siteId: 7, index: 0 },
      scalar: 0x0A, visible: true, visibilityWinner: null },
    { identity: { timestamp: 102, siteId: 7, index: 2 },
      parent: { timestamp: 101, siteId: 7, index: 1 },
      scalar: 0x42, visible: true, visibilityWinner: null },
  ];
}
