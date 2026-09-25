// 原版 CreateRecordingWidgetProvider：2×2 小部件点击 →
// CREATE_NOTE + start_recording=true extra → hv7.i → kx 建笔记
// 直开并自动起录（rd9 消费 auto_start_recording_applied 一次性
// 标记）。Harmony：postCardAction(router) → NoteAbility
// want.parameters['launch_action']='create_recording_note' →
// LaunchActionIngress → LibraryPage.createAndLaunch(autoRecord=
// true) → NotePage autoRecordRequested 既有挂点。
// 视觉对齐 create_recording_widget.xml：tile_bg_recording #fff6ea
// r20 底、左上标签 #171a20、左下 40dp r12 按钮 #ffa629 + 白
// widget_record 图标。
@Entry
@Component
struct NewRecordingCard {
  build() {
    Column() {
      Text($r('app.string.form_new_recording_display'))
        .fontSize(13)
        .fontColor('#171a20')
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Blank()
      Stack() {
        Image($r('app.media.widget_record'))
          .width(22)
          .height(22)
      }
      .width(40)
      .height(40)
      .backgroundColor('#ffa629')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .backgroundColor('#fff6ea')
    .borderRadius(20)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'NoteAbility',
        params: { launch_action: 'create_recording_note' }
      });
    })
  }
}
