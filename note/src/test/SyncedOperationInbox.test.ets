import { describe, it, expect } from '@ohos/hypium';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import {
  compareIncomingSyncedOperationOrder, IncomingSyncedOperation, StoredSyncedOperation,
  SyncedOperationInboxState, validateIncomingSyncedBatch,
} from '../main/ets/data/SyncedOperationInbox';
import {
  crc32Signed, parseOriginalSyncedOperationEnvelope, readOriginalPayloadTable,
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
import { decodeOriginalDeleteEntities, decodeOriginalDeleteEntitiesTable,
  OriginalDeleteEntitiesOperationApplier } from
  '../main/ets/data/OriginalDeleteEntitiesOperation';
import { OriginalPageOperationApplier } from '../main/ets/data/OriginalPageOperationApplier';
import { decodeOriginalCreateInk, decodeOriginalCreateInkTable,
  OriginalCreateInkOperationApplier, unsupportedOriginalCreateInkReason } from
  '../main/ets/data/OriginalCreateInkOperation';
import { decodeOriginalAddPathElements, decodeOriginalAddPathElementsTable,
  OriginalAddPathElementsOperationApplier } from
  '../main/ets/data/OriginalAddPathElementsOperation';
import { decodeOriginalModifyInk, decodeOriginalModifyInkTable,
  OriginalModifyInkOperationApplier } from '../main/ets/data/OriginalModifyInkOperation';
import { decodeOriginalCreateBlock, decodeOriginalCreateBlockTable, OriginalBlockType,
  OriginalCreateBlockOperationApplier, unsupportedOriginalCreateBlockReason } from
  '../main/ets/data/OriginalCreateBlockOperation';
import { decodeOriginalModifyBlock, decodeOriginalModifyBlockTable,
  OriginalModifyBlockOperationApplier } from '../main/ets/data/OriginalModifyBlockOperation';
import { decodeOriginalInsertText, decodeOriginalInsertTextTable,
  decodeOriginalTextVisibility, decodeOriginalTextVisibilityTable,
  OriginalInsertTextOperationApplier, OriginalTextVisibilityOperationApplier } from
  '../main/ets/data/OriginalInsertTextOperation';
import {
  decodeOriginalRichTextStyle, decodeOriginalRichTextStyleTable,
  ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE,
  ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE, ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE,
  OriginalRichTextStyleOperationApplier,
} from '../main/ets/data/OriginalRichTextStyleOperation';
import { decodeOriginalAuxiliaryInkPath, originalInkTransform,
  transformedExpandedBounds } from '../main/ets/data/OriginalInkPathCodec';
import { decodeOriginalInkPath, decodeOriginalInkPathAppend } from
  '../main/ets/data/OriginalInkPathCodec';
import { Rect2D } from '../main/ets/core/model/GeometryTypes';
import { InkPathCommandType } from '../main/ets/core/model/StrokeTypes';
import {
  decodeOriginalSetMetadataTable, OriginalSetMetadataOperationApplier,
} from '../main/ets/data/OriginalSetMetadataOperation';
import {
  decodeOriginalAssetCloudPersistedTable, OriginalAssetCloudPersistedOperationApplier,
} from '../main/ets/data/OriginalAssetCloudPersistedOperation';
import {
  decodeOriginalModifyPositions,
} from '../main/ets/data/OriginalModifyPositionsOperation';
import {
  decodeOriginalUpdateCheckbox, ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE,
  OriginalUpdateCheckboxOperationApplier,
} from '../main/ets/data/OriginalUpdateCheckboxOperation';
import {
  decodeOriginalModifyPdfField, ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE,
  ORIGINAL_PDF_FIELD_BOOLEAN_VALUE, ORIGINAL_PDF_FIELD_STRING_VALUE,
  OriginalModifyPdfFieldOperationApplier,
} from '../main/ets/data/OriginalModifyPdfFieldOperation';
import {
  decodeOriginalTransientInteractionEnded,
  ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE,
  OriginalTransientInteractionStore,
} from '../main/ets/data/OriginalTransientInteractionOperation';
import {
  consumeOriginalPeerInteractionBatch, decodeOriginalPeerInteraction,
  ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
  OriginalPeerInteractionStore, OriginalPeerTool,
} from '../main/ets/data/OriginalPeerInteractionOperation';
import {
  decodeOriginalCreateComment, decodeOriginalModifyComment,
  ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE, ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE,
  OriginalCommentAnchorType, preflightOriginalCommentTable,
} from '../main/ets/data/OriginalCommentOperation';
import {
  decodeOriginalCreateRecording, decodeOriginalModifyRecording,
  ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE, ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE,
  OriginalRecordingOperationApplier,
} from '../main/ets/data/OriginalRecordingOperation';
import {
  decodeOriginalCreateGroup, decodeOriginalCreateShape, decodeOriginalModifyGroup,
  decodeOriginalModifyShape, ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE,
  ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE, ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE,
  ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE, OriginalShapeDefinitionType,
  OriginalShapeGroupOperationApplier,
} from '../main/ets/data/OriginalShapeGroupOperation';
import { OriginalPageMutationBatch } from '../main/ets/data/OriginalPageMutationBatch';

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
      const pdfPayload = decodeOriginalCreatePage(flatBufferCreatePagePdfBackground());
      expect(pdfPayload.pageCount).assertEqual(2);
      expect(pdfPayload.background?.background.pdf?.layoutBehavior).assertEqual(1);
      expect(pdfPayload.background?.background.pdf?.totalPageCount).assertEqual(12);
      expect(pdfPayload.background?.background.pdf?.pagesConsumed).assertEqual(2);
      expect(pdfPayload.background?.background.pdf?.pageOffset).assertEqual(4);
      expect(pdfPayload.background?.background.pdf?.pageInAsset).assertEqual(4);
      expect(pdfPayload.background?.background.pdf?.cropBoxes.length).assertEqual(2);
      expect(pdfPayload.background?.background.pdf?.cropBoxes[1].widthPt).assertEqual(612);
      expect(pdfPayload.background?.background.pdf?.metadata.assetHashBits[7])
        .assertEqual('18446744073709551615');
      expect(pdfPayload.background?.background.pdf?.metadata.fileName).assertEqual('source.pdf');
      expect(pdfPayload.background?.background.pdf?.metadata.mimeType).assertEqual('application/pdf');
      expect(pdfPayload.background?.background.pdf?.metadata.fileSize).assertEqual(4096);
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
      expect(applier.supports(ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(5)).assertFalse();
    });

    it('decodes and consumes original transient interaction endings in memory only', 0, async () => {
      const raw: Uint8Array = flatBufferTransientInteractionEnded();
      const payload = decodeOriginalTransientInteractionEnded(raw);
      expect(payload.interactionId.timestamp).assertEqual(80);
      expect(payload.interactionId.siteId).assertEqual(6);
      expect(payload.replacedByOp?.timestamp).assertEqual(90);
      expect(payload.replacedByOp?.siteId).assertEqual(7);
      const transientStore = new OriginalTransientInteractionStore();
      transientStore.recordPreview('note', payload.interactionId, { timestamp: 70, siteId: 5 });
      transientStore.recordPreview('other', payload.interactionId, { timestamp: 71, siteId: 5 });
      const applier = new OriginalPageOperationApplier(transientStore);
      const operation: StoredSyncedOperation = {
        noteId: 'note', timestamp: 300, siteId: 7, clientTime: '400', serverTime: '500',
        schemaVersion: 1, payloadType: ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE,
        rawOperation: raw, state: SyncedOperationInboxState.RECEIVED,
        deferredReason: null, receivedAt: 1,
      };
      const noWriteStore = { executeSql: async (_sql: string): Promise<void> => {} };
      expect((await applier.apply(noWriteStore, operation)).deferredReason === null).assertTrue();
      expect(transientStore.previewCount('note', payload.interactionId)).assertEqual(0);
      expect(transientStore.previewCount('other', payload.interactionId)).assertEqual(1);
      expect((await applier.apply(noWriteStore, operation)).deferredReason === null).assertTrue();
    });

    it('rejects malformed transient endings and does not mistake audioTime for transient', 0, async () => {
      let rejected: number = 0;
      for (const raw of [
        flatBufferTransientInteractionEnded(false),
        flatBufferTransientInteractionEnded(true, false),
        flatBufferTransientInteractionEnded(true, true, true),
        flatBufferTransientInteractionEnded(true, true, false, true),
      ]) {
        try {
          decodeOriginalTransientInteractionEnded(raw);
        } catch (_error) {
          rejected++;
        }
      }
      expect(rejected).assertEqual(4);
      const raw: Uint8Array = flatBufferAssetCloudPersisted(true, false, false, true);
      const statements: string[] = [];
      const fakeStore = {
        executeSql: async (sql: string): Promise<void> => { statements.push(sql); },
      };
      const operation: StoredSyncedOperation = {
        noteId: 'note', timestamp: 92, siteId: 7, clientTime: '123', serverTime: '124',
        schemaVersion: 1, payloadType: 2, rawOperation: raw,
        state: SyncedOperationInboxState.RECEIVED, deferredReason: null, receivedAt: 1,
      };
      expect((await new OriginalPageOperationApplier().apply(fakeStore, operation))
        .deferredReason === null).assertTrue();
      expect(statements.length).assertEqual(1);
    });

    it('decodes original peer interaction and preserves its generated-reader fallbacks', 0, () => {
      const payload = decodeOriginalPeerInteraction(flatBufferPeerInteraction(
        true, true, false, false, true, 2, 2));
      expect(payload.cursorPosition?.x).assertEqual(12.5);
      expect(payload.cursorPosition?.y).assertEqual(-4.25);
      expect(payload.selectedEntities.length).assertEqual(2);
      expect(payload.selectedEntities[0].timestamp).assertEqual(20);
      expect(payload.selectedEntities[1].timestamp).assertEqual(21);
      expect(payload.tool).assertEqual(OriginalPeerTool.HIGHLIGHTER);
      expect(payload.textSelection?.anchor?.timestamp).assertEqual(30);
      expect(payload.textSelection?.focus?.index).assertEqual(4);
      expect(payload.recordingInProgress).assertTrue();
      const fallback = decodeOriginalPeerInteraction(flatBufferPeerInteraction(
        true, true, false, false, false, 255, 0));
      expect(fallback.cursorPosition === null).assertTrue();
      expect(fallback.tool).assertEqual(OriginalPeerTool.POINTER);
      expect(fallback.recordingInProgress).assertFalse();
    });

    it('coalesces peer interaction in memory without writing the durable model', 0, async () => {
      const peerStore = new OriginalPeerInteractionStore();
      const first = decodeOriginalPeerInteraction(flatBufferPeerInteraction());
      const noCursor = decodeOriginalPeerInteraction(flatBufferPeerInteraction(
        true, true, false, false, false, 3, 0));
      expect(peerStore.consume('note', 8, first, 7)).assertTrue();
      expect(peerStore.consume('note', 8, noCursor, 7)).assertTrue();
      expect(peerStore.read('note', 8)?.cursorPosition?.x).assertEqual(12.5);
      expect(peerStore.read('note', 8)?.tool).assertEqual(OriginalPeerTool.ERASER);
      expect(peerStore.consume('note', 7, first, 7)).assertFalse();
      expect(peerStore.read('note', 7) === null).assertTrue();
      expect(peerStore.consume('other', 8, first, 7)).assertTrue();
      peerStore.clearNote('note');
      expect(peerStore.read('note', 8) === null).assertTrue();
      expect(peerStore.read('other', 8) !== null).assertTrue();

      const operation: StoredSyncedOperation = {
        noteId: 'note', timestamp: 310, siteId: 8, clientTime: '410', serverTime: '510',
        schemaVersion: 1, payloadType: ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
        rawOperation: flatBufferPeerInteraction(), state: SyncedOperationInboxState.RECEIVED,
        deferredReason: null, receivedAt: 1,
      };
      let writeCount: number = 0;
      const noWriteStore = {
        executeSql: async (_sql: string): Promise<void> => { writeCount++; },
      };
      const applier = new OriginalPageOperationApplier(new OriginalTransientInteractionStore());
      expect((await applier.apply(noWriteStore, operation)).deferredReason === null).assertTrue();
      expect(writeCount).assertEqual(0);
      const batch = consumeOriginalPeerInteractionBatch('note', [operation], peerStore, 7);
      expect(batch.operationCount).assertEqual(1);
      expect(batch.updateCount).assertEqual(1);
      expect(peerStore.read('note', 8)?.tool).assertEqual(OriginalPeerTool.PEN);

      const beforeBatch = decodeOriginalPeerInteraction(flatBufferPeerInteraction());
      if (beforeBatch.cursorPosition !== null) {
        beforeBatch.cursorPosition.x = 1;
        beforeBatch.cursorPosition.y = 2;
      }
      peerStore.consume('batch', 8, beforeBatch, 7);
      const firstInBatch: IncomingSyncedOperation = {
        noteId: 'batch', timestamp: 311, siteId: 8, clientTime: '411', serverTime: '511',
        schemaVersion: 1, payloadType: ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
        rawOperation: flatBufferPeerInteraction(true, true, false, false, true, 2, 1, 311),
      };
      const lastInBatch: IncomingSyncedOperation = {
        noteId: 'batch', timestamp: 312, siteId: 8, clientTime: '412', serverTime: '512',
        schemaVersion: 1, payloadType: ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
        rawOperation: flatBufferPeerInteraction(true, true, false, false, false, 3, 0, 312),
      };
      const coalesced = consumeOriginalPeerInteractionBatch(
        'batch', [firstInBatch, lastInBatch], peerStore, 7);
      expect(coalesced.operationCount).assertEqual(2);
      expect(coalesced.updateCount).assertEqual(1);
      expect(peerStore.read('batch', 8)?.cursorPosition?.x).assertEqual(1);
      expect(peerStore.read('batch', 8)?.tool).assertEqual(OriginalPeerTool.ERASER);

      const malformedLast: IncomingSyncedOperation = {
        noteId: 'batch', timestamp: 313, siteId: 8, clientTime: '413', serverTime: '513',
        schemaVersion: 1, payloadType: ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
        rawOperation: flatBufferPeerInteraction(true, true, false, true, true, 1, 1, 313),
      };
      const discarded = consumeOriginalPeerInteractionBatch(
        'batch', [firstInBatch, malformedLast], peerStore, 7);
      expect(discarded.updateCount).assertEqual(0);
      expect(discarded.discardedCount).assertEqual(1);
      expect(peerStore.read('batch', 8)?.tool).assertEqual(OriginalPeerTool.ERASER);
    });

    it('rejects malformed peer metadata, reserved fields and extensions', 0, () => {
      let rejected: number = 0;
      for (const raw of [
        flatBufferPeerInteraction(false),
        flatBufferPeerInteraction(true, false),
        flatBufferPeerInteraction(true, true, true),
        flatBufferPeerInteraction(true, true, false, true),
      ]) {
        try {
          decodeOriginalPeerInteraction(raw);
        } catch (_error) {
          rejected++;
        }
      }
      expect(rejected).assertEqual(4);
    });

    it('decodes all original CREATE_COMMENT anchor unions', 0, () => {
      const canvas = decodeOriginalCreateComment(
        flatBufferCreateComment(OriginalCommentAnchorType.CANVAS));
      expect(canvas.anchor.type).assertEqual(OriginalCommentAnchorType.CANVAS);
      if (canvas.anchor.type === OriginalCommentAnchorType.CANVAS) {
        expect(canvas.anchor.page.timestamp).assertEqual(40);
        expect(canvas.anchor.page.index).assertEqual(3);
        expect(canvas.anchor.origin.x).assertEqual(12.5);
      }
      const text = decodeOriginalCreateComment(
        flatBufferCreateComment(OriginalCommentAnchorType.TEXT));
      expect(text.anchor.type).assertEqual(OriginalCommentAnchorType.TEXT);
      if (text.anchor.type === OriginalCommentAnchorType.TEXT) {
        expect(text.anchor.textField?.timestamp).assertEqual(50);
        expect(text.anchor.selection.anchor?.index).assertEqual(4);
        expect(text.anchor.selection.focus?.timestamp).assertEqual(61);
      }
      const entity = decodeOriginalCreateComment(
        flatBufferCreateComment(OriginalCommentAnchorType.ENTITY));
      expect(entity.anchor.type).assertEqual(OriginalCommentAnchorType.ENTITY);
      if (entity.anchor.type === OriginalCommentAnchorType.ENTITY) {
        expect(entity.anchor.entities.length).assertEqual(2);
        expect(entity.anchor.entities[1].timestamp).assertEqual(71);
      }
      const reply = decodeOriginalCreateComment(
        flatBufferCreateComment(OriginalCommentAnchorType.REPLY));
      expect(reply.anchor.type).assertEqual(OriginalCommentAnchorType.REPLY);
      if (reply.anchor.type === OriginalCommentAnchorType.REPLY) {
        expect(reply.anchor.root.timestamp).assertEqual(80);
      }
      expect(reply.text).assertEqual('comment');
      expect(preflightOriginalCommentTable(readOriginalPayloadTable(
        flatBufferCreateComment(OriginalCommentAnchorType.REPLY),
        ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE), ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE) === null)
        .assertTrue();
    });

    it('decodes MODIFY_COMMENT nullable setters and generated boolean behavior', 0, () => {
      const changed = decodeOriginalModifyComment(
        flatBufferModifyComment(true, true, 'updated', true, 2));
      expect(changed.comment.timestamp).assertEqual(90);
      expect(changed.anchor?.page.index).assertEqual(5);
      expect(changed.text?.value).assertEqual('updated');
      expect(changed.resolved?.value).assertTrue();
      const cleared = decodeOriginalModifyComment(
        flatBufferModifyComment(false, true, null, true, null));
      expect(cleared.anchor === null).assertTrue();
      expect(cleared.text?.value === null).assertTrue();
      expect(cleared.resolved?.value === null).assertTrue();
      expect(preflightOriginalCommentTable(readOriginalPayloadTable(
        flatBufferModifyComment(false, true, null, true, null),
        ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE), ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE) === null)
        .assertTrue();
    });

    it('consumes validated comments without original-model writes and defers malformed ones', 0,
      async () => {
        let writeCount: number = 0;
        const noWriteStore = {
          executeSql: async (_sql: string): Promise<void> => { writeCount++; },
        };
        const applier = new OriginalPageOperationApplier(new OriginalTransientInteractionStore());
        const create: StoredSyncedOperation = {
          noteId: 'note', timestamp: 320, siteId: 8, clientTime: '1', serverTime: '2',
          schemaVersion: 1, payloadType: ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE,
          rawOperation: flatBufferCreateComment(OriginalCommentAnchorType.REPLY),
          state: SyncedOperationInboxState.RECEIVED, deferredReason: null, receivedAt: 1,
        };
        expect((await applier.apply(noWriteStore, create)).deferredReason === null).assertTrue();
        expect(writeCount).assertEqual(0);
        create.rawOperation = flatBufferCreateComment(0);
        expect((await applier.apply(noWriteStore, create)).deferredReason)
          .assertEqual('MALFORMED_COMMENT_PAYLOAD');
        expect(writeCount).assertEqual(0);
      });

    it('rejects malformed original comment schemas before consumption', 0, () => {
      let rejected: number = 0;
      for (const decode of [
        (): void => { decodeOriginalCreateComment(flatBufferCreateComment(0)); },
        (): void => { decodeOriginalCreateComment(flatBufferCreateComment(255)); },
        (): void => { decodeOriginalCreateComment(
          flatBufferCreateComment(OriginalCommentAnchorType.CANVAS, '', true)); },
        (): void => { decodeOriginalCreateComment(
          flatBufferCreateComment(OriginalCommentAnchorType.CANVAS, 'comment', true, true)); },
        (): void => { decodeOriginalCreateComment(
          flatBufferCreateComment(OriginalCommentAnchorType.CANVAS, 'comment', false)); },
        (): void => { decodeOriginalModifyComment(
          flatBufferModifyComment(false, false, null, false, null)); },
        (): void => { decodeOriginalModifyComment(
          flatBufferModifyComment(false, true, 'value', false, null, false, false)); },
        (): void => { decodeOriginalModifyComment(
          flatBufferModifyComment(false, true, 'value', false, null, true)); },
      ]) {
        try {
          decode();
        } catch (_error) {
          rejected++;
        }
      }
      expect(rejected).assertEqual(8);
    });

    it('decodes original Recording assets, uint64 bounds, segments and nullable modifications', 0, () => {
      const created = decodeOriginalCreateRecording(flatBufferCreateRecording());
      expect(created.metadata.fileName).assertEqual('audio.m4a');
      expect(created.metadata.mimeType).assertEqual('audio/mp4');
      expect(created.metadata.fileSize).assertEqual(4096);
      expect(created.startTime).assertEqual('18446744073709551600');
      expect(created.endTime).assertEqual('18446744073709551615');
      expect(created.name).assertEqual('Lecture');
      expect(created.segments?.length).assertEqual(2);
      expect(created.zIndex).assertEqual('18446744073709551614');

      const modified = decodeOriginalModifyRecording(flatBufferModifyRecording());
      expect(modified.recording.timestamp).assertEqual(330);
      expect(modified.recording.siteId).assertEqual(9);
      expect(modified.name).assertEqual('Renamed');
      expect(modified.segments?.length).assertEqual(1);
      expect(modified.zIndex).assertEqual('18446744073709551613');
      const emptyModify = decodeOriginalModifyRecording(
        flatBufferModifyRecording(false, false, false));
      expect(emptyModify.name === null && emptyModify.segments === null &&
        emptyModify.zIndex === null).assertTrue();
    });

    it('strictly rejects malformed original Recording payloads and routes both durable types', 0, () => {
      const applier: OriginalRecordingOperationApplier = new OriginalRecordingOperationApplier();
      expect(applier.supports(ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE)).assertTrue();
      expect(applier.supports(ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE)).assertTrue();
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferCreateRecording(false), ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE),
      ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE)).assertEqual('MALFORMED_RECORDING_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferCreateRecording(true, true), ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE),
      ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE)).assertEqual('MALFORMED_RECORDING_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferModifyRecording(true, true, true, false),
        ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE), ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE))
        .assertEqual('MALFORMED_RECORDING_PAYLOAD');
      const router: OriginalPageOperationApplier = new OriginalPageOperationApplier();
      expect(router.supports(ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE)).assertTrue();
      expect(router.supports(ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE)).assertTrue();
    });

    it('decodes original Shape definitions, nullable registers and Group members', 0, () => {
      const created = decodeOriginalCreateShape(flatBufferCreateShape(), '77');
      expect(created.page.timestamp).assertEqual(400);
      expect(created.originX).assertEqual(12.5);
      expect(created.originY).assertEqual(-3.25);
      expect(created.definition.type).assertEqual(OriginalShapeDefinitionType.ELLIPSE);
      expect(created.color).assertEqual(-16116706);
      expect(created.zIndex).assertEqual('77');

      const modified = decodeOriginalModifyShape(flatBufferModifyShape());
      expect(modified.shapes.length).assertEqual(2);
      expect(modified.rotation.present).assertTrue();
      expect(modified.rotation.value === null).assertTrue();
      expect(modified.color).assertEqual(-2147417597);
      expect(modified.zIndex).assertEqual('18446744073709551615');

      const group = decodeOriginalCreateGroup(flatBufferCreateGroup());
      expect(group.members.length).assertEqual(2);
      expect(group.members[1].timestamp).assertEqual(102);
      const groupModify = decodeOriginalModifyGroup(flatBufferModifyGroup());
      expect(groupModify.group.timestamp).assertEqual(500);
      expect(groupModify.members[0].siteId).assertEqual(4);
    });

    it('strictly routes all four original Shape and Group operation types', 0, () => {
      const applier: OriginalShapeGroupOperationApplier = new OriginalShapeGroupOperationApplier();
      const router: OriginalPageOperationApplier = new OriginalPageOperationApplier();
      for (const type of [ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE,
        ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE, ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE,
        ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE]) {
        expect(applier.supports(type)).assertTrue();
        expect(router.supports(type)).assertTrue();
      }
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferCreateShape(true), ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE),
      ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE, '1')).assertEqual('MALFORMED_SHAPE_GROUP_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferModifyGroup(false), ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE),
      ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE, '1')).assertEqual('MALFORMED_SHAPE_GROUP_PAYLOAD');
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

    it('decodes cloud-persisted asset hashes without changing local asset status', 0, async () => {
      const raw: Uint8Array = flatBufferAssetCloudPersisted();
      const table = readOriginalPayloadTable(raw, 2);
      const payload = decodeOriginalAssetCloudPersistedTable(table);
      let expectedHash: string = '';
      for (let index: number = 0; index < 64; index++) {
        expectedHash += index.toString(16).padStart(2, '0');
      }
      expect(payload.storageHash).assertEqual(expectedHash);
      const statements: string[] = [];
      const fakeStore = {
        executeSql: async (sql: string): Promise<void> => {
          statements.push(sql);
        },
      } as relationalStore.RdbStore;
      const cloudOperation: StoredSyncedOperation = {
        noteId: 'note', timestamp: 92, siteId: 7, clientTime: '123', serverTime: '124',
        schemaVersion: 1, payloadType: 2, rawOperation: raw,
        state: SyncedOperationInboxState.RECEIVED, deferredReason: null, receivedAt: 1,
      };
      const applier = new OriginalAssetCloudPersistedOperationApplier();
      expect((await applier.apply(fakeStore, cloudOperation)).deferredReason === null).assertTrue();
      expect((await applier.apply(fakeStore, cloudOperation)).deferredReason === null).assertTrue();
      expect(statements.length).assertEqual(2);
      expect(statements[0]).assertContain('INSERT OR IGNORE INTO original_asset_cloud_state');
      expect(statements[0].includes('note_asset')).assertFalse();
    });

    it('defers missing, truncated and extended AssetCloudPersisted tables', 0, () => {
      const applier = new OriginalAssetCloudPersistedOperationApplier();
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferAssetCloudPersisted(false), 2))).assertEqual(
        'MALFORMED_ASSET_CLOUD_PERSISTED_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferAssetCloudPersisted(true, true), 2))).assertEqual(
        'MALFORMED_ASSET_CLOUD_PERSISTED_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferAssetCloudPersisted(true, false, true), 2))).assertEqual(
        'ASSET_CLOUD_PERSISTED_FIELDS_UNSUPPORTED');
    });

    it('decodes original UpdateCheckbox target, stable location and explicit false', 0, () => {
      const checked = decodeOriginalUpdateCheckbox(flatBufferUpdateCheckbox(true));
      expect(checked.textField.timestamp).assertEqual(20);
      expect(checked.textField.siteId).assertEqual(2);
      expect(checked.location.timestamp).assertEqual(100);
      expect(checked.location.siteId).assertEqual(7);
      expect(checked.location.index).assertEqual(3);
      expect(checked.isChecked).assertTrue();
      const unchecked = decodeOriginalUpdateCheckbox(flatBufferUpdateCheckbox(false));
      expect(unchecked.isChecked).assertFalse();
    });

    it('rejects incomplete and extended original UpdateCheckbox payloads', 0, () => {
      const applier = new OriginalUpdateCheckboxOperationApplier();
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferUpdateCheckbox(true, false, false), 28))).assertEqual(
        'MALFORMED_UPDATE_CHECKBOX_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferUpdateCheckbox(true, true, false, false), 28))).assertEqual(
        'MALFORMED_UPDATE_CHECKBOX_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(
        flatBufferUpdateCheckbox(true, true, true), 28))).assertEqual(
        'MALFORMED_UPDATE_CHECKBOX_PAYLOAD');
    });

    it('decodes original ModifyPDFField string and explicit boolean values', 0, () => {
      const stringValue = decodeOriginalModifyPdfField(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_STRING_VALUE, true, true, true, false, false, 'Alice'));
      expect(stringValue.storageHash.length).assertEqual(128);
      expect(stringValue.storageHash.substring(0, 8)).assertEqual('00010203');
      expect(stringValue.key).assertEqual('name');
      expect(stringValue.stringValue).assertEqual('Alice');
      expect(stringValue.booleanValue === null).assertTrue();
      const checked = decodeOriginalModifyPdfField(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_BOOLEAN_VALUE, true, true, false, true, false));
      expect(checked.booleanValue).assertTrue();
      const unchecked = decodeOriginalModifyPdfField(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_BOOLEAN_VALUE, true, true, false, true, false, '', false));
      expect(unchecked.booleanValue).assertFalse();
    });

    it('rejects incomplete, mismatched and extended original ModifyPDFField values', 0, () => {
      const applier = new OriginalModifyPdfFieldOperationApplier();
      expect(applier.preflightTable(readOriginalPayloadTable(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_STRING_VALUE, false), 27))).assertEqual(
        'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_BOOLEAN_VALUE, true, true, false, false), 27))).assertEqual(
        'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_STRING_VALUE, true, true, true, true), 27))).assertEqual(
        'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(flatBufferModifyPdfField(
        2, true, true, false, false), 27))).assertEqual(
        'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD');
      expect(applier.preflightTable(readOriginalPayloadTable(flatBufferModifyPdfField(
        ORIGINAL_PDF_FIELD_STRING_VALUE, true, true, true, false, true), 27))).assertEqual(
        'MALFORMED_MODIFY_PDF_FIELD_PAYLOAD');
    });

    it('decodes per-target original ModifyPositions registers without number loss', 0, () => {
      const payload = decodeOriginalModifyPositions(flatBufferModifyPositions());
      expect(payload.modifications.length).assertEqual(2);
      const first = payload.modifications[0];
      expect(first.target.timestamp).assertEqual(10);
      expect(first.target.siteId).assertEqual(1);
      expect(first.pageOrigin?.page.timestamp).assertEqual(100);
      expect(first.pageOrigin?.page.siteId).assertEqual(2);
      expect(first.pageOrigin?.page.index).assertEqual(3);
      expect(first.pageOrigin?.originX).assertEqual(1.5);
      expect(first.pageOrigin?.originY).assertEqual(-2);
      expect(first.rotation.value).assertEqual(0.5);
      expect(first.scale.value?.x).assertEqual(2);
      expect(first.scale.value?.y).assertEqual(3);
      expect(first.zIndex).assertEqual('18446744073709551615');
      const second = payload.modifications[1];
      expect(second.target.timestamp).assertEqual(20);
      expect(second.rotation.present).assertTrue();
      expect(second.rotation.value === null).assertTrue();
      expect(second.scale.present).assertTrue();
      expect(second.scale.value === null).assertTrue();
      expect(second.zIndex === null).assertTrue();
    });

    it('rejects repeated ModifyPositions targets and unpaired page/origin', 0, () => {
      let rejected: number = 0;
      try {
        decodeOriginalModifyPositions(flatBufferModifyPositions(true, false));
      } catch (_error) {
        rejected++;
      }
      try {
        decodeOriginalModifyPositions(flatBufferModifyPositions(false, true));
      } catch (_error) {
        rejected++;
      }
      expect(rejected).assertEqual(2);
    });

    it('batches mixed position page revisions and search invalidation once', 0, async () => {
      let updates: number = 0;
      const statements: string[] = [];
      const fakeStore = {
        update: async (): Promise<number> => {
          updates++;
          return 1;
        },
        executeSql: async (sql: string): Promise<void> => {
          statements.push(sql);
        },
      } as relationalStore.RdbStore;
      const target = {
        page: { timestamp: 10, siteId: 1, index: 2 }, pageId: 'page',
        revisionTable: 'page_info', revision: 7, archived: false,
      };
      const batch = new OriginalPageMutationBatch();
      batch.recordInk(target);
      batch.recordBlock(target, true);
      await batch.flush(fakeStore, 'note');
      expect(updates).assertEqual(1);
      expect(statements.length).assertEqual(3);
      expect(statements[0]).assertContain('search_page_state');
      expect(statements[1]).assertContain('search_item');
      expect(statements[2]).assertContain('search_item');
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
      const pdf = decodeOriginalModifyPage(flatBufferModifyPagePdfBackground());
      expect(pdf.pages.length).assertEqual(2);
      expect(pdf.background?.background.pdf?.pagesConsumed).assertEqual(2);
      expect(pdf.background?.background.pdf?.pageOffset).assertEqual(7);
    });

    it('decodes note-level background SET_METADATA including an explicit null', 0, () => {
      const applier = new OriginalSetMetadataOperationApplier();
      const valueTable = readOriginalPayloadTable(flatBufferSetMetadataBackground(true), 1);
      const value = decodeOriginalSetMetadataTable(valueTable);
      expect(value.hasPageBackground).assertTrue();
      expect(value.pageBackground?.background.paper?.flair).assertEqual(2);
      expect(value.pageBackground?.background.sourceWidthPt).assertEqual(612);
      expect(applier.preflightTable(valueTable) === null).assertTrue();
      const clearTable = readOriginalPayloadTable(flatBufferSetMetadataBackground(false), 1);
      const clear = decodeOriginalSetMetadataTable(clearTable);
      expect(clear.hasPageBackground).assertTrue();
      expect(clear.pageBackground === null).assertTrue();
      expect(applier.preflightTable(clearTable) === null).assertTrue();
      const combinedTable = readOriginalPayloadTable(flatBufferSetMetadataBackground(true, 'Imported title'), 1);
      const combined = decodeOriginalSetMetadataTable(combinedTable);
      expect(combined.hasTitle).assertTrue();
      expect(combined.title).assertEqual('Imported title');
      expect(combined.hasPageBackground).assertTrue();
      expect(applier.preflightTable(combinedTable) === null).assertTrue();
      const pdfTable = readOriginalPayloadTable(flatBufferSetMetadataPdfBackground(), 1);
      const pdf = decodeOriginalSetMetadataTable(pdfTable);
      expect(pdf.hasPageBackground).assertTrue();
      expect(pdf.pageBackground?.background.pdf?.metadata.fileName).assertEqual('source.pdf');
      expect(applier.preflightTable(pdfTable) === null).assertTrue();
    });

    it('decodes original DELETE_ENTITIES page tombstones independently from entities', 0, () => {
      const payload = decodeOriginalDeleteEntities(flatBufferDeleteEntities());
      expect(payload.entityDeleteCount).assertEqual(1);
      expect(payload.entityUndeleteCount).assertEqual(1);
      expect(payload.entityDeletes[0].timestamp).assertEqual(9);
      expect(payload.entityDeletes[0].siteId).assertEqual(8);
      expect(payload.entityUndeletes[0].timestamp).assertEqual(11);
      expect(payload.entityUndeletes[0].siteId).assertEqual(10);
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

    it('decodes and preflights MODIFY_INK from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundleWithCreateInk(true, true));
      expect(bundle.operations.length).assertEqual(4);
      expect(bundle.operations[3].payloadType).assertEqual(17);
      const modify = decodeOriginalModifyInkTable(bundle.operations[3].payload);
      expect(modify.inks.length).assertEqual(1);
      expect(modify.inks[0].timestamp).assertEqual(20);
      expect(modify.inks[0].siteId).assertEqual(2);
      expect(modify.width).assertEqual(9);
      expect(new OriginalModifyInkOperationApplier().preflightTable(
        bundle.operations[3].payload) === null).assertTrue();
    });

    it('decodes and preflights DELETE_ENTITIES from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(flatBufferNoteBundleWithCreateInk(true, true, true));
      expect(bundle.operations.length).assertEqual(5);
      expect(bundle.operations[4].payloadType).assertEqual(25);
      const deleted = decodeOriginalDeleteEntitiesTable(bundle.operations[4].payload);
      expect(deleted.entityDeletes.length).assertEqual(1);
      expect(deleted.entityDeletes[0].timestamp).assertEqual(20);
      expect(deleted.entityDeletes[0].siteId).assertEqual(2);
      expect(deleted.entityUndeletes.length).assertEqual(1);
      expect(new OriginalDeleteEntitiesOperationApplier().preflightTable(
        bundle.operations[4].payload) === null).assertTrue();
    });

    it('decodes and preflights CREATE_BLOCK from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(
        flatBufferNoteBundleWithCreateInk(true, true, true, true));
      expect(bundle.operations.length).assertEqual(6);
      expect(bundle.operations[5].payloadType).assertEqual(22);
      const block = decodeOriginalCreateBlockTable(
        bundle.operations[5].payload, bundle.operations[5].clientTime);
      expect(block.blockType).assertEqual(OriginalBlockType.TEXT);
      expect(block.page.timestamp).assertEqual(10);
      expect(block.page.siteId).assertEqual(1);
      expect(block.page.index).assertEqual(0);
      expect(block.width).assertEqual(200);
      expect(block.height).assertEqual(40);
      expect(block.zIndex).assertEqual('70');
      expect(new OriginalCreateBlockOperationApplier().preflightTable(
        bundle.operations[5].payload, bundle.operations[5].clientTime) === null).assertTrue();
    });

    it('decodes and preflights MODIFY_BLOCK from a NOTE_BUNDLE child table', 0, () => {
      const bundle = decodeOriginalNoteBundle(
        flatBufferNoteBundleWithCreateInk(true, true, true, true, true));
      expect(bundle.operations.length).assertEqual(7);
      expect(bundle.operations[6].payloadType).assertEqual(23);
      const block = decodeOriginalModifyBlockTable(bundle.operations[6].payload);
      expect(block.blocks.length).assertEqual(1);
      expect(block.blocks[0].timestamp).assertEqual(60);
      expect(block.blocks[0].siteId).assertEqual(6);
      expect(block.zIndex).assertEqual('80');
      expect(block.positionLocked).assertTrue();
      expect(new OriginalModifyBlockOperationApplier().preflightTable(
        bundle.operations[6].payload) === null).assertTrue();
    });

    it('decodes and preflights Text character operations from NOTE_BUNDLE children', 0, () => {
      const bundle = decodeOriginalNoteBundle(
        flatBufferNoteBundleWithCreateInk(true, true, true, true, true, true));
      expect(bundle.operations.length).assertEqual(10);
      expect(bundle.operations[7].payloadType).assertEqual(8);
      const inserted = decodeOriginalInsertTextTable(bundle.operations[7].payload, 8);
      expect(inserted.location === null).assertTrue();
      expect(inserted.textField?.timestamp).assertEqual(60);
      expect(inserted.textField?.siteId).assertEqual(6);
      expect(inserted.scalars.length).assertEqual(2);
      expect(inserted.scalars[0]).assertEqual(0x41);
      expect(inserted.scalars[1]).assertEqual(0x1F600);
      expect(new OriginalInsertTextOperationApplier().preflightTable(
        bundle.operations[7].payload, 8) === null).assertTrue();
      const removed = decodeOriginalTextVisibilityTable(bundle.operations[8].payload, 10);
      const revived = decodeOriginalTextVisibilityTable(bundle.operations[9].payload, 11);
      expect(removed.locations.length).assertEqual(2);
      expect(removed.locations[0].timestamp).assertEqual(80);
      expect(removed.locations[0].siteId).assertEqual(8);
      expect(removed.locations[1].index).assertEqual(1);
      expect(removed.visible).assertFalse();
      expect(revived.visible).assertTrue();
      expect(new OriginalTextVisibilityOperationApplier().preflightTable(
        bundle.operations[8].payload, 10) === null).assertTrue();
      expect(new OriginalTextVisibilityOperationApplier().preflightTable(
        bundle.operations[9].payload, 11) === null).assertTrue();
    });

    it('decodes and preflights rich-text styles from NOTE_BUNDLE children', 0, () => {
      const bundle = decodeOriginalNoteBundle(
        flatBufferNoteBundleWithCreateInk(true, true, true, true, true, true, true));
      expect(bundle.operations.length).assertEqual(13);
      const character = decodeOriginalRichTextStyleTable(bundle.operations[10].payload, 12);
      expect(character.start.location.timestamp).assertEqual(80);
      expect(character.start.location.siteId).assertEqual(8);
      expect(character.end.location.index).assertEqual(1);
      expect(character.attributes.bold).assertTrue();
      expect(character.textField?.timestamp).assertEqual(60);
      const paragraph = decodeOriginalRichTextStyleTable(bundle.operations[11].payload, 13);
      expect(paragraph.paragraph).assertTrue();
      expect(paragraph.attributes.indentLevel).assertEqual(2);
      const cleared = decodeOriginalRichTextStyleTable(bundle.operations[12].payload, 14);
      expect(cleared.clearAll).assertTrue();
      expect(cleared.paragraph).assertFalse();
      const applier = new OriginalRichTextStyleOperationApplier();
      expect(applier.preflightTable(bundle.operations[10].payload, 12) === null).assertTrue();
      expect(applier.preflightTable(bundle.operations[11].payload, 13) === null).assertTrue();
      expect(applier.preflightTable(bundle.operations[12].payload, 14) === null).assertTrue();
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

function flatBufferNoteBundleWithCreateInk(includeAppend: boolean = false,
  includeModify: boolean = false, includeDelete: boolean = false,
  includeCreateBlock: boolean = false, includeModifyBlock: boolean = false,
  includeTextOperations: boolean = false, includeStyleOperations: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 0, 20, 24, 0, 28, 32, 36], 40);
  const uuid: number[] = [0xff, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0x99, 0x88,
    0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00];
  builder.color(root + 4, uuid);
  builder.uint16(root + 20, 9);
  builder.uint16(root + 36, 7);
  const operationCount: number = 2 + (includeAppend ? 1 : 0) + (includeModify ? 1 : 0) +
    (includeDelete ? 1 : 0) + (includeCreateBlock ? 1 : 0) + (includeModifyBlock ? 1 : 0) +
    (includeTextOperations ? 3 : 0) + (includeStyleOperations ? 3 : 0);
  const operations: number = builder.tableVector(operationCount);
  builder.pointer(root + 32, operations);
  const createPageOp: number = builder.table([4, 12, 20, 0, 28, 32, 0], 36);
  const createInkOp: number = builder.table([4, 12, 20, 0, 28, 32, 0], 36);
  const appendOp: number = includeAppend ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const modifyOp: number = includeModify ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const deleteOp: number = includeDelete ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const createBlockOp: number = includeCreateBlock ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const modifyBlockOp: number = includeModifyBlock ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const insertStringOp: number = includeTextOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const removeCharsOp: number = includeTextOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const reviveCharsOp: number = includeTextOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const modifyStyleOp: number = includeStyleOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const paragraphStyleOp: number = includeStyleOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  const clearStyleOp: number = includeStyleOperations ?
    builder.table([4, 12, 20, 0, 28, 32, 0], 36) : 0;
  builder.pointer(operations + 4, createPageOp);
  builder.pointer(operations + 8, createInkOp);
  let operationIndex: number = 2;
  if (includeAppend) {
    builder.pointer(operations + 4 + operationIndex * 4, appendOp);
    operationIndex++;
  }
  if (includeModify) {
    builder.pointer(operations + 4 + operationIndex * 4, modifyOp);
    operationIndex++;
  }
  if (includeDelete) {
    builder.pointer(operations + 4 + operationIndex * 4, deleteOp);
    operationIndex++;
  }
  if (includeCreateBlock) {
    builder.pointer(operations + 4 + operationIndex * 4, createBlockOp);
    operationIndex++;
  }
  if (includeModifyBlock) {
    builder.pointer(operations + 4 + operationIndex * 4, modifyBlockOp);
    operationIndex++;
  }
  if (includeTextOperations) {
    builder.pointer(operations + 4 + operationIndex * 4, insertStringOp);
    builder.pointer(operations + 8 + operationIndex * 4, removeCharsOp);
    builder.pointer(operations + 12 + operationIndex * 4, reviveCharsOp);
    operationIndex += 3;
  }
  if (includeStyleOperations) {
    builder.pointer(operations + 4 + operationIndex * 4, modifyStyleOp);
    builder.pointer(operations + 8 + operationIndex * 4, paragraphStyleOp);
    builder.pointer(operations + 12 + operationIndex * 4, clearStyleOp);
  }
  writeBundleOperation(builder, createPageOp, 1, 10, '11', '12', 3);
  writeBundleOperation(builder, createInkOp, 2, 20, '21', '22', 15);
  if (includeAppend) {
    writeBundleOperation(builder, appendOp, 3, 30, '31', '32', 16);
  }
  if (includeModify) {
    writeBundleOperation(builder, modifyOp, 4, 40, '41', '42', 17);
  }
  if (includeDelete) {
    writeBundleOperation(builder, deleteOp, 5, 50, '51', '52', 25);
  }
  if (includeCreateBlock) {
    writeBundleOperation(builder, createBlockOp, 6, 60, '61', '62', 22);
  }
  if (includeModifyBlock) {
    writeBundleOperation(builder, modifyBlockOp, 7, 70, '71', '72', 23);
  }
  if (includeTextOperations) {
    writeBundleOperation(builder, insertStringOp, 8, 80, '81', '82', 8);
    writeBundleOperation(builder, removeCharsOp, 9, 90, '91', '92', 10);
    writeBundleOperation(builder, reviveCharsOp, 10, 100, '101', '102', 11);
  }
  if (includeStyleOperations) {
    writeBundleOperation(builder, modifyStyleOp, 11, 110, '111', '112', 12);
    writeBundleOperation(builder, paragraphStyleOp, 12, 120, '121', '122', 13);
    writeBundleOperation(builder, clearStyleOp, 13, 130, '131', '132', 14);
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
  if (includeModify) {
    const modify: number = builder.table([4, 0, 0, 0, 0, 0, 0, 8, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0], 12);
    builder.pointer(modifyOp + 32, modify);
    builder.pointer(modify + 4, builder.operationIdentityVector([
      { timestamp: 20, siteId: 2 },
    ]));
    builder.float32(modify + 8, 9);
  }
  if (includeDelete) {
    const deleted: number = builder.table([4, 8, 0, 0], 12);
    builder.pointer(deleteOp + 32, deleted);
    builder.pointer(deleted + 4, builder.operationIdentityVector([
      { timestamp: 20, siteId: 2 },
    ]));
    builder.pointer(deleted + 8, builder.operationIdentityVector([
      { timestamp: 20, siteId: 2 },
    ]));
  }
  if (includeCreateBlock) {
    const block: number = builder.table([
      4, 0, 8, 20, 0, 0, 28, 0, 0, 36,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ], 44);
    builder.pointer(createBlockOp + 32, block);
    builder.uint8(block + 4, OriginalBlockType.TEXT);
    builder.inlineSequence(block + 8, 10, 1, 0);
    builder.float32(block + 20, 12);
    builder.float32(block + 24, 34);
    builder.float32(block + 28, 200);
    builder.float32(block + 32, 40);
    writeDecimalU64At(builder, block + 36, '70');
  }
  if (includeModifyBlock) {
    const block: number = builder.table([
      4, 0, 0, 0, 0, 0, 0, 0, 0, 8,
      0, 0, 0, 0, 0, 0, 0, 16,
    ], 20);
    builder.pointer(modifyBlockOp + 32, block);
    builder.pointer(block + 4, builder.operationIdentityVector([
      { timestamp: 60, siteId: 6 },
    ]));
    writeDecimalU64At(builder, block + 8, '80');
    builder.uint8(block + 16, 1);
  }
  if (includeTextOperations) {
    const inserted: number = builder.table([4, 16, 20], 28);
    builder.pointer(insertStringOp + 32, inserted);
    builder.inlineSequence(inserted + 4, 0, 0xFFFF, 0);
    builder.pointer(inserted + 16, builder.byteVector([0x41, 0xF0, 0x9F, 0x98, 0x80]));
    builder.inlineIdentity(inserted + 20, 60, 6);
    const removed: number = builder.table([4, 8], 16);
    builder.pointer(removeCharsOp + 32, removed);
    builder.pointer(removed + 4, builder.sequenceIdentityVector([
      { timestamp: 80, siteId: 8, index: 0 },
      { timestamp: 80, siteId: 8, index: 1 },
    ]));
    builder.inlineIdentity(removed + 8, 60, 6);
    const revived: number = builder.table([4, 8], 16);
    builder.pointer(reviveCharsOp + 32, revived);
    builder.pointer(revived + 4, builder.sequenceIdentityVector([
      { timestamp: 80, siteId: 8, index: 0 },
      { timestamp: 80, siteId: 8, index: 1 },
    ]));
    builder.inlineIdentity(revived + 8, 60, 6);
  }
  if (includeStyleOperations) {
    const character: number = builder.table([4, 20, 36, 44, 0, 0, 0, 0, 0, 48,
      0, 0, 0, 0, 0], 52);
    builder.pointer(modifyStyleOp + 32, character);
    builder.inlineBoundary(character + 4, 80, 8, 0, 0);
    builder.inlineBoundary(character + 20, 80, 8, 1, 1);
    builder.inlineIdentity(character + 36, 60, 6);
    builder.pointer(character + 44, boolWrapper(builder, true));
    builder.pointer(character + 48, colorWrapper(builder, [17, 34, 51, 255]));
    const paragraph: number = builder.table([4, 16, 28, 0, 0, 0, 0, 32, 0, 0], 40);
    builder.pointer(paragraphStyleOp + 32, paragraph);
    builder.inlineSequence(paragraph + 4, 80, 8, 0);
    builder.inlineSequence(paragraph + 16, 80, 8, 1);
    builder.pointer(paragraph + 28, enumWrapper(builder, 2));
    builder.inlineIdentity(paragraph + 32, 60, 6);
    const cleared: number = builder.table([4, 20, 36, 40], 48);
    builder.pointer(clearStyleOp + 32, cleared);
    builder.inlineBoundary(cleared + 4, 0, 0xFFFF, 0, 0);
    builder.inlineBoundary(cleared + 20, 0, 0xFFFF, 0, 3);
    builder.uint8(cleared + 36, 0);
    builder.inlineIdentity(cleared + 40, 60, 6);
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
  private bytes: Uint8Array = new Uint8Array(2048);
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

  recordingSegmentVector(values: { startTime: string, endTime: string }[]): number {
    this.align(8);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length * 16;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      writeDecimalU64(this.bytes, vector + 4 + index * 16, values[index].startTime);
      writeDecimalU64(this.bytes, vector + 12 + index * 16, values[index].endTime);
    }
    return vector;
  }

  pointVector(values: { x: number, y: number }[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length * 8;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      this.float32(vector + 4 + index * 8, values[index].x);
      this.float32(vector + 8 + index * 8, values[index].y);
    }
    return vector;
  }

  inlineBytes(size: number): number {
    this.align(4);
    const start: number = this.cursor;
    this.cursor += size;
    return start;
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

  cropBoxVector(values: { width: number, height: number }[]): number {
    this.align(4);
    const vector: number = this.cursor;
    this.cursor += 4 + values.length * 8;
    writeU32(this.bytes, vector, values.length);
    for (let index: number = 0; index < values.length; index++) {
      this.float32(vector + 4 + index * 8, values[index].width);
      this.float32(vector + 8 + index * 8, values[index].height);
    }
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

function flatBufferUpdateCheckbox(checked: boolean, includeTarget: boolean = true,
  includeUnknown: boolean = false, includeLocation: boolean = true): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  const payload: number = builder.table(
    [includeTarget ? 4 : 0, includeLocation ? 12 : 0,
      checked ? 24 : 0, includeUnknown ? 25 : 0], 28);
  if (includeTarget) {
    builder.inlineIdentity(payload + 4, 20, 2);
  }
  if (includeLocation) {
    builder.inlineSequence(payload + 12, 100, 7, 3);
  }
  if (checked) {
    builder.uint8(payload + 24, 1);
  }
  if (includeUnknown) {
    builder.uint8(payload + 25, 1);
  }
  return styleEnvelope(28, root, payload, builder);
}

function flatBufferModifyPdfField(valueType: number, includeHash: boolean = true,
  includeKey: boolean = true, includeString: boolean = false,
  includeBoolean: boolean = false, includeUnknown: boolean = false,
  stringValue: string = '', booleanValue: boolean = true): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  const payload: number = builder.table([
    includeHash ? 4 : 0, includeKey ? 68 : 0,
    valueType === 0 ? 0 : 72, includeString ? 76 : 0,
    includeBoolean ? 80 : 0, includeUnknown ? 81 : 0,
  ], 84);
  if (includeHash) {
    for (let index: number = 0; index < 64; index++) {
      builder.uint8(payload + 4 + index, index);
    }
  }
  if (includeKey) {
    builder.pointer(payload + 68, builder.string('name'));
  }
  if (valueType !== 0) {
    builder.uint8(payload + 72, valueType);
  }
  if (includeString) {
    builder.pointer(payload + 76, builder.string(stringValue));
  }
  if (includeBoolean) {
    builder.uint8(payload + 80, booleanValue ? 1 : 0);
  }
  if (includeUnknown) {
    builder.uint8(payload + 81, 1);
  }
  return styleEnvelope(27, root, payload, builder);
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

function flatBufferSetMetadataBackground(includeValue: boolean, title: string | null = null): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 91);
  builder.uint8(root + 28, 1);
  const metadata: number = builder.table([title === null ? 0 : 4, 8, 0, 0, 0, 0, 0, 0], 12);
  builder.pointer(root + 32, metadata);
  if (title !== null) {
    const titleSetter: number = stringWrapper(builder, title);
    builder.pointer(metadata + 4, titleSetter);
  }
  const setter: number = builder.table([includeValue ? 4 : 0], includeValue ? 8 : 4);
  builder.pointer(metadata + 8, setter);
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

function flatBufferCreatePagePdfBackground(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 4);
  builder.uint32(root + 8, 10);
  builder.uint8(root + 28, 3);
  const create: number = builder.table([0, 4, 8, 0], 12);
  builder.pointer(root + 32, create);
  builder.uint32(create + 8, 2);
  builder.pointer(create + 4, pdfPageBackground(builder, 2, 4));
  return builder.finish(root);
}

function flatBufferModifyPagePdfBackground(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 92);
  builder.uint8(root + 28, 4);
  const modify: number = builder.table([4, 0, 8, 0], 12);
  builder.pointer(root + 32, modify);
  const pages: number = builder.sequenceIdentityVector([
    { timestamp: 10, siteId: 1, index: 2 },
    { timestamp: 20, siteId: 3, index: 4 },
  ]);
  builder.pointer(modify + 4, pages);
  const setter: number = builder.table([4], 8);
  builder.pointer(modify + 8, setter);
  builder.pointer(setter + 4, pdfPageBackground(builder, 2, 7));
  return builder.finish(root);
}

