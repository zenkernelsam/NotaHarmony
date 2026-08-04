// T-020 页面管理条（上一页/下一页/添加/删除；T-037 模板设置入口）
import { PageInfo } from '../../core/model/NoteTypes';
import { PageSettingsPanel } from '../components/PageSettingsPanel';

// bindPopup onStateChange 事件类型
interface PopupStateChangeEvent {
  isVisible: boolean;
}

@Component
export struct PageManagerBar {
  @Prop currentPageIndex: number = 0;
  @Prop pageCount: number = 1;
  @Prop currentPage: PageInfo = { pageId: '', size: 1, template: 0, orientation: 0, widthMm: 210, heightMm: 297 };
  @State showSettings: boolean = false;
  onPrev: () => void = () => {
  };
  onNext: () => void = () => {
  };
  onAdd: () => void = () => {
  };
  onDelete: () => void = () => {
  };
  onApplyPage: (page: PageInfo) => void = () => {
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
      // T-037：页面设置入口（bindPopup 原生承载）
      Button('模板')
        .height(40)
        .fontSize(13)
        .margin({ left: 8 })
        .onClick(() => {
          this.showSettings = true;
        })
        .bindPopup(this.showSettings, {
          message: '',
          builder: () => {
            PageSettingsPanel({
              page: this.currentPage,
              onApply: (page: PageInfo) => {
                this.showSettings = false;
                this.onApplyPage(page);
              },
            })
          },
          placement: Placement.Top,
          onStateChange: (event: PopupStateChangeEvent) => {
            this.showSettings = event.isVisible;
          },
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
