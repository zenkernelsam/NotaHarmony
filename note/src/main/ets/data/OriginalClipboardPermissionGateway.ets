import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';

export const READ_PASTEBOARD_PERMISSION: Permissions = 'ohos.permission.READ_PASTEBOARD';

export type OriginalClipboardPermissionRequester =
  (permission: Permissions) => Promise<boolean>;

let requestOriginalClipboardPermission: OriginalClipboardPermissionRequester =
  requestWithHarmonyAccessControl;

export function setOriginalClipboardPermissionRequesterForTest(
  requester: OriginalClipboardPermissionRequester): void {
  requestOriginalClipboardPermission = requester;
}

export function resetOriginalClipboardPermissionRequesterForTest(): void {
  requestOriginalClipboardPermission = requestWithHarmonyAccessControl;
}

async function requestWithHarmonyAccessControl(
  permission: Permissions): Promise<boolean> {
  const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  const context: common.UIAbilityContext = getContext() as common.UIAbilityContext;
  const result: PermissionRequestResult = await manager.requestPermissionsFromUser(
    context, [permission]);
  return result.permissions.length === 1 &&
    result.permissions[0] === permission && result.authResults.length === 1 &&
    result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}

export async function ensureOriginalClipboardReadPermission(): Promise<boolean> {
  return await requestOriginalClipboardPermission(READ_PASTEBOARD_PERMISSION);
}
