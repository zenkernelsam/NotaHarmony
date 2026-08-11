import { util } from '@kit.ArkTS';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

const MAX_ORIGINAL_MATH_LATEX_BYTES: number = 1048576;

export function isOriginalMathLatexDraftValid(value: string): boolean {
  if (value.trim().length === 0) {
    return false;
  }
  const encoded: Uint8Array = new util.TextEncoder().encodeInto(value);
  return encoded.length <= MAX_ORIGINAL_MATH_LATEX_BYTES &&
    util.TextDecoder.create('utf-8').decodeToString(encoded) === value;
}

@Component
export struct MathEditorOverlay {
  @Prop visible: boolean = false;
  @Prop draft: string = '';
  @Prop busy: boolean = false;
  @Prop failed: boolean = false;
  @Prop containerWidth: number = 0;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onDraftChange: (value: string) => void = (_value: string): void => {};
  onCancel: () => void = (): void => {};
  onConfirm: () => void = (): void => {};

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private panelWidth(): number {
    return Math.max(200, Math.min(360, this.containerWidth - 32));
  }

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Center }) {
        Column() {
          Text($r('app.string.math_editor_title'))
            .width('100%')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary)
          TextArea({
            text: this.draft,
            placeholder: $r('app.string.math_editor_placeholder'),
          })
            .width('100%')
            .height(112)
            .margin({ top: 16 })
            .fontSize(16)
            .fontColor(this.resolveTokens().textPrimary)
            .placeholderColor(this.resolveTokens().textSecondary)
            .backgroundColor(this.resolveTokens().control)
            .border({ width: 1, color: this.resolveTokens().border })
            .borderRadius(6)
            .enabled(!this.busy)
            .onChange((value: string): void => this.onDraftChange(value))
          if (this.failed || (this.draft.length > 0 && !isOriginalMathLatexDraftValid(this.draft))) {
            Text(this.failed ? $r('app.string.math_editor_failed') :
              $r('app.string.math_editor_invalid'))
              .width('100%')
              .margin({ top: 8 })
              .fontSize(13)
              .fontColor(this.resolveTokens().danger)
          }
          Row({ space: 8 }) {
            Button($r('app.string.math_editor_cancel'))
              .height(40)
              .layoutWeight(1)
              .fontSize(14)
              .fontColor(this.resolveTokens().textPrimary)
              .backgroundColor(this.resolveTokens().control)
              .enabled(!this.busy)
              .onClick((): void => this.onCancel())
            Button($r('app.string.math_editor_done'))
              .height(40)
              .layoutWeight(1)
              .fontSize(14)
              .fontColor(this.resolveTokens().onAccent)
              .backgroundColor(this.resolveTokens().accent)
              .enabled(!this.busy && isOriginalMathLatexDraftValid(this.draft))
              .onClick((): void => this.onConfirm())
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width(this.panelWidth())
        .padding(20)
        .backgroundColor(this.resolveTokens().surface)
        .border({ width: 1, color: this.resolveTokens().border })
        .borderRadius(8)
        .shadow({ radius: 12, color: this.resolveTokens().shadow, offsetY: 4 })
        .hitTestBehavior(HitTestMode.Block)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.resolveTokens().scrim)
      .hitTestBehavior(HitTestMode.Block)
    }
  }
}
