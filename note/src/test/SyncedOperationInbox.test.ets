import { describe, it, expect } from '@ohos/hypium';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import {
  compareIncomingSyncedOperationOrder, IncomingSyncedOperation, StoredSyncedOperation,
  SyncedOperationInboxState, validateIncomingSyncedBatch,
} from '../main/ets/data/SyncedOperationInbox';
import {
  crc32Signed, parseOriginalSyncedOperationEnvelope,
} from '../main/ets/data/OriginalSyncedOperationFlatBuffer';
import {
  DeferredSyncedOperationTableType, validateDeferredSyncedOperationTableType,
} from '../main/ets/data/DeferredSyncedOperationBundle';
import {
  decodeOriginalCreatePage, decodeOriginalCreatePageTable,
  ORIGINAL_DEFAULT_PAGE_HEIGHT_MM, ORIGINAL_DEFAULT_PAGE_WIDTH_MM,
} from '../main/ets/data/OriginalCreatePageOperation';
import {
  compareOriginalSequenceIdentity, encodeOriginalPageStorageId, encodeOriginalSequenceId,
} from '../main/ets/data/OperationIdentity';
import { decodeOriginalNoteBundle } from '../main/ets/data/OriginalNoteBundlePageIdentity';
import { decodeOriginalModifyPage } from '../main/ets/data/OriginalModifyPageOperation';
import { decodeOriginalDeleteEntities } from '../main/ets/data/OriginalDeleteEntitiesOperation';
import { OriginalPageOperationApplier } from '../main/ets/data/OriginalPageOperationApplier';
import { decodeOriginalCreateInk, decodeOriginalCreateInkTable,
  OriginalCreateInkOperationApplier, unsupportedOriginalCreateInkReason } from
  '../main/ets/data/OriginalCreateInkOperation';
import { decodeOriginalAddPathElements, decodeOriginalAddPathElementsTable,
  OriginalAddPathElementsOperationApplier } from
  '../main/ets/data/OriginalAddPathElementsOperation';
import { decodeOriginalModifyInk } from '../main/ets/data/OriginalModifyInkOperation';
import { decodeOriginalCreateBlock, OriginalBlockType, OriginalCreateBlockOperationApplier,
  unsupportedOriginalCreateBlockReason } from
  '../main/ets/data/OriginalCreateBlockOperation';
import { decodeOriginalModifyBlock } from '../main/ets/data/OriginalModifyBlockOperation';
import { decodeOriginalInsertText, decodeOriginalTextVisibility } from
  '../main/ets/data/OriginalInsertTextOperation';
import {
  decodeOriginalRichTextStyle, ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE,
  ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE, ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE,
} from '../main/ets/data/OriginalRichTextStyleOperation';
import { decodeOriginalAuxiliaryInkPath, originalInkTransform,
  transformedExpandedBounds } from '../main/ets/data/OriginalInkPathCodec';
import { decodeOriginalInkPath, decodeOriginalInkPathAppend } from
  '../main/ets/data/OriginalInkPathCodec';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';
import { InkPathCommandType } from '../main/ets/core/model/StrokeTypes';

function operation(timestamp: number, serverTime: string,
  clientTime: string = serverTime, payloadType: number = 3): IncomingSyncedOperation {
  return {
    noteId: 'note', timestamp: timestamp, siteId: 7, clientTime: clientTime,
    serverTime: serverTime, schemaVersion: 1, payloadType: payloadType,
    rawOperation: flatBufferOperation(timestamp, 7, clientTime, serverTime, payloadType),
  };
}

