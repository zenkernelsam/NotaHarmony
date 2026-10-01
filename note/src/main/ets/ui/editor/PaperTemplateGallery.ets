// Phase 1401 捆绑纸张模板图库（原版 1.4.2 x2n/u7n.e 模板面）。
// 原版证据（decompiled_1.4.2）：
//   rgc: assets.list("papertemplates") → zgc.b 解析 metadata.json +
//     文件名约定 <P>_<Size>_<hex6>[_orient].pdf；thumb 门控可见性；
//     排序 category.ordinal → displayIndex(null→MAX) → name。
//   ha6: 按 ugc 类目分节（NOTEPADS/ACADEMIC/CREATIVE/PLANNING/SELF_CARE，
//     ui_papertemplates__* 标题）；pgc.a(size,orient,colorHex) 为当前页
//     上下文解析 variant——无匹配变体的模板不出现在图库中。
//   点选 cell → rsh.q(chc) → a1d Preset → f1d/sqc.b 暂存打包 PDF →
//     导入资产库 → 设置当前页背景寄存器。
// Harmony 子集（ADR-1337）：类目分节 + PDF 光栅化缩略图 + 点选应用当前页。
// 变体编辑器（尺寸/颜色/方向/应用范围）、收藏/最近、My Templates、封面、
// repeat-template 为后续 Phase 登记项。
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import {
  BundledPaperCategory, BundledPaperTemplate, BundledPaperVariant,
  BUNDLED_PAPER_TEMPLATES, resolveBundledPaperVariant,
} from '../../core/model/PaperTemplateCatalog';
import { PageOrientation, PaperSize } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { loadBundledTemplateThumb } from '../../data/BundledPaperTemplateApply';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';

interface GalleryCellItem {
  template: BundledPaperTemplate;
  variant: BundledPaperVariant;
  cellKey: string;
}

interface GallerySection {
  category: BundledPaperCategory;
  titleRes: Resource;
  items: GalleryCellItem[];
}

const CATEGORY_TITLES: Resource[] = [
  $r('app.string.paper_templates_cat_notepads'),
  $r('app.string.paper_templates_cat_academic'),
  $r('app.string.paper_templates_cat_creative'),
  $r('app.string.paper_templates_cat_planning'),
  $r('app.string.paper_templates_cat_self_care'),
];

@Component
export struct PaperTemplateGallery {
  database?: DatabaseManager;
  // 原版 wfc 当前页上下文：解析 variant 用页 size/orientation + 纸张色 hex6。
  @Prop pageSize: PaperSize = PaperSize.LETTER;
  @Prop pageOrientation: PageOrientation = PageOrientation.PORTRAIT;
  @Prop backgroundColorHex: string = 'ffffff';
  @Prop busy: boolean = false;
  onSelectVariant: (variant: BundledPaperVariant) => void =
    (_variant: BundledPaperVariant): void => {
    };
  onRequestClose: () => void = () => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // ha6：pgc.a 对每个模板解析当前页上下文的 variant；null → 该模板不显示。
  private sections(): GallerySection[] {
    const sections: GallerySection[] = [];
    for (let c = 0; c < CATEGORY_TITLES.length; c++) {
      const items: GalleryCellItem[] = [];
      for (const template of BUNDLED_PAPER_TEMPLATES) {
        if (template.category !== c) {
          continue;
        }
        const variant: BundledPaperVariant | null = resolveBundledPaperVariant(
          template, this.pageSize, this.pageOrientation, this.backgroundColorHex);
        if (variant === null) {
          continue;
        }
        items.push({ template: template, variant: variant,
          cellKey: `${template.dir}/${variant.rawfilePath}` });
      }
      if (items.length > 0) {
        sections.push({ category: c, titleRes: CATEGORY_TITLES[c], items: items });
      }
    }
    return sections;
  }

  build() {
    Column() {
      Row() {
        Text($r('app.string.paper_templates_title'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
          .layoutWeight(1)
        Button() {
          ToolGlyph({
            glyph: 'close_med_regular',
            contentColor: this.resolveTokens().textSecondary,
            iconSize: 20,
          })
        }
          .width(36)
          .height(32)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.cd_pages_panel_close'))
          .onClick((): void => this.onRequestClose())
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 12, bottom: 8 })

      if (this.sections().length === 0) {
        Text($r('app.string.paper_templates_empty'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ top: 48 })
      } else {
        Scroll() {
          Column() {
            ForEach(this.sections(), (section: GallerySection) => {
              Column() {
                Text(section.titleRes)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.resolveTokens().textSecondary)
                  .width('100%')
                  .margin({ left: 16, bottom: 8, top: 12 })
                Grid() {
                  ForEach(section.items, (item: GalleryCellItem) => {
                    GridItem() {
                      BundledTemplateCell({
                        item: item,
                        database: this.database,
                        busy: this.busy,
                        onTap: (): void => this.onSelectVariant(item.variant),
                      })
                    }
                  }, (item: GalleryCellItem): string => item.cellKey)
                }
                .columnsTemplate('1fr 1fr 1fr')
                .columnsGap(10)
                .rowsGap(10)
                .padding({ left: 16, right: 16 })
              }
              .width('100%')
            }, (section: GallerySection): string => section.category.toString())
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().surface)
  }
}

@Component
struct BundledTemplateCell {
  item?: GalleryCellItem;
  database?: DatabaseManager;
  busy: boolean = false;
  onTap: () => void = () => {
  };
  @State private thumb: image.PixelMap | null = null;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private generation: number = 0;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    const generation: number = ++this.generation;
    const item: GalleryCellItem | undefined = this.item;
    const database: DatabaseManager | undefined = this.database;
    if (item === undefined || database === undefined) {
      return;
    }
    const context = getContext(this) as common.UIAbilityContext;
    loadBundledTemplateThumb(context, database, item.variant).then(
      (pixelMap: image.PixelMap | null): void => {
        if (generation === this.generation) {
          this.thumb = pixelMap;
        } else if (pixelMap !== null) {
          pixelMap.release().catch((_e: Object) => {
          });
        }
      }).catch((_e: Object) => {
      });
  }

  aboutToDisappear(): void {
    this.generation++;
    if (this.thumb !== null) {
      const pixelMap: image.PixelMap = this.thumb;
      this.thumb = null;
      pixelMap.release().catch((_e: Object) => {
      });
    }
  }

  build() {
    Column() {
      Stack() {
        if (this.thumb !== null) {
          Image(this.thumb)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
      }
      .width('100%')
      .height(132)
      .borderRadius(10)
      .backgroundColor(this.resolveTokens().control)
      .border({ width: 1, color: this.resolveTokens().border })
      .clip(true)
      Text(this.item === undefined ? '' : this.item.template.name)
        .fontSize(12)
        .fontColor(this.resolveTokens().textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .width('100%')
    .enabled(!this.busy)
    .onClick((): void => {
      if (!this.busy) {
        this.onTap();
      }
    })
  }
}