function flatBufferSetMetadataPdfBackground(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 93);
  builder.uint8(root + 28, 1);
  const metadata: number = builder.table([0, 4, 0, 0, 0, 0, 0, 0], 8);
  builder.pointer(root + 32, metadata);
  const setter: number = builder.table([4], 8);
  builder.pointer(metadata + 4, setter);
  builder.pointer(setter + 4, pdfPageBackground(builder, 1, 3));
  return builder.finish(root);
}

function pdfPageBackground(builder: FixtureFlatBufferBuilder,
  pagesConsumed: number, pageOffset: number): number {
  const background: number = builder.table([0, 4, 8, 12, 0], 20);
  builder.float32(background + 8, 0);
  builder.float32(background + 12, 612);
  builder.float32(background + 16, 792);
  const pdf: number = builder.table([4, 8, 12, 16, 20, 24], 28);
  builder.pointer(background + 4, pdf);
  builder.uint8(pdf + 8, 1);
  builder.uint32(pdf + 12, 12);
  builder.uint32(pdf + 16, pagesConsumed);
  builder.uint32(pdf + 20, pageOffset);
  const asset: number = builder.table([4, 68, 72, 76], 80);
  builder.pointer(pdf + 4, asset);
  const hashWords: string[] = ['1', '2', '3', '4', '5', '6', '7', '18446744073709551615'];
  for (let index: number = 0; index < hashWords.length; index++) {
    writeDecimalU64At(builder, asset + 4 + index * 8, hashWords[index]);
  }
  const fileName: number = builder.string('source.pdf');
  builder.pointer(asset + 68, fileName);
  const mimeType: number = builder.string('application/pdf');
  builder.pointer(asset + 72, mimeType);
  builder.uint32(asset + 76, 4096);
  const crops: { width: number, height: number }[] = [];
  for (let index: number = 0; index < pagesConsumed; index++) {
    crops.push({ width: 612, height: 792 });
  }
  builder.pointer(pdf + 24, builder.cropBoxVector(crops));
  return background;
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

function flatBufferAssetCloudPersisted(includeHash: boolean = true,
  truncated: boolean = false, extraField: boolean = false,
  includeAudioTime: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, includeAudioTime ? 36 : 0, 28, 32],
    includeAudioTime ? 44 : 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 92);
  writeDecimalU64At(builder, root + 12, '123');
  writeDecimalU64At(builder, root + 20, '124');
  builder.uint8(root + 28, 2);
  if (includeAudioTime) {
    writeDecimalU64At(builder, root + 36, '99');
  }
  const objectSize: number = truncated ? 60 : (extraField ? 72 : 68);
  const payload: number = builder.table(
    [includeHash ? 4 : 0, extraField ? 68 : 0], objectSize);
  builder.pointer(root + 32, payload);
  if (includeHash) {
    const byteCount: number = truncated ? 56 : 64;
    for (let index: number = 0; index < byteCount; index++) {
      builder.uint8(payload + 4 + index, index);
    }
  }
  if (extraField) {
    builder.uint8(payload + 68, 1);
  }
  return builder.finish(root);
}

