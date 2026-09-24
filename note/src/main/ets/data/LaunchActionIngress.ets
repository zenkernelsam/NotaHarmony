// 原版 v50 动态快捷方式：new_note/new_photo 桌面长按快捷项 →
// CREATE_NOTE intent（new_photo 另带 start_camera extra）→ hv7.i
// 置 Q.j 启动标记后 kx 协程建笔记并打开（photo 直进拍摄）。
// Harmony 等价：module.json5 shortcuts 静态声明两条快捷项，want 经
// parameters['launch_action'] 携带动作（create_note /
// create_photo_note）入进程内队列；LibraryPage 显示时 drain 并走
// 与内建「+」一致的 createAndLaunch 管线。
// 原版近期笔记动态快捷项（mc7Var.d 驱动的 ShortcutManager
// setDynamicShortcuts）无 Harmony 对应 API —— fail-closed 登记。
import { Want } from '@kit.AbilityKit';

export const LAUNCH_ACTION_PARAM: string = 'launch_action';
export const LAUNCH_ACTION_CREATE_NOTE: string = 'create_note';
export const LAUNCH_ACTION_CREATE_PHOTO_NOTE: string = 'create_photo_note';

const pendingLaunchActions: string[] = [];

export function enqueueLaunchAction(want: Want): void {
  const action: Object | undefined = want.parameters === undefined ?
    undefined : want.parameters[LAUNCH_ACTION_PARAM];
  if (typeof action === 'string' &&
    (action === LAUNCH_ACTION_CREATE_NOTE ||
      action === LAUNCH_ACTION_CREATE_PHOTO_NOTE)) {
    pendingLaunchActions.push(action);
  }
}

export function drainLaunchActions(): string[] {
  if (pendingLaunchActions.length === 0) {
    return [];
  }
  return pendingLaunchActions.splice(0, pendingLaunchActions.length);
}
