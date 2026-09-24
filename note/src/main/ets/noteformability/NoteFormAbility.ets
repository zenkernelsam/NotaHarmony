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
// 原版 FolderNotesWidgetProvider（qk9 子类 + 配置活动）：
// folder_notes_card 卡片 + FolderNotesFormFeed（formId→folderId 存
// filesDir JSON，等价 widget_bindings）；配置 UI = type=formEdit 的
// FolderFormEditAbility（对应 FolderNotesConfigActivity），卡片内
// 编辑入口经 onFormEvent → openFormEditAbility 拉起。
// 原版 NoteThumbnailWidgetProvider（配置型单缩略图部件）仍需
// 独立卡片 + 笔记选择配置 —— fail-closed 登记（ADR-0632/0635）。
import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import {
  RECENT_NOTES_FORM_NAME,
  registerRecentNotesForm,
  unregisterRecentNotesForm,
  pushRecentNotesTitles
} from '../data/RecentNotesFormFeed';
import {
  FOLDER_NOTES_FORM_NAME,
  registerFolderNotesForm,
  unregisterFolderNotesForm,
  pushFolderNotesTitles
} from '../data/FolderNotesFormFeed';

const FOLDER_EDIT_ABILITY: string = 'FolderFormEditAbility';

export default class NoteFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = (want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? '') as string;
    const formName: string = (want.parameters?.[formInfo.FormParam.NAME_KEY] ?? '') as string;
    if (formId.length === 0) {
      return formBindingData.createFormBindingData({});
    }
    if (formName === RECENT_NOTES_FORM_NAME) {
      registerRecentNotesForm(this.context, formId).then(() => {
        pushRecentNotesTitles(this.context, formId);
      }).catch((e: Error) => {
        console.error(`recent form register failed: ${JSON.stringify(e)}`);
      });
    } else if (formName === FOLDER_NOTES_FORM_NAME) {
      registerFolderNotesForm(this.context, formId).then(() => {
        pushFolderNotesTitles(this.context, formId);
      }).catch((e: Error) => {
        console.error(`folder form register failed: ${JSON.stringify(e)}`);
      });
    }
    return formBindingData.createFormBindingData({});
  }

  onUpdateForm(formId: string): void {
    pushRecentNotesTitles(this.context, formId).then(() => {
      pushFolderNotesTitles(this.context, formId);
    }).catch((e: Error) => {
      console.error(`form title push failed: ${JSON.stringify(e)}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    // 原版 FolderNotesConfigActivity 对应路径：卡片编辑入口 →
    // openFormEditAbility 拉起 formEdit 配置页。
    try {
      const parsed: Record<string, Object> = JSON.parse(message) as Record<string, Object>;
      if (parsed['edit'] === true) {
        formProvider.openFormEditAbility(FOLDER_EDIT_ABILITY, formId);
      }
    } catch (e) {
      console.error(`form event parse failed: ${JSON.stringify(e)}`);
    }
  }

  onRemoveForm(formId: string): void {
    unregisterRecentNotesForm(this.context, formId).then(() => {
      unregisterFolderNotesForm(this.context, formId);
    }).catch((e: Error) => {
      console.error(`form unregister failed: ${JSON.stringify(e)}`);
    });
  }
}