function flatBufferTransientInteractionEnded(includeMetadata: boolean = true,
  matchingInteraction: boolean = true, includeTimeout: boolean = false,
  includeUnknownPayloadField: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32, includeMetadata ? 36 : 0], 40);
  builder.inlineIdentity(root + 4, 300, 7);
  writeDecimalU64At(builder, root + 12, '400');
  writeDecimalU64At(builder, root + 20, '500');
  builder.uint8(root + 28, ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE);
  const payload: number = builder.table([4, 12, includeUnknownPayloadField ? 20 : 0],
    includeUnknownPayloadField ? 24 : 20);
  builder.inlineIdentity(payload + 4, 80, 6);
  builder.inlineIdentity(payload + 12, 90, 7);
  if (includeUnknownPayloadField) {
    builder.uint8(payload + 20, 1);
  }
  builder.pointer(root + 32, payload);
  if (includeMetadata) {
    const metadata: number = builder.table([4, includeTimeout ? 12 : 0],
      includeTimeout ? 16 : 12);
    builder.inlineIdentity(metadata + 4, matchingInteraction ? 80 : 81, 6);
    if (includeTimeout) {
      builder.uint32(metadata + 12, 10);
    }
    builder.pointer(root + 36, metadata);
  }
  return builder.finish(root);
}

