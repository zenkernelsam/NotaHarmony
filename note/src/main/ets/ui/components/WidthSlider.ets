// T-019 粗细滑块（Slider 范围 [2, 100]，步进 2）
import { EditorViewModel } from '../editor/EditorViewModel';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@Component
export struct WidthSlider {
  @ObjectLink viewModel: EditorViewModel;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text('Width: ' + Math.round(this.viewModel.brushWidth).toString())
        .fontSize(14)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ bottom: 8 })
      Slider({
        value: this.viewModel.brushWidth,
        min: 2,
        max: 100,
        step: 2,
      })
        .width(220)
        .onChange((value: number) => {
          this.viewModel.setBrushWidth(value, Math.round((value - 2) / 2));
        })
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }
}
