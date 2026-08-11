import { describe, expect, it } from '@ohos/hypium';
import { relationalStore } from '@kit.ArkData';
import { ElementType, MathElement, TextBlockElement } from '../main/ets/core/model/ElementTypes';
import { decodeOriginalCreateBlock, OriginalBlockType } from
  '../main/ets/data/OriginalCreateBlockOperation';
import { encodeOriginalLocalCreateMathBlock, encodeOriginalLocalCreateTextBlock } from
  '../main/ets/data/OriginalCreateBlockPayloadEncoder';
import { decodeOriginalInsertText, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE } from
  '../main/ets/data/OriginalInsertTextOperation';
import { encodeOriginalInitialInsertString } from
  '../main/ets/data/OriginalInsertTextPayloadEncoder';
import { encodeOriginalOperationEnvelope } from
  '../main/ets/data/OriginalOperationEnvelopeEncoder';
import { OriginalPageMutationBatch } from
  '../main/ets/data/OriginalPageMutationBatch';

export default function originalCreateTextPayloadEncoderTest() {
  describe('OriginalCreateTextPayloadEncoder', () => {
    it('round-trips canonical local Text placement through CREATE_BLOCK', 0, () => {
      const text: TextBlockElement = sampleText();
      const decoded = decodeOriginalCreateBlock(wrap(22,
        encodeOriginalLocalCreateTextBlock(
          { timestamp: 80, siteId: 7, index: 2 }, text)), '1234');
      expect(decoded.blockType).assertEqual(OriginalBlockType.TEXT);
      expect(decoded.page.timestamp).assertEqual(80);
      expect(decoded.page.siteId).assertEqual(7);
      expect(decoded.page.index).assertEqual(2);
      expect(decoded.originX).assertEqual(25);
      expect(decoded.originY).assertEqual(40);
      expect(decoded.width).assertEqual(200);
      expect(decoded.height).assertEqual(40);
      expect(decoded.zIndex).assertEqual('1234');
      expect(decoded.margins.top).assertEqual(3);
      expect(decoded.margins.bottom).assertEqual(10);
      expect(decoded.margins.left).assertEqual(5);
      expect(decoded.margins.right).assertEqual(5);
      expect(decoded.hasMathLatex).assertFalse();
      expect(decoded.hasImage).assertFalse();
    });

    it('round-trips initial Unicode text with explicit Block target', 0, () => {
      const decoded = decodeOriginalInsertText(wrap(8,
        encodeOriginalInitialInsertString({ timestamp: 100, siteId: 7 }, 'A\uD83D\uDE00\u4E2D')),
      ORIGINAL_INSERT_STRING_PAYLOAD_TYPE);
      expect(decoded.location === null).assertTrue();
      expect(decoded.textField?.timestamp).assertEqual(100);
      expect(decoded.textField?.siteId).assertEqual(7);
      expect(decoded.scalars.length).assertEqual(3);
      expect(decoded.scalars[1]).assertEqual(0x1F600);
      expect(decoded.scalars[2]).assertEqual(0x4E2D);
    });

    it('round-trips original Math state through CREATE_BLOCK', 0, () => {
      const math: MathElement = {
        id: 'op:65:7', type: ElementType.MATH,
        transform: [0, -3, 25, 2, 0, 40, 0, 0, 1],
        bounds: { left: -95, top: 40, right: 25, bottom: 120 },
        latex: '\\frac{a}{b}', color: 0x80112233 | 0,
        blockWidth: 40, blockHeight: 40, rotationRadians: Math.PI / 2,
        corner: 1, textWrap: 1, enableCaption: true, positionLocked: true,
      };
      const decoded = decodeOriginalCreateBlock(wrap(22,
        encodeOriginalLocalCreateMathBlock(
          { timestamp: 80, siteId: 7, index: 2 }, math)), '1234');
      expect(decoded.blockType).assertEqual(OriginalBlockType.MATH);
      expect(decoded.originX).assertEqual(25);
      expect(decoded.originY).assertEqual(40);
      expect(decoded.scaleX).assertEqual(2);
      expect(decoded.scaleY).assertEqual(3);
      expect(decoded.mathLatex).assertEqual('\\frac{a}{b}');
      expect(decoded.mathColor).assertEqual(0x80112233 | 0);
      expect(decoded.corner).assertEqual(1);
      expect(decoded.textWrap).assertEqual(1);
      expect(decoded.enableCaption).assertTrue();
      expect(decoded.positionLocked).assertTrue();
      expect(decoded.hasImage).assertFalse();
    });

    it('rejects state that needs unsupported style or affine fields', 0, () => {
      const styled: TextBlockElement = sampleText();
      styled.fontSize = 24;
      expect(() => encodeOriginalLocalCreateTextBlock(
        { timestamp: 80, siteId: 7, index: 2 }, styled)).assertThrow();
      const sheared: TextBlockElement = sampleText();
      sheared.transform[1] = 0.25;
      expect(() => encodeOriginalLocalCreateTextBlock(
        { timestamp: 80, siteId: 7, index: 2 }, sheared)).assertThrow();
      expect(() => encodeOriginalInitialInsertString(
        { timestamp: 100, siteId: 7 }, '')).assertThrow();
      expect(() => encodeOriginalInitialInsertString(
        { timestamp: 100, siteId: 7 }, '\uD800')).assertThrow();
      const invalidMath: MathElement = {
        id: 'op:65:7', type: ElementType.MATH,
        transform: [1, 0.25, 0, 0, 1, 0, 0, 0, 1],
        bounds: { left: 0, top: 0, right: 40, bottom: 20 },
        latex: 'x', color: -16777216, blockWidth: 40, blockHeight: 20,
        rotationRadians: 0, corner: 0, textWrap: 0,
        enableCaption: false, positionLocked: false,
      };
      expect(() => encodeOriginalLocalCreateMathBlock(
        { timestamp: 80, siteId: 7, index: 2 }, invalidMath)).assertThrow();
    });

    it('flushes CREATE_BLOCK and initial INSERT_STRING as one page revision', 0, async () => {
      let revisionUpdates: number = 0;
      const statements: string[] = [];
      const fakeStore = {
        update: async (): Promise<number> => {
          revisionUpdates++;
          return 1;
        },
        executeSql: async (sql: string): Promise<void> => {
          statements.push(sql);
        },
      } as relationalStore.RdbStore;
      const target = {
        page: { timestamp: 80, siteId: 7, index: 2 }, pageId: 'page',
        revisionTable: 'page_info', revision: 9, archived: false,
      };
      const batch: OriginalPageMutationBatch = new OriginalPageMutationBatch();
      batch.recordBlock(target, true);
      batch.recordBlock(target, true);
      await batch.flush(fakeStore, 'note');

      expect(revisionUpdates).assertEqual(1);
      expect(statements.length).assertEqual(2);
      expect(statements[0]).assertContain('search_page_state');
      expect(statements[1]).assertContain('search_item');
    });
  });
}

function sampleText(): TextBlockElement {
  return {
    id: 'op:64:7', type: ElementType.TEXT,
    transform: [1, 0, 25, 0, 1, 40, 0, 0, 1],
    bounds: { left: 25, top: 40, right: 225, bottom: 80 },
    richText: 'hello', characterStyleRuns: [], paragraphStyleRuns: [],
    textOrigin: { x: 0, y: 0 }, blockWidth: 200, blockHeight: 40,
    rotationRadians: 0, contentLeftInset: 5, contentTopInset: 3,
    fontSize: 17, fontColor: -16777216, corner: 0, textWrap: 0,
    enableCaption: false, paper: null, resizesWidthToFitText: false,
    positionLocked: false,
  };
}

function wrap(payloadType: number, payload: Uint8Array): Uint8Array {
  return encodeOriginalOperationEnvelope({
    identity: { timestamp: 100, siteId: 7 }, clientTime: '1234', serverTime: null,
    audioTime: null, payloadType: payloadType,
  }, payload);
}