export default function syncedOperationInboxTest() {
  describe('SyncedOperationInbox', () => {
    it('orders full unsigned server and client times without number conversion', 0, () => {
      const first = operation(1, '9007199254740993', '18446744073709551614');
      const second = operation(2, '18446744073709551615', '0');
      expect(compareIncomingSyncedOperationOrder(first, second)).assertEqual(-1);
      validateIncomingSyncedBatch('note', [first, second]);
    });

    it('rejects out-of-order and repeated operation identities before persistence', 0, () => {
      const first = operation(1, '10');
      const second = operation(2, '9');
      let rejected: number = 0;
      try {
        validateIncomingSyncedBatch('note', [first, second]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [first, operation(1, '11')]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('parses the original little-endian uq9 root without losing uint64 values', 0, () => {
      const source: IncomingSyncedOperation = operation(
        0xFFFFFFFF, '18446744073709551615', '9007199254740993', 31);
      const parsed = parseOriginalSyncedOperationEnvelope(source.rawOperation);
      expect(parsed.timestamp).assertEqual(0xFFFFFFFF);
      expect(parsed.siteId).assertEqual(7);
      expect(parsed.clientTime).assertEqual('9007199254740993');
      expect(parsed.serverTime).assertEqual('18446744073709551615');
      expect(parsed.payloadType).assertEqual(31);
      expect(parsed.payloadTypeKnown).assertTrue();
    });

    it('rejects metadata substitution and malformed FlatBuffer roots', 0, () => {
      let rejected: number = 0;
      const valid: IncomingSyncedOperation = operation(1, '10');
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, serverTime: '11' }]);
      } catch (_error) {
        rejected++;
      }
      try {
        validateIncomingSyncedBatch('note', [{ ...valid, rawOperation: new Uint8Array([1, 2, 3]) }]);
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('uses standard signed CRC32 and the original deferred type allowlist', 0, () => {
      expect(crc32Signed(new Uint8Array([0x31, 0x32, 0x33, 0x34, 0x35,
        0x36, 0x37, 0x38, 0x39]))).assertEqual(-873187034);
      expect(validateDeferredSyncedOperationTableType('OPS_BUNDLE')).assertEqual(
        DeferredSyncedOperationTableType.OPS_BUNDLE);
      let rejected: boolean = false;
      try {
        validateDeferredSyncedOperationTableType('OPS');
      } catch (_error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('decodes original CREATE_PAGE inline SeqId and default-safe fields', 0, () => {
      const raw: Uint8Array = flatBufferCreatePage(9, 4, '11', '12',
        7, 3, 2, 2, false);
      const payload = decodeOriginalCreatePage(raw);
      expect(payload.location?.timestamp).assertEqual(7);
      expect(payload.location?.siteId).assertEqual(3);
      expect(payload.location?.index).assertEqual(2);
      expect(payload.pageCount).assertEqual(2);
      expect(payload.hasBackground).assertFalse();
      expect(payload.bookmarked).assertFalse();
      expect(ORIGINAL_DEFAULT_PAGE_WIDTH_MM).assertEqual(215.9);
      expect(ORIGINAL_DEFAULT_PAGE_HEIGHT_MM).assertEqual(279.4);
      const rootPayload = decodeOriginalCreatePage(flatBufferCreatePageBackground());
      expect(rootPayload.location === null).assertTrue();
      expect(rootPayload.hasBackground).assertTrue();
      expect(rootPayload.bookmarked).assertTrue();
      expect(rootPayload.background?.background.paper?.colorA).assertEqual(255);
    });

    it('keeps original SeqId comparison and note-scoped storage IDs', 0, () => {
      const older = { timestamp: 5, siteId: 2, index: 0 };
      const newer = { timestamp: 6, siteId: 1, index: 0 };
      expect(compareOriginalSequenceIdentity(older, newer)).assertEqual(-1);
      expect(compareOriginalSequenceIdentity({ timestamp: 5, siteId: 2, index: 1 }, older))
        .assertEqual(-1);
      expect(encodeOriginalSequenceId(older)).assertEqual('seq:5:2:0');
      expect(encodeOriginalPageStorageId('a', older)).assertEqual('original-page:1:a:seq:5:2:0');
    });

    it('decodes original MODIFY_PAGE page vector and nullable SeqMove target', 0, () => {
      const payload = decodeOriginalModifyPage(flatBufferModifyPage());
      expect(payload.pages.length).assertEqual(2);
      expect(payload.pages[0].timestamp).assertEqual(10);
      expect(payload.pages[0].siteId).assertEqual(1);
      expect(payload.pages[0].index).assertEqual(2);
      expect(payload.pages[1].timestamp).assertEqual(20);
      expect(payload.pages[1].siteId).assertEqual(3);
      expect(payload.pages[1].index).assertEqual(4);
      expect(payload.hasMove).assertTrue();
      expect(payload.moveTo?.timestamp).assertEqual(30);
      expect(payload.moveTo?.siteId).assertEqual(5);
      expect(payload.moveTo?.index).assertEqual(6);
      expect(payload.hasBackground).assertFalse();
      expect(payload.hasBookmarked).assertFalse();
      const applier = new OriginalPageOperationApplier();
      expect(applier.supports(3)).assertTrue();
      expect(applier.supports(4)).assertTrue();
      expect(applier.supports(25)).assertTrue();
      expect(applier.supports(15)).assertTrue();
      expect(applier.supports(16)).assertTrue();
      expect(applier.supports(17)).assertTrue();
      expect(applier.supports(22)).assertTrue();
      expect(applier.supports(23)).assertTrue();
      expect(applier.supports(7)).assertTrue();
      expect(applier.supports(8)).assertTrue();
      expect(applier.supports(9)).assertTrue();
      expect(applier.supports(10)).assertTrue();
      expect(applier.supports(11)).assertTrue();
      expect(applier.supports(ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(5)).assertFalse();
    });

    it('decodes original INSERT_CHAR and INSERT_STRING Unicode code points', 0, () => {
      const inserted = decodeOriginalInsertText(flatBufferInsertString(), 8);
      expect(inserted.location === null).assertTrue();
      expect(inserted.textField?.timestamp).assertEqual(20);
      expect(inserted.textField?.siteId).assertEqual(2);
      expect(inserted.scalars.length).assertEqual(3);
      expect(inserted.scalars[0]).assertEqual(0x41);
      expect(inserted.scalars[1]).assertEqual(0x4E2D);
      expect(inserted.scalars[2]).assertEqual(0x1F600);
      const character = decodeOriginalInsertText(flatBufferInsertChar(), 7);
      expect(character.location?.timestamp).assertEqual(100);
      expect(character.location?.siteId).assertEqual(7);
      expect(character.location?.index).assertEqual(1);
      expect(character.scalars[0]).assertEqual(0x1F642);
    });

    it('decodes original REMOVE_CHAR, REMOVE_CHARS and REVIVE_CHARS targets', 0, () => {
      const single = decodeOriginalTextVisibility(flatBufferTextVisibility(9, false), 9);
      expect(single.visible).assertFalse();
      expect(single.locations.length).assertEqual(1);
      expect(single.locations[0].timestamp).assertEqual(100);
      expect(single.locations[0].index).assertEqual(1);
      const removed = decodeOriginalTextVisibility(flatBufferTextVisibility(10, true), 10);
      expect(removed.visible).assertFalse();
      expect(removed.locations.length).assertEqual(2);
      expect(removed.locations[1].index).assertEqual(2);
      const revived = decodeOriginalTextVisibility(flatBufferTextVisibility(11, true), 11);
      expect(revived.visible).assertTrue();
      expect(revived.textField?.timestamp).assertEqual(20);
      expect(revived.textField?.siteId).assertEqual(2);
    });

    it('decodes original me8/he8/io1 rich-text style payloads', 0, () => {
      const character = decodeOriginalRichTextStyle(flatBufferModifyStyle(), 12);
      expect(character.paragraph).assertFalse();
      expect(character.start.location.timestamp).assertEqual(100);
      expect(character.end.type).assertEqual(1);
      expect(character.attributes.boldPresent).assertTrue();
      expect(character.attributes.bold).assertTrue();
      expect(character.attributes.highlightColorPresent).assertTrue();
      expect(character.attributes.highlightColor).assertEqual(0x80FFEE00 | 0);
      expect(character.attributes.fontSize).assertEqual(24);
      expect(character.attributes.foregroundColor).assertEqual(0xFF112233 | 0);
      const paragraph = decodeOriginalRichTextStyle(flatBufferParagraphStyle(), 13);
      expect(paragraph.paragraph).assertTrue();
      expect(paragraph.attributes.indentLevel).assertEqual(2);
      expect(paragraph.attributes.alignment).assertEqual(2);
      expect(paragraph.attributes.lineSpacing).assertEqual(1.5);
      expect(paragraph.attributes.decoratorStyle).assertEqual(1);
      expect(paragraph.attributes.programmingLanguage).assertEqual('swift');
      expect(paragraph.attributes.writingDirection).assertEqual(0);
      const clear = decodeOriginalRichTextStyle(flatBufferClearStyle(), 14);
      expect(clear.clearAll).assertTrue();
      expect(clear.paragraph).assertFalse();
      expect(clear.start.location.siteId).assertEqual(0xFFFF);
      expect(clear.end.type).assertEqual(3);
    });

    it('decodes original text CREATE_BLOCK common state', 0, () => {
      const payload = decodeOriginalCreateBlock(flatBufferCreateBlock(), '123');
      expect(payload.blockType).assertEqual(OriginalBlockType.TEXT);
      expect(payload.corner).assertEqual(1);
      expect(payload.page.timestamp).assertEqual(10);
      expect(payload.page.siteId).assertEqual(2);
      expect(payload.page.index).assertEqual(3);
      expect(payload.originX).assertEqual(12);
      expect(payload.originY).assertEqual(34);
      expect(Math.abs((payload.rotation as number) - Math.PI / 2) < 0.000001).assertTrue();
      expect(payload.scaleX).assertEqual(2);
      expect(payload.scaleY).assertEqual(3);
      expect(payload.width).assertEqual(200);
      expect(payload.height).assertEqual(40);
      expect(payload.textWrap).assertEqual(1);
      expect(payload.zIndex).assertEqual('18446744073709551615');
      expect(payload.margins.top).assertEqual(3);
      expect(payload.margins.bottom).assertEqual(10);
      expect(payload.margins.left).assertEqual(5);
      expect(payload.margins.right).assertEqual(5);
      expect(payload.hasImage).assertFalse();
      expect(payload.hasMathLatex).assertFalse();
      expect(payload.paper === null).assertTrue();
      expect(payload.positionLocked).assertTrue();
    });

    it('decodes original IMAGE CREATE_BLOCK asset metadata without uint64 loss', 0, () => {
      const payload = decodeOriginalCreateBlock(flatBufferCreateImageBlock(), '123');
      expect(payload.blockType).assertEqual(OriginalBlockType.IMAGE);
      expect(payload.image?.assetHash.bits.length).assertEqual(8);
      expect(payload.image?.assetHash.bits[0]).assertEqual('0');
      expect(payload.image?.assetHash.bits[2]).assertEqual('9007199254740993');
      expect(payload.image?.assetHash.bits[7]).assertEqual('18446744073709551615');
      expect(payload.image?.fileName).assertEqual('原版照片.png');
      expect(payload.image?.mimeType).assertEqual('image/png');
      expect(payload.image?.fileSize).assertEqual(4294967295);
      expect(payload.image?.width).assertEqual(4032);
      expect(payload.image?.height).assertEqual(3024);
      expect(payload.cropRect?.x).assertEqual(-5);
      expect(payload.cropRect?.y).assertEqual(2);
      expect(payload.cropRect?.width).assertEqual(100);
      expect(payload.cropRect?.height).assertEqual(50);
      expect(payload.webUrl).assertEqual('https://example.test/照片.png');
      expect(payload.imageFlippedHorizontally).assertTrue();
      expect(payload.imageFlippedVertically).assertTrue();
    });

    it('defers invalid cross-type IMAGE fields before touching page storage', 0, async () => {
      const operation: StoredSyncedOperation = {
        noteId: 'note', timestamp: 90, siteId: 7, clientTime: '123', serverTime: '124',
        schemaVersion: 1, payloadType: 22,
        rawOperation: flatBufferCreateImageBlock(OriginalBlockType.MATH),
        state: SyncedOperationInboxState.RECEIVED, deferredReason: null, receivedAt: 1,
      };
      const result = await new OriginalCreateBlockOperationApplier().apply(
        {} as relationalStore.RdbStore, operation);
      expect(result.deferredReason).assertEqual('CREATE_BLOCK_IMAGE_FIELDS_ON_MATH');
    });

    it('does not reject valid IMAGE or MATH type-specific CREATE fields', 0, () => {
      const image = decodeOriginalCreateBlock(flatBufferCreateImageBlock(), '123');
      const math = decodeOriginalCreateBlock(flatBufferCreateMathBlock(), '123');
      expect(unsupportedOriginalCreateBlockReason(image) === null).assertTrue();
      expect(unsupportedOriginalCreateBlockReason(math) === null).assertTrue();
    });

    it('decodes original MODIFY_BLOCK common registers', 0, () => {
      const payload = decodeOriginalModifyBlock(flatBufferModifyBlock());
      expect(payload.blocks.length).assertEqual(2);
      expect(payload.blocks[0].timestamp).assertEqual(20);
      expect(payload.blocks[1].siteId).assertEqual(3);
      expect(payload.corner).assertEqual(1);
      expect(payload.pageOrigin?.page.timestamp).assertEqual(10);
      expect(payload.pageOrigin?.originX).assertEqual(12);
      expect(payload.rotation.value).assertEqual(0.5);
      expect(payload.scale.value?.x).assertEqual(2);
      expect(payload.width).assertEqual(300);
      expect(payload.height).assertEqual(60);
      expect(payload.textWrap).assertEqual(1);
      expect(payload.enableCaption).assertTrue();
      expect(payload.zIndex).assertEqual('18446744073709551615');
      expect(payload.positionLocked).assertTrue();
      expect(payload.mathLatex.present).assertFalse();
      expect(payload.mathColor.present).assertFalse();
      const cleared = decodeOriginalModifyBlock(flatBufferModifyBlock(true));
      expect(cleared.rotation.present).assertTrue();
      expect(cleared.rotation.value === null).assertTrue();
      expect(cleared.scale.present).assertTrue();
      expect(cleared.scale.value === null).assertTrue();
    });

    it('decodes original MODIFY_BLOCK image crop and flip registers', 0, () => {
      const payload = decodeOriginalModifyBlock(flatBufferModifyImageBlock(false, false, true));
      expect(payload.blocks.length).assertEqual(1);
      expect(payload.cropRect.present).assertTrue();
      expect(payload.cropRect.value?.x).assertEqual(-5);
      expect(payload.cropRect.value?.y).assertEqual(2);
      expect(payload.cropRect.value?.width).assertEqual(100);
      expect(payload.cropRect.value?.height).assertEqual(50);
      expect(payload.imageFlippedHorizontally).assertFalse();
      expect(payload.imageFlippedVertically).assertTrue();
      expect(payload.mathLatex.present).assertFalse();
      expect(payload.mathColor.present).assertFalse();
      const cleared = decodeOriginalModifyBlock(flatBufferModifyImageBlock(true, true, false));
      expect(cleared.cropRect.present).assertTrue();
      expect(cleared.cropRect.value === null).assertTrue();
      expect(cleared.imageFlippedHorizontally).assertTrue();
      expect(cleared.imageFlippedVertically).assertFalse();
    });

    it('decodes original MATH CREATE and independent MODIFY registers', 0, () => {
      const created = decodeOriginalCreateBlock(flatBufferCreateMathBlock(), '123');
      expect(created.blockType).assertEqual(OriginalBlockType.MATH);
      expect(created.mathLatex).assertEqual('\\frac{a}{b}');
      expect(created.mathColor).assertEqual(0x80112233 | 0);
      expect(created.image === null).assertTrue();
      const modified = decodeOriginalModifyBlock(flatBufferModifyMathBlock(false, false));
      expect(modified.mathLatex.present).assertTrue();
      expect(modified.mathLatex.value).assertEqual('x^2+y^2');
      expect(modified.mathColor.present).assertTrue();
      expect(modified.mathColor.value).assertEqual(0xFF445566 | 0);
      const cleared = decodeOriginalModifyBlock(flatBufferModifyMathBlock(true, true));
      expect(cleared.mathLatex.present).assertTrue();
      expect(cleared.mathLatex.value === null).assertTrue();
      expect(cleared.mathColor.present).assertTrue();
      expect(cleared.mathColor.value === null).assertTrue();
    });

    it('decodes original CREATE_INK path attributes, transform and uint64 z-index', 0, () => {
      const payload = decodeOriginalCreateInk(flatBufferCreateInk(), '123');
      expect(payload.page.timestamp).assertEqual(10);
      expect(payload.page.siteId).assertEqual(1);
      expect(payload.page.index).assertEqual(2);
      expect(payload.originX).assertEqual(12);
      expect(payload.originY).assertEqual(34);
      expect(Math.abs(payload.rotation - Math.PI / 2) < 0.000001).assertTrue();
      expect(payload.scaleX).assertEqual(2);
      expect(payload.scaleY).assertEqual(3);
      expect(payload.tool).assertEqual(0);
      expect(payload.style).assertEqual(0);
      expect(payload.color).assertEqual(-2146823138);
      expect(payload.width).assertEqual(4);
      expect(payload.zIndex).assertEqual('18446744073709551615');
      expect(payload.path?.pathPoints.length).assertEqual(3);
      expect(payload.path?.cubicSegments.length).assertEqual(2);
      expect(payload.path?.pathPoints[0].position.x).assertEqual(1);
      expect(payload.path?.pathPoints[0].widthFactor).assertEqual(1);
      expect(payload.path?.pathPoints[1].position.x).assertEqual(6);
      expect(payload.path?.pathPoints[1].pressure).assertEqual(0.25);
      expect(Math.abs((payload.path?.pathPoints[1].altitudeAngleRadians as number) - Math.PI / 2) <
        0.000001).assertTrue();
      expect(Math.abs((payload.path?.pathPoints[1].azimuthUnitX as number)) < 0.000001).assertTrue();
      expect(Math.abs((payload.path?.pathPoints[1].azimuthUnitY as number) - 1) < 0.000001).assertTrue();
      expect(payload.path?.localBounds.left).assertEqual(1);
      expect(payload.path?.localBounds.top).assertEqual(-3);
      expect(payload.path?.localBounds.right).assertEqual(20);
      expect(payload.path?.localBounds.bottom).assertEqual(9);
      expect(payload.centerPathBytes?.length).assertEqual(64);
      const withAuxiliary = decodeOriginalCreateInk(flatBufferCreateInk(0, 0, true), '123');
      expect(withAuxiliary.customPath?.commands.length).assertEqual(5);
      expect(withAuxiliary.fillPath?.commands.length).assertEqual(5);
      expect(withAuxiliary.fillColor).assertEqual(-2146823138);
      const withStyleMap = decodeOriginalCreateInk(flatBufferCreateInk(0, 2, false, true), '123');
      expect(withStyleMap.styleMap.length).assertEqual(1);
      expect(withStyleMap.styleMap[0].backingPencilSeed).assertEqual(-123);
      expect(withStyleMap.styleMap[0].backingPencilReferencePoint.x).assertEqual(1.5);
      expect(withStyleMap.styleMap[0].backingPencilReferencePoint.y).assertEqual(-2.25);
      expect(withStyleMap.styleMap[0].backingDashPhase).assertEqual(7.5);
      expect(withStyleMap.styleMap[0].backingDashPeriod).assertEqual(30);
      const withLegacyNib = decodeOriginalCreateInk(
        flatBufferCreateInk(0, 2, false, false, true), '123');
      expect(withLegacyNib.nibAngle).assertEqual(65535);
      expect(withLegacyNib.nibFlatness).assertEqual(40000);
      const bounds = transformedExpandedBounds(payload.path?.localBounds as Rect2D, payload.width,
        originalInkTransform(payload.originX, payload.originY, payload.rotation,
          payload.scaleX, payload.scaleY));
      expect(Math.abs(bounds.left + 39) < 0.00001).assertTrue();
      expect(Math.abs(bounds.top - 20) < 0.00001).assertTrue();
      expect(Math.abs(bounds.right - 45) < 0.00001).assertTrue();
      expect(Math.abs(bounds.bottom - 90) < 0.00001).assertTrue();
      const unknownEnums = decodeOriginalCreateInk(flatBufferCreateInk(255, 255), '123');
      expect(unknownEnums.tool).assertEqual(0);
      expect(unknownEnums.style).assertEqual(0);
      const flipped = originalInkTransform(0, 0, 0, -2, 0);
      expect(flipped[0]).assertEqual(-2);
      expect(flipped[4]).assertEqual(0);
    });

    it('decodes original ADD_PATH_ELEMENTS target and keeps the raw quadratic hull', 0, () => {
      const payload = decodeOriginalAddPathElements(flatBufferAddPathElements());
      expect(payload.ink.timestamp).assertEqual(20);
      expect(payload.ink.siteId).assertEqual(2);
      expect(payload.centerPathEstimatedElements === null).assertTrue();
      const append = decodeOriginalInkPathAppend(
        payload.centerPathElements as Uint8Array, { x: 0, y: 0 });
      expect(append.pathPoints.length).assertEqual(1);
      expect(append.cubicSegments.length).assertEqual(1);
      expect(append.pathPoints[0].position.x).assertEqual(10);
      expect(append.localBounds.left).assertEqual(0);
      expect(append.localBounds.right).assertEqual(100);
      expect(append.localBounds.bottom).assertEqual(100);
      expect(append.attributed).assertTrue();
    });

    it('decodes original MODIFY_INK target vector and center-path field 8', 0, () => {
      const payload = decodeOriginalModifyInk(flatBufferModifyInk());
      expect(payload.inks.length).assertEqual(2);
      expect(payload.inks[0].timestamp).assertEqual(20);
      expect(payload.inks[0].siteId).assertEqual(2);
      expect(payload.inks[1].timestamp).assertEqual(21);
      expect(payload.inks[1].siteId).assertEqual(3);
      expect(payload.centerPath?.length).assertEqual(33);
      expect(payload.hasUnsupportedFields).assertFalse();
      const withRender = decodeOriginalModifyInk(flatBufferModifyInk(true));
      expect(withRender.style).assertEqual(2);
      expect(withRender.color).assertEqual(-2147417597);
      expect(withRender.width).assertEqual(5);
      expect(withRender.hasUnsupportedFields).assertFalse();
      const withRotation = decodeOriginalModifyInk(flatBufferModifyInk(false, true));
      expect(withRotation.rotation.present).assertTrue();
      expect(withRotation.rotation.value).assertEqual(0.5);
      expect(withRotation.hasUnsupportedFields).assertFalse();
      const withClear = decodeOriginalModifyInk(flatBufferModifyInk(false, false, true, true));
      expect(withClear.rotation.present).assertTrue();
      expect(withClear.rotation.value === null).assertTrue();
      expect(withClear.scale.present).assertTrue();
      expect(withClear.scale.value?.x).assertEqual(2);
      expect(withClear.scale.value?.y).assertEqual(3);
      const moved = decodeOriginalModifyInk(flatBufferModifyInk(false, false, false, false, 1));
      expect(moved.pageOrigin?.page.timestamp).assertEqual(30);
      expect(moved.pageOrigin?.page.siteId).assertEqual(4);
      expect(moved.pageOrigin?.page.index).assertEqual(5);
      expect(moved.pageOrigin?.originX).assertEqual(40);
      expect(moved.pageOrigin?.originY).assertEqual(50);
      const partial = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 2));
      expect(partial.pageOrigin === null).assertTrue();
      expect(partial.hasUnsupportedFields).assertFalse();
      const withZIndex = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 0, '18446744073709551615'));
      expect(withZIndex.zIndex).assertEqual('18446744073709551615');
      expect(withZIndex.hasUnsupportedFields).assertFalse();
      const withAuxiliary = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 0, null, 1));
      expect(withAuxiliary.customPath.present).assertTrue();
      expect(withAuxiliary.customPath.value?.length).assertEqual(72);
      expect(withAuxiliary.fillPath.present).assertTrue();
      expect(withAuxiliary.fillPath.value?.length).assertEqual(72);
      expect(withAuxiliary.fillColor.present).assertTrue();
      expect(withAuxiliary.fillColor.value).assertEqual(-2146823138);
      expect(withAuxiliary.hasUnsupportedFields).assertFalse();
      const clearedAuxiliary = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 0, null, 2));
      expect(clearedAuxiliary.customPath.present).assertTrue();
      expect(clearedAuxiliary.customPath.value?.length).assertEqual(0);
      expect(clearedAuxiliary.fillPath.present).assertTrue();
      expect(clearedAuxiliary.fillPath.value?.length).assertEqual(0);
      expect(clearedAuxiliary.fillColor.present).assertTrue();
      expect(clearedAuxiliary.fillColor.value === null).assertTrue();
      const withStyleMap = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 0, null, 0, true));
      expect(withStyleMap.styleMap.present).assertTrue();
      expect(withStyleMap.styleMap.value?.length).assertEqual(20);
      expect(withStyleMap.hasUnsupportedFields).assertFalse();
      const withLegacyNib = decodeOriginalModifyInk(
        flatBufferModifyInk(false, false, false, false, 0, null, 0, false, true));
      expect(withLegacyNib.nibAngle).assertEqual(65535);
      expect(withLegacyNib.nibFlatness).assertEqual(40000);
      expect(withLegacyNib.hasUnsupportedFields).assertFalse();
    });

    it('preserves original auxiliary path verbs and multiple components', 0, () => {
      const decoded = decodeOriginalAuxiliaryInkPath(auxiliaryInkPath(), 'TEST_AUXILIARY_PATH');
      expect(decoded.commands.length).assertEqual(5);
      expect(decoded.commands[0].type).assertEqual(InkPathCommandType.MOVE_TO);
      expect(decoded.commands[1].type).assertEqual(InkPathCommandType.LINE_TO);
      expect(decoded.commands[2].type).assertEqual(InkPathCommandType.QUADRATIC);
      expect(decoded.commands[3].type).assertEqual(InkPathCommandType.CUBIC);
      expect(decoded.commands[4].type).assertEqual(InkPathCommandType.MOVE_TO);
      expect(decoded.commands[2].points.length).assertEqual(2);
      expect(decoded.commands[3].points.length).assertEqual(3);
      expect(decoded.localBounds?.left).assertEqual(-5);
      expect(decoded.localBounds?.top).assertEqual(-6);
      expect(decoded.localBounds?.right).assertEqual(11);
      expect(decoded.localBounds?.bottom).assertEqual(12);
    });

    it('decodes the original big-endian half-float coordinate path variant', 0, () => {
      const path = decodeOriginalInkPath(new Uint8Array([
        0, 0, 2,
        3, 0x3C, 0, 0x40, 0, 0x3C, 0, 0x38, 0, 0, 0,
        2, 0x42, 0, 0x44, 0, 0x3C, 0, 0x38, 0, 255, 64,
      ]));
      expect(path.pathPoints.length).assertEqual(2);
      expect(path.pathPoints[0].position.x).assertEqual(1);
      expect(path.pathPoints[0].position.y).assertEqual(2);
      expect(path.pathPoints[1].position.x).assertEqual(3);
      expect(path.pathPoints[1].position.y).assertEqual(4);
    });

    it('decodes background-only MODIFY_PAGE and preserves an explicit null setter', 0, () => {
      const payload = decodeOriginalModifyPage(flatBufferModifyPageBackground(true));
      expect(payload.pages.length).assertEqual(1);
      expect(payload.hasMove).assertFalse();
      expect(payload.hasBackground).assertTrue();
      expect(payload.background?.background.paper?.flair).assertEqual(2);
      expect(payload.background?.background.paper?.flairSpacingPt).assertEqual(18);
      expect(payload.background?.background.paper?.colorR).assertEqual(244);
      expect(payload.background?.background.paper?.colorA).assertEqual(255);
      expect(payload.background?.widthMm).assertEqual(215.9);
      expect(payload.background?.heightMm).assertEqual(279.4);
      const clear = decodeOriginalModifyPage(flatBufferModifyPageBackground(false));
      expect(clear.hasBackground).assertTrue();
      expect(clear.background === null).assertTrue();
    });

    it('decodes original DELETE_ENTITIES page tombstones independently from entities', 0, () => {
      const payload = decodeOriginalDeleteEntities(flatBufferDeleteEntities());
      expect(payload.entityDeleteCount).assertEqual(1);
      expect(payload.entityUndeleteCount).assertEqual(1);
      expect(payload.pageDeletes.length).assertEqual(2);
      expect(payload.pageDeletes[0].timestamp).assertEqual(10);
      expect(payload.pageDeletes[0].siteId).assertEqual(1);
      expect(payload.pageDeletes[0].index).assertEqual(2);
      expect(payload.pageUndeletes.length).assertEqual(1);
      expect(payload.pageUndeletes[0].timestamp).assertEqual(20);
      expect(payload.pageUndeletes[0].siteId).assertEqual(3);
      expect(payload.pageUndeletes[0].index).assertEqual(4);
    });

    it('decodes original NOTE_BUNDLE metadata and nested operation tables', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundle());
      expect(bundle.noteId).assertEqual('00112233-4455-6677-8899-aabbccddeeff');
      expect(bundle.editorSiteId).assertEqual(9);
      expect(bundle.schemaVersion).assertEqual(7);
      expect(bundle.operations.length).assertEqual(2);
      expect(bundle.operations[0].timestamp).assertEqual(10);
      expect(bundle.operations[0].siteId).assertEqual(1);
      expect(bundle.operations[0].payloadType).assertEqual(3);
      expect(bundle.operations[0].clientTime).assertEqual('11');
      expect(bundle.operations[0].serverTime).assertEqual('12');
      const child = decodeOriginalCreatePageTable(bundle.operations[1].payload);
      expect(child.location?.timestamp).assertEqual(10);
      expect(child.location?.siteId).assertEqual(1);
      expect(child.location?.index).assertEqual(0);
      expect(child.pageCount).assertEqual(1);
    });

    it('decodes and preflights CREATE_INK directly from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundleWithCreateInk());
      expect(bundle.operations.length).assertEqual(2);
      expect(bundle.operations[1].payloadType).assertEqual(15);
      const ink = decodeOriginalCreateInkTable(bundle.operations[1].payload,
        bundle.operations[1].clientTime);
      expect(ink.page.timestamp).assertEqual(10);
      expect(ink.page.siteId).assertEqual(1);
      expect(ink.path?.pathPoints.length).assertEqual(3);
      expect(ink.zIndex).assertEqual('18446744073709551615');
      expect(unsupportedOriginalCreateInkReason(ink) === null).assertTrue();
      expect(new OriginalCreateInkOperationApplier().preflightTable(
        bundle.operations[1].payload, bundle.operations[1].clientTime) === null).assertTrue();
    });

    it('decodes and preflights ADD_PATH_ELEMENTS from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundleWithCreateInk(true));
      expect(bundle.operations.length).assertEqual(3);
      expect(bundle.operations[2].payloadType).assertEqual(16);
      const add = decodeOriginalAddPathElementsTable(bundle.operations[2].payload);
      expect(add.ink.timestamp).assertEqual(20);
      expect(add.ink.siteId).assertEqual(2);
      expect((add.centerPathElements as Uint8Array).length > 3).assertTrue();
      expect(new OriginalAddPathElementsOperationApplier().preflightTable(
        bundle.operations[2].payload) === null).assertTrue();
    });
  });
}

