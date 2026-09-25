// 原版 FolderNotesWidgetProvider（qk9 子类 + FolderNotesConfigActivity）：
// 每个实例经 widget_bindings 绑定一个 folderId；头部=文件夹名 →
// VIEW+folder_id；创建钮 → CREATE_NOTE+folder_id；行 = 缩略图/占位
// + 标题 + 分隔线，行点击 = nbnote:<id> + note_id；未配置 →
// "Tap to open Notability"，空文件夹 → "No notes in this folder"。
// Harmony：folderId/folderName/configured 由 FolderNotesFormFeed 下发；
// 编辑入口 postCardAction(message {edit:true}) → onFormEvent →
// openFormEditAbility（对应原版配置活动）。
interface FolderCardItem {
  id: string;
  title: string;
  thumb: string;
  folder: string;
}

@Entry
@Component
struct FolderNotesCard {
  @LocalStorageProp('items') items: FolderCardItem[] = [];
  @LocalStorageProp('folderId') folderId: string = '';
  @LocalStorageProp('folderName') folderName: string = '';
  @LocalStorageProp('configured') configured: boolean = false;

  build() {
    Column() {
      Row() {
        Text(this.configured && this.folderName.length > 0 ?
          this.folderName : $r('app.string.form_folder_notes_display'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.app_widgets__widget_text'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'NoteAbility',
              params: { folder_id: this.folderId }
            });
          })
        Text('✎')
          .fontSize(18)
          .margin({ right: 10 })
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { edit: true }
            });
          })
        if (this.configured) {
          Image($r('app.media.shortcut_new_note'))
            .width(24)
            .height(24)
            .onClick(() => {
              postCardAction(this, {
                action: 'router',
                abilityName: 'NoteAbility',
                params: { launch_action: 'create_note', folder_id: this.folderId }
              });
            })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      if (!this.configured) {
        Text($r('app.string.form_folder_notes_unconfigured'))
          .fontSize(12)
          .opacity(0.6)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { edit: true }
            });
          })
      } else if (this.items.length === 0) {
        Text($r('app.string.form_folder_notes_empty'))
          .fontSize(12)
          .opacity(0.6)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.items, (item: FolderCardItem, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  if (item.thumb.length > 0) {
                    Image('memory://' + item.thumb)
                      .width(36)
                      .height(36)
                      // widget_thumb_corner_radius=6dp + thumb_border 1px #e8ebf0
                      .borderRadius(6)
                      .border({ width: 1, color: $r('app.color.app_widgets__widget_divider') })
                  } else {
                    // widget_thumb_border + placeholder_tile：#f6f6f8 底 +
                    // #c8cfdb 图标
                    Stack() {
                      Image($r('app.media.shortcut_new_note'))
                        .width(20)
                        .height(20)
                        .fillColor($r('app.color.app_widgets__widget_placeholder_icon'))
                    }
                    .width(36)
                    .height(36)
                    .backgroundColor($r('app.color.app_widgets__widget_placeholder_bg'))
                    .borderRadius(6)
                    .border({ width: 1, color: $r('app.color.app_widgets__widget_divider') })
                  }
                  // Original nti/ksh widget feeds: empty title ->
                  // data_library_state__default_note_title.
                  Text(item.title.length > 0 ? item.title : $r('app.string.untitled_note'))
                    .fontSize(13)
                    .fontColor($r('app.color.app_widgets__widget_text'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                // widget_row_divider：每行无条件 1dp #e8ebf0
                Divider()
                  .strokeWidth(1)
                  .color($r('app.color.app_widgets__widget_divider'))
                  .margin({ left: 12, right: 12 })
              }
            }
            .onClick(() => {
              postCardAction(this, {
                action: 'router',
                abilityName: 'NoteAbility',
                params: { note_id: item.id }
              });
            })
          }, (item: FolderCardItem) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    // widget_bg：r16 卡片底
    .backgroundColor($r('app.color.app_widgets__widget_bg'))
    .borderRadius(16)
  }
}
