// 原版 CreateNoteWidgetProvider：2×2 小部件点击 → CREATE_NOTE
// intent → hv7.i → kx 建笔记直开。Harmony：postCardAction(router)
// → NoteAbility want.parameters['launch_action']='create_note' →
// LaunchActionIngress → LibraryPage.createAndLaunch。
@Entry
@Component
struct NewNoteCard {
  build() {
    Column() {
      Image($r('app.media.shortcut_new_note'))
        .width(40)
        .height(40)
      Text($r('app.string.form_new_note_display'))
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
        params: { launch_action: 'create_note' }
      });
    })
  }
}