function flatBufferPeerInteraction(includeMetadata: boolean = true,
  matchingInteraction: boolean = true, includeReservedField: boolean = false,
  includeUnknownField: boolean = false, includeCursor: boolean = true,
  tool: number = 1, recording: number = 1, operationTimestamp: number = 310): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32, includeMetadata ? 36 : 0], 40);
  builder.inlineIdentity(root + 4, operationTimestamp, 8);
  writeDecimalU64At(builder, root + 12, '410');
  writeDecimalU64At(builder, root + 20, '510');
  builder.uint8(root + 28, ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE);
  const payload: number = builder.table([
    includeCursor ? 4 : 0, includeReservedField ? 28 : 0, 0, 12, 16, 20, 24,
    includeUnknownField ? 29 : 0,
  ], 36);
  if (includeCursor) {
    builder.float32(payload + 4, 12.5);
    builder.float32(payload + 8, -4.25);
  }
  const selected: number = builder.operationIdentityVector([
    { timestamp: 20, siteId: 2 },
    { timestamp: 20, siteId: 2 },
    { timestamp: 21, siteId: 3 },
  ]);
  builder.pointer(payload + 12, selected);
  builder.uint8(payload + 16, tool);
  const selection: number = builder.table([4, 16], 28);
  builder.inlineSequence(selection + 4, 30, 4, 2);
  builder.inlineSequence(selection + 16, 31, 5, 4);
  builder.pointer(payload + 20, selection);
  builder.uint8(payload + 24, recording);
  if (includeReservedField) {
    builder.uint8(payload + 28, 1);
  }
  if (includeUnknownField) {
    builder.uint8(payload + 29, 1);
  }
  builder.pointer(root + 32, payload);
  if (includeMetadata) {
    const metadata: number = builder.table([4], 12);
    builder.inlineIdentity(metadata + 4,
      matchingInteraction ? operationTimestamp : operationTimestamp + 1, 8);
    builder.pointer(root + 36, metadata);
  }
  return builder.finish(root);
}