function flatBufferNoteBundle(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(260);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 20);
  writeU16(bytes, 6, 40);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 0);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 14, 24);
  writeU16(bytes, 16, 0);
  writeU16(bytes, 18, 28);
  writeU16(bytes, 20, 32);
  writeU16(bytes, 22, 36);
  writeU32(bytes, 24, 20);
  const uuid: number[] = [0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88,
    0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00];
  for (let index: number = 0; index < uuid.length; index++) {
    bytes[28 + index] = uuid[index];
  }
  writeU16(bytes, 44, 9);
  writeU32(bytes, 48, 20);
  writeU32(bytes, 52, 24);
  writeU32(bytes, 56, 28);
  writeU16(bytes, 60, 7);
  writeU32(bytes, 68, 1);
  bytes[72] = 0x65;
  writeU32(bytes, 76, 1);
  bytes[80] = 0x63;
  writeU32(bytes, 84, 2);
  writeU32(bytes, 88, 28);
  writeU32(bytes, 92, 80);
  writeNoteBundleOperation(bytes, 96, 116, 1, 10, '11', '12', 220);
  writeNoteBundleOperation(bytes, 152, 172, 2, 20, '21', '22', 240);
  writeU16(bytes, 208, 10);
  writeU16(bytes, 210, 8);
  writeU16(bytes, 212, 0);
  writeU16(bytes, 214, 0);
  writeU16(bytes, 216, 4);
  writeU32(bytes, 220, 12);
  writeU32(bytes, 224, 1);
  writeU16(bytes, 228, 10);
  writeU16(bytes, 230, 20);
  writeU16(bytes, 232, 4);
  writeU16(bytes, 234, 0);
  writeU16(bytes, 236, 16);
  writeU32(bytes, 240, 12);
  writeU16(bytes, 244, 1);
  writeU32(bytes, 248, 10);
  writeU32(bytes, 252, 0);
  writeU32(bytes, 256, 1);
  return bytes;
}

