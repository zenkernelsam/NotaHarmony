// Phase 1401 捆绑纸张模板图库（原版 1.4.2 x2n/u7n.e 模板面）。
// Phase 1402：cell 星标收藏 + Recents/Favorites 顶部区块（gaf/qsh
//   FavoritePaperTemplate/RecentPaperTemplate/PaperTemplateUsage 等价物，
//   BundledTemplateMetaStore 承载；原版挂 PRESET tab 的 qia{recents,favorites}
//   在 Harmony 合并为统一分节列表，见 ADR-1338）。
// 原版证据（decompiled_1.4.2）：
//   rgc: assets.list("papertemplates") → zgc.b 解析 metadata.json +
//     文件名约定 <P>_<Size>_<hex6>[_orient].pdf；thumb 门控可见性；
//     排序 category.ordinal → displayIndex(null→MAX) → name。
//   ha6: 按 ugc 类目分节（NOTEPADS/ACADEMIC/CREATIVE/PLANNING/SELF_CARE，
//     ui_papertemplates__* 标题）；pgc.a(size,orient,colorHex) 为当前页
//     上下文解析 variant——无匹配变体的模板不出现在图库中。
//   点选 cell → rsh.q(chc) → a1d Preset → f1d/sqc.b 暂存打包 PDF →
//     导入资产库 → 设置当前页背景寄存器。
//   qgc.b = {模板, resolvedVariant, isCurrent, isFavorite}；cell 右上星标
//     ui_designsystem__favorite_fill/outline（星形 path，fill vs 1.25 stroke），
//     tap → rsh/ith.o(chc,z) 持久化收藏；qgc.c = 本会话最近应用变体徽记。
// Harmony 子集（ADR-1337/1338）：类目分节 + Recents/Favorites 区块 +
//   PDF 光栅化缩略图 + 星标收藏 + 点选应用当前页。
// 变体作用域（Pages scope）、set-as-default、My Templates、封面、
// repeat-template 为后续 Phase 登记项。
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import {
  BundledPaperTemplate, BundledPaperVariant, BundledPaperVariantMatch,
  BUNDLED_PAPER_TEMPLATES, findBundledPaperVariantByPath,
  resolveBundledPaperVariant,
} from '../../core/model/PaperTemplateCatalog';
import { PageOrientation, PaperSize } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { BundledTemplateMetaStore } from '../../data/BundledTemplateMetaStore';
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
  titleRes: Resource;
  items: GalleryCellItem[];
  // 原版 ria.FAVORITES/RECENTS：区块非类别 → 空态文案；类别区块空时不渲染。
  emptyRes?: Resource;
  sectionKey: string;
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
  // 原版 qgc.c：本会话最近一次 Preset 应用的 rawfilePath（重开图库时徽记）。
  @Prop appliedVariantPath: string = '';
  onSelectVariant: (variant: BundledPaperVariant) => void =
    (_variant: BundledPaperVariant): void => {
    };
  onRequestClose: () => void = () => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  @State private favoritePaths: string[] = [];
  @State private recentPaths: string[] = [];
  private metaStore?: BundledTemplateMetaStore;

  private store(): BundledTemplateMetaStore {
    if (this.metaStore === undefined) {
      this.metaStore = new BundledTemplateMetaStore(
        getContext(this) as common.UIAbilityContext);
    }
    return this.metaStore;
  }

  aboutToAppear(): void {
    const store: BundledTemplateMetaStore = this.store();
    store.getFavoritePaths().then((paths: string[]): void => {
      this.favoritePaths = paths;
    }).catch((_e: Object) => {
    });
    store.getRecentPaths().then((paths: string[]): void => {
      this.recentPaths = paths;
    }).catch((_e: Object) => {
    });
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  private isFavorited(variant: BundledPaperVariant): boolean {
    return this.favoritePaths.indexOf(variant.rawfilePath) >= 0;
  }

  // 原版 pth.o(chc,z) → yb6(gaf, chc.e, z)：FavoritePaperTemplate upsert/delete。
  private toggleFavorite(variant: BundledPaperVariant): void {
    const favorite: boolean = !this.isFavorited(variant);
    const optimistic: string[] = this.favoritePaths.slice();
    if (favorite && optimistic.indexOf(variant.rawfilePath) < 0) {
      optimistic.unshift(variant.rawfilePath);
    } else if (!favorite) {
      const index: number = optimistic.indexOf(variant.rawfilePath);
      if (index >= 0) {
        optimistic.splice(index, 1);
      }
    }
    this.favoritePaths = optimistic;
    this.store().setFavorite(variant.rawfilePath, favorite).catch((_e: Object) => {
      // 写库失败回滚显示态，与 EditorSettingsStore 的 prefs 回滚语义一致。
      this.store().getFavoritePaths().then((paths: string[]): void => {
        this.favoritePaths = paths;
      }).catch((_e2: Object) => {
      });
    });
  }

  // 原版 s7n.d(mapI0,…)：recents/favorites 按存入的 pdfAssetPath 精确反查变体。
  private itemsFromPaths(paths: string[]): GalleryCellItem[] {
    const items: GalleryCellItem[] = [];
    for (const path of paths) {
      const match: BundledPaperVariantMatch | null =
        findBundledPaperVariantByPath(path);
      if (match === null) {
        continue;
      }
      items.push({ template: match.template, variant: match.variant,
        cellKey: `${match.template.dir}/${match.variant.rawfilePath}` });
    }
    return items;
  }

  // ha6：pgc.a 对每个模板解析当前页上下文的 variant；null → 该模板不显示。
  // 原版 qia{recents,favorites} 置顶（favoritedAt/usedAt DESC）；类别区块随后。
  private sections(): GallerySection[] {
    const sections: GallerySection[] = [];
    const recentItems: GalleryCellItem[] = this.itemsFromPaths(this.recentPaths);
    const favoriteItems: GalleryCellItem[] = this.itemsFromPaths(this.favoritePaths);
    // 原版 ria.RECENTS/FAVORITES：区块恒在，空时显示引导文案。
    sections.push({ titleRes: $r('app.string.paper_templates_recents'),
      items: recentItems, emptyRes: $r('app.string.paper_templates_no_recents'),
      sectionKey: 'recents' });
    sections.push({ titleRes: $r('app.string.paper_templates_favorites'),
      items: favoriteItems, emptyRes: $r('app.string.paper_templates_no_favorites'),
      sectionKey: 'favorites' });
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
        sections.push({ titleRes: CATEGORY_TITLES[c], items: items,
          sectionKey: `cat_${c}` });
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
                if (section.items.length === 0 && section.emptyRes !== undefined) {
                  // 原版 ria 空态文案（PRESET tab 区块）。
                  Text(section.emptyRes)
                    .fontSize(13)
                    .fontColor(this.resolveTokens().textSecondary)
                    .width('100%')
                    .margin({ left: 16, right: 16, bottom: 4 })
                } else {
                  Grid() {
                    ForEach(section.items, (item: GalleryCellItem) => {
                      GridItem() {
                        BundledTemplateCell({
                          item: item,
                          database: this.database,
                          busy: this.busy,
                          favorite: this.isFavorited(item.variant),
                          current: item.variant.rawfilePath ===
                            this.appliedVariantPath,
                          onTap: (): void => this.onSelectVariant(item.variant),
                          onToggleFavorite: (): void =>
                            this.toggleFavorite(item.variant),
                        })
                      }
                    }, (item: GalleryCellItem): string => item.cellKey)
                  }
                  .columnsTemplate('1fr 1fr 1fr')
                  .columnsGap(10)
                  .rowsGap(10)
                  .padding({ left: 16, right: 16 })
                }
              }
              .width('100%')
            }, (section: GallerySection): string => section.sectionKey)
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