function flatBufferCreateComment(anchorType: number, text: string = 'comment',
  finiteOrigin: boolean = true, includeUnknown: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 320, 8);
  writeDecimalU64At(builder, root + 12, '1');
  writeDecimalU64At(builder, root + 20, '2');
  builder.uint8(root + 28, ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE);
  const payload: number = builder.table([4, anchorType === 0 ? 0 : 8, 12,
    includeUnknown ? 16 : 0], 20);
  builder.uint8(payload + 4, anchorType);
  builder.pointer(payload + 12, builder.string(text));
  if (anchorType === OriginalCommentAnchorType.CANVAS) {
    const anchor: number = builder.inlineBytes(20);
    builder.inlineSequence(anchor, 40, 2, 3);
    builder.float32(anchor + 12, finiteOrigin ? 12.5 : Number.NaN);
    builder.float32(anchor + 16, -4.25);
    builder.pointer(payload + 8, anchor);
  } else if (anchorType === OriginalCommentAnchorType.TEXT) {
    const anchor: number = builder.table([4, 12], 16);
    builder.inlineIdentity(anchor + 4, 50, 5);
    const selection: number = builder.table([4, 16], 28);
    builder.inlineSequence(selection + 4, 60, 6, 4);
    builder.inlineSequence(selection + 16, 61, 6, 7);
    builder.pointer(anchor + 12, selection);
    builder.pointer(payload + 8, anchor);
  } else if (anchorType === OriginalCommentAnchorType.ENTITY) {
    const anchor: number = builder.table([4], 8);
    const entities: number = builder.operationIdentityVector([
      { timestamp: 70, siteId: 7 }, { timestamp: 70, siteId: 7 },
      { timestamp: 71, siteId: 8 },
    ]);
    builder.pointer(anchor + 4, entities);
    builder.pointer(payload + 8, anchor);
  } else if (anchorType === OriginalCommentAnchorType.REPLY) {
    const anchor: number = builder.inlineBytes(8);
    builder.inlineIdentity(anchor, 80, 9);
    builder.pointer(payload + 8, anchor);
  }
  if (includeUnknown) {
    builder.uint8(payload + 16, 1);
  }
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferModifyComment(includeAnchor: boolean, includeText: boolean,
  text: string | null, includeResolved: boolean, resolved: number | null,
  includeUnknown: boolean = false, includeComment: boolean = true): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 321, 8);
  writeDecimalU64At(builder, root + 12, '3');
  writeDecimalU64At(builder, root + 20, '4');
  builder.uint8(root + 28, ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE);
  const payload: number = builder.table([
    includeComment ? 4 : 0, includeAnchor ? 12 : 0,
    includeText ? 32 : 0, includeResolved ? 36 : 0,
    includeUnknown ? 40 : 0,
  ], 44);
  if (includeComment) {
    builder.inlineIdentity(payload + 4, 90, 10);
  }
  if (includeAnchor) {
    builder.inlineSequence(payload + 12, 41, 2, 5);
    builder.float32(payload + 24, 20);
    builder.float32(payload + 28, 30);
  }
  if (includeText) {
    const setter: number = builder.table([text === null ? 0 : 4], 8);
    if (text !== null) {
      builder.pointer(setter + 4, builder.string(text));
    }
    builder.pointer(payload + 32, setter);
  }
  if (includeResolved) {
    const setter: number = builder.table([resolved === null ? 0 : 4], 8);
    if (resolved !== null) {
      builder.uint8(setter + 4, resolved);
    }
    builder.pointer(payload + 36, setter);
  }
  if (includeUnknown) {
    builder.uint8(payload + 40, 1);
  }
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferCreateRecording(includeAsset: boolean = true,
  segmentPastEnd: boolean = false, includeUnknown: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 330, 9);
  writeDecimalU64At(builder, root + 12, '18446744073709551614');
  writeDecimalU64At(builder, root + 20, '18446744073709551615');
  builder.uint8(root + 28, ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE);
  const payload: number = builder.table([
    includeAsset ? 4 : 0, 8, 16, 24, 28, 32, includeUnknown ? 40 : 0,
  ], 44);
  writeDecimalU64At(builder, payload + 8, '18446744073709551600');
  writeDecimalU64At(builder, payload + 16,
    segmentPastEnd ? '18446744073709551610' : '18446744073709551615');
  builder.pointer(payload + 24, builder.string('Lecture'));
  const segments: number = builder.recordingSegmentVector([
    { startTime: '18446744073709551600', endTime: '18446744073709551605' },
    {
      startTime: '18446744073709551606',
      endTime: '18446744073709551615',
    },
  ]);
  builder.pointer(payload + 28, segments);
  writeDecimalU64At(builder, payload + 32, '18446744073709551614');
  if (includeUnknown) {
    builder.uint8(payload + 40, 1);
  }
  if (includeAsset) {
    const recording: number = builder.table([4], 8);
    builder.pointer(payload + 4, recording);
    const metadata: number = builder.table([4, 68, 72, 76], 80);
    builder.pointer(recording + 4, metadata);
    for (let index: number = 0; index < 8; index++) {
      writeDecimalU64At(builder, metadata + 4 + index * 8, (index + 1).toString());
    }
    builder.pointer(metadata + 68, builder.string('audio.m4a'));
    builder.pointer(metadata + 72, builder.string('audio/mp4'));
    builder.uint32(metadata + 76, 4096);
  }
  return builder.finish(root);
}

