// 原版 FolderNotesConfigActivity：添加文件夹小部件时弹出配置活动，
// 选定文件夹后把 folderId 写进 widget_bindings["folder_"+appWidgetId]。
// Harmony 等价：type=formEdit 的 UIExtension —— 桌面长按卡片或卡片内
// 编辑入口经 openFormEditAbility 拉起本页；want 携带被编辑 formId，
// 经 LocalStorage 传给 FolderNotesEditPage 写回配置并刷新卡片。
import { FormEditExtensionAbility } from '@kit.FormKit';
import { Want, UIExtensionContentSession } from '@kit.AbilityKit';
import { formInfo } from '@kit.FormKit';

export default class FolderFormEditAbility extends FormEditExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    const formId: string =
      (want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? '') as string;
    const storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('editFormId', formId);
    try {
      session.loadContent('noteformability/pages/FolderNotesEditPage', storage);
    } catch (e) {
      console.error(`folder edit page load failed: ${JSON.stringify(e)}`);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
  }
}
