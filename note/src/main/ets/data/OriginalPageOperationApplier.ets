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
  OriginalFlatBufferTableReader,
} from './OriginalSyncedOperationFlatBuffer';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export class OriginalPageOperationApplier implements SyncedOperationApplier {
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
      payloadType === ORIGINAL_CLEAR_STYLE_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    try {
      if (OriginalFlatBufferTableReader.fromRoot(operation.rawOperation).readUint8(3, 0) !== 0) {
        return { deferredReason: 'TRANSIENT_ORIGINAL_OPERATION_UNSUPPORTED' };
      }
    } catch (_error) {
      return { deferredReason: 'MALFORMED_ORIGINAL_OPERATION' };
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
    throw new Error('original page operation applier received an unsupported payload');
  }
}
