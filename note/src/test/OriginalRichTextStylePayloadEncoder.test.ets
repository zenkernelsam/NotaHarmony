import { describe, expect, it } from '@ohos/hypium';
import { ElementType, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import {
  EncodedOriginalRichTextStyleOperation, encodeOriginalInitialRichTextStyles,
} from '../main/ets/data/OriginalRichTextStylePayloadEncoder';
import {
  decodeOriginalRichTextStyle, OriginalRichTextStylePayload,
} from '../main/ets/data/OriginalRichTextStyleOperation';
import {
  materializeOriginalTextStyles, OriginalTextBoundaryType,
  StoredOriginalTextCharacter, StoredOriginalTextStyleOperation,
} from '../main/ets/data/OriginalRichTextStyleState';

export default function originalRichTextStylePayloadEncoderTest() {
  describe('OriginalRichTextStylePayloadEncoder', () => {
    it('round-trips Unicode character and paragraph runs through original payloads', 0, () => {
      const source: TextBlockElement = styledText();
      const encoded: EncodedOriginalRichTextStyleOperation[] =
        encodeOriginalInitialRichTextStyles(
          { timestamp: 70, siteId: 9 }, { timestamp: 80, siteId: 9 }, source);
      expect(encoded.length).assertEqual(4);

      const operations: StoredOriginalTextStyleOperation[] = [];
      for (let index: number = 0; index < encoded.length; index++) {
        const item: EncodedOriginalRichTextStyleOperation = encoded[index];
        const decoded: OriginalRichTextStylePayload = decodeOriginalRichTextStyle(
          wrap(item.payloadType, item.payload, 100 + index), item.payloadType);
        expect(decoded.textField?.timestamp).assertEqual(70);
        expect(decoded.textField?.siteId).assertEqual(9);
        operations.push({
          identity: { timestamp: 100 + index, siteId: 9 },
          paragraph: decoded.paragraph, clearAll: decoded.clearAll,
          start: decoded.start, end: decoded.end, attributes: decoded.attributes,
        });
      }

      expect(operations[0].start.location.index).assertEqual(0);
      expect(operations[0].end.location.index).assertEqual(2);
      expect(operations[1].end.type).assertEqual(OriginalTextBoundaryType.END_OF_DOC);
      expect(operations[0].attributes.italic).assertFalse();
      expect(operations[0].attributes.highlightColor).assertEqual(-15654349);
      expect(operations[0].attributes.familyName).assertEqual('HarmonyOS Sans');
      expect(operations[0].attributes.link).assertEqual('https://example.test/a');
      expect(operations[0].attributes.fontSize).assertEqual(13.25);
      expect(operations[2].attributes.lineSpacing).assertEqual(1.5);
      expect(operations[2].attributes.programmingLanguage).assertEqual('kotlin');
      expect(operations[3].end.type).assertEqual(OriginalTextBoundaryType.END_OF_DOC);

      const materialized = materializeOriginalTextStyles(characters(), operations);
      expect(materialized === null).assertFalse();
      expect(JSON.stringify(materialized?.characterRuns)).assertEqual(
        JSON.stringify(source.characterStyleRuns));
      expect(JSON.stringify(materialized?.paragraphRuns)).assertEqual(
        JSON.stringify(source.paragraphStyleRuns));
    });

    it('rejects ranges and attributes the original copy protocol cannot preserve', 0, () => {
      const overlap: TextBlockElement = styledText();
      overlap.characterStyleRuns = [
        { start: 0, end: 3, style: { bold: true } },
        { start: 2, end: 4, style: { italic: true } },
      ];
      expect(() => encode(overlap)).assertThrowError();

      const outOfBounds: TextBlockElement = styledText();
      outOfBounds.characterStyleRuns = [{ start: 0, end: 5, style: { bold: true } }];
      expect(() => encode(outOfBounds)).assertThrowError();

      const emptyRange: TextBlockElement = styledText();
      emptyRange.characterStyleRuns = [{ start: 1, end: 1, style: { bold: true } }];
      expect(() => encode(emptyRange)).assertThrowError();

      const emptyStyle: TextBlockElement = styledText();
      emptyStyle.characterStyleRuns = [{ start: 0, end: 1, style: {} }];
      expect(() => encode(emptyStyle)).assertThrowError();

      const invalidEnum: TextBlockElement = styledText();
      invalidEnum.paragraphStyleRuns = [{ start: 0, end: 1, style: { alignment: 0 } }];
      expect(() => encode(invalidEnum)).assertThrowError();

      const lossyFloat: TextBlockElement = styledText();
      lossyFloat.characterStyleRuns = [{ start: 0, end: 1, style: { fontSize: 13.1 } }];
      expect(() => encode(lossyFloat)).assertThrowError();

      const nonCanonicalColor: TextBlockElement = styledText();
      nonCanonicalColor.characterStyleRuns = [{
        start: 0, end: 1, style: { foregroundColor: 0xFF00FF00 },
      }];
      expect(() => encode(nonCanonicalColor)).assertThrowError();

      const malformedUnicode: TextBlockElement = styledText();
      malformedUnicode.richText = '\uD800';
      malformedUnicode.characterStyleRuns = [];
      malformedUnicode.paragraphStyleRuns = [];
      expect(() => encode(malformedUnicode)).assertThrowError();
    });

    it('copies checkbox decorators but resets checked state like original m4c copy', 0, () => {
      const source: TextBlockElement = styledText();
      source.richText = 'AB';
      source.characterStyleRuns = [];
      source.paragraphStyleRuns = [
        { start: 0, end: 1, style: { decoratorStyle: 3, isChecked: true } },
        { start: 1, end: 2, style: { decoratorStyle: 3, isChecked: false } },
      ];
      const encoded: EncodedOriginalRichTextStyleOperation[] = encode(source);
      expect(encoded.length).assertEqual(1);
      const decoded: OriginalRichTextStylePayload = decodeOriginalRichTextStyle(
        wrap(encoded[0].payloadType, encoded[0].payload, 100), encoded[0].payloadType);
      const materialized = materializeOriginalTextStyles(checkboxCharacters(), [{
        identity: { timestamp: 100, siteId: 9 }, paragraph: decoded.paragraph,
        clearAll: decoded.clearAll, start: decoded.start, end: decoded.end,
        attributes: decoded.attributes,
      }]);
      expect(JSON.stringify(materialized?.paragraphRuns)).assertEqual(JSON.stringify([
        { start: 0, end: 2, style: { decoratorStyle: 3 } },
      ]));
    });
  });
}

function encode(text: TextBlockElement): EncodedOriginalRichTextStyleOperation[] {
  return encodeOriginalInitialRichTextStyles(
    { timestamp: 70, siteId: 9 }, { timestamp: 80, siteId: 9 }, text);
}

function styledText(): TextBlockElement {
  return {
    id: 'op:70:9', type: ElementType.TEXT,
    transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
    bounds: { left: 0, top: 0, right: 200, bottom: 50 },
    richText: 'A\uD83D\uDE00\u4E2DZ', textOrigin: { x: 0, y: 0 },
    blockWidth: 200, blockHeight: 50, rotationRadians: 0,
    contentLeftInset: 5, contentTopInset: 3, fontSize: 17, fontColor: -16777216,
    characterStyleRuns: [
      { start: 0, end: 2, style: {
        bold: true, italic: false, underline: true, highlightColor: -15654349,
        familyName: 'HarmonyOS Sans', fontSize: 13.25, foregroundColor: -16711936,
        link: 'https://example.test/a', superscript: false, subscript: false,
        strikethrough: true,
      } },
      { start: 2, end: 4, style: { italic: true, foregroundColor: -16776961 } },
    ],
    paragraphStyleRuns: [
      { start: 0, end: 2, style: {
        indentLevel: 2, alignment: 2, lineSpacing: 1.5, decoratorStyle: 1,
        programmingLanguage: 'kotlin', writingDirection: 0,
      } },
      { start: 2, end: 4, style: { alignment: 3, writingDirection: 1 } },
    ],
  };
}

function characters(): StoredOriginalTextCharacter[] {
  const scalars: number[] = [0x41, 0x1F600, 0x4E2D, 0x5A];
  const result: StoredOriginalTextCharacter[] = [];
  for (let index: number = 0; index < scalars.length; index++) {
    result.push({
      identity: { timestamp: 80, siteId: 9, index: index },
      parent: index === 0 ? null : { timestamp: 80, siteId: 9, index: index - 1 },
      scalar: scalars[index], visible: true, visibilityWinner: null,
    });
  }
  return result;
}

function checkboxCharacters(): StoredOriginalTextCharacter[] {
  return [
    { identity: { timestamp: 80, siteId: 9, index: 0 }, parent: null,
      scalar: 0x41, visible: true, visibilityWinner: null },
    { identity: { timestamp: 80, siteId: 9, index: 1 },
      parent: { timestamp: 80, siteId: 9, index: 0 },
      scalar: 0x42, visible: true, visibilityWinner: null },
  ];
}

function wrap(payloadType: number, payload: Uint8Array, timestamp: number): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: timestamp, siteId: 9 }, clientTime: '1234',
    serverTime: null, audioTime: null, payloadType: payloadType,
  }, payload);
}
