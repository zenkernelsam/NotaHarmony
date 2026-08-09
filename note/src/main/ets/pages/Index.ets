// T-016 应用入口：自动重定向到资料库（replaceUrl 不保留 Index 在栈中）
import { router } from '@kit.ArkUI';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../ui/theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../ui/theme/EditorTheme';

@Entry
@Component
struct Index {
  @State routing: boolean = false;
  @State routeFailed: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.openLibrary();
  }

  private openLibrary(): void {
    if (this.routing) {
      return;
    }
    this.routing = true;
    this.routeFailed = false;
    router.replaceUrl({ url: 'ui/library/LibraryPage' }).catch((err: Error) => {
      this.routing = false;
      this.routeFailed = true;
      console.error(`replaceUrl failed: ${JSON.stringify(err)}`);
    });
  }

  build() {
    Column() {
      if (this.routeFailed) {
        Text($r('app.string.open_library_failed'))
          .fontSize(18)
          .fontColor(this.resolveTokens().textSecondary)
        Button($r('app.string.retry'))
          .height(40)
          .margin({ top: 16 })
          .onClick(() => {
            this.openLibrary();
          })
      } else {
        LoadingProgress()
          .width(40)
          .height(40)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.resolveTokens().background)
  }
}
