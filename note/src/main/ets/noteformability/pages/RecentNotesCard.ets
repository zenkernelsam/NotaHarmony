// 原版 RecentNotesWidgetProvider：4×2 数据小部件。
// 头部 → VIEW+show_recent PendingIntent；创建按钮 → CREATE_NOTE；
// 行 = 48dp 缩略图（无图时 page_new_note_fill 占位）+ 标题 + 分隔线；
// 行点击 = nbnote:<id> + note_id extra；空态 = "No recent notes"。
// Harmony：items/thumb 键由 RecentNotesFormFeed 经 formBindingData 下发；
// 点击路由复用 OpenTargetIngress（note_id / show_recent）与
// LaunchActionIngress（launch_action=create_note）——与原版 extras 一致。
interface RecentCardItem {
  id: string;
  title: string;
  thumb: string;
  folder: string;
}

@Entry
@Component
struct RecentNotesCard {
  @LocalStorageProp('items') items: RecentCardItem[] = [];

  build() {
    Column() {
      Row() {
        Text($r('app.string.form_recent_notes_display'))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'NoteAbility',
              params: { show_recent: true }
            });
          })
        Image($r('app.media.shortcut_new_note'))
          .width(24)
          .height(24)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'NoteAbility',
              params: { launch_action: 'create_note' }
            });
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      if (this.items.length === 0) {
        Text($r('app.string.form_recent_notes_empty'))
          .fontSize(12)
          .opacity(0.6)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.items, (item: RecentCardItem, index: number) => {
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
                  Column() {
                    Text(item.title)
                      .fontSize(13)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (item.folder.length > 0) {
                      Text(item.folder)
                        .fontSize(10)
                        .opacity(0.6)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
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
          }, (item: RecentCardItem) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
