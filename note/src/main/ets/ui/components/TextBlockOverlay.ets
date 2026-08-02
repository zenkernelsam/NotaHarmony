// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { TextBlockElement } from '../../core/model/ElementTypes';

@Component
export struct TextBlockOverlay {
  @Prop editing: boolean = false;
  @Prop element: TextBlockElement | null = null;
  @State draftText: string = '';
  onCommit: (text: string) => void = () => {
  };
  onCancel: () => void = () => {
  };

  build() {
    Stack() {
      if (this.editing && this.element !== null) {
        Stack()
          .width(this.element.blockWidth)
          .height(this.element.blockHeight)
          .position({ x: this.element.textOrigin.x, y: this.element.textOrigin.y })
          .border({ width: 1.5, color: '#3366FF', style: BorderStyle.Dashed })
        TextArea({ text: this.draftText, placeholder: 'Type here...' })
          .width(this.element.blockWidth)
          .height(this.element.blockHeight)
          .position({ x: this.element.textOrigin.x, y: this.element.textOrigin.y })
          .fontSize(this.element.fontSize)
          .padding(4)
          .onChange((value: string) => {
            this.draftText = value;
          })
        Row() {
          Button('Done')
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.onCommit(this.draftText);
            })
          Button('Cancel')
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.onCancel();
            })
        }
        .position({
          x: this.element.textOrigin.x,
          y: this.element.textOrigin.y + this.element.blockHeight + 4,
        })
      }
    }
    // 固定左上角 + 零尺寸：position 子组件按实际位置参与 hit，不遮挡下层 Canvas
    .position({ x: 0, y: 0 })
    .width(0)
    .height(0)
  }
}
