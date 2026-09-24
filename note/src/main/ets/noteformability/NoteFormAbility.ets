// 原版 CreateNoteWidgetProvider / CreateRecordingWidgetProvider：
// 2×2 动作小部件，点击发 CREATE_NOTE intent（录音件另带
// start_recording=true extra）→ hv7.i → kx 协程建笔记直开。
// Harmony 等价：FormExtensionAbility + forms_config.json 声明两张
// 2*2 ArkTS 卡片；卡片 postCardAction(router) 以
// params.launch_action 携带动作到 NoteAbility，由
// LaunchActionIngress 队列 → LibraryPage drain → createAndLaunch。
// 原版三张数据小部件（RecentNotes 列表+show_recent、
// NoteThumbnail 缩略+配置、FolderNotes 文件夹+配置）需要
// formProvider 数据通道与配置 UI —— fail-closed 登记（ADR-0632）。
import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

export default class NoteFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData({});
  }

  onUpdateForm(formId: string): void {
  }

  onRemoveForm(formId: string): void {
  }
}
