// 原版 v50 动态快捷方式：new_note/new_photo 桌面长按快捷项 →
// CREATE_NOTE intent（new_photo 另带 start_camera extra）→ hv7.i
// 置 Q.j 启动标记后 kx 协程建笔记并打开（photo 直进拍摄）。
// 原版 CreateRecordingWidgetProvider 桌面小部件同样发
// CREATE_NOTE + start_recording=true（rd9 消费
// auto_start_recording_applied 一次性标记自动起录）。
// Harmony 等价：shortcuts 静态快捷项与 form 卡片
// postCardAction(router) 都经 parameters['launch_action'] 携带
// 动作（create_note / create_photo_note / create_recording_note）
// 入进程内队列；LibraryPage 显示时 drain 并走与内建「+」一致的
// createAndLaunch 管线（recording → autoRecord 既有挂点）。
// 原版 intent 裸 extra（start_camera/start_recording）同样接收，
// 兼容 CREATE_NOTE intent 契约的其它投递方。
// 原版近期笔记动态快捷项（mc7Var.d 驱动的 ShortcutManager
// setDynamicShortcuts）无 Harmony 对应 API —— fail-closed 登记。
import { Want } from '@kit.AbilityKit';

export const LAUNCH_ACTION_PARAM: string = 'launch_action';
export const LAUNCH_ACTION_CREATE_NOTE: string = 'create_note';
export const LAUNCH_ACTION_CREATE_PHOTO_NOTE: string = 'create_photo_note';
export const LAUNCH_ACTION_CREATE_RECORDING_NOTE: string = 'create_recording_note';

const EXTRA_START_CAMERA: string = 'start_camera';
const EXTRA_START_RECORDING: string = 'start_recording';

const pendingLaunchActions: string[] = [];

export function enqueueLaunchAction(want: Want): void {
  if (want.parameters === undefined) {
    return;
  }
  const action: Object | undefined = want.parameters[LAUNCH_ACTION_PARAM];
  if (typeof action === 'string' &&
    (action === LAUNCH_ACTION_CREATE_NOTE ||
      action === LAUNCH_ACTION_CREATE_PHOTO_NOTE ||
      action === LAUNCH_ACTION_CREATE_RECORDING_NOTE)) {
    pendingLaunchActions.push(action);
    return;
  }
  // 原版 CREATE_NOTE intent extras（CreateRecordingWidgetProvider
  // putExtra("start_recording", true)；v50 new_photo 同理带
  // start_camera）—— 无 launch_action 时按原版契约兜底。
  if (want.parameters[EXTRA_START_RECORDING] === true) {
    pendingLaunchActions.push(LAUNCH_ACTION_CREATE_RECORDING_NOTE);
  } else if (want.parameters[EXTRA_START_CAMERA] === true) {
    pendingLaunchActions.push(LAUNCH_ACTION_CREATE_PHOTO_NOTE);
  }
}

export function drainLaunchActions(): string[] {
  if (pendingLaunchActions.length === 0) {
    return [];
  }
  return pendingLaunchActions.splice(0, pendingLaunchActions.length);
}
