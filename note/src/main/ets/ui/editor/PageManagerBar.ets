// T-020 页面管理条（上一页/下一页/添加/删除；T-037 模板设置入口）
import { PageInfo } from '../../core/model/NoteTypes';
import { PageSettingsPanel } from '../components/PageSettingsPanel';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

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
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }
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
          // T-040 修复：不能同时传 message 与 builder（message 优先，builder 被忽略导致面板不渲染）
          builder: (): void => {
            this.PageSettingsBuilder()
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
    .backgroundColor(this.resolveTokens().surface)
  }

  // T-040 修复：bindPopup 的 builder 必须通过 @Builder 方法承载子组件，普通函数内实例化组件不生效
  @Builder
  PageSettingsBuilder() {
    PageSettingsPanel({
      page: this.currentPage,
      onApply: (page: PageInfo) => {
        this.showSettings = false;
        this.onApplyPage(page);
      },
    })
  }
}
