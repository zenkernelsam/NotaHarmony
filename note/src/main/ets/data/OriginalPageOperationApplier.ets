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
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export class OriginalPageOperationApplier implements SyncedOperationApplier {
  private createPage: OriginalCreatePageOperationApplier = new OriginalCreatePageOperationApplier();
  private modifyPage: OriginalModifyPageOperationApplier = new OriginalModifyPageOperationApplier();
  private deleteEntities: OriginalDeleteEntitiesOperationApplier =
    new OriginalDeleteEntitiesOperationApplier();
  private createInk: OriginalCreateInkOperationApplier = new OriginalCreateInkOperationApplier();
  private addPathElements: OriginalAddPathElementsOperationApplier =
    new OriginalAddPathElementsOperationApplier();
  private modifyInk: OriginalModifyInkOperationApplier = new OriginalModifyInkOperationApplier();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_DELETE_ENTITIES_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_ADD_PATH_ELEMENTS_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_INK_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
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
    throw new Error('original page operation applier received an unsupported payload');
  }
}
