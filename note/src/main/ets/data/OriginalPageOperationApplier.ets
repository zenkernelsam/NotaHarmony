import { relationalStore } from '@kit.ArkData';
import {
  ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE, OriginalCreatePageOperationApplier,
} from './OriginalCreatePageOperation';
import {
  ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE, OriginalModifyPageOperationApplier,
} from './OriginalModifyPageOperation';
import {
  ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE, OriginalDeleteEntitiesOperationApplier,
} from './OriginalDeleteEntitiesOperation';
import {
  ORIGINAL_CREATE_INK_PAYLOAD_TYPE, OriginalCreateInkOperationApplier,
} from './OriginalCreateInkOperation';
import {
  ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE, OriginalAddPathElementsOperationApplier,
} from './OriginalAddPathElementsOperation';
import {
  ORIGINAL_MODIFY_INK_PAYLOAD_TYPE, OriginalModifyInkOperationApplier,
} from './OriginalModifyInkOperation';
import {
  ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE, OriginalCreateBlockOperationApplier,
} from './OriginalCreateBlockOperation';
import {
  ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE, OriginalModifyBlockOperationApplier,
} from './OriginalModifyBlockOperation';
import {
  ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE, ORIGINAL_INSERT_STRING_PAYLOAD_TYPE,
  ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE, ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE,
  ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE, OriginalInsertTextOperationApplier,
  OriginalTextVisibilityOperationApplier,
} from './OriginalInsertTextOperation';
import {
  ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE, ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE,
  ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE, OriginalRichTextStyleOperationApplier,
} from './OriginalRichTextStyleOperation';
import {
  ORIGINAL_SET_METADATA_PAYLOAD_TYPE, OriginalSetMetadataOperationApplier,
} from './OriginalSetMetadataOperation';
import {
  ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE, OriginalAssetCloudPersistedOperationApplier,
} from './OriginalAssetCloudPersistedOperation';
import {
  ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE, OriginalModifyPositionsOperationApplier,
} from './OriginalModifyPositionsOperation';
import {
  ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE, OriginalUpdateCheckboxOperationApplier,
} from './OriginalUpdateCheckboxOperation';
import {
  ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE, OriginalModifyPdfFieldOperationApplier,
} from './OriginalModifyPdfFieldOperation';
import {
  decodeOriginalTransientInteractionEnded,
  ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE,
  OriginalTransientInteractionEndedPayload, OriginalTransientInteractionStore,
} from './OriginalTransientInteractionOperation';
import {
  decodeOriginalPeerInteraction, ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE,
} from './OriginalPeerInteractionOperation';
import {
  decodeOriginalCreateComment, decodeOriginalModifyComment,
  ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE, ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE,
} from './OriginalCommentOperation';
import {
  ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE, ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE,
  OriginalRecordingOperationApplier,
} from './OriginalRecordingOperation';
import {
  ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE, ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE,
  ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE, ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE,
  OriginalShapeGroupOperationApplier,
} from './OriginalShapeGroupOperation';
import {
  OriginalFlatBufferTableReader,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export class OriginalPageOperationApplier implements SyncedOperationApplier {
  private transientInteractions: OriginalTransientInteractionStore;
  private setMetadata: OriginalSetMetadataOperationApplier = new OriginalSetMetadataOperationApplier();
  private assetCloudPersisted: OriginalAssetCloudPersistedOperationApplier =
    new OriginalAssetCloudPersistedOperationApplier();
  private modifyPositions: OriginalModifyPositionsOperationApplier =
    new OriginalModifyPositionsOperationApplier();
  private createPage: OriginalCreatePageOperationApplier = new OriginalCreatePageOperationApplier();
  private modifyPage: OriginalModifyPageOperationApplier = new OriginalModifyPageOperationApplier();
  private deleteEntities: OriginalDeleteEntitiesOperationApplier =
    new OriginalDeleteEntitiesOperationApplier();
  private createInk: OriginalCreateInkOperationApplier = new OriginalCreateInkOperationApplier();
  private addPathElements: OriginalAddPathElementsOperationApplier =
    new OriginalAddPathElementsOperationApplier();
  private modifyInk: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();
  private createBlock: OriginalCreateBlockOperationApplier =
    new OriginalCreateBlockOperationApplier();
  private modifyBlock: OriginalModifyBlockOperationApplier =
    new OriginalModifyBlockOperationApplier();
  private insertText: OriginalInsertTextOperationApplier =
    new OriginalInsertTextOperationApplier();
  private textVisibility: OriginalTextVisibilityOperationApplier =
    new OriginalTextVisibilityOperationApplier();
  private richTextStyle: OriginalRichTextStyleOperationApplier =
    new OriginalRichTextStyleOperationApplier();
  private updateCheckbox: OriginalUpdateCheckboxOperationApplier =
    new OriginalUpdateCheckboxOperationApplier();
  private modifyPdfField: OriginalModifyPdfFieldOperationApplier =
    new OriginalModifyPdfFieldOperationApplier();
  private recording: OriginalRecordingOperationApplier = new OriginalRecordingOperationApplier();
  private shapeGroup: OriginalShapeGroupOperationApplier = new OriginalShapeGroupOperationApplier();

  constructor(transientInteractions: OriginalTransientInteractionStore =
    new OriginalTransientInteractionStore()) {
    this.transientInteractions = transientInteractions;
  }

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_INSERT_STRING_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_SHAPE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_GROUP_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    let root: OriginalFlatBufferTableReader;
    try {
      root = OriginalFlatBufferTableReader.fromRoot(operation.rawOperation);
      if (operation.payloadType !== ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE &&
        operation.payloadType !== ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE &&
        root.hasField(6)) {
        return { deferredReason: 'TRANSIENT_ORIGINAL_OPERATION_UNSUPPORTED' };
      }
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ORIGINAL_OPERATION' };
    }
    if (operation.payloadType === ORIGINAL_TRANSIENT_INTERACTION_ENDED_PAYLOAD_TYPE) {
      let payload: OriginalTransientInteractionEndedPayload;
      try {
        payload = decodeOriginalTransientInteractionEnded(operation.rawOperation);
      } catch (_error) {
        return { deferredReason: 'MALFORMED_TRANSIENT_INTERACTION_ENDED_PAYLOAD' };
      }
      this.transientInteractions.endInteraction(operation.noteId, payload.interactionId);
      return { deferredReason: null };
    }
    if (operation.payloadType === ORIGINAL_PEER_INTERACTION_PAYLOAD_TYPE) {
      try {
        decodeOriginalPeerInteraction(operation.rawOperation);
      } catch (_error) {
        // The original mzc peer branch catches malformed peer payloads, removes them from model
        // replay and continues the batch. They must not block unrelated durable operations.
      }
      return { deferredReason: null };
    }
    if (operation.payloadType === ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_MODIFY_COMMENT_PAYLOAD_TYPE) {
      try {
        if (operation.payloadType === ORIGINAL_CREATE_COMMENT_PAYLOAD_TYPE) {
          decodeOriginalCreateComment(operation.rawOperation);
        } else {
          decodeOriginalModifyComment(operation.rawOperation);
        }
      } catch (_error) {
        return { deferredReason: 'MALFORMED_COMMENT_PAYLOAD' };
      }
      // Original 1.0.3 validates both schemas but v69/fsi route neither payload into a model.
      return { deferredReason: null };
    }
    if (operation.payloadType === ORIGINAL_SET_METADATA_PAYLOAD_TYPE) {
      return this.setMetadata.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_ASSET_CLOUD_PERSISTED_PAYLOAD_TYPE) {
      return this.assetCloudPersisted.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_POSITIONS_PAYLOAD_TYPE) {
      return this.modifyPositions.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE) {
      return this.createPage.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE) {
      return this.modifyPage.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE) {
      return this.deleteEntities.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE) {
      return this.createInk.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE) {
      return this.addPathElements.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE) {
      return this.modifyInk.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_CREATE_BLOCK_PAYLOAD_TYPE) {
      return this.createBlock.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_BLOCK_PAYLOAD_TYPE) {
      return this.modifyBlock.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_INSERT_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_INSERT_STRING_PAYLOAD_TYPE) {
      return this.insertText.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_REMOVE_CHAR_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REMOVE_CHARS_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_REVIVE_CHARS_PAYLOAD_TYPE) {
      return this.textVisibility.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_STYLE_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_MODIFY_PARAGRAPH_STYLE_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE) {
      return this.richTextStyle.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_UPDATE_CHECKBOX_PAYLOAD_TYPE) {
      return this.updateCheckbox.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_PDF_FIELD_PAYLOAD_TYPE) {
      return this.modifyPdfField.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE ||
      operation.payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE) {
      return this.recording.apply(store, operation);
    }
    if (operation.payloadType >= ORIGINAL_CREATE_SHAPE_PAYLOAD_TYPE &&
      operation.payloadType <= ORIGINAL_MODIFY_GROUP_PAYLOAD_TYPE) {
      return this.shapeGroup.apply(store, operation);
    }
    throw new Error('original page operation applier received an unsupported payload');
  }
}
