// T-024 文本框编辑覆盖层（TextArea 编辑态）
import { TextBlockElement, RichTextParagraphStyle, RichTextParagraphStyleRun } from '../../core/model/ElementTypes';
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
  // 原版 h32 文本格式工具条（ADR-0648）：光标段落级 BLOCK_QUOTE(4)/CODE_BLOCK(5)
  // 切换；draftStyles 以段落序号为键承载编辑期样式，提交时折回字符区间 run。
  @State caretOffset: number = -1;
  @State caretDecoratorStyle: number = 0;
  private draftStyles: Map<number, RichTextParagraphStyle> = new Map();
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private controller: TextAreaController = new TextAreaController();
  onCommit: (text: string, paragraphStyleRuns: RichTextParagraphStyleRun[]) =>
    Promise<boolean> = async (_text: string,
      _runs: RichTextParagraphStyleRun[]): Promise<boolean> => {
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
    this.seedParagraphStyles();
  }

  onElementChange(): void {
    this.draftText = this.element !== null ? this.element.richText : '';
    this.seedParagraphStyles();
  }

  // 种子：把元素上的段落 run 解回“段落序号 → 样式”映射。换行插入/删除期间
  // 序号可能漂移——与原版一致的近似（原版同样按段落持样式）。
  private seedParagraphStyles(): void {
    this.draftStyles.clear();
    const runs: RichTextParagraphStyleRun[] = this.element !== null &&
      this.element.paragraphStyleRuns !== undefined ? this.element.paragraphStyleRuns : [];
    const text: string = this.element !== null ? this.element.richText : '';
    this.caretOffset = this.restoreCaret >= 0 ? Math.min(this.restoreCaret, text.length) :
      text.length;
    if (runs.length === 0) {
      this.caretDecoratorStyle = 0;
      return;
    }
    let paragraphIndex: number = 0;
    let paragraphStart: number = 0;
    for (let index: number = 0; index <= text.length; index++) {
      if (index === text.length || text.charAt(index) === '\n') {
        const style: RichTextParagraphStyle = this.styleAtChar(runs, paragraphStart);
        if (Object.keys(style).length > 0) {
          this.draftStyles.set(paragraphIndex, style);
        }
        paragraphStart = index + 1;
        paragraphIndex++;
      }
    }
    this.caretDecoratorStyle = this.decoratorAt(this.caretOffset);
  }

  private styleAtChar(runs: RichTextParagraphStyleRun[],
    offset: number): RichTextParagraphStyle {
    for (const run of runs) {
      if (offset >= run.start && offset < run.end) {
        return run.style;
      }
    }
    return {};
  }

  private paragraphIndexAt(offset: number): number {
    const clamped: number = Math.max(0, Math.min(offset, this.draftText.length));
    let index: number = 0;
    for (let i: number = 0; i < clamped; i++) {
      if (this.draftText.charAt(i) === '\n') {
        index++;
      }
    }
    return index;
  }

  private decoratorAt(offset: number): number {
    const style: RichTextParagraphStyle | undefined =
      this.draftStyles.get(this.paragraphIndexAt(offset));
    return style === undefined || style.decoratorStyle === undefined ? 0 :
      style.decoratorStyle;
  }

  // 原版 h32 工具条按钮语义：段落级 decorator 单选互斥切换（再次点击同项回到 NONE=0）。
  private toggleDecoratorStyle(decorator: number): void {
    const paragraphIndex: number = this.paragraphIndexAt(this.caretOffset);
    const current: RichTextParagraphStyle = this.draftStyles.get(paragraphIndex) ?? {};
    const next: RichTextParagraphStyle = {};
    if (current.indentLevel !== undefined) {
      next.indentLevel = current.indentLevel;
    }
    if (current.alignment !== undefined) {
      next.alignment = current.alignment;
    }
    if (current.lineSpacing !== undefined) {
      next.lineSpacing = current.lineSpacing;
    }
    if (current.writingDirection !== undefined) {
      next.writingDirection = current.writingDirection;
    }
    if (current.isChecked !== undefined) {
      next.isChecked = current.isChecked;
    }
    if (current.decoratorStyle !== decorator) {
      next.decoratorStyle = decorator;
      if (decorator === 5 && current.programmingLanguage !== undefined) {
        next.programmingLanguage = current.programmingLanguage;
      }
    }
    if (Object.keys(next).length === 0) {
      this.draftStyles.delete(paragraphIndex);
    } else {
      this.draftStyles.set(paragraphIndex, next);
    }
    this.caretDecoratorStyle = next.decoratorStyle ?? 0;
  }

  // 提交时把段落序号样式折回字符区间 run（run.end 含段内换行符；末段无换行则止于文末）。
  private computeParagraphRuns(): RichTextParagraphStyleRun[] {
    const runs: RichTextParagraphStyleRun[] = [];
    const text: string = this.draftText;
    let paragraphIndex: number = 0;
    let paragraphStart: number = 0;
    for (let index: number = 0; index <= text.length; index++) {
      if (index === text.length || text.charAt(index) === '\n') {
        const style: RichTextParagraphStyle | undefined = this.draftStyles.get(paragraphIndex);
        if (style !== undefined && Object.keys(style).length > 0) {
          const end: number = index < text.length ? index + 1 : index;
          if (end > paragraphStart) {
            runs.push({ start: paragraphStart, end: end, style: style });
          }
        }
        paragraphStart = index + 1;
        paragraphIndex++;
      }
    }
    return runs;
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
              this.caretOffset = end;
              this.caretDecoratorStyle = this.decoratorAt(end);
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
          // 原版 h32 文本格式行中的 BLOCK_QUOTE/CODE_BLOCK 两项
          // （bold/list/link 等其余项已在既有表面实现）。
          Button($r('app.string.block_quote'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 4 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 4 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .onClick(() => {
              this.toggleDecoratorStyle(4);
            })
          Button($r('app.string.code_block'))
            .height(32)
            .fontSize(12)
            .backgroundColor(this.caretDecoratorStyle === 5 ?
              this.resolveTokens().accent : this.resolveTokens().surface)
            .fontColor(this.caretDecoratorStyle === 5 ?
              this.resolveTokens().onAccent :
              (this.element !== null ? this.element.fontColor : '#000000'))
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(() => {
              this.toggleDecoratorStyle(5);
            })
          Button($r('app.string.done'))
            .height(32)
            .fontSize(12)
            .enabled(!this.photoImportLeaseActive)
            .margin({ left: 4 })
            .onClick(async () => {
              if (this.photoImportLeaseActive) {
                return;
              }
              if (await this.onCommit(this.draftText, this.computeParagraphRuns())) {
                this.draftText = '';
                this.draftStyles.clear();
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
