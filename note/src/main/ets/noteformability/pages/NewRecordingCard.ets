// 原版 CreateRecordingWidgetProvider：2×2 小部件点击 →
// CREATE_NOTE + start_recording=true extra → hv7.i → kx 建笔记
// 直开并自动起录（rd9 消费 auto_start_recording_applied 一次性
// 标记）。Harmony：postCardAction(router) → NoteAbility
// want.parameters['launch_action']='create_recording_note' →
// LaunchActionIngress → LibraryPage.createAndLaunch(autoRecord=
// true) → NotePage autoRecordRequested 既有挂点。
@Entry
@Component
struct NewRecordingCard {
  build() {
    Column() {
      Image($r('app.media.shortcut_new_recording'))
        .width(40)
        .height(40)
      Text($r('app.string.form_new_recording_display'))
        .fontSize(14)
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'NoteAbility',
        params: { launch_action: 'create_recording_note' }
      });
    })
  }
}