function flatBufferModifyRecording(includeName: boolean = true,
  includeSegments: boolean = true, includeZIndex: boolean = true,
  includeTarget: boolean = true): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 331, 9);
  writeDecimalU64At(builder, root + 12, '18446744073709551613');
  writeDecimalU64At(builder, root + 20, '18446744073709551614');
  builder.uint8(root + 28, ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE);
  const payload: number = builder.table([
    includeTarget ? 4 : 0, includeName ? 12 : 0,
    includeSegments ? 16 : 0, includeZIndex ? 24 : 0,
  ], 32);
  if (includeTarget) {
    builder.inlineIdentity(payload + 4, 330, 9);
  }
  if (includeName) {
    builder.pointer(payload + 12, builder.string('Renamed'));
  }
  if (includeSegments) {
    builder.pointer(payload + 16, builder.recordingSegmentVector([
      { startTime: '18446744073709551600', endTime: '18446744073709551615' },
    ]));
  }
  if (includeZIndex) {
    writeDecimalU64At(builder, payload + 24, '18446744073709551613');
  }
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferCreateShape(includeUnknown: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 410, 7);
  writeDecimalU64At(builder, root + 12, '70');
  writeDecimalU64At(builder, root + 20, '80');
  builder.uint8(root + 28, ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE);
  const offsets: number[] = [4, 16, 0, 0, 24, 28, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0];
  if (includeUnknown) {
    offsets.push(36);
  }
  const payload: number = builder.table(offsets, 40);
  builder.inlineSequence(payload + 4, 400, 5, 2);
  builder.float32(payload + 16, 12.5);
  builder.float32(payload + 20, -3.25);
  builder.uint8(payload + 24, OriginalShapeDefinitionType.ELLIPSE);
  const ellipse: number = builder.table([0, 4], 12);
  builder.float32(ellipse + 4, 20);
  builder.float32(ellipse + 8, 10);
  builder.pointer(payload + 28, ellipse);
  builder.color(payload + 32, [10, 20, 30, 255]);
  if (includeUnknown) {
    builder.uint8(payload + 36, 1);
  }
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferModifyShape(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 420, 7);
  writeDecimalU64At(builder, root + 12, '81');
  writeDecimalU64At(builder, root + 20, '82');
  builder.uint8(root + 28, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE);
  const payload: number = builder.table([
    4, 0, 0, 8, 0, 0, 0, 0, 0, 0, 12, 0, 0, 16, 0, 0, 0,
  ], 24);
  builder.pointer(payload + 4, builder.operationIdentityVector([
    { timestamp: 410, siteId: 7 }, { timestamp: 411, siteId: 8 },
  ]));
  const clearRotation: number = builder.table([0], 4);
  builder.pointer(payload + 8, clearRotation);
  builder.color(payload + 12, [1, 2, 3, 128]);
  writeDecimalU64At(builder, payload + 16, '18446744073709551615');
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferCreateGroup(): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 500, 9);
  writeDecimalU64At(builder, root + 12, '83');
  writeDecimalU64At(builder, root + 20, '84');
  builder.uint8(root + 28, ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE);
  const payload: number = builder.table([4], 8);
  builder.pointer(payload + 4, builder.operationIdentityVector([
    { timestamp: 101, siteId: 3 }, { timestamp: 102, siteId: 4 },
  ]));
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferModifyGroup(includeGroup: boolean = true): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.inlineIdentity(root + 4, 501, 9);
  writeDecimalU64At(builder, root + 12, '85');
  writeDecimalU64At(builder, root + 20, '86');
  builder.uint8(root + 28, ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE);
  const payload: number = builder.table([includeGroup ? 4 : 0, 12], 16);
  if (includeGroup) {
    builder.inlineIdentity(payload + 4, 500, 9);
  }
  builder.pointer(payload + 12, builder.operationIdentityVector([
    { timestamp: 102, siteId: 4 },
  ]));
  builder.pointer(root + 32, payload);
  return builder.finish(root);
}

