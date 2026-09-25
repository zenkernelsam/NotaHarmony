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
import { rotatedOriginalPageInfo } from '../../core/model/PageBackgroundModel';
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
  @Prop @Watch('onPagesChange') pages: PageInfo[] = [];
  @Prop currentPageIndex: number = 0;
  // 内容修订种子：history push（undo/redo/插入/清空等）与结构变更时
  // 由宿主递增；cell key 携带它即可驱动缩略图重渲染，NOTES 过滤的
  // 元素计数也随之刷新。
  @Prop @Watch('onRevisionChange') thumbRevision: number = 0;
  onJumpToPage: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  onRequestClose: () => void = () => {
  };
  // 原版 n9j cell 菜单 → fd2 dispatch：Add page/Cut/Copy/Paste?/
  // Duplicate/Rotate?/Clear?/Delete（Create Template 生产 flag 关闭，
  // 上游不可见）。action 取值 'add'|'cut'|'copy'|'paste'|'duplicate'|
  // 'rotate'|'clear'|'delete'，宿主按 fd2 语义分发到页操作。
  canPastePages: boolean = false;
  onPageAction: (pageIndex: number, action: string) => void =
    (_pageIndex: number, _action: string): void => {
    };
  // 原版 tfh 选择工具条 → tc2 dispatch：action 取值
  // 'copy'|'duplicate'|'delete'|'cut'|'paste'|'bookmark'|'clear'，
  // pageIds 为当前选中页键集合（au1.T1 排序集等价物，升序页序）。
  onSelectionAction: (action: string, pageIds: string[]) => void =
    (_action: string, _pageIds: string[]): void => {
    };
  @State private filter: number = FILTER_ALL;
  // 原版 qd2.isSelecting/selectedPageIds：cell 菜单 "Select"（s8 case1 →
  // fd2 case0）把页键并入选中集；选中集非空即进入选择态并展示 tfh
  // 工具条。
  @State private selecting: boolean = false;
  @State private selectedPageIds: string[] = [];
  @State private nonEmptyPageIds: Set<string> = new Set<string>();
  @State private renderReady: boolean = false;
  // 原版 qd2.isSearchActive/searchQuery/searchMatchingPageKeys：
  // 搜索激活且 query 非空白时，把 nd2 过滤结果与命中页集合求交。
  @State private searchActive: boolean = false;
  @State private searchQuery: string = '';
  @State private matchingPageIds: Set<string> = new Set<string>();
  private searchGeneration: number = 0;
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

  // 原版 fd2 case0：toggle 页键进出 qd2.selectedPageIds。Harmony：
  // 并入首个页键时同步进入选择态（原版 isSelecting 与选中集为独立
  // 信号，选中集非空即渲染 tfh 工具条）。
  private toggleSelectPage(pageId: string): void {
    const index: number = this.selectedPageIds.indexOf(pageId);
    const next: string[] = this.selectedPageIds.slice();
    if (index >= 0) {
      next.splice(index, 1);
    } else {
      next.push(pageId);
    }
    this.selectedPageIds = next;
    if (next.length > 0) {
      this.selecting = true;
    }
  }

  // 原版 de2.u()：isSelecting=false + selectedPageIds=空 +
  // isSearchActive=false（掩码 463 一次复位三字段）。
  private exitSelection(): void {
    this.selecting = false;
    this.selectedPageIds = [];
    this.searchActive = false;
    this.searchGeneration++;
    this.matchingPageIds = new Set<string>();
  }

  // 原版 n9j function9 case2：selectedPageIds = qd2.c() 过滤后全集。
  private selectAllVisible(): void {
    const ids: string[] = [];
    for (const item of this.visibleItems()) {
      ids.push(item.page.pageId);
    }
    this.selectedPageIds = ids;
    if (ids.length > 0) {
      this.selecting = true;
    }
  }

  // 页列表变化（批删/批插）后裁剪选中集——原版 qd2.f 与 pages 同源
  // 更新，Harmony 在 Prop 变更时同步剔除已消失页键。
  private onPagesChange(): void {
    const alive: Set<string> = new Set<string>();
    for (const page of this.pages) {
      alive.add(page.pageId);
    }
    const kept: string[] = this.selectedPageIds.filter(
      (id: string): boolean => alive.has(id));
    if (kept.length !== this.selectedPageIds.length) {
      this.selectedPageIds = kept;
    }
  }

  private allVisibleSelected(): boolean {
    const items: PageCellItem[] = this.visibleItems();
    if (items.length === 0) {
      return false;
    }
    for (const item of items) {
      if (this.selectedPageIds.indexOf(item.page.pageId) < 0) {
        return false;
      }
    }
    return true;
  }

  private dispatchSelection(action: string): void {
    // tc2 dispatch 参数：au1.T1(selectedPageIds) → 升序页序排列。
    const ordered: string[] = this.pages
      .filter((page: PageInfo): boolean => this.selectedPageIds.indexOf(page.pageId) >= 0)
      .map((page: PageInfo): string => page.pageId);
    if (ordered.length === 0) {
      return;
    }
    this.onSelectionAction(action, ordered);
    // 原版退出语义：Copy(case0)/Delete(case2)/Cut(case3) 之后 u()；
    // Duplicate/Bookmark/Clear/Paste 保持选择态。
    if (action === 'copy' || action === 'delete' || action === 'cut') {
      this.exitSelection();
    }
  }

  // 原版 de2.s(query) → xd9.d 流产出命中页集合（sl case9 写回
  // qd2.searchMatchingPageKeys）。Harmony：generation 防乱序，
  // 空白 query 立即清空命中集（qd2.c() 空白即返回未过滤列表）。
  private runSearch(): void {
    const persistence = this.persistence;
    const query: string = this.searchQuery;
    const generation: number = ++this.searchGeneration;
    if (persistence === undefined || this.noteId.length === 0 ||
      query.trim().length === 0) {
      this.matchingPageIds = new Set<string>();
      return;
    }
    persistence.searchPageIdsWithText(this.noteId, query)
      .then((matches: Set<string>): void => {
        if (this.disposed || generation !== this.searchGeneration) {
          return;
        }
        this.matchingPageIds = matches;
      })
      .catch((e: Error) => {
        console.error(`PageOverviewPanel search failed: ${JSON.stringify(e)}`);
      });
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
      // 原版 qd2.c() 尾段：isSearchActive && !query.isBlank → 与
      // searchMatchingPageKeys 求交（结果未到齐前为空集 → fail-closed
      // 空列表，与原版初始空集一致）。
      if (this.searchActive && this.searchQuery.trim().length > 0 &&
        !this.matchingPageIds.has(page.pageId)) {
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
        // 原版 r22 case24：content_manager_search 行（ue4.A 搜索图标）
        // 激活 de2.l() → qd2.isSearchActive。
        Button('🔍')
          .width(36)
          .height(32)
          .fontSize(14)
          .margin({ left: 4 })
          .fontColor(this.searchActive ?
            this.resolveTokens().accent : this.resolveTokens().textSecondary)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.cd_pages_panel_search'))
          .onClick(() => {
            // de2.l() 对齐：开启搜索；关闭时清空 query 与命中集。
            this.searchActive = !this.searchActive;
            if (!this.searchActive) {
              this.searchQuery = '';
              this.searchGeneration++;
              this.matchingPageIds = new Set<string>();
            }
          })
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

      if (this.selecting) {
        // 原版 tfh 选择工具条：select/deselect-all + 批量页操作
        // （copy/duplicate/delete 图标位 + cut/paste/bookmark/clear
        // 溢出项）。Clear 对多页选集 fail-closed（ADR-0615），仅当选中
        // 集恰为当前页时可经画布信号执行。
        // p7j:663/951：工具条前部 "N of M selected" 计数标签
        // （ui_pageselection__x_of_y_selected，分母=过滤后可见列表）。
        Row() {
          Text($r('app.string.pages_x_of_y_selected',
            this.selectedPageIds.length, this.visibleItems().length))
            .fontSize(12)
            .fontColor(this.resolveTokens().textSecondary)
            .margin({ right: 8 })
          Scroll() {
          Row() {
            this.SelectionActionChip(
              this.allVisibleSelected() ?
                $r('app.string.pages_deselect_all') :
                $r('app.string.pages_select_all'),
              (): void => {
                // n9j case2/case3：Select all 装载过滤全集；Deselect all
                // 清空选中集并经 de2.u() 退出选择态。
                if (this.allVisibleSelected()) {
                  this.exitSelection();
                } else {
                  this.selectAllVisible();
                }
              }, true)
            this.SelectionActionChip($r('app.string.copy_page'),
              (): void => this.dispatchSelection('copy'), this.selectedPageIds.length > 0)
            this.SelectionActionChip($r('app.string.duplicate_page'),
              (): void => this.dispatchSelection('duplicate'), this.selectedPageIds.length > 0)
            this.SelectionActionChip($r('app.string.delete_page'),
              (): void => this.dispatchSelection('delete'), this.selectedPageIds.length > 0)
            this.SelectionActionChip($r('app.string.cut_page'),
              (): void => this.dispatchSelection('cut'), this.selectedPageIds.length > 0)
            if (this.canPastePages) {
              this.SelectionActionChip($r('app.string.paste_page'),
                (): void => this.dispatchSelection('paste'), this.selectedPageIds.length > 0)
            }
            this.SelectionActionChip($r('app.string.bookmark_page'),
              (): void => this.dispatchSelection('bookmark'), this.selectedPageIds.length > 0)
            // ae2 v1 批量 Clear：任意选中集可清空（非当前页走持久层
            // 通道，当前页走画布信号）。
            this.SelectionActionChip($r('app.string.clear_page'),
              (): void => this.dispatchSelection('clear'),
              this.selectedPageIds.length > 0)
            this.SelectionActionChip($r('app.string.pages_done'),
              (): void => this.exitSelection(), true)
          }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .padding({ right: 12, bottom: 8 })
        }
        .width('100%')
        .padding({ left: 16 })
      }

      if (this.searchActive) {
        // 原版 de2.s(query)：输入即写入 qd2.searchQuery 并触发命中
        // 集合重算（generation 防乱序）。
        TextInput({ placeholder: $r('app.string.pages_panel_search_placeholder'),
          text: this.searchQuery })
          .height(36)
          .fontSize(14)
          .margin({ left: 16, right: 16, bottom: 8 })
          .fontColor(this.resolveTokens().textPrimary)
          .placeholderColor(this.resolveTokens().textSecondary)
          .backgroundColor(this.resolveTokens().control)
          .borderRadius(10)
          .accessibilityText($r('app.string.pages_panel_search'))
          .onChange((value: string) => {
            this.searchQuery = value;
            this.runSearch();
          })
      }

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
                canPaste: this.canPastePages,
                selecting: this.selecting,
                checked: this.selectedPageIds.indexOf(item.page.pageId) >= 0,
                onRequest: (page: PageInfo): Promise<PixelMap | null> =>
                  this.requestThumbnail(page),
                onTap: (pageIndex: number): void => {
                  // 原版 id2 cell：选择态下 tap 走 fd2 case0 切换选中
                  // 成员；非选择态才是跳页（gd2/hd2）。
                  if (this.selecting) {
                    this.toggleSelectPage(item.page.pageId);
                  } else {
                    this.onJumpToPage(pageIndex);
                  }
                },
                onMenuAction: (pageIndex: number, action: string): void => {
                  this.onPageAction(pageIndex, action);
                },
                onToggleSelect: (pageIndex: number): void => {
                  if (pageIndex >= 0 && pageIndex < this.pages.length) {
                    this.toggleSelectPage(this.pages[pageIndex].pageId);
                  }
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
  SelectionActionChip(label: ResourceStr, onTap: () => void, enabled: boolean) {
    Text(label)
      .fontSize(12)
      .fontColor(enabled ?
        this.resolveTokens().accent : this.resolveTokens().textSecondary)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.resolveTokens().control)
      .borderRadius(8)
      .margin({ right: 8 })
      .opacity(enabled ? 1 : 0.45)
      .onClick(() => {
        if (enabled) {
          onTap();
        }
      })
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
  @Prop canPaste: boolean = false;
  // 原版 qd2.isSelecting/f.contains(key)：选择态下 cell 渲染勾选
  // 指示，tap 语义切换为 fd2 case0（成员切换）。
  @Prop selecting: boolean = false;
  @Prop checked: boolean = false;
  onRequest: (page: PageInfo) => Promise<PixelMap | null> =
    (_page: PageInfo): Promise<PixelMap | null> => Promise.resolve(null);
  onTap: (pageIndex: number) => void = (_pageIndex: number): void => {
  };
  onMenuAction: (pageIndex: number, action: string) => void =
    (_pageIndex: number, _action: string): void => {
    };
  // s8 case1 → fd2 case0：cell 溢出菜单 "Select" 项。
  onToggleSelect: (pageIndex: number) => void = (_pageIndex: number): void => {
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
        if (this.selecting) {
          // 选择态勾选指示：选中=实心 ✓，未选中=空心圈。
          Text(this.checked ? '✓' : '')
            .fontSize(12)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(20)
            .height(20)
            .borderRadius(10)
            .backgroundColor(this.checked ?
              this.resolveTokens().accent : '#66000000')
            .border({ width: 1, color: Color.White, radius: 10 })
            .position({ x: 4, y: 4 })
            .accessibilityText($r('app.string.pages_menu_select'))
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
    // 原版 n9j cell 下拉菜单（fd2 dispatch）：Add page/Cut/Copy/Paste?/
    // Duplicate/Rotate?/Clear?/Delete。Harmony 以长按上下文菜单承载；
    // Clear 仅当前页可经画布信号清空（非当前页 fail-closed 隐藏）。
    .bindContextMenu(this.buildCellMenu(), ResponseType.LongPress)
  }

  @Builder
  private buildCellMenu() {
    Menu() {
      // fd2 case3 → zd2 v0 → u5j.i：在该页之后插入新页。
      MenuItem({ content: $r('app.string.add_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'add'))
      // fd2 case4 → de2.p → ae2 v3：Copy + Delete。
      MenuItem({ content: $r('app.string.cut_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'cut'))
      // fd2 case5 → de2.o → ae2 v2：页剪贴板拷贝。
      MenuItem({ content: $r('app.string.copy_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'copy'))
      if (this.canPaste) {
        // fd2 case6 → e2 v16：页剪贴板粘贴到该页之后。
        MenuItem({ content: $r('app.string.paste_page') })
          .onClick(() => this.onMenuAction(this.pageIndex, 'paste'))
      }
      // fd2 case7 → de2.r → ae2 v5：整页复制到该页之后。
      MenuItem({ content: $r('app.string.duplicate_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'duplicate'))
      if (this.page !== undefined && rotatedOriginalPageInfo(this.page) !== null) {
        // fd2 default → zd2 v1：Rotate Page。
        MenuItem({ content: $r('app.string.rotate_page') })
          .onClick(() => this.onMenuAction(this.pageIndex, 'rotate'))
      }
      // fd2 case1 → de2.n → ae2 v1：Clear Page——当前页走画布信号，
      // 非当前页经持久层清空（clearOriginalPageContent）。
      MenuItem({ content: $r('app.string.clear_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'clear'))
      // fd2 case2 → de2.q → ae2 v4：Delete Pages。
      MenuItem({ content: $r('app.string.delete_page') })
        .onClick(() => this.onMenuAction(this.pageIndex, 'delete'))
      // s8 case1 → fd2 case0：把该页键并入/移出选中集（进入选择态）。
      MenuItem({ content: $r('app.string.pages_menu_select') })
        .onClick(() => this.onToggleSelect(this.pageIndex))
    }
  }
}