function flatBufferNoteBundleWithCreateInk(includeAppend: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 0, 20, 24, 0, 28, 32, 36], 40);
  const uuid: number[] = [0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88,
    0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00];
  builder.color(root + 4, uuid);
  builder.uint16(root + 20, 9);
  builder.uint16(root + 36, 7);
  const operations: number = builder.tableVector(includeAppend ? 3 : 2);
  builder.pointer(root + 32, operations);
  const createPageOp: number = builder.table([4, 12, 20, 0, 28, 32, 0], 36);
  const createInkOp: number = builder.table([4, 12, 20, 0, 28, 32, 0], 36);
  const appendOp: number = includeAppend ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  builder.pointer(operations + 4, createPageOp);
  builder.pointer(operations + 8, createInkOp);
  if (includeAppend) {
    builder.pointer(operations + 12, appendOp);
  }
  writeBundleOperation(builder, createPageOp, 1, 10, '11', '12', 3);
  writeBundleOperation(builder, createInkOp, 2, 20, '21', '22', 15);
  if (includeAppend) {
    writeBundleOperation(builder, appendOp, 3, 30, '31', '32', 16);
  }

  const createPage: number = builder.table([0, 0, 4, 0], 8);
  builder.uint32(createPage + 4, 1);
  builder.pointer(createPageOp + 32, createPage);
  const ink: number = builder.table([
    4, 16, 24, 28, 36, 37, 0, 40, 44, 48, 0, 0, 0, 0, 52,
  ], 60);
  builder.pointer(createInkOp + 32, ink);
  builder.inlineSequence(ink + 4, 10, 1, 0);
  builder.float32(ink + 16, 12);
  builder.float32(ink + 20, 34);
  builder.float32(ink + 24, Math.PI / 2);
  builder.float32(ink + 28, 2);
  builder.float32(ink + 32, 3);
  builder.uint8(ink + 36, 0);
  builder.uint8(ink + 37, 0);
  builder.color(ink + 40, [10, 20, 30, 128]);
  builder.float32(ink + 44, 4);
  writeDecimalU64At(builder, ink + 52, '18446744073709551615');
  const path: number[] = [1, 0, 3];
  appendAttributedPathElement(path, 3, [{ x: 1, y: 2 }], 0x3C00, 0x3800, 0, 0);
  appendAttributedPathElement(path, 0,
    [{ x: 20, y: -3 }, { x: 4, y: 5 }, { x: 6, y: 7 }], 0x3800, 0x3400, 255, 64);
  appendAttributedPathElement(path, 2, [{ x: 8, y: 9 }], 0x3C00, 0x3800, 128, 128);
  builder.pointer(ink + 48, builder.byteVector(path));
  if (includeAppend) {
    const add: number = builder.table([4, 12, 0], 16);
    builder.pointer(appendOp + 32, add);
    builder.uint16(add + 4, 2);
    builder.uint32(add + 8, 20);
    const appended: number[] = [1, 0, 1];
    appendAttributedPathElement(appended, 1,
      [{ x: 100, y: 100 }, { x: 10, y: 0 }], 0x3C00, 0x3800, 255, 0);
    builder.pointer(add + 12, builder.byteVector(appended));
  }
  builder.pointer(root + 24, builder.byteVector([0x65]));
  builder.pointer(root + 28, builder.byteVector([0x63]));
  return builder.finish(root);
}

