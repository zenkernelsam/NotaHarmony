// T-019 编辑器工具栏（工具切换 + 颜色/粗细面板 + Undo/Redo 占位）
import { ToolType } from '../../core/model/BrushTypes';
import { EditorViewModel } from './EditorViewModel';
import { ColorPickerView } from '../components/ColorPicker';
import { WidthSlider } from '../components/WidthSlider';

@Component
export struct EditorToolbar {
  @ObjectLink viewModel: EditorViewModel;
  // Undo/Redo 回调（T-021 实现功能）
  onUndo: () => void = () => {
  };
  onRedo: () => void = () => {
  };
  @Prop canUndo: boolean = false;
  @Prop canRedo: boolean = false;

  build() {
    Column() {
      Row() {
        // === 工具按钮（48vp 点击区）===
        this.ToolButton('Pen', ToolType.PEN)
        this.ToolButton('Pencil', ToolType.PENCIL)
        this.ToolButton('Highlighter', ToolType.HIGHLIGHTER)
        this.ToolButton('Eraser', ToolType.WHOLE_ERASER)
        this.ToolButton('Select', ToolType.SELECTION)

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // 颜色按钮（当前色圆点）
        Button()
          .width(32)
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.viewModel.colorToHex(this.viewModel.brushColor))
          .margin({ left: 4, right: 4 })
          .onClick(() => {
            this.viewModel.showColorPicker = !this.viewModel.showColorPicker;
            this.viewModel.showWidthSlider = false;
          })

        // 粗细按钮（当前宽度指示）
        Button(Math.round(this.viewModel.brushWidth).toString())
          .width(48)
          .height(32)
          .fontSize(13)
          .margin({ left: 4, right: 4 })
          .onClick(() => {
            this.viewModel.showWidthSlider = !this.viewModel.showWidthSlider;
            this.viewModel.showColorPicker = false;
          })

        Divider().vertical(true).height(24).margin({ left: 8, right: 8 })

        // Undo / Redo（T-021 实现功能）
        Button('↶')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canUndo)
          .opacity(this.canUndo ? 1 : 0.4)
          .onClick(() => {
            this.onUndo();
          })
        Button('↷')
          .width(48)
          .height(32)
          .fontSize(18)
          .enabled(this.canRedo)
          .opacity(this.canRedo ? 1 : 0.4)
          .onClick(() => {
            this.onRedo();
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor('#F8F8F8')

      // 弹层（颜色/粗细面板）
      if (this.viewModel.showColorPicker) {
        Row() {
          ColorPickerView({ viewModel: this.viewModel })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
      if (this.viewModel.showWidthSlider) {
        Row() {
          WidthSlider({ viewModel: this.viewModel })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8 })
      }
    }
  }

  @Builder
  ToolButton(label: string, tool: ToolType) {
    Button(label)
      .width(88)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.viewModel.currentTool === tool ? '#3366FF' : '#E8E8E8')
      .fontColor(this.viewModel.currentTool === tool ? '#FFFFFF' : '#333333')
      .margin({ left: 2, right: 2 })
      .onClick(() => {
        this.viewModel.selectTool(tool);
        if (tool === ToolType.WHOLE_ERASER) {
          this.viewModel.eraserIsPartial = false;
        }
      })
  }
}
