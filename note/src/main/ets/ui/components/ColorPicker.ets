// T-019 颜色选择器（12 色预设网格）
// 注意：struct 名不能使用保留标签名 ColorPicker，用 ColorPickerView
import { EditorViewModel } from '../editor/EditorViewModel';

@Component
export struct ColorPickerView {
  @ObjectLink viewModel: EditorViewModel;
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

  build() {
    Column() {
      Grid() {
        ForEach(this.presetColors, (color: number) => {
          GridItem() {
            Column()
              .width(32)
              .height(32)
              .borderRadius(16)
              .backgroundColor(this.viewModel.colorToHex(color))
              .border({
                width: color === this.viewModel.brushColor ? 3 : 1,
                color: color === this.viewModel.brushColor ? '#3366FF' : '#DDDDDD',
              })
              .onClick(() => {
                this.viewModel.brushColor = color;
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
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#33000000', offsetY: 4 })
  }
}
