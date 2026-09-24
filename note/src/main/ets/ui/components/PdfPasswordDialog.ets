// 原版 ou5.onPasswordSubmitted/onPasswordCancelled：加密 PDF 导入的密码
// 输入对话框。attempt>0 时提示密码错误可重试；取消 → 返回 null。
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@CustomDialog
export struct PdfPasswordDialog {
  controller?: CustomDialogController;
  fileName: string = '';
  attempt: number = 0;
  @State inputText: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onResult: (password: string | null) => void = (_password: string | null): void => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private finish(password: string | null): void {
    this.onResult(password);
    if (this.controller !== undefined) {
      this.controller.close();
    }
  }

  build() {
    Column() {
      Text($r('app.string.import_pdf_password_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
        .width('100%')
      Text(this.fileName)
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
      TextInput({ placeholder: $r('app.string.import_pdf_password_hint'),
        text: this.inputText })
        .type(InputType.Password)
        .showPasswordIcon(true)
        .fontSize(14)
        .width('100%')
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          if (this.inputText.length > 0) {
            this.finish(this.inputText);
          }
        })
      if (this.attempt > 0) {
        Text($r('app.string.import_pdf_password_wrong'))
          .fontSize(12)
          .fontColor(0xE53935)
          .width('100%')
          .margin({ top: 6 })
      }
      Row() {
        Button($r('app.string.cancel'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            this.finish(null);
          })
        Button($r('app.string.import_pdf_password_unlock'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .enabled(this.inputText.length > 0)
          .onClick(() => {
            if (this.inputText.length > 0) {
              this.finish(this.inputText);
            }
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}
