// 原版 zy7/tpe.b/qcb 引导气泡：深色圆角气泡 + 本地化提示文本 + "Got it"
// 关闭按钮（data_onboarding__got_it → js7 写 seen 集）。bindPopup.builder 与
// 画布内元素锚定浮层共用此组件。
@Component
export struct OnboardingTipBubble {
  tipText: ResourceStr = '';
  onGotIt: () => void = () => {
  };

  build() {
    Column() {
      Text(this.tipText)
        .fontSize(13)
        .fontColor(Color.White)
        .maxLines(5)
        .textAlign(TextAlign.Start)
      Row() {
        Button($r('app.string.data_onboarding__got_it'))
          .fontSize(13)
          .height(28)
          .backgroundColor(Color.Transparent)
          .fontColor('#8EC5FF')
          .padding({ left: 8, right: 8 })
          .onClick(() => {
            this.onGotIt();
          })
      }
      .justifyContent(FlexAlign.End)
      .width('100%')
      .margin({ top: 4 })
    }
    .width(230)
    .padding({ left: 14, right: 10, top: 10, bottom: 6 })
    .alignItems(HorizontalAlign.Start)
  }
}
