// 原版 CreateNoteWidgetProvider / CreateRecordingWidgetProvider：
// 2×2 动作小部件，点击发 CREATE_NOTE intent（录音件另带
// start_recording=true extra）→ hv7.i → kx 协程建笔记直开。
// Harmony 等价：FormExtensionAbility + forms_config.json 声明两张
// 2*2 ArkTS 卡片；卡片 postCardAction(router) 以
// params.launch_action 携带动作到 NoteAbility，由
// LaunchActionIngress 队列 → LibraryPage drain → createAndLaunch。
// 原版 RecentNotesWidgetProvider（4×2 数据小部件）：
// recent_notes_card + RecentNotesFormFeed；formId 登记进 filesDir
// JSON（Harmony 无活动实例枚举 API）；onAddForm/onUpdateForm 先推
// 标题（缩略图由 UIAbility 侧补齐，等价原版 WidgetImageProvider
// 懒加载）。
// 原版 FolderNotesWidgetProvider（qk9 子类 + 配置活动）：
// folder_notes_card + FolderNotesFormFeed（formId→folderId 存
// filesDir JSON = widget_bindings）；FolderFormEditAbility
// （type=formEdit）对应 FolderNotesConfigActivity。
// 原版 NoteThumbnailWidgetProvider（配置型单缩略图部件）：
// note_thumbnail_card + NoteThumbnailFormFeed（formId→noteId）+
// NoteThumbnailFormEditAbility（对应 NoteThumbnailConfigActivity）；
// 卡片编辑入口统一 message{edit:true} → onFormEvent 按 formId
// 归属注册器分发对应 edit ability。
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
  pushFolderNotesTitles,
  folderNotesFormIds
} from '../data/FolderNotesFormFeed';
import {
  NOTE_THUMBNAIL_FORM_NAME,
  registerNoteThumbnailForm,
  unregisterNoteThumbnailForm,
  pushNoteThumbnailTitles,
  noteThumbnailFormIds
} from '../data/NoteThumbnailFormFeed';

const FOLDER_EDIT_ABILITY: string = 'FolderFormEditAbility';
const THUMB_EDIT_ABILITY: string = 'NoteThumbnailFormEditAbility';

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
    } else if (formName === NOTE_THUMBNAIL_FORM_NAME) {
      registerNoteThumbnailForm(this.context, formId).then(() => {
        pushNoteThumbnailTitles(this.context, formId);
      }).catch((e: Error) => {
        console.error(`thumb form register failed: ${JSON.stringify(e)}`);
      });
    }
    return formBindingData.createFormBindingData({});
  }

  onUpdateForm(formId: string): void {
    pushRecentNotesTitles(this.context, formId).then(() => {
      pushFolderNotesTitles(this.context, formId).then(() => {
        pushNoteThumbnailTitles(this.context, formId);
      });
    }).catch((e: Error) => {
      console.error(`form title push failed: ${JSON.stringify(e)}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    // 原版配置活动对应路径：卡片编辑入口 → openFormEditAbility
    // 拉起 formEdit 配置页；按 formId 归属注册器分发。
    try {
      const parsed: Record<string, Object> = JSON.parse(message) as Record<string, Object>;
      if (parsed['edit'] === true) {
        folderNotesFormIds(this.context).then((folderIds: string[]) => {
          if (folderIds.includes(formId)) {
            formProvider.openFormEditAbility(FOLDER_EDIT_ABILITY, formId);
            return;
          }
          noteThumbnailFormIds(this.context).then((thumbIds: string[]) => {
            if (thumbIds.includes(formId)) {
              formProvider.openFormEditAbility(THUMB_EDIT_ABILITY, formId);
            }
          }).catch((e: Error) => {
            console.error(`thumb form lookup failed: ${JSON.stringify(e)}`);
          });
        }).catch((e: Error) => {
          console.error(`folder form lookup failed: ${JSON.stringify(e)}`);
        });
      }
    } catch (e) {
      console.error(`form event parse failed: ${JSON.stringify(e)}`);
    }
  }

  onRemoveForm(formId: string): void {
    unregisterRecentNotesForm(this.context, formId).then(() => {
      unregisterFolderNotesForm(this.context, formId).then(() => {
        unregisterNoteThumbnailForm(this.context, formId);
      });
    }).catch((e: Error) => {
      console.error(`form unregister failed: ${JSON.stringify(e)}`);
    });
  }
}
