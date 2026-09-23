// Phase 645 页面管理面板（原版 content manager 页总览）。
// 原版证据（decompiled_1.0.3）：
//   qd2.UiState = currentPageIndex/pages/thumbnails/selectedFilter/
//     isSelecting/selectedPageIds/isSearchActive/...；
//   nd2 过滤枚举 ALL(0)/BOOKMARKS(1)/NOTES(2) → n9j:2212-2220 三枚
//     filter chip（feature_note__content_manager_filter_*）；
//   gs8 case2 = content_manager_toggle（顶栏 pq9.N 首位）；
//   标题 feature_note__content_manager_title = "Pages"；
//   空态 ui_pageselection__no_pages = "No pages to display"；
//   关闭 a11y = content_manager_close_description。
// Harmony 子集（ADR-0612）：缩略图栅格 + 三过滤 chip + 点击跳页 +
// 当前页高亮 + 书签角标；多选（isSelecting/selectedPageIds/tfh 工具条）
// 与页内搜索（isSearchActive/searchMatchingPageKeys）登记后续 Phase。
import { common } from '@kit.AbilityKit';
import { PageInfo } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { StrokePersistence } from '../../data/StrokePersistence';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

// 原版 nd2 枚举序：ALL(0)、BOOKMARKS(1)、NOTES(2)。
const FILTER_ALL: number = 0;
const FILTER_BOOKMARKS: number = 1;
const FILTER_NOTES: number = 2;

interface PageCellItem {
  page: PageInfo;
  index: number;
  cellKey: string;
}

