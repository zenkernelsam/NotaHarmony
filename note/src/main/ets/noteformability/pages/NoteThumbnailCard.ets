// 原版 NoteThumbnailWidgetProvider：2×2 单笔记缩略图小部件 —
// widget_bindings["note_"+id] 绑定笔记，整卡渲染该笔记首页位图
// （无图时 page_new_note_fill 占位），点击 = VIEW+note_id
// （未配置 → MAIN+LAUNCHER 纯拉起）。配置活动 "Choose a note"。
// Harmony：noteId/title/thumb/configured 由 NoteThumbnailFormFeed
// 下发；点击 postCardAction(router)→note_id；未配置态点按与 ✎
// → message{edit:true} → onFormEvent → openFormEditAbility。
@Entry
@Component
struct NoteThumbnailCard {
  @LocalStorageProp('noteId') noteId: string = '';
  @LocalStorageProp('title') title: string = '';
  @LocalStorageProp('thumb') thumb: string = '';
  @LocalStorageProp('configured') configured: boolean = false;

  build() {
    Stack() {
      if (this.thumb.length > 0) {
        Image('memory://' + this.thumb)
          .width('100%')
          .height('100%')
          // 原版 ImageView scaleType=fitXY（拉伸充满，非裁剪）
          .objectFit(ImageFit.Fill)
      } else {
        // widget_placeholder_tile：#f6f6f8 r16 底 + #c8cfdb 着色图标
        Column() {
          Image($r('app.media.shortcut_new_note'))
            .width(40)
            .height(40)
            .fillColor('#c8cfdb')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#f6f6f8')
        .borderRadius(16)
      }
      if (!this.configured) {
        Column() {
          Text($r('app.string.form_note_thumbnail_pick'))
            .fontSize(12)
            .opacity(0.8)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#80000000')
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { edit: true }
          });
        })
      } else {
        Row() {
          Text('✎')
            .fontSize(14)
            .fontColor('#ffffff')
            .margin({ right: 6, top: 6 })
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Top)
        .justifyContent(FlexAlign.End)
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { edit: true }
          });
        })
      }
    }
    .width('100%')
    .height('100%')
    // widget_bg：#ffffff r16 卡片底
    .backgroundColor('#ffffff')
    .borderRadius(16)
    .onClick(() => {
      if (this.configured && this.noteId.length > 0) {
        postCardAction(this, {
          action: 'router',
          abilityName: 'NoteAbility',
          params: { note_id: this.noteId }
        });
      } else {
        // 原版未配置时 MAIN+LAUNCHER 纯拉起宿主。
        postCardAction(this, {
          action: 'router',
          abilityName: 'NoteAbility'
        });
      }
    })
  }
}
