// T-037 页面设置面板（尺寸/模板/方向选择，bindPopup 承载）
import {
  NoteBackgroundSettings, PageOrientation, PaperSize, PaperTemplate,
} from '../../core/model/NoteTypes';
import {
  originalDefaultNoteBackgroundSettings,
} from '../../core/model/PageBackgroundModel';
import {
  applyOriginalTemplatePickerSelection, isOriginalTemplatePickerSelection,
  OriginalTemplatePickerDraft, originalTemplatePickerDraft,
  stageOriginalTemplateOrientation, stageOriginalTemplateSize,
} from '../../core/model/OriginalTemplatePickerState';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

const SIZE_OPTIONS: PaperSizeOption[] = [
  { size: PaperSize.A3, label: 'A3', dim: '297×420' },
  { size: PaperSize.A4, label: 'A4', dim: '210×297' },
  { size: PaperSize.A5, label: 'A5', dim: '148×210' },
  { size: PaperSize.A6, label: 'A6', dim: '105×148' },
  { size: PaperSize.A7, label: 'A7', dim: '74×105' },
  { size: PaperSize.LETTER, label: 'Letter', dim: '216×279' },
  { size: PaperSize.LEGAL, label: 'Legal', dim: '216×356' },
  { size: PaperSize.TABLOID, label: 'Tabloid', dim: '279×432' },
];

interface PaperSizeOption {
  size: PaperSize;
  label: string;
  dim: string;
}

@Component
export struct PageSettingsPanel {
  @Prop @Watch('onSettingsChange') settings: NoteBackgroundSettings =
    originalDefaultNoteBackgroundSettings();
  @Prop busy: boolean = false;
  @State draft: OriginalTemplatePickerDraft = {
    size: PaperSize.LETTER,
    orientation: PageOrientation.PORTRAIT,
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onApply: (settings: NoteBackgroundSettings) => void = () => {
  };

  aboutToAppear(): void {
    this.resetDraft();
  }

  private onSettingsChange(): void {
    this.resetDraft();
  }

  private resetDraft(): void {
    this.draft = originalTemplatePickerDraft(this.settings);
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      // === 尺寸 ===
      Text($r('app.string.paper_size')).fontSize(14).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
      Grid() {
        ForEach(SIZE_OPTIONS, (opt: PaperSizeOption) => {
          GridItem() {
            Column() {
              Text(opt.label).fontSize(13)
              Text(opt.dim).fontSize(10).fontColor(this.resolveTokens().textSecondary)
            }
            .width(76)
            .height(52)
            .justifyContent(FlexAlign.Center)
            .borderRadius(8)
            .backgroundColor(opt.size === this.draft.size ? this.resolveTokens().accent :
              this.resolveTokens().control)
            .border({ width: 1, color: opt.size === this.draft.size ? this.resolveTokens().accent :
              this.resolveTokens().border })
            .onClick(() => {
              if (!this.busy) {
                this.draft = stageOriginalTemplateSize(this.draft, opt.size);
              }
            })
          }
        }, (opt: PaperSizeOption) => opt.size.toString())
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width(340)
      .height(130)

      // === 模板（自绘迷你预览：展示类，无原生等价物）===
      Text($r('app.string.paper_template')).fontSize(14).fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
      Text($r('app.string.template_pick_hint'))
        .fontSize(11)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ bottom: 8 })
      Row() {
        ForEach([PaperTemplate.PLAIN, PaperTemplate.LINES, PaperTemplate.GRID, PaperTemplate.DOTS],
          (tpl: PaperTemplate) => {
            Column() {
              this.TemplatePreview(tpl)
              Text(this.templateLabel(tpl)).fontSize(10).margin({ top: 4 })
            }
            .margin({ right: 12 })
            .onClick(() => {
              if (!this.busy) {
                this.onApply(applyOriginalTemplatePickerSelection(this.settings, this.draft, tpl));
              }
            })
          }, (tpl: PaperTemplate) => tpl.toString())
      }

      // === 方向 ===
      Text($r('app.string.page_orientation')).fontSize(14).fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })
      Row() {
        Button($r('app.string.portrait'))
          .height(36)
          .fontSize(13)
          .margin({ right: 8 })
          .backgroundColor(this.draft.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.draft.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            if (!this.busy && this.draft.orientation !== PageOrientation.PORTRAIT) {
              this.draft = stageOriginalTemplateOrientation(
                this.draft, PageOrientation.PORTRAIT);
            }
          })
        Button($r('app.string.landscape'))
          .height(36)
          .fontSize(13)
          .backgroundColor(this.draft.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.draft.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            if (!this.busy && this.draft.orientation !== PageOrientation.LANDSCAPE) {
              this.draft = stageOriginalTemplateOrientation(
                this.draft, PageOrientation.LANDSCAPE);
            }
          })
      }
    }
    .padding(16)
    .width('100%')
    .constraintSize({ minWidth: 320, maxWidth: 420 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .enabled(!this.busy)
    .opacity(this.busy ? 0.6 : 1)
  }

  // 模板迷你预览（自绘：白色底 + 线/点模拟）
  @Builder
  TemplatePreview(tpl: PaperTemplate) {
    Stack() {
      Column()
        .width(60)
        .height(78)
        .backgroundColor(this.resolveTokens().paperBackground)
        .border({ width: isOriginalTemplatePickerSelection(this.settings, this.draft, tpl) ? 2 : 1,
          color: isOriginalTemplatePickerSelection(this.settings, this.draft, tpl) ?
            this.resolveTokens().accent : this.resolveTokens().border })
        .borderRadius(4)
      if (tpl === PaperTemplate.LINES) {
        Column() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            Divider().color(this.resolveTokens().paperLineColor).strokeWidth(1).margin({ top: 12 })
          }, (_i: number) => _i.toString())
        }
        .width(48)
        .height(66)
        .justifyContent(FlexAlign.Center)
      } else if (tpl === PaperTemplate.GRID) {
        Grid() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            GridItem() {
              Column().width(8).height(8).backgroundColor(this.resolveTokens().paperLineColor)
            }
          }, (_i: number) => _i.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width(48)
        .height(48)
        .columnsGap(6)
        .rowsGap(6)
        .margin({ top: 10 })
      } else if (tpl === PaperTemplate.DOTS) {
        Grid() {
          ForEach([1, 2, 3, 4], (_i: number) => {
            GridItem() {
              Column().width(5).height(5).borderRadius(3).backgroundColor(this.resolveTokens().paperLineColor)
            }
          }, (_i: number) => _i.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .width(48)
        .height(48)
        .columnsGap(8)
        .rowsGap(8)
        .margin({ top: 10 })
      }
    }
    .width(60)
    .height(78)
  }

  private templateLabel(tpl: PaperTemplate): ResourceStr {
    switch (tpl) {
      case PaperTemplate.PLAIN:
        return $r('app.string.template_plain');
      case PaperTemplate.LINES:
        return $r('app.string.template_lines');
      case PaperTemplate.GRID:
        return $r('app.string.template_grid');
      case PaperTemplate.DOTS:
        return $r('app.string.template_dots');
      default:
        return '';
    }
  }
}
