// 原版 CreateNoteWidgetProvider / CreateRecordingWidgetProvider：
// 2×2 动作小部件，点击发 CREATE_NOTE intent（录音件另带
// start_recording=true extra）→ hv7.i → kx 协程建笔记直开。
// Harmony 等价：FormExtensionAbility + forms_config.json 声明两张
// 2*2 ArkTS 卡片；卡片 postCardAction(router) 以
// params.launch_action 携带动作到 NoteAbility，由
// LaunchActionIngress 队列 → LibraryPage drain → createAndLaunch。
// 原版 RecentNotesWidgetProvider（4×2 数据小部件）：
// recent_notes_card 卡片 + RecentNotesFormFeed；实例 formId 登记进
// filesDir JSON（Harmony 无活动实例枚举 API）；onAddForm/onUpdateForm
// 先推标题（缩略图由 UIAbility 侧 refreshRecentNotesForms 补齐，
// 等价原版 WidgetImageProvider 懒加载）。
// 原版 NoteThumbnail/FolderNotes 两张配置型数据小部件仍需配置 UI —
// fail-closed 登记（ADR-0632）。
import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import {
  RECENT_NOTES_FORM_NAME,
  registerRecentNotesForm,
  unregisterRecentNotesForm,
  pushRecentNotesTitles
} from '../data/RecentNotesFormFeed';

export default class NoteFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = (want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? '') as string;
    const formName: string = (want.parameters?.[formInfo.FormParam.NAME_KEY] ?? '') as string;
    if (formName === RECENT_NOTES_FORM_NAME && formId.length > 0) {
      registerRecentNotesForm(this.context, formId).then(() => {
        pushRecentNotesTitles(this.context, formId);
      }).catch((e: Error) => {
        console.error(`recent form register failed: ${JSON.stringify(e)}`);
      });
    }
    return formBindingData.createFormBindingData({});
  }

  onUpdateForm(formId: string): void {
    pushRecentNotesTitles(this.context, formId).catch((e: Error) => {
      console.error(`recent form title push failed: ${JSON.stringify(e)}`);
    });
  }

  onRemoveForm(formId: string): void {
    unregisterRecentNotesForm(this.context, formId).catch((e: Error) => {
      console.error(`recent form unregister failed: ${JSON.stringify(e)}`);
    });
  }
}
