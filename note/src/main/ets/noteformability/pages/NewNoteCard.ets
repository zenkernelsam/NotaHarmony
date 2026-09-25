// 原版 CreateNoteWidgetProvider：2×2 小部件点击 → CREATE_NOTE
// intent → hv7.i → kx 建笔记直开。Harmony：postCardAction(router)
// → NoteAbility want.parameters['launch_action']='create_note' →
// LaunchActionIngress → LibraryPage.createAndLaunch。
// 视觉对齐 create_note_widget.xml：tile_bg_note #ecf2ff r20 底、
// 左上标签（widget_create_label #171a20）、左下 40dp r12 主色按钮
// #4278ff + 白 widget_add 图标（widget_on_accent）。
@Entry
@Component
struct NewNoteCard {
  build() {
    Column() {
      Text($r('app.string.form_new_note_display'))
        .fontSize(13)
        .fontColor('#171a20')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank()
      Stack() {
        Image($r('app.media.widget_add'))
          .width(22)
          .height(22)
      }
      .width(40)
      .height(40)
      .backgroundColor('#4278ff')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor('#ecf2ff')
    .borderRadius(20)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'NoteAbility',
        params: { launch_action: 'create_note' }
      });
    })
  }
}