function writeBundleOperation(builder: FixtureFlatBufferBuilder, table: number,
  siteId: number, timestamp: number, clientTime: string, serverTime: string,
  payloadType: number): void {
  builder.uint16(table + 4, siteId);
  builder.uint32(table + 8, timestamp);
  writeDecimalU64At(builder, table + 12, clientTime);
  writeDecimalU64At(builder, table + 20, serverTime);
  builder.uint8(table + 28, payloadType);
}

function writeNoteBundleOperation(bytes: Uint8Array, vtable: number, table: number,
  siteId: number, timestamp: number, clientTime: string, serverTime: string,
  payloadTable: number): void {
  writeU16(bytes, vtable, 18);
  writeU16(bytes, vtable + 2, 36);
  writeU16(bytes, vtable + 4, 4);
  writeU16(bytes, vtable + 6, 12);
  writeU16(bytes, vtable + 8, 20);
  writeU16(bytes, vtable + 10, 0);
  writeU16(bytes, vtable + 12, 28);
  writeU16(bytes, vtable + 14, 32);
  writeU16(bytes, vtable + 16, 0);
  writeU32(bytes, table, table - vtable);
  writeU16(bytes, table + 4, siteId);
  writeU32(bytes, table + 8, timestamp);
  writeDecimalU64(bytes, table + 12, clientTime);
  writeDecimalU64(bytes, table + 20, serverTime);
  bytes[table + 28] = 3;
  writeU32(bytes, table + 32, payloadTable - (table + 32));
}

function flatBufferCreatePage(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, locationTimestamp: number, locationSite: number,
  locationIndex: number, pageCount: number, bookmarked: boolean,
  hasLocation: boolean = true, hasBackground: boolean = false): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(96);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = 3;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 24);
  writeU16(bytes, 64, hasLocation ? 4 : 0);
  writeU16(bytes, 66, hasBackground ? 4 : 0);
  writeU16(bytes, 68, 16);
  writeU16(bytes, 70, 20);
  writeU32(bytes, 72, 12);
  writeU16(bytes, 76, locationSite);
  writeU32(bytes, 80, locationTimestamp);
  writeU32(bytes, 84, locationIndex);
  writeU32(bytes, 88, pageCount);
  bytes[92] = bookmarked ? 1 : 0;
  return bytes;
}

function flatBufferModifyPage(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(156);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, 7);
  writeU32(bytes, 32, 40);
  writeDecimalU64(bytes, 36, '41');
  writeDecimalU64(bytes, 44, '42');
  bytes[52] = 4;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 12);
  writeU16(bytes, 64, 4);
  writeU16(bytes, 66, 8);
  writeU32(bytes, 72, 12);
  writeU32(bytes, 76, 28);
  writeU32(bytes, 80, 60);

  writeU32(bytes, 104, 2);
  writeU16(bytes, 108, 1);
  writeU32(bytes, 112, 10);
  writeU32(bytes, 116, 2);
  writeU16(bytes, 120, 3);
  writeU32(bytes, 124, 20);
  writeU32(bytes, 128, 4);

  writeU16(bytes, 132, 6);
  writeU16(bytes, 134, 16);
  writeU16(bytes, 136, 4);
  writeU32(bytes, 140, 8);
  writeU16(bytes, 144, 5);
  writeU32(bytes, 148, 30);
  writeU32(bytes, 152, 6);
  return bytes;
}

class FixtureFlatBufferBuilder {
  private bytes: Uint8Array = new Uint8Array(512);
  private cursor: number = 4;

  table(offsets: number[], objectSize: number): number {
    const vtable: number = this.cursor;
    const vtableSize: number = 4 + offsets.length * 2;
    this.cursor += vtableSize;
    this.align(4);
    const table: number = this.cursor;
    this.cursor += objectSize;
    writeU16(this.bytes, vtable, vtableSize);
    writeU16(this.bytes, vtable + 2, objectSize);
    for (let index: number = 0; index < offsets.length; index++) {
      writeU16(this.bytes, vtable + 4 + index * 2, offsets[index]);
    }
    writeU32(this.bytes, table, table - vtable);
    return table;
  }

  sequenceVector(timestamp: number, siteId: number, index: number): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 16;
    writeU32(this.bytes, vector, 1);
    writeU16(this.bytes, vector + 4, siteId);
    writeU32(this.bytes, vector + 8, timestamp);
    writeU32(this.bytes, vector + 12, index);
    return vector;
  }

  tableVector(count: number): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + count * 4;
    writeU32(this.bytes, vector, count);
    return vector;
  }

  sequenceIdentityVector(values: { timestamp: number, siteId: number, index: number }[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length * 12;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      writeU16(this.bytes, vector + 4 + index * 12, values[index].siteId);
      writeU32(this.bytes, vector + 8 + index * 12, values[index].timestamp);
      writeU32(this.bytes, vector + 12 + index * 12, values[index].index);
    }
    return vector;
  }

  operationIdentityVector(values: { timestamp: number, siteId: number }[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length * 8;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      writeU16(this.bytes, vector + 4 + index * 8, values[index].siteId);
      writeU32(this.bytes, vector + 8 + index * 8, values[index].timestamp);
    }
    return vector;
  }

  byteVector(values: number[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length + 1;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      this.bytes[vector + 4 + index] = values[index];
    }
    this.bytes[vector + 4 + values.length] = 0;
    return vector;
  }

  string(value: string): number {
    const encoded: Uint8Array = new util.TextEncoder().encode(value);
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 5 + encoded.length;
    writeU32(this.bytes, vector, encoded.length);
    for (let index: number = 0; index < encoded.length; index++) {
      this.bytes[vector + 4 + index] = encoded[index];
    }
    return vector;
  }

  styleMapVector(includeValue: boolean): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += includeValue ? 24 : 4;
    writeU32(this.bytes, vector, includeValue ? 1 : 0);
    if (includeValue) {
      writeU32(this.bytes, vector + 4, -123);
      this.float32(vector + 8, 1.5);
      this.float32(vector + 12, -2.25);
      this.float32(vector + 16, 7.5);
      this.float32(vector + 20, 30);
    }
    return vector;
  }

  pointer(slot: number, target: number): void {
    writeU32(this.bytes, slot, target - slot);
  }

  uint8(offset: number, value: number): void {
    this.bytes[offset] = value;
  }

  uint16(offset: number, value: number): void {
    writeU16(this.bytes, offset, value);
  }

  uint32(offset: number, value: number): void {
    writeU32(this.bytes, offset, value);
  }

  float32(offset: number, value: number): void {
    const source: Uint8Array = new Uint8Array(new Float32Array([value]).buffer);
    for (let index: number = 0; index < 4; index++) {
      this.bytes[offset + index] = source[index];
    }
  }

  color(offset: number, values: number[]): void {
    for (let index: number = 0; index < values.length; index++) {
      this.bytes[offset + index] = values[index];
    }
  }

  inlineSequence(offset: number, timestamp: number, siteId: number, index: number): void {
    writeU16(this.bytes, offset, siteId);
    writeU32(this.bytes, offset + 4, timestamp);
    writeU32(this.bytes, offset + 8, index);
  }

  inlineBoundary(offset: number, timestamp: number, siteId: number, index: number,
    type: number): void {
    this.inlineSequence(offset, timestamp, siteId, index);
    this.bytes[offset + 12] = type;
  }

  inlineIdentity(offset: number, timestamp: number, siteId: number): void {
    writeU16(this.bytes, offset, siteId);
    writeU32(this.bytes, offset + 4, timestamp);
  }

  finish(root: number): Uint8Array {
    writeU32(this.bytes, 0, root);
    return this.bytes.slice(0, this.cursor);
  }

  private align(value: number): void {
    while ((this.cursor & (value - 1)) !== 0) {
      this.cursor++;
    }
  }
}

