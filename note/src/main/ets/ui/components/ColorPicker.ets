// T-019 颜色选择器（12 色预设网格）
// 注意：struct 名不能使用保留标签名 ColorPicker，用 ColorPickerView
import { EditorViewModel } from '../editor/EditorViewModel';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@Component
export struct ColorPickerView {
  @ObjectLink viewModel: EditorViewModel;
  @Prop selectionMode: boolean = false;
  @Prop selectionColor: number = -16777216;
  onSelectionColor: (color: number) => void = (_color: number): void => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private presetColors: number[] = [
    -16777216,   // 黑
    -7829368,    // 灰
    -65536,      // 红
    -26368,      // 橙
    -256,        // 黄
    -16744448,   // 绿
    -16711681,   // 青
    -16776961,   // 蓝
    -8388480,    // 紫
    -16181,      // 粉
    -10011977,   // 棕
    -1,          // 白
  ];

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Grid() {
        ForEach(this.presetColors, (color: number, index: number) => {
          GridItem() {
            Column()
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor(this.viewModel.colorToHex(color))
              .border({
                width: color === (this.selectionMode ? this.selectionColor :
                  this.viewModel.brushColor) ? 3 : 1,
                color: color === (this.selectionMode ? this.selectionColor :
                  this.viewModel.brushColor) ? this.resolveTokens().accent :
                  this.resolveTokens().border,
              })
              .onClick(() => {
                if (this.selectionMode) {
                  this.onSelectionColor(color);
                } else {
                  this.viewModel.setBrushColor(color, index);
                }
              })
          }
        }, (color: number) => color.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width(200)
      .height(180)
    }
    .padding(16)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }
}
