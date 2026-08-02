// T-020 页面管理条（上一页/下一页/添加/删除）
@Component
export struct PageManagerBar {
  @Prop currentPageIndex: number = 0;
  @Prop pageCount: number = 1;
  onPrev: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onAdd: () => void = () => {
  };
  onDelete: () => void = () => {
  };

  build() {
    Row() {
      Button('←')
        .width(48)
        .height(40)
        .margin({ left: 16, right: 8 })
        .enabled(this.currentPageIndex > 0)
        .opacity(this.currentPageIndex > 0 ? 1 : 0.4)
        .onClick(() => {
          this.onPrev();
        })
      Text((this.currentPageIndex + 1) + ' / ' + this.pageCount)
        .fontSize(14)
        .width(60)
        .textAlign(TextAlign.Center)
      Button('→')
        .width(48)
        .height(40)
        .margin({ left: 8, right: 8 })
        .enabled(this.currentPageIndex < this.pageCount - 1)
        .opacity(this.currentPageIndex < this.pageCount - 1 ? 1 : 0.4)
        .onClick(() => {
          this.onNext();
        })
      Blank()
      Button('+  Add Page')
        .height(40)
        .margin({ left: 8, right: 8 })
        .onClick(() => {
          this.onAdd();
        })
      Button('Del')
        .width(56)
        .height(40)
        .margin({ left: 8, right: 16 })
        .enabled(this.pageCount > 1)
        .opacity(this.pageCount > 1 ? 1 : 0.4)
        .onClick(() => {
          this.onDelete();
        })
    }
    .width('100%')
    .height(56)
    .backgroundColor('#F8F8F8')
  }
}