function styleEnvelope(payloadType: number, root: number, payload: number,
  builder: FixtureFlatBufferBuilder): Uint8Array {
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 300 + payloadType);
  writeDecimalU64At(builder, root + 12, '1');
  writeDecimalU64At(builder, root + 20, '1');
  builder.uint8(root + 28, payloadType);
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function boolWrapper(builder: FixtureFlatBufferBuilder, value: boolean | null): number {
  const wrapper: number = builder.table([value === null ? 0 : 4], 8);
  if (value !== null) {
    builder.uint8(wrapper + 4, value ? 1 : 0);
  }
  return wrapper;
}

function floatWrapper(builder: FixtureFlatBufferBuilder, value: number | null): number {
  const wrapper: number = builder.table([value === null ? 0 : 4], 8);
  if (value !== null) {
    builder.float32(wrapper + 4, value);
  }
  return wrapper;
}

function colorWrapper(builder: FixtureFlatBufferBuilder, value: number[]): number {
  const wrapper: number = builder.table([4], 8);
  builder.color(wrapper + 4, value);
  return wrapper;
}

function enumWrapper(builder: FixtureFlatBufferBuilder, value: number): number {
  const wrapper: number = builder.table([4], 8);
  builder.uint8(wrapper + 4, value);
  return wrapper;
}

function stringWrapper(builder: FixtureFlatBufferBuilder, value: string): number {
  const wrapper: number = builder.table([4], 8);
  builder.pointer(wrapper + 4, builder.string(value));
  return wrapper;
}

function flatBufferModifyStyle(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  const payload: number = builder.table([4, 20, 36, 44, 0, 0, 48, 0, 52, 56,
    0, 0, 0, 0, 0], 60);
  builder.inlineBoundary(payload + 4, 100, 7, 0, 0);
  builder.inlineBoundary(payload + 20, 100, 7, 2, 1);
  builder.inlineIdentity(payload + 36, 20, 2);
  builder.pointer(payload + 44, boolWrapper(builder, true));
  builder.pointer(payload + 48, colorWrapper(builder, [255, 238, 0, 128]));
  builder.pointer(payload + 52, floatWrapper(builder, 24));
  builder.pointer(payload + 56, colorWrapper(builder, [17, 34, 51, 255]));
  return styleEnvelope(12, root, payload, builder);
}

function flatBufferParagraphStyle(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  const payload: number = builder.table([4, 16, 28, 32, 36, 40, 0, 44, 52, 56], 60);
  builder.inlineSequence(payload + 4, 100, 7, 0);
  builder.inlineSequence(payload + 16, 100, 7, 2);
  builder.pointer(payload + 28, enumWrapper(builder, 2));
  builder.pointer(payload + 32, enumWrapper(builder, 2));
  builder.pointer(payload + 36, floatWrapper(builder, 1.5));
  builder.pointer(payload + 40, enumWrapper(builder, 1));
  builder.inlineIdentity(payload + 44, 20, 2);
  builder.pointer(payload + 52, stringWrapper(builder, 'swift'));
  builder.pointer(payload + 56, enumWrapper(builder, 0));
  return styleEnvelope(13, root, payload, builder);
}

function flatBufferClearStyle(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  const payload: number = builder.table([4, 20, 36, 40], 48);
  builder.inlineBoundary(payload + 4, 0, 0xFFFF, 0, 0);
  builder.inlineBoundary(payload + 20, 0, 0xFFFF, 0, 3);
  builder.uint8(payload + 36, 0);
  builder.inlineIdentity(payload + 40, 20, 2);
  return styleEnvelope(14, root, payload, builder);
}

function flatBufferCreateInk(tool: number = 0, style: number = 0,
  includeAuxiliary: boolean = false, includeStyleMap: boolean = false,
  includeLegacyNib: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 15);
  const fields: number[] = [4, 16, 24, 28, 36, 37, 0, 40, 44, 48,
    includeAuxiliary ? 52 : 0, includeAuxiliary ? 56 : 0, includeAuxiliary ? 60 : 0,
    includeStyleMap ? 68 : 0, 64, 0,
    includeLegacyNib ? 72 : 0, includeLegacyNib ? 74 : 0, 0, 0, 0];
  const ink: number = builder.table(fields, 76);
  builder.pointer(root + 32, ink);
  builder.uint16(ink + 4, 1);
  builder.uint32(ink + 8, 10);
  builder.uint32(ink + 12, 2);
  builder.float32(ink + 16, 12);
  builder.float32(ink + 20, 34);
  builder.float32(ink + 24, Math.PI / 2);
  builder.float32(ink + 28, 2);
  builder.float32(ink + 32, 3);
  builder.uint8(ink + 36, tool);
  builder.uint8(ink + 37, style);
  builder.color(ink + 40, [10, 20, 30, 128]);
  builder.float32(ink + 44, 4);
  writeDecimalU64At(builder, ink + 64, '18446744073709551615');
  const path: number[] = [1, 0, 3];
  appendAttributedPathElement(path, 3, [{ x: 1, y: 2 }], 0x3C00, 0x3800, 0, 0);
  appendAttributedPathElement(path, 0,
    [{ x: 20, y: -3 }, { x: 4, y: 5 }, { x: 6, y: 7 }], 0x3800, 0x3400, 255, 64);
  appendAttributedPathElement(path, 2, [{ x: 8, y: 9 }], 0x3C00, 0x3800, 128, 128);
  const vector: number = builder.byteVector(path);
  builder.pointer(ink + 48, vector);
  if (includeAuxiliary) {
    const auxiliary: number[] = Array.from(auxiliaryInkPath());
    const customPath: number = builder.byteVector(auxiliary);
    builder.pointer(ink + 52, customPath);
    const fillPath: number = builder.byteVector(auxiliary);
    builder.pointer(ink + 56, fillPath);
    builder.color(ink + 60, [10, 20, 30, 128]);
  }
  if (includeStyleMap) {
    builder.pointer(ink + 68, builder.styleMapVector(true));
  }
  if (includeLegacyNib) {
    builder.uint16(ink + 72, 65535);
    builder.uint16(ink + 74, 40000);
  }
  return builder.finish(root);
}

function flatBufferCreateBlock(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 22);
  const block: number = builder.table([
    4, 5, 8, 20, 28, 32, 40, 48, 0, 56,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 80,
  ], 84);
  builder.pointer(root + 32, block);
  builder.uint8(block + 4, 0);
  builder.uint8(block + 5, 1);
  builder.uint16(block + 8, 2);
  builder.uint32(block + 12, 10);
  builder.uint32(block + 16, 3);
  builder.float32(block + 20, 12);
  builder.float32(block + 24, 34);
  builder.float32(block + 28, Math.PI / 2);
  builder.float32(block + 32, 2);
  builder.float32(block + 36, 3);
  builder.float32(block + 40, 200);
  builder.float32(block + 44, 40);
  builder.uint8(block + 48, 1);
  writeDecimalU64At(builder, block + 56, '18446744073709551615');
  builder.float32(block + 64, 3);
  builder.float32(block + 68, 10);
  builder.float32(block + 72, 5);
  builder.float32(block + 76, 5);
  builder.uint8(block + 80, 1);
  return builder.finish(root);
}

function flatBufferCreateImageBlock(blockType: OriginalBlockType = OriginalBlockType.IMAGE): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 22);
  const block: number = builder.table([
    4, 0, 8, 20, 0, 0, 28, 0, 0, 36,
    44, 48, 64, 0, 0, 0, 68, 69, 0, 0, 0,
  ], 72);
  builder.pointer(root + 32, block);
  builder.uint8(block + 4, blockType);
  builder.uint16(block + 8, 2);
  builder.uint32(block + 12, 10);
  builder.uint32(block + 16, 3);
  builder.float32(block + 20, 12);
  builder.float32(block + 24, 34);
  builder.float32(block + 28, 200);
  builder.float32(block + 32, 150);
  writeDecimalU64At(builder, block + 36, '18446744073709551615');
  builder.float32(block + 48, -5);
  builder.float32(block + 52, 2);
  builder.float32(block + 56, 100);
  builder.float32(block + 60, 50);
  builder.uint8(block + 68, 1);
  builder.uint8(block + 69, 1);

  const asset: number = builder.table([4, 8], 16);
  builder.pointer(block + 44, asset);
  builder.float32(asset + 8, 4032);
  builder.float32(asset + 12, 3024);
  const metadata: number = builder.table([8, 72, 76, 80], 84);
  builder.pointer(asset + 4, metadata);
  const hashBits: string[] = ['0', '1', '9007199254740993', '18446744073709551614',
    '42', '4294967296', '9223372036854775808', '18446744073709551615'];
  for (let index: number = 0; index < hashBits.length; index++) {
    writeDecimalU64At(builder, metadata + 8 + index * 8, hashBits[index]);
  }
  builder.uint32(metadata + 80, 0xFFFFFFFF);
  const fileName: number = builder.string('原版照片.png');
  builder.pointer(metadata + 72, fileName);
  const mimeType: number = builder.string('image/png');
  builder.pointer(metadata + 76, mimeType);
  const webUrl: number = builder.string('https://example.test/照片.png');
  builder.pointer(block + 64, webUrl);
  return builder.finish(root);
}

