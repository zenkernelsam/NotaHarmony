import { relationalStore } from '@kit.ArkData';
import {
  ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE, OriginalCreatePageOperationApplier,
} from './OriginalCreatePageOperation';
import {
  ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE, OriginalModifyPageOperationApplier,
} from './OriginalModifyPageOperation';
import {
  StoredSyncedOperation, SyncedOperationApplier, SyncedOperationApplyResult,
} from './SyncedOperationInbox';

export class OriginalPageOperationApplier implements SyncedOperationApplier {
  private createPage: OriginalCreatePageOperationApplier = new OriginalCreatePageOperationApplier();
  private modifyPage: OriginalModifyPageOperationApplier = new OriginalModifyPageOperationApplier();

  supports(payloadType: number): boolean {
    return payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE ||
      payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE;
  }

  async apply(store: relationalStore.RdbStore,
    operation: StoredSyncedOperation): Promise<SyncedOperationApplyResult> {
    if (operation.payloadType === ORIGINAL_CREATE_PAGE_PAYLOAD_TYPE) {
      return this.createPage.apply(store, operation);
    }
    if (operation.payloadType === ORIGINAL_MODIFY_PAGE_PAYLOAD_TYPE) {
      return this.modifyPage.apply(store, operation);
    }
    throw new Error('original page operation applier received an unsupported payload');
  }
}
