import { describe, expect, it } from '@ohos/hypium';
import {
  ensureOriginalClipboardReadPermission, READ_PASTEBOARD_PERMISSION,
  resetOriginalClipboardPermissionRequesterForTest,
  setOriginalClipboardPermissionRequesterForTest,
} from '../main/ets/data/OriginalClipboardPermissionGateway';

export default function originalClipboardPermissionGatewayTest() {
  describe('OriginalClipboardPermissionGateway', () => {
    it('requests the exact SDK pasteboard permission', 0, async () => {
      const requested: string[] = [];
      setOriginalClipboardPermissionRequesterForTest(
        async (permission: string): Promise<boolean> => {
          requested.push(permission);
          return true;
        });
      expect(await ensureOriginalClipboardReadPermission()).assertTrue();
      expect(requested.length).assertEqual(1);
      expect(requested[0]).assertEqual('ohos.permission.READ_PASTEBOARD');
      expect(READ_PASTEBOARD_PERMISSION).assertEqual('ohos.permission.READ_PASTEBOARD');
      resetOriginalClipboardPermissionRequesterForTest();
    });

    it('fails closed when permission is denied or malformed', 0, async () => {
      setOriginalClipboardPermissionRequesterForTest(
        async (_permission: string): Promise<boolean> => false);
      expect(await ensureOriginalClipboardReadPermission()).assertFalse();
      setOriginalClipboardPermissionRequesterForTest(
        async (_permission: string): Promise<boolean> => {
          throw new Error('permission request failed');
        });
      let failure = '';
      try {
        await ensureOriginalClipboardReadPermission();
      } catch (e) {
        failure = (e as Error).message;
      }
      expect(failure).assertEqual('permission request failed');
      resetOriginalClipboardPermissionRequesterForTest();
    });
  });
}