function flatBufferCreateMathBlock(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 93);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 22);
  const block: number = builder.table([
    4, 0, 8, 20, 0, 0, 28, 0, 0, 36,
    0, 0, 0, 44, 48, 0, 0, 0, 0, 0, 0,
  ], 52);
  builder.pointer(root + 32, block);
  builder.uint8(block + 4, OriginalBlockType.MATH);
  builder.uint16(block + 8, 2);
  builder.uint32(block + 12, 10);
  builder.uint32(block + 16, 3);
  builder.float32(block + 20, 12);
  builder.float32(block + 24, 34);
  builder.float32(block + 28, 200);
  builder.float32(block + 32, 80);
  writeDecimalU64At(builder, block + 36, '17');
  builder.color(block + 48, [0x11, 0x22, 0x33, 0x80]);
  builder.pointer(block + 44, builder.string('\\frac{a}{b}'));
  return builder.finish(root);
}

function flatBufferModifyBlock(clearTransform: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 91);
  writeDecimalU64At(builder, root + 12, '125');
  writeDecimalU64At(builder, root + 20, '126');
  builder.uint8(root + 28, 23);
  const modify: number = builder.table([
    4, 8, 12, 24, 32, 36, 40, 48, 49, 56,
    0, 0, 0, 0, 0, 0, 0, 64,
  ], 68);
  builder.pointer(root + 32, modify);
  builder.uint8(modify + 8, 1);
  builder.uint16(modify + 12, 2);
  builder.uint32(modify + 16, 10);
  builder.uint32(modify + 20, 3);
  builder.float32(modify + 24, 12);
  builder.float32(modify + 28, 34);
  builder.float32(modify + 40, 300);
  builder.float32(modify + 44, 60);
  builder.uint8(modify + 48, 1);
  builder.uint8(modify + 49, 1);
  writeDecimalU64At(builder, modify + 56, '18446744073709551615');
  builder.uint8(modify + 64, 1);
  const rotation: number = builder.table([clearTransform ? 0 : 4], 8);
  if (!clearTransform) {
    builder.float32(rotation + 4, 0.5);
  }
  builder.pointer(modify + 32, rotation);
  const scale: number = builder.table([clearTransform ? 0 : 4], 12);
  if (!clearTransform) {
    builder.float32(scale + 4, 2);
    builder.float32(scale + 8, 3);
  }
  builder.pointer(modify + 36, scale);
  const blocks: number = builder.operationIdentityVector([
    { timestamp: 20, siteId: 2 }, { timestamp: 21, siteId: 3 },
  ]);
  builder.pointer(modify + 4, blocks);
  return builder.finish(root);
}

function flatBufferModifyImageBlock(clearCrop: boolean, horizontal: boolean,
  vertical: boolean): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 92);
  writeDecimalU64At(builder, root + 12, '126');
  writeDecimalU64At(builder, root + 20, '127');
  builder.uint8(root + 28, 23);
  const modify: number = builder.table([
    4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 8, 0, 12, 13, 0, 0,
  ], 16);
  builder.pointer(root + 32, modify);
  builder.uint8(modify + 12, horizontal ? 1 : 0);
  builder.uint8(modify + 13, vertical ? 1 : 0);
  const crop: number = builder.table([clearCrop ? 0 : 4], clearCrop ? 8 : 20);
  if (!clearCrop) {
    builder.float32(crop + 4, -5);
    builder.float32(crop + 8, 2);
    builder.float32(crop + 12, 100);
    builder.float32(crop + 16, 50);
  }
  builder.pointer(modify + 8, crop);
  const blocks: number = builder.operationIdentityVector([{ timestamp: 20, siteId: 2 }]);
  builder.pointer(modify + 4, blocks);
  return builder.finish(root);
}

function flatBufferModifyMathBlock(clearLatex: boolean, clearColor: boolean): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 94);
  writeDecimalU64At(builder, root + 12, '128');
  writeDecimalU64At(builder, root + 20, '129');
  builder.uint8(root + 28, 23);
  const modify: number = builder.table([
    4, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    8, 12, 0, 0, 0, 0, 0, 0,
  ], 16);
  builder.pointer(root + 32, modify);
  const blocks: number = builder.operationIdentityVector([{ timestamp: 20, siteId: 2 }]);
  builder.pointer(modify + 4, blocks);
  const latex: number = builder.table([clearLatex ? 0 : 4], 8);
  if (!clearLatex) {
    builder.pointer(latex + 4, builder.string('x^2+y^2'));
  }
  builder.pointer(modify + 8, latex);
  const color: number = builder.table([clearColor ? 0 : 4], 8);
  if (!clearColor) {
    builder.color(color + 4, [0x44, 0x55, 0x66, 0xFF]);
  }
  builder.pointer(modify + 12, color);
  return builder.finish(root);
}

function flatBufferInsertString(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 100);
  writeDecimalU64At(builder, root + 12, '100');
  writeDecimalU64At(builder, root + 20, '100');
  builder.uint8(root + 28, 8);
  const insert: number = builder.table([4, 16, 20], 28);
  builder.pointer(root + 32, insert);
  builder.uint16(insert + 4, 0xFFFF);
  builder.uint32(insert + 8, 0);
  builder.uint32(insert + 12, 0);
  builder.uint16(insert + 20, 2);
  builder.uint32(insert + 24, 20);
  const value: number = builder.byteVector([0x41, 0xE4, 0xB8, 0xAD,
    0xF0, 0x9F, 0x98, 0x80]);
  builder.pointer(insert + 16, value);
  return builder.finish(root);
}

function flatBufferInsertChar(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 101);
  writeDecimalU64At(builder, root + 12, '101');
  writeDecimalU64At(builder, root + 20, '101');
  builder.uint8(root + 28, 7);
  const insert: number = builder.table([4, 16, 20], 28);
  builder.pointer(root + 32, insert);
  builder.uint16(insert + 4, 7);
  builder.uint32(insert + 8, 100);
  builder.uint32(insert + 12, 1);
  builder.uint32(insert + 16, 0x1F642);
  builder.uint16(insert + 20, 2);
  builder.uint32(insert + 24, 20);
  return builder.finish(root);
}

function flatBufferTextVisibility(payloadType: number, many: boolean): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 110 + payloadType);
  writeDecimalU64At(builder, root + 12, '200');
  writeDecimalU64At(builder, root + 20, '200');
  builder.uint8(root + 28, payloadType);
  if (many) {
    const payload: number = builder.table([4, 8], 16);
    builder.pointer(root + 32, payload);
    builder.uint16(payload + 8, 2);
    builder.uint32(payload + 12, 20);
    const locations: number = builder.sequenceIdentityVector([
      { timestamp: 100, siteId: 7, index: 1 },
      { timestamp: 100, siteId: 7, index: 2 },
    ]);
    builder.pointer(payload + 4, locations);
  } else {
    const payload: number = builder.table([4, 16], 24);
    builder.pointer(root + 32, payload);
    builder.uint16(payload + 4, 7);
    builder.uint32(payload + 8, 100);
    builder.uint32(payload + 12, 1);
    builder.uint16(payload + 16, 2);
    builder.uint32(payload + 20, 20);
  }
  return builder.finish(root);
}

function flatBufferAddPathElements(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 91);
  writeDecimalU64At(builder, root + 12, '125');
  writeDecimalU64At(builder, root + 20, '126');
  builder.uint8(root + 28, 16);
  const add: number = builder.table([4, 12, 0], 16);
  builder.pointer(root + 32, add);
  builder.uint16(add + 4, 2);
  builder.uint32(add + 8, 20);
  const path: number[] = [1, 0, 1];
  appendAttributedPathElement(path, 1,
    [{ x: 100, y: 100 }, { x: 10, y: 0 }], 0x3C00, 0x3800, 255, 0);
  const vector: number = builder.byteVector(path);
  builder.pointer(add + 12, vector);
  return builder.finish(root);
}

function flatBufferModifyInk(includeRender: boolean = false,
  includeRotation: boolean = false, clearRotation: boolean = false,
  includeScale: boolean = false, pageOriginMode: number = 0,
  zIndex: string | null = null, auxiliaryMode: number = 0,
  includeStyleMap: boolean = false, includeLegacyNib: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 92);
  writeDecimalU64At(builder, root + 12, '127');
  writeDecimalU64At(builder, root + 20, '128');
  builder.uint8(root + 28, 17);
  const fields: number[] = [4, pageOriginMode > 0 ? 8 : 0, pageOriginMode === 1 ? 20 : 0,
    includeRotation || clearRotation ? 28 : 0, includeScale ? 32 : 0,
    includeRender ? 36 : 0, includeRender ? 40 : 0, includeRender ? 44 : 0, 48,
    auxiliaryMode > 0 ? 52 : 0, auxiliaryMode > 0 ? 56 : 0,
    auxiliaryMode > 0 ? 60 : 0, includeStyleMap ? 64 : 0,
    zIndex === null ? 0 : 68, includeLegacyNib ? 76 : 0,
    includeLegacyNib ? 78 : 0, 0, 0, 0];
  const modify: number = builder.table(fields, 80);
  builder.pointer(root + 32, modify);
  if (pageOriginMode > 0) {
    builder.uint16(modify + 8, 4);
    builder.uint32(modify + 12, 30);
    builder.uint32(modify + 16, 5);
  }
  if (pageOriginMode === 1) {
    builder.float32(modify + 20, 40);
    builder.float32(modify + 24, 50);
  }
  if (includeRotation || clearRotation) {
    const rotation: number = builder.table([clearRotation ? 0 : 4], 8);
    if (!clearRotation) {
      builder.float32(rotation + 4, 0.5);
    }
    builder.pointer(modify + 28, rotation);
  }
  if (includeScale) {
    const scale: number = builder.table([4], 12);
    builder.float32(scale + 4, 2);
    builder.float32(scale + 8, 3);
    builder.pointer(modify + 32, scale);
  }
  if (includeRender) {
    builder.uint8(modify + 36, 2);
    builder.uint8(modify + 40, 1);
    builder.uint8(modify + 41, 2);
    builder.uint8(modify + 42, 3);
    builder.uint8(modify + 43, 128);
    builder.float32(modify + 44, 5);
  }
  if (zIndex !== null) {
    writeDecimalU64At(builder, modify + 68, zIndex);
  }
  if (includeLegacyNib) {
    builder.uint16(modify + 76, 65535);
    builder.uint16(modify + 78, 40000);
  }
  const inks: number = builder.operationIdentityVector([
    { timestamp: 20, siteId: 2 }, { timestamp: 21, siteId: 3 },
  ]);
  builder.pointer(modify + 4, inks);
  const path: number[] = [1, 0, 2];
  appendAttributedPathElement(path, 3, [{ x: 5, y: 6 }], 0x3C00, 0x3800, 255, 0);
  appendAttributedPathElement(path, 2, [{ x: 15, y: 16 }], 0x3C00, 0x3800, 255, 0);
  const vector: number = builder.byteVector(path);
  builder.pointer(modify + 48, vector);
  if (auxiliaryMode > 0) {
    const auxiliary: number[] = auxiliaryMode === 1 ? Array.from(auxiliaryInkPath()) : [];
    const customPath: number = builder.byteVector(auxiliary);
    builder.pointer(modify + 52, customPath);
    const fillPath: number = builder.byteVector(auxiliary);
    builder.pointer(modify + 56, fillPath);
    const fillColor: number = builder.table([auxiliaryMode === 1 ? 4 : 0], 8);
    if (auxiliaryMode === 1) {
      builder.color(fillColor + 4, [10, 20, 30, 128]);
    }
    builder.pointer(modify + 60, fillColor);
  }
  if (includeStyleMap) {
    const styleMap: number = builder.styleMapVector(true);
    builder.pointer(modify + 64, styleMap);
  }
  return builder.finish(root);
}