// 原版 ui_designsystem__favorite_fill/_outline 星形 pathData（24×24 viewport）；
// fill 版纯色填充，outline 版同色 1.25 stroke round-join evenOdd。
const FAVORITE_STAR_PATH: string =
  'M12.691,19.969C12.258,19.743 11.742,19.743 11.309,19.969L6.811,22.327' +
  'C5.722,22.897 4.449,21.976 4.657,20.767L5.516,15.774C5.599,15.294 ' +
  '5.439,14.805 5.089,14.465L1.45,10.929C0.569,10.073 1.055,8.582 ' +
  '2.272,8.405L7.302,7.677C7.786,7.607 8.203,7.304 8.42,6.868L10.669,2.325' +
  'C11.214,1.225 12.786,1.225 13.331,2.325L15.58,6.868C15.797,7.304 ' +
  '16.214,7.607 16.698,7.677L21.728,8.405C22.945,8.582 23.431,10.073 ' +
  '22.55,10.929L18.91,14.465C18.561,14.805 18.401,15.294 18.484,15.774' +
  'L19.343,20.767C19.551,21.976 18.278,22.897 17.19,22.327L12.691,19.969Z';

@Component
struct BundledTemplateCell {
  item?: GalleryCellItem;
  database?: DatabaseManager;
  @Prop busy: boolean = false;
  @Prop favorite: boolean = false;
  // 原版 qgc.c：本会话最近应用变体的徽记态。
  @Prop current: boolean = false;
  onTap: () => void = () => {
  };
  onToggleFavorite: () => void = () => {
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
        // 原版 ibn.c cell：右上星标 favorite_fill/outline → rsh.o(chc,z)。
        Stack() {
          Shape() {
            if (this.favorite) {
              Path()
                .commands(FAVORITE_STAR_PATH)
                .fill(this.resolveTokens().accent)
                .stroke(Color.Transparent)
            } else {
              Path()
                .commands(FAVORITE_STAR_PATH)
                .fill(Color.Transparent)
                .stroke(this.resolveTokens().textSecondary)
                .strokeWidth(1.25)
                .strokeLineJoin(LineJoinStyle.Round)
            }
          }
          .width(18)
          .height(18)
          .viewPort({ x: 0, y: 0, width: 24, height: 24 })
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(this.resolveTokens().surface)
        .opacity(0.92)
        .align(Alignment.TopEnd)
        .margin({ top: 6, right: 6 })
        .accessibilityText(this.favorite
          ? $r('app.string.paper_templates_unfavorite')
          : $r('app.string.paper_templates_favorite'))
        // ArkUI 命中测试落在最内层组件 —— 星标 tap 不会冒泡触发 cell onTap。
        .onClick((): void => {
          if (!this.busy) {
            this.onToggleFavorite();
          }
        })
      }
      .width('100%')
      .height(132)
      .borderRadius(10)
      .backgroundColor(this.resolveTokens().control)
      // 原版 qgc.c：当前已应用变体以 accent 描边徽记。
      .border(this.current
        ? { width: 2, color: this.resolveTokens().accent }
        : { width: 1, color: this.resolveTokens().border })
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
