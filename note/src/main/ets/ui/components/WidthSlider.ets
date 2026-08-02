// T-019 粗细滑块（Slider 范围 [2, 100]，步进 2）
import { EditorViewModel } from '../editor/EditorViewModel';

@Component
export struct WidthSlider {
  @ObjectLink viewModel: EditorViewModel;

  build() {
    Column() {
      Text('Width: ' + Math.round(this.viewModel.brushWidth).toString())
        .fontSize(14)
        .margin({ bottom: 8 })
      Slider({
        value: this.viewModel.brushWidth,
        min: 2,
        max: 100,
        step: 2,
      })
        .width(220)
        .onChange((value: number) => {
          this.viewModel.brushWidth = value;
        })
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#33000000', offsetY: 4 })
  }
}