function auxiliaryInkPath(): Uint8Array {
  const path: number[] = [0, 0, 5];
  appendPlainPathElement(path, 7, [{ x: -5, y: -6 }]);
  appendPlainPathElement(path, 6, [{ x: 1, y: 2 }]);
  appendPlainPathElement(path, 5, [{ x: 3, y: 4 }, { x: 5, y: 6 }]);
  appendPlainPathElement(path, 4,
    [{ x: 7, y: 8 }, { x: 9, y: 10 }, { x: 11, y: 12 }]);
  appendPlainPathElement(path, 7, [{ x: 0, y: 1 }]);
  return new Uint8Array(path);
}

function appendPlainPathElement(target: number[], type: number,
  points: { x: number, y: number }[]): void {
  target.push(type);
  for (const point of points) {
    appendFloat32(target, point.x);
    appendFloat32(target, point.y);
  }
}

function appendAttributedPathElement(target: number[], type: number,
  points: { x: number, y: number }[], width: number, force: number,
  altitude: number, azimuth: number): void {
  target.push(type);
  for (const point of points) {
    appendFloat32(target, point.x);
    appendFloat32(target, point.y);
  }
  target.push((width >>> 8) & 0xFF, width & 0xFF,
    (force >>> 8) & 0xFF, force & 0xFF, altitude, azimuth);
}

function appendFloat32(target: number[], value: number): void {
  const bytes: Uint8Array = new Uint8Array(new Float32Array([value]).buffer);
  for (let index: number = 0; index < 4; index++) {
    target.push(bytes[index]);
  }
}

function writeDecimalU64At(builder: FixtureFlatBufferBuilder,
  offset: number, decimal: string): void {
  let remaining: string = decimal;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let carry: number = 0;
    for (let digit: number = 0; digit < remaining.length; digit++) {
      const value: number = carry * 10 + remaining.charCodeAt(digit) - 0x30;
      const part: number = Math.floor(value / 256);
      carry = value % 256;
      if (quotient.length > 0 || part > 0) {
        quotient += part.toString();
      }
    }
    builder.uint8(offset + index, carry);
    remaining = quotient.length === 0 ? '0' : quotient;
  }
}

function flatBufferModifyPageBackground(includeValue: boolean): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 90);
  builder.uint8(root + 28, 4);
  const modify: number = builder.table([4, 0, 8, 0], 12);
  builder.pointer(root + 32, modify);
  const pages: number = builder.sequenceVector(10, 1, 2);
  builder.pointer(modify + 4, pages);
  const setter: number = builder.table([includeValue ? 4 : 0], includeValue ? 8 : 4);
  builder.pointer(modify + 8, setter);
  if (includeValue) {
    const background: number = builder.table([4, 0, 8, 12, 0], 20);
    builder.pointer(setter + 4, background);
    builder.float32(background + 8, 0);
    builder.float32(background + 12, 612);
    builder.float32(background + 16, 792);
    const paper: number = builder.table([4, 8, 12, 13, 16, 20], 24);
    builder.pointer(background + 4, paper);
    builder.uint8(paper + 4, 2);
    builder.float32(paper + 8, 18);
    builder.uint8(paper + 12, 1);
    builder.uint8(paper + 13, 1);
    builder.color(paper + 16, [244, 245, 246, 255]);
    builder.uint8(paper + 20, 7);
  }
  return builder.finish(root);
}

function flatBufferCreatePageBackground(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 4);
  builder.uint32(root + 8, 10);
  builder.uint8(root + 28, 3);
  const create: number = builder.table([0, 4, 8, 12], 16);
  builder.pointer(root + 32, create);
  builder.uint32(create + 8, 1);
  builder.uint8(create + 12, 1);
  const background: number = builder.table([4, 0, 8, 12, 0], 20);
  builder.pointer(create + 4, background);
  builder.float32(background + 8, 0);
  builder.float32(background + 12, 612);
  builder.float32(background + 16, 792);
  const paper: number = builder.table([4, 8, 12, 13, 16, 20], 24);
  builder.pointer(background + 4, paper);
  builder.uint8(paper + 4, 2);
  builder.float32(paper + 8, 18);
  builder.uint8(paper + 12, 1);
  builder.uint8(paper + 13, 1);
  builder.color(paper + 16, [244, 245, 246, 255]);
  builder.uint8(paper + 20, 7);
  return builder.finish(root);
}

function flatBufferDeleteEntities(): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(164);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, 7);
  writeU32(bytes, 32, 50);
  writeDecimalU64(bytes, 36, '51');
  writeDecimalU64(bytes, 44, '52');
  bytes[52] = 25;
  writeU32(bytes, 56, 16);

  writeU16(bytes, 60, 12);
  writeU16(bytes, 62, 20);
  writeU16(bytes, 64, 4);
  writeU16(bytes, 66, 8);
  writeU16(bytes, 68, 12);
  writeU16(bytes, 70, 16);
  writeU32(bytes, 72, 12);
  writeU32(bytes, 76, 20);
  writeU32(bytes, 80, 28);
  writeU32(bytes, 84, 36);
  writeU32(bytes, 88, 60);

  writeU32(bytes, 96, 1);
  writeU16(bytes, 100, 8);
  writeU32(bytes, 104, 9);
  writeU32(bytes, 108, 1);
  writeU16(bytes, 112, 10);
  writeU32(bytes, 116, 11);

  writeU32(bytes, 120, 2);
  writeU16(bytes, 124, 1);
  writeU32(bytes, 128, 10);
  writeU32(bytes, 132, 2);
  writeU16(bytes, 136, 5);
  writeU32(bytes, 140, 30);
  writeU32(bytes, 144, 6);

  writeU32(bytes, 148, 1);
  writeU16(bytes, 152, 3);
  writeU32(bytes, 156, 20);
  writeU32(bytes, 160, 4);
  return bytes;
}

function flatBufferOperation(timestamp: number, siteId: number, clientTime: string,
  serverTime: string, payloadType: number): Uint8Array {
  const bytes: Uint8Array = new Uint8Array(68);
  writeU32(bytes, 0, 24);
  writeU16(bytes, 4, 18);
  writeU16(bytes, 6, 36);
  writeU16(bytes, 8, 4);
  writeU16(bytes, 10, 12);
  writeU16(bytes, 12, 20);
  writeU16(bytes, 16, 28);
  writeU16(bytes, 18, 32);
  writeU32(bytes, 24, 20);
  writeU16(bytes, 28, siteId);
  writeU32(bytes, 32, timestamp);
  writeDecimalU64(bytes, 36, clientTime);
  writeDecimalU64(bytes, 44, serverTime);
  bytes[52] = payloadType;
  writeU32(bytes, 56, 8);
  writeU16(bytes, 60, 4);
  writeU16(bytes, 62, 4);
  writeU32(bytes, 64, 4);
  return bytes;
}

function writeU16(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
}

function writeU32(bytes: Uint8Array, offset: number, value: number): void {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = Math.floor(value / 0x100) & 0xFF;
  bytes[offset + 2] = Math.floor(value / 0x10000) & 0xFF;
  bytes[offset + 3] = Math.floor(value / 0x1000000) & 0xFF;
}

function writeDecimalU64(bytes: Uint8Array, offset: number, decimal: string): void {
  let remaining: string = decimal;
  for (let index: number = 0; index < 8; index++) {
    let quotient: string = '';
    let carry: number = 0;
    for (let digit: number = 0; digit < remaining.length; digit++) {
      const value: number = carry * 10 + remaining.charCodeAt(digit) - 0x30;
      const part: number = Math.floor(value / 256);
      carry = value % 256;
      if (quotient.length > 0 || part > 0) {
        quotient += part.toString();
      }
    }
    bytes[offset + index] = carry;
    remaining = quotient.length === 0 ? '0' : quotient;
  }
}
