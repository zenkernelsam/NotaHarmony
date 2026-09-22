// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { TextBlockElement } from '../../core/model/ElementTypes';
import { Point2D, Rect2D } from '../../core/model/GeometryTypes';
import { textBlockTransformComponents, TextBlockTransformComponents } from '../../core/model/TextBlockGeometry';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

@Component
export struct TextBlockOverlay {
  @Prop editing: boolean = false;
  @Prop @Watch('onElementChange') element: TextBlockElement | null = null;
  @Prop screenOrigin: Point2D = { x: 0, y: 0 };
  @Prop screenBounds: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @Prop viewportZoom: number = 1;
  @Prop layoutWidth: number = 0;
  @Prop photoImportLeaseActive: boolean = false;
  // 原版 pke（NoneActive）挂起保留 ake 会话：再激活同块恢复光标。
  // restoreCaret < 0 表示无挂起会话（新块/显式销毁后）。
  @Prop restoreCaret: number = -1;
  @State draftText: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private controller: TextAreaController = new TextAreaController();
  onCommit: (text: string) => Promise<boolean> = async (_text: string): Promise<boolean> => {
    return false;
  };
  onCancel: () => void = () => {
  };
  onDraftChange: (text: string) => void = () => {
  };
  onCaretChange: (offset: number) => void = (_offset: number) => {
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

  private transformComponents(): TextBlockTransformComponents {
    return this.element !== null ? textBlockTransformComponents(this.element) : {
      origin: { x: 0, y: 0 }, rotationRadians: 0, scaleX: 1, scaleY: 1,
    };
  }

  private editorWidth(): number {
    if (this.element === null) {
      return 0;
    }
    return this.layoutWidth > 0 ? this.layoutWidth : this.element.blockWidth;
  }

  build() {
    Stack() {
      if (this.editing && this.element !== null) {
        Stack() {
          Stack()
            .width(this.editorWidth() * this.viewportZoom)
            .height(this.element.blockHeight * this.viewportZoom)
            .border({ width: 1.5, color: this.resolveTokens().accent, style: BorderStyle.Dashed })
          TextArea({ text: this.draftText, placeholder: $r('app.string.type_here'),
            controller: this.controller })
            .width(this.editorWidth() * this.viewportZoom)
            .height(this.element.blockHeight * this.viewportZoom)
            .fontSize(this.element.fontSize * this.viewportZoom)
            .lineHeight((this.element.fontSize + 8) * this.viewportZoom)
            .fontColor(this.element.fontColor)
            .backgroundColor(this.resolveTokens().surface)
            .padding({
              left: this.element.contentLeftInset * this.viewportZoom,
              top: this.element.contentTopInset * this.viewportZoom,
              right: (this.element.contentRightInset ?? this.element.contentLeftInset) *
                this.viewportZoom,
              bottom: (this.element.contentBottomInset ?? this.element.contentTopInset) *
                this.viewportZoom,
            })
            .enabled(!this.photoImportLeaseActive)
            .onAppear(() => {
              if (this.restoreCaret >= 0) {
                this.controller.caretPosition(Math.min(this.restoreCaret, this.draftText.length));
              }
            })
            .onTextSelectionChange((_start: number, end: number) => {
              this.onCaretChange(end);
            })
            .onChange((value: string) => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.draftText = value;
              this.onDraftChange(value);
            })
        }
          .width(this.editorWidth() * this.viewportZoom)
          .height(this.element.blockHeight * this.viewportZoom)
          .position({ x: this.screenOrigin.x, y: this.screenOrigin.y })
          .scale({
            x: this.transformComponents().scaleX,
            y: this.transformComponents().scaleY,
            centerX: 0,
            centerY: 0,
          })
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: this.transformComponents().rotationRadians.toString() + 'rad',
            centerX: 0,
            centerY: 0,
          })
        Row() {
          Button($r('app.string.done'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .onClick(async () => {
              if (this.photoImportLeaseActive) {
                return;
              }
              if (await this.onCommit(this.draftText)) {
                this.draftText = '';
              }
            })
          Button($r('app.string.cancel'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              if (this.photoImportLeaseActive) {
                return;
              }
              this.draftText = '';
              this.onCancel();
            })
        }
        .position({
          x: this.screenBounds.left,
          y: this.screenBounds.bottom + 4,
        })
      }
    }
    // 固定左上角 + 零尺寸：position 子组件按实际位置参与 hit，不遮挡下层 Canvas
    .position({ x: 0, y: 0 })
    .width(0)
    .height(0)
  }
}