function flatBufferModifyPositions(repeatTarget: boolean = false,
  unpairedPage: boolean = false): Uint8Array {
  const builder = new FixtureFlatBufferBuilder();
  const root: number = builder.table([4, 12, 20, 0, 28, 32], 36);
  builder.uint16(root + 4, 7);
  builder.uint32(root + 8, 300);
  writeDecimalU64At(builder, root + 12, '400');
  writeDecimalU64At(builder, root + 20, '500');
  builder.uint8(root + 28, 24);
  const payload: number = builder.table([4], 8);
  builder.pointer(root + 32, payload);
  const modifications: number = builder.tableVector(2);
  builder.pointer(payload + 4, modifications);

  const first: number = builder.table([4, 12, unpairedPage ? 0 : 24, 32, 36, 40], 48);
  builder.pointer(modifications + 4, first);
  builder.inlineIdentity(first + 4, 10, 1);
  builder.inlineSequence(first + 12, 100, 2, 3);
  if (!unpairedPage) {
    builder.float32(first + 24, 1.5);
    builder.float32(first + 28, -2);
  }
  const rotation: number = builder.table([4], 8);
  builder.pointer(first + 32, rotation);
  builder.float32(rotation + 4, 0.5);
  const scale: number = builder.table([4], 12);
  builder.pointer(first + 36, scale);
  builder.float32(scale + 4, 2);
  builder.float32(scale + 8, 3);
  writeDecimalU64At(builder, first + 40, '18446744073709551615');

  const second: number = builder.table([4, 0, 0, 12, 16, 0], 20);
  builder.pointer(modifications + 8, second);
  builder.inlineIdentity(second + 4, repeatTarget ? 10 : 20, repeatTarget ? 1 : 4);
  const clearRotation: number = builder.table([0], 4);
  builder.pointer(second + 12, clearRotation);
  const clearScale: number = builder.table([0], 4);
  builder.pointer(second + 16, clearScale);
  return builder.finish(root);
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