@Component
export struct PageOverviewPanel {
  // 宿主注入：笔记身份与数据源（服务对象，构建期一次性传入）。
  noteId: string = '';
  persistence?: StrokePersistence;
  database?: DatabaseManager;
  @Prop pages: PageInfo[] = [];
  @Prop currentPageIndex: number = 0;
  // 内容修订种子：history push（undo/redo/插入/清空等）与结构变更时
  // 由宿主递增；cell key 携带它即可驱动缩略图重渲染，NOTES 过滤的
  // 元素计数也随之刷新。
  @Prop @Watch('onRevisionChange') thumbRevision: number = 0;
  onJumpToPage: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  onRequestClose: () => void = () => {
  };
  @State private filter: number = FILTER_ALL;
  @State private nonEmptyPageIds: Set<string> = new Set<string>();
  @State private renderReady: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private renderer: ThumbnailRenderer | null = null;
  private thumbChain: Promise<void> = Promise.resolve();
  private disposed: boolean = false;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const renderer: ThumbnailRenderer = new ThumbnailRenderer();
    this.renderer = renderer;
    renderer.initialize(context)
      .then((): void => {
        if (!this.disposed && this.renderer === renderer) {
          this.renderReady = true;
        }
      })
      .catch((e: Error) => {
        console.error(`PageOverviewPanel renderer init failed: ${JSON.stringify(e)}`);
      });
    this.loadElementCounts();
  }

  private onRevisionChange(): void {
    this.loadElementCounts();
  }

  private loadElementCounts(): void {
    const persistence = this.persistence;
    if (persistence === undefined || this.noteId.length === 0) {
      return;
    }
    persistence.getPageElementCounts(this.noteId)
      .then((counts: Map<string, number>): void => {
        if (this.disposed) {
          return;
        }
        const ids: Set<string> = new Set<string>();
        counts.forEach((count: number, pageId: string): void => {
          if (count > 0) {
            ids.add(pageId);
          }
        });
        this.nonEmptyPageIds = ids;
      })
      .catch((e: Error) => {
        console.error(`PageOverviewPanel element counts failed: ${JSON.stringify(e)}`);
      });
  }

  aboutToDisappear(): void {
    this.disposed = true;
    const renderer = this.renderer;
    this.renderer = null;
    if (renderer !== null) {
      renderer.dispose().catch((e: Error) => {
        console.error(`PageOverviewPanel renderer dispose failed: ${JSON.stringify(e)}`);
      });
    }
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // 串行化缩略图渲染：一次一个，cell 拿到 PixelMap 后自行持有/释放。
  private requestThumbnail(page: PageInfo): Promise<PixelMap | null> {
    const renderer = this.renderer;
    const persistence = this.persistence;
    const database = this.database;
    if (renderer === null || persistence === undefined || database === undefined ||
      !this.renderReady || this.disposed) {
      return Promise.resolve(null);
    }
    const theme: ThemeTokens = this.resolveTokens();
    const noteId: string = this.noteId;
    let produced: PixelMap | null = null;
    this.thumbChain = this.thumbChain.then(async (): Promise<void> => {
      if (this.disposed || this.renderer !== renderer) {
        return;
      }
      produced = await renderer.renderThumbnail(noteId, persistence, page, theme, database);
    }).catch((e: Error) => {
      console.error(`PageOverviewPanel thumbnail failed: ${JSON.stringify(e)}`);
    });
    return this.thumbChain.then((): PixelMap | null => produced);
  }

  private visibleItems(): PageCellItem[] {
    const items: PageCellItem[] = [];
    for (let i = 0; i < this.pages.length; i++) {
      const page: PageInfo = this.pages[i];
      if (this.filter === FILTER_BOOKMARKS && page.bookmarked !== true) {
        continue;
      }
      if (this.filter === FILTER_NOTES && !this.nonEmptyPageIds.has(page.pageId)) {
        continue;
      }
      items.push({
        page: page,
        index: i,
        // key 携带页身份 + 几何/背景相关字段 + 内容修订种子：
        // 旋转/换模板/内容编辑都会驱动该 cell 重新取缩略图。
        cellKey: `${page.pageId}:${page.size}:${page.template}:${page.orientation}:` +
          `${page.widthMm}:${page.heightMm}:${this.thumbRevision}:${this.themeMode}:` +
          `${this.systemDark ? 1 : 0}`,
      });
    }
    return items;
  }

  build() {
    Column() {
      // 头部：标题 "Pages"（content_manager_title）+ 三枚过滤 chip +
      // 显式关闭按钮（close_description a11y）。
      Row() {
        Text($r('app.string.pages_panel_title'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
        Blank()
        this.FilterChip($r('app.string.pages_filter_all'), FILTER_ALL)
        this.FilterChip($r('app.string.pages_filter_bookmarks'), FILTER_BOOKMARKS)
        this.FilterChip($r('app.string.pages_filter_notes'), FILTER_NOTES)
        Button('✕')
          .width(36)
          .height(32)
          .fontSize(14)
          .margin({ left: 8 })
          .fontColor(this.resolveTokens().textSecondary)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.cd_pages_panel_close'))
          .onClick(() => {
            this.onRequestClose();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 12, bottom: 8 })

      if (this.visibleItems().length === 0) {
        // ui_pageselection__no_pages：过滤后为空时渲染空态文案。
        Text($r('app.string.pages_panel_empty'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ top: 48 })
      } else {
        Grid() {
          ForEach(this.visibleItems(), (item: PageCellItem) => {
            GridItem() {
              PageOverviewCell({
                page: item.page,
                pageIndex: item.index,
                cellKey: item.cellKey,
                selected: item.index === this.currentPageIndex,
                onRequest: (page: PageInfo): Promise<PixelMap | null> =>
                  this.requestThumbnail(page),
                onTap: (pageIndex: number): void => {
                  this.onJumpToPage(pageIndex);
                },
              })
            }
          }, (item: PageCellItem): string => item.cellKey)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding({ left: 12, right: 12, bottom: 12 })
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().surface)
  }

  @Builder
  FilterChip(label: ResourceStr, value: number) {
    Text(label)
      .fontSize(12)
      .fontColor(this.filter === value ?
        this.resolveTokens().accent : this.resolveTokens().textSecondary)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.filter === value ?
        this.resolveTokens().control : Color.Transparent)
      .borderRadius(8)
      .margin({ left: 4 })
      .onClick(() => {
        this.filter = value;
      })
  }
}

// 单页缩略图 cell：自带 PixelMap 生命周期（出现时取图，消失时释放）。
@Component
struct PageOverviewCell {
  page?: PageInfo;
  @Prop pageIndex: number = 0;
  @Prop @Watch('onCellKeyChange') cellKey: string = '';
  @Prop selected: boolean = false;
  onRequest: (page: PageInfo) => Promise<PixelMap | null> =
    (_page: PageInfo): Promise<PixelMap | null> => Promise.resolve(null);
  onTap: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  @State private pixelMap: PixelMap | null = null;
  @State private loadingFailed: boolean = false;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  private loadGeneration: number = 0;

  aboutToAppear(): void {
    this.reload();
  }

  aboutToDisappear(): void {
    this.loadGeneration++;
    const pm: PixelMap | null = this.pixelMap;
    this.pixelMap = null;
    if (pm !== null) {
      pm.release().catch((): void => { });
    }
  }

  private onCellKeyChange(): void {
    this.reload();
  }

  private reload(): void {
    const page = this.page;
    if (page === undefined) {
      return;
    }
    const generation: number = ++this.loadGeneration;
    this.loadingFailed = false;
    this.onRequest(page)
      .then((pm: PixelMap | null): void => {
        if (generation !== this.loadGeneration) {
          if (pm !== null) {
            pm.release().catch((): void => { });
          }
          return;
        }
        const old: PixelMap | null = this.pixelMap;
        this.pixelMap = pm;
        this.loadingFailed = pm === null;
        if (old !== null) {
          old.release().catch((): void => { });
        }
      })
      .catch((): void => {
        if (generation === this.loadGeneration) {
          this.loadingFailed = true;
        }
      });
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Stack() {
        if (this.pixelMap !== null) {
          Image(this.pixelMap)
            .width('100%')
            .aspectRatio(0.75)
            .objectFit(ImageFit.Contain)
        } else {
          Column()
            .width('100%')
            .aspectRatio(0.75)
            .backgroundColor('#F5F5F5')
        }
        if (this.page?.bookmarked === true) {
          // md.java bookmark_tall_fill 角标对齐（PageManagerBar 同款）。
          Text('🔖')
            .fontSize(12)
            .position({ x: '82%', y: 4 })
            .accessibilityText($r('app.string.bookmark_page'))
        }
      }
      .width('100%')
      .borderRadius(6)
      .clip(true)
      .border({
        width: this.selected ? 2 : 1,
        color: this.selected ? this.resolveTokens().accent : '#E0E0E0',
        radius: 6,
      })
      Text((this.pageIndex + 1).toString())
        .fontSize(11)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 4 })
    }
    .width('100%')
    .onClick(() => {
      this.onTap(this.pageIndex);
    })
  }
}
