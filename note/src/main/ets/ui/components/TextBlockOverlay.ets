// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { TextBlockElement } from '../../core/model/ElementTypes';
import { Point2D } from '../../core/model/GeometryTypes';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@Component
export struct TextBlockOverlay {
  @Prop editing: boolean = false;
  @Prop @Watch('onElementChange') element: TextBlockElement | null = null;
  @Prop screenOrigin: Point2D = { x: 0, y: 0 };
  @Prop viewportZoom: number = 1;
  @State draftText: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onCommit: (text: string) => void = () => {
  };
  onCancel: () => void = () => {
  };
  onDraftChange: (text: string) => void = () => {
  };

  aboutToAppear(): void {
    this.draftText = this.element !== null ? this.element.richText : '';
  }

  onElementChange(): void {
    this.draftText = this.element !== null ? this.element.richText : '';
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Stack() {
      if (this.editing && this.element !== null) {
        Stack()
          .width(this.element.blockWidth * this.viewportZoom)
          .height(this.element.blockHeight * this.viewportZoom)
          .position({ x: this.screenOrigin.x, y: this.screenOrigin.y })
          .border({ width: 1.5, color: this.resolveTokens().accent, style: BorderStyle.Dashed })
        TextArea({ text: this.draftText, placeholder: $r('app.string.type_here') })
          .width(this.element.blockWidth * this.viewportZoom)
          .height(this.element.blockHeight * this.viewportZoom)
          .position({ x: this.screenOrigin.x, y: this.screenOrigin.y })
          .fontSize(this.element.fontSize * this.viewportZoom)
          .fontColor(this.resolveTokens().textPrimary)
          .backgroundColor(this.resolveTokens().surface)
          .padding(4)
          .onChange((value: string) => {
            this.draftText = value;
            this.onDraftChange(value);
          })
        Row() {
          Button($r('app.string.done'))
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.onCommit(this.draftText);
              this.draftText = '';
            })
          Button($r('app.string.cancel'))
            .height(32)
            .fontSize(12)
            .onClick(() => {
              this.draftText = '';
              this.onCancel();
            })
        }
        .position({
          x: this.screenOrigin.x,
          y: this.screenOrigin.y + this.element.blockHeight * this.viewportZoom + 4,
        })
      }
    }
    // 固定左上角 + 零尺寸：position 子组件按实际位置参与 hit，不遮挡下层 Canvas
    .position({ x: 0, y: 0 })
    .width(0)
    .height(0)
  }
}
