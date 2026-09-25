// T-019 粗细滑块（原版 WidthSizeWell 槽位 + Slider 范围 [2, 100]，步进 2）
import { EditorViewModel } from '../editor/EditorViewModel';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@Component
export struct WidthSlider {
  @ObjectLink viewModel: EditorViewModel;
  @Prop selectionMode: boolean = false;
  @Prop selectionWidth: number = 5;
  @Prop selectionMinimum: number = 0.5;
  @Prop selectionMaximum: number = 30;
  @Prop photoImportLeaseActive: boolean = false;
  onSelectionWidth: (width: number) => void = (_width: number): void => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      if (!this.selectionMode && this.viewModel.widthWells.length > 0) {
        Row() {
          ForEach(this.viewModel.widthWells, (width: number, index: number) => {
            Text(width.toString())
              .fontSize(12)
              .fontColor(this.viewModel.brushWidth === width ?
                this.resolveTokens().accent : this.resolveTokens().textPrimary)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(8)
              .border({
                width: 1,
                color: this.viewModel.brushWidth === width ?
                  this.resolveTokens().accent : this.resolveTokens().border,
              })
              .margin({ right: 8 })
              .enabled(!this.photoImportLeaseActive)
              .onClick(() => {
                if (this.photoImportLeaseActive) {
                  return;
                }
                this.viewModel.setBrushWidth(width, index);
              })
          }, (width: number, index: number) => index.toString() + ':' + width.toString())
        }
        .width(220)
        .margin({ bottom: 10 })
      }
      // 原版 yed：ui_tools__width = "Width: %1$d"（整型入参）。
      Text($r('app.string.ui_tools_width',
        Math.round(this.selectionMode ? this.selectionWidth :
          this.viewModel.brushWidth)))
        .fontSize(14)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ bottom: 8 })
      Slider({
        value: this.selectionMode ? this.selectionWidth : this.viewModel.brushWidth,
        min: this.selectionMode ? this.selectionMinimum : 2,
        max: this.selectionMode ? this.selectionMaximum : 100,
        step: this.selectionMode ? 0.5 : 2,
      })
        .width(220)
        .enabled(!this.photoImportLeaseActive)
        .onChange((value: number) => {
          if (this.photoImportLeaseActive) {
            return;
          }
          if (this.selectionMode) {
            this.onSelectionWidth(value);
          } else {
            this.viewModel.setBrushWidth(value);
          }
        })
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }
}
