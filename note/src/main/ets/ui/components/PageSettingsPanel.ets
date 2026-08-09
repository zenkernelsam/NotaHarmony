// T-037 页面设置面板（尺寸/模板/方向选择，bindPopup 承载）
import { PageInfo, PaperSize, PaperTemplate, PageOrientation } from '../../core/model/NoteTypes';
import { clonePageInfo } from '../../core/model/PageBackgroundModel';
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
  @Prop page: PageInfo = { pageId: '', pageIndex: 0, size: 1, template: 0, orientation: 0,
    widthMm: 210, heightMm: 297 };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onApply: (page: PageInfo) => void = () => {
  };

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
            .backgroundColor(opt.size === this.page.size ? this.resolveTokens().accent :
              this.resolveTokens().control)
            .border({ width: 1, color: opt.size === this.page.size ? this.resolveTokens().accent :
              this.resolveTokens().border })
            .onClick(() => {
              const updated: PageInfo = this.clonePage();
              updated.background = null;
              updated.size = opt.size;
              const dims: number[] = this.dimForSize(opt.size);
              if (updated.orientation === PageOrientation.LANDSCAPE) {
                updated.widthMm = dims[1];
                updated.heightMm = dims[0];
              } else {
                updated.widthMm = dims[0];
                updated.heightMm = dims[1];
              }
              this.onApply(updated);
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
      Row() {
        ForEach([PaperTemplate.PLAIN, PaperTemplate.LINES, PaperTemplate.GRID, PaperTemplate.DOTS],
          (tpl: PaperTemplate) => {
            Column() {
              this.TemplatePreview(tpl)
              Text(this.templateLabel(tpl)).fontSize(10).margin({ top: 4 })
            }
            .margin({ right: 12 })
            .onClick(() => {
              const updated: PageInfo = this.clonePage();
              updated.background = null;
              updated.template = tpl;
              this.onApply(updated);
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
          .backgroundColor(this.page.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.page.orientation === PageOrientation.PORTRAIT ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            const updated: PageInfo = this.clonePage();
            if (updated.orientation !== PageOrientation.PORTRAIT) {
              const w: number = updated.widthMm;
              updated.widthMm = updated.heightMm;
              updated.heightMm = w;
              updated.orientation = PageOrientation.PORTRAIT;
              updated.background = null;
              this.onApply(updated);
            }
          })
        Button($r('app.string.landscape'))
          .height(36)
          .fontSize(13)
          .backgroundColor(this.page.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .fontColor(this.page.orientation === PageOrientation.LANDSCAPE ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .onClick(() => {
            const updated: PageInfo = this.clonePage();
            if (updated.orientation !== PageOrientation.LANDSCAPE) {
              const w: number = updated.widthMm;
              updated.widthMm = updated.heightMm;
              updated.heightMm = w;
              updated.orientation = PageOrientation.LANDSCAPE;
              updated.background = null;
              this.onApply(updated);
            }
          })
      }
    }
    .padding(16)
    .width(380)
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
  }

  // 模板迷你预览（自绘：白色底 + 线/点模拟）
  @Builder
  TemplatePreview(tpl: PaperTemplate) {
    Stack() {
      Column()
        .width(60)
        .height(78)
        .backgroundColor(this.resolveTokens().paperBackground)
        .border({ width: tpl === this.page.template ? 2 : 1,
          color: tpl === this.page.template ? this.resolveTokens().accent : this.resolveTokens().border })
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

  private clonePage(): PageInfo {
    return clonePageInfo(this.page);
  }

  private dimForSize(size: PaperSize): number[] {
    switch (size) {
      case PaperSize.A3:
        return [297, 420];
      case PaperSize.A4:
        return [210, 297];
      case PaperSize.A5:
        return [148, 210];
      case PaperSize.A6:
        return [105, 148];
      case PaperSize.A7:
        return [74, 105];
      case PaperSize.LETTER:
        return [216, 279];
      case PaperSize.LEGAL:
        return [216, 356];
      case PaperSize.TABLOID:
        return [279, 432];
      default:
        return [210, 297];
    }
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
