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
          .fontColor($r('app.color.app_widgets__widget_text'))
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
                  Column() {
                    Text(item.title)
                      .fontSize(13)
                      .fontColor($r('app.color.app_widgets__widget_text'))
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
          }, (item: RecentCardItem) => item.id)
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
