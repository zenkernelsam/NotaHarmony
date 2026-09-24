// 原版 NoteThumbnailConfigActivity：添加缩略图小部件时弹出
// "Choose a note" 配置活动（含搜索），选定后把 noteId 写进
// widget_bindings["note_"+appWidgetId]。Harmony 等价：
// type=formEdit 的 UIExtension —— 桌面长按卡片或卡片内编辑入口经
// openFormEditAbility 拉起；want 携带被编辑 formId，经
// LocalStorage 传给 NoteThumbnailEditPage 写回绑定并刷新卡片。
import { FormEditExtensionAbility, formInfo } from '@kit.FormKit';
import { Want, UIExtensionContentSession } from '@kit.AbilityKit';

export default class NoteThumbnailFormEditAbility extends FormEditExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    const formId: string =
      (want.parameters?.[formInfo.FormParam.IDENTITY_KEY] ?? '') as string;
    const storage: LocalStorage = new LocalStorage();
    storage.setOrCreate('editFormId', formId);
    try {
      session.loadContent('noteformability/pages/NoteThumbnailEditPage', storage);
    } catch (e) {
      console.error(`thumb edit page load failed: ${JSON.stringify(e)}`);
    }
  }

  onSessionDestroy(session: UIExtensionContentSession): void {
  }
}
