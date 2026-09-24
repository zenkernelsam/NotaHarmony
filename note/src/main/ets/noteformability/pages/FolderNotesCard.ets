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
                      .borderRadius(4)
                  } else {
                    Image($r('app.media.shortcut_new_note'))
                      .width(36)
                      .height(36)
                      .opacity(0.5)
                  }
                  Text(item.title)
                    .fontSize(13)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                if (index < this.items.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .opacity(0.3)
                    .margin({ left: 12, right: 12 })
                }
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
  }
}
