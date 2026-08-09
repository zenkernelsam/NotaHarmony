// T-025 笔记编辑器页面（EditorToolbar + NoteCanvasView + PageManagerBar 集成）
// T-036：标题行内编辑 + 持久化
import { router, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NoteMeta, PageInfo } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { ToolRepositoryImpl } from '../../data/ToolRepositoryImpl';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import {
  AddPageAction, DeletePageAction, EditorHistoryBridge, PageContentSnapshot, UndoableAction,
  UndoableActionType,
} from '../../rendering/UndoRedoManager';
import { EditorViewModel } from './EditorViewModel';
import { EditorToolbar } from './EditorToolbar';
import { NoteCanvasView } from './NoteCanvasView';
import { PageManagerBar } from './PageManagerBar';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct NotePage {
  private noteId: string = '';
  @State viewModel: EditorViewModel = new EditorViewModel();
  @State pages: PageInfo[] = [];
  @State currentPageIndex: number = 0;
  @State undoSignal: number = 0;
  @State redoSignal: number = 0;
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  @State pageOperationBusy: boolean = false;
  @State pageLoading: boolean = false;
  @State pageLoadFailed: boolean = false;
  @State noteTitle: string = '';          // T-036：标题
  @State editingTitle: boolean = false;   // T-036：标题编辑态
  @State titleDraft: string = '';
  private noteRepo: NoteRepositoryImpl | null = null;
  private pageRepo: PageRepositoryImpl | null = null;
  private persistence: StrokePersistence = new StrokePersistence();
  private historyBridge: EditorHistoryBridge | null = null;
  private pageLoadInFlight: boolean = false;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params['noteId'] !== undefined) {
      this.noteId = params['noteId'];
    }
    this.loadPages();
  }

  // T-040 修复：路由返回时 TextInput 的 onBlur 不保证触发，必须在页面销毁时兜底保存标题
  aboutToDisappear(): void {
    if (this.editingTitle) {
      this.saveTitle();
    }
  }

  onBackPress(): boolean {
    this.leaveEditor();
    return true;
  }

  private async leaveEditor(): Promise<void> {
    if (this.editingTitle) {
      await this.saveTitle();
    }
    if (this.historyBridge !== null && !await this.historyBridge.flushCurrentPage()) {
      return;
    }
    await this.viewModel.flushToolState();
    router.back();
  }

  private async loadPages(): Promise<void> {
    if (this.pageLoadInFlight) {
      return;
    }
    this.pageLoadInFlight = true;
    this.pageLoading = true;
    this.pageLoadFailed = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.pageRepo = new PageRepositoryImpl(db);
      this.persistence.initialize(db);
      this.viewModel.onPersistenceError = (message: string): void => {
        hilog.error(0x0001, 'NotePage', '%{public}s', message);
        try {
          promptAction.showToast({ message: 'Tool settings could not be saved', duration: 2500 });
        } catch (toastError) {
          console.error(`Tool settings toast failed: ${JSON.stringify(toastError)}`);
        }
      };
      await this.viewModel.initialize(new ToolRepositoryImpl(db), 'primary-editor',
        new EditorSettingsStore(context));
      // T-036：加载标题
      this.noteRepo = new NoteRepositoryImpl(db);
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      if (note === null) {
        throw new Error('note does not exist');
      }
      this.noteTitle = note.title;
      const loaded: PageInfo[] = await this.pageRepo.getPages(this.noteId);
      if (loaded.length === 0) {
        // 创建默认首页（A4 / PLAIN）
        const defaultPage: PageInfo = {
          pageId: this.generateId(),
          pageIndex: 0,
          size: 1,
          template: 0,
          orientation: 0,
          widthMm: 210.0,
          heightMm: 297.0,
        };
        const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, defaultPage);
        this.pages = [assignedPage];
      } else {
        this.pages = loaded;
      }
      this.currentPageIndex = 0;
      this.pageLoadFailed = false;
    } catch (e) {
      this.pages = [];
      this.currentPageIndex = 0;
      this.historyBridge = null;
      this.pageRepo = null;
      this.noteRepo = null;
      this.pageLoadFailed = true;
      console.error(`NotePage loadPages failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.note_open_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Note page load toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.pageLoading = false;
      this.pageLoadInFlight = false;
    }
  }

  // T-036：标题编辑保存（updateNote 持久化）
  private async saveTitle(): Promise<void> {
    this.editingTitle = false;
    const draft: string = this.titleDraft.trim();
    if (draft.length === 0) {
      return;  // 空标题不保存（显示占位）
    }
    const previousTitle: string = this.noteTitle;
    this.noteTitle = draft;
    try {
      if (this.noteRepo === null) {
        throw new Error('note repository is unavailable');
      }
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      if (note === null) {
        throw new Error('note does not exist');
      }
      note.title = draft;
      await this.noteRepo.updateNote(note);
    } catch (e) {
      this.noteTitle = previousTitle;
      console.error(`saveTitle failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.note_save_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Title save failure toast failed: ${JSON.stringify(toastError)}`);
      }
    }
  }

  build() {
    Column() {
      // 顶部导航行（48vp）
      Row() {
        Button($r('app.string.back'))
          .height(36)
          .fontSize(14)
          .onClick(async () => {
            // T-040 修复：先等待标题保存完成再返回，避免与 LibraryPage onPageShow 刷新竞态
            if (this.editingTitle) {
              await this.saveTitle();
            }
            if (this.historyBridge !== null && !await this.historyBridge.flushCurrentPage()) {
              return;
            }
            await this.viewModel.flushToolState();
            router.back();
          })
        if (this.editingTitle) {
          // T-036：标题编辑态（TextInput，失焦/回车保存）
          TextInput({ text: this.titleDraft })
            .layoutWeight(1)
            .height(36)
            .fontSize(16)
            .margin({ left: 12 })
            .onChange((value: string) => {
              this.titleDraft = value;
            })
            .onSubmit(() => {
              this.saveTitle();
            })
            .onBlur(() => {
              this.saveTitle();
            })
        } else {
          Text(this.noteTitle.length > 0 ? this.noteTitle : $r('app.string.untitled_note'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary)
            .margin({ left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .onClick(() => {
              if (this.pageLoadFailed || this.pageLoading) {
                return;
              }
              this.titleDraft = this.noteTitle;
              this.editingTitle = true;
            })
        }
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.resolveTokens().surface)

      // 工具栏
      if (this.pages.length > 0) {
        EditorToolbar({
          viewModel: this.viewModel,
          canUndo: this.canUndo,
          canRedo: this.canRedo,
          onUndo: () => {
            this.undoSignal++;
          },
          onRedo: () => {
            this.redoSignal++;
          },
        })
      }

      // 画布（layoutWeight 撑满）
      if (this.pages.length > 0) {
        NoteCanvasView({
          viewModel: this.viewModel,
          noteId: this.noteId,
          currentPage: this.pages[this.currentPageIndex],
          undoSignal: this.undoSignal,
          redoSignal: this.redoSignal,
          onUndoRedoChanged: (u: boolean, r: boolean) => {
            hilog.info(0x0001, 'NotePage', 'undoRedoChanged u=%{public}s r=%{public}s',
              u.toString(), r.toString());
            this.canUndo = u;
            this.canRedo = r;
          },
          onRequestPage: (pageId: string) => {
            for (let i: number = 0; i < this.pages.length; i++) {
              if (this.pages[i].pageId === pageId) {
                this.currentPageIndex = i;
                return;
              }
            }
            hilog.error(0x0001, 'NotePage', 'history requested missing page %{public}s', pageId);
          },
          onHistoryBridgeReady: (bridge: EditorHistoryBridge) => {
            this.historyBridge = bridge;
          },
          onApplyPageHistory: async (action: UndoableAction, isUndo: boolean): Promise<boolean> =>
            this.applyPageHistory(action, isUndo),
        })
          .layoutWeight(1)
      } else if (this.pageLoadFailed) {
        Column() {
          Text($r('app.string.note_open_failed'))
            .fontSize(16)
            .fontColor(this.resolveTokens().textSecondary)
            .textAlign(TextAlign.Center)
          Button($r('app.string.retry'))
            .height(36)
            .margin({ top: 12 })
            .onClick(() => {
              this.loadPages();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Text($r('app.string.loading_note'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }

      // 页面管理条（56vp 底部；异步加载完成前不能传入 undefined currentPage）
      if (this.pages.length > 0) {
        PageManagerBar({
          currentPageIndex: this.currentPageIndex,
          pageCount: this.pages.length,
          currentPage: this.pages[this.currentPageIndex],
          busy: this.pageOperationBusy,
          onPrev: () => {
            if (this.currentPageIndex > 0) {
              this.currentPageIndex--;
            }
          },
          onNext: () => {
            if (this.currentPageIndex < this.pages.length - 1) {
              this.currentPageIndex++;
            }
          },
          onAdd: () => {
            this.runPageOperation(async (): Promise<void> => this.addPage());
          },
          onDelete: () => {
            this.runPageOperation(async (): Promise<void> => this.deleteCurrentPage());
          },
          onMovePrevious: () => {
            this.runPageOperation(async (): Promise<void> => this.moveCurrentPage(-1));
          },
          onMoveNext: () => {
            this.runPageOperation(async (): Promise<void> => this.moveCurrentPage(1));
          },
          onApplyPage: (page: PageInfo) => {
            this.runPageOperation(async (): Promise<void> => this.applyPageSettings(page));
          },
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }

  // T-037：应用页面设置（模板/尺寸/方向 → updatePage 持久化 + 更新当前页）
  private async applyPageSettings(page: PageInfo): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    const before: PageInfo = this.clonePage(this.pages[this.currentPageIndex]);
    if (this.samePageSettings(before, page)) {
      return;
    }
    await this.pageRepo.updatePage(page);
    const updated: PageInfo[] = this.pages.slice();
    updated[this.currentPageIndex] = page;
    this.pages = updated;
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction({
        type: UndoableActionType.PAGE_SETTINGS,
        noteId: this.noteId,
        pageId: page.pageId,
        pageBefore: before,
        pageAfter: this.clonePage(page),
      });
    }
  }

  private async runPageOperation(operation: () => Promise<void>): Promise<void> {
    if (this.pageOperationBusy) {
      return;
    }
    this.pageOperationBusy = true;
    try {
      await operation();
    } catch (e) {
      hilog.error(0x0001, 'NotePage', 'page operation failed: %{public}s', JSON.stringify(e));
      try {
        promptAction.showToast({ message: $r('app.string.page_operation_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Page operation toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.pageOperationBusy = false;
    }
  }

  private async addPage(): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    const selectedBefore: string = this.pages[this.currentPageIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const page: PageInfo = {
      pageId: this.generateId(),
      pageIndex: this.pages.length,
      size: 1,
      template: 0,
      orientation: 0,
      widthMm: 210.0,
      heightMm: 297.0,
    };
    const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, page);
    const updated: PageInfo[] = this.pages.slice();
    updated.push(assignedPage);
    this.pages = updated;
    this.currentPageIndex = this.pages.length - 1;
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction({
        type: UndoableActionType.ADD_PAGE,
        noteId: this.noteId,
        pageId: assignedPage.pageId,
        pageAfter: this.clonePage(assignedPage),
        pageOrderBefore: orderBefore,
        pageOrderAfter: this.pageIds(this.pages),
        pageStrokes: [],
        pageTextBlocks: [],
        pageShapes: [],
        pageElementOrder: [],
        selectedPageIdBefore: selectedBefore,
        selectedPageIdAfter: assignedPage.pageId,
      });
    }
  }

  private async deleteCurrentPage(): Promise<void> {
    if (this.pageRepo === null || this.pages.length <= 1 || this.historyBridge === null) {
      return;
    }
    const deletedPage: PageInfo = this.clonePage(this.pages[this.currentPageIndex]);
    const pageId: string = deletedPage.pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const selectedBefore: string = pageId;
    const snapshot: PageContentSnapshot = this.historyBridge.captureCurrentPage();
    this.historyBridge.preparePageRemoval(pageId);
    try {
      await this.pageRepo.deletePage(this.noteId, pageId);
    } catch (e) {
      this.historyBridge.cancelPageRemoval(pageId);
      throw new Error(`deleteCurrentPage failed: ${JSON.stringify(e)}`);
    }
    const updated: PageInfo[] = [];
    for (const p of this.pages) {
      if (p.pageId !== pageId) {
        updated.push(p);
      }
    }
    this.pages = updated;
    if (this.currentPageIndex >= this.pages.length) {
      this.currentPageIndex = this.pages.length - 1;
    }
    const selectedAfter: string = this.pages[this.currentPageIndex].pageId;
    this.historyBridge.pushPageAction({
      type: UndoableActionType.DELETE_PAGE,
      noteId: this.noteId,
      pageId: pageId,
      pageBefore: deletedPage,
      pageOrderBefore: orderBefore,
      pageOrderAfter: this.pageIds(this.pages),
      pageStrokes: snapshot.strokes,
      pageTextBlocks: snapshot.textBlocks,
      pageShapes: snapshot.shapes,
      pageElementOrder: snapshot.elementOrder,
      selectedPageIdBefore: selectedBefore,
      selectedPageIdAfter: selectedAfter,
    });
  }

  private async moveCurrentPage(delta: number): Promise<void> {
    if (this.pageRepo === null || this.historyBridge === null) {
      return;
    }
    const targetIndex: number = this.currentPageIndex + delta;
    if (targetIndex < 0 || targetIndex >= this.pages.length) {
      return;
    }
    const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const orderAfter: string[] = orderBefore.slice();
    const displaced: string = orderAfter[targetIndex];
    orderAfter[targetIndex] = selectedPageId;
    orderAfter[this.currentPageIndex] = displaced;
    await this.pageRepo.reorderPages(this.noteId, orderAfter);
    this.pages = this.orderPages(this.pages, orderAfter);
    this.currentPageIndex = targetIndex;
    this.historyBridge.pushPageAction({
      type: UndoableActionType.REORDER_PAGES,
      noteId: this.noteId,
      pageId: selectedPageId,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
    });
  }

  private async applyPageHistory(action: UndoableAction, isUndo: boolean): Promise<boolean> {
    if (this.pageRepo === null || action.noteId !== this.noteId) {
      if (action.noteId !== this.noteId) {
        hilog.error(0x0001, 'NotePage',
          'page history note mismatch, actionNote=%{public}s currentNote=%{public}s', action.noteId, this.noteId);
      }
      return false;
    }
    if (!this.validatePageActionState(action, isUndo)) {
      hilog.error(0x0001, 'NotePage',
        'page history source state mismatch, type=%{public}d undo=%{public}s', action.type, isUndo.toString());
      return false;
    }
    try {
      if (action.type === UndoableActionType.ADD_PAGE) {
        return await this.applyAddPageHistory(action, isUndo);
      }
      if (action.type === UndoableActionType.DELETE_PAGE) {
        return await this.applyDeletePageHistory(action, isUndo);
      }
      if (action.type === UndoableActionType.PAGE_SETTINGS) {
        const page: PageInfo = isUndo ? action.pageBefore : action.pageAfter;
        await this.pageRepo.updatePage(page);
        this.replacePage(page);
        this.selectPageById(page.pageId);
        return true;
      }
      if (action.type === UndoableActionType.REORDER_PAGES) {
        const order: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
        await this.pageRepo.reorderPages(this.noteId, order);
        this.pages = this.orderPages(this.pages, order);
        this.selectPageById(action.pageId);
        return true;
      }
    } catch (e) {
      if (this.historyBridge !== null) {
        this.historyBridge.cancelPageRemoval(action.pageId);
      }
      hilog.error(0x0001, 'NotePage', 'applyPageHistory failed: %{public}s', JSON.stringify(e));
    }
    return false;
  }

  private validatePageActionState(action: UndoableAction, isUndo: boolean): boolean {
    const currentOrder: string[] = this.pageIds(this.pages);
    if (!this.hasUniqueStrings(currentOrder)) {
      return false;
    }
    if (action.type === UndoableActionType.ADD_PAGE) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      const sourceSelection: string = isUndo ? action.selectedPageIdAfter : action.selectedPageIdBefore;
      const targetSelection: string = isUndo ? action.selectedPageIdBefore : action.selectedPageIdAfter;
      return action.pageId === action.pageAfter.pageId && this.sameStringArray(currentOrder, sourceOrder) &&
        this.isSinglePageTransition(sourceOrder, targetOrder, action.pageId, isUndo) &&
        this.countString(sourceOrder, sourceSelection) === 1 && this.countString(targetOrder, targetSelection) === 1;
    }
    if (action.type === UndoableActionType.DELETE_PAGE) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      const sourceSelection: string = isUndo ? action.selectedPageIdAfter : action.selectedPageIdBefore;
      const targetSelection: string = isUndo ? action.selectedPageIdBefore : action.selectedPageIdAfter;
      return action.pageId === action.pageBefore.pageId && this.sameStringArray(currentOrder, sourceOrder) &&
        this.isSinglePageTransition(sourceOrder, targetOrder, action.pageId, !isUndo) &&
        this.countString(sourceOrder, sourceSelection) === 1 && this.countString(targetOrder, targetSelection) === 1;
    }
    if (action.type === UndoableActionType.REORDER_PAGES) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      return this.sameStringArray(currentOrder, sourceOrder) && this.sameStringMembers(sourceOrder, targetOrder) &&
        this.countString(targetOrder, action.pageId) === 1;
    }
    if (action.type === UndoableActionType.PAGE_SETTINGS) {
      const sourcePage: PageInfo = isUndo ? action.pageAfter : action.pageBefore;
      const targetPage: PageInfo = isUndo ? action.pageBefore : action.pageAfter;
      if (sourcePage.pageId !== action.pageId || targetPage.pageId !== action.pageId) {
        return false;
      }
      let matched: number = 0;
      for (const page of this.pages) {
        if (page.pageId === action.pageId && this.samePageSettings(page, sourcePage)) {
          matched++;
        }
      }
      return matched === 1;
    }
    return false;
  }

  private isSinglePageTransition(source: string[], target: string[], pageId: string,
    sourceContainsPage: boolean): boolean {
    if (!this.hasUniqueStrings(source) || !this.hasUniqueStrings(target)) {
      return false;
    }
    if (sourceContainsPage) {
      if (source.length !== target.length + 1 || this.countString(source, pageId) !== 1 ||
        this.countString(target, pageId) !== 0) {
        return false;
      }
    } else if (target.length !== source.length + 1 || this.countString(source, pageId) !== 0 ||
      this.countString(target, pageId) !== 1) {
      return false;
    }
    const withoutPage: string[] = [];
    const longer: string[] = sourceContainsPage ? source : target;
    for (const id of longer) {
      if (id !== pageId) {
        withoutPage.push(id);
      }
    }
    return this.sameStringArray(withoutPage, sourceContainsPage ? target : source);
  }

  private sameStringMembers(a: string[], b: string[]): boolean {
    if (a.length !== b.length || !this.hasUniqueStrings(a) || !this.hasUniqueStrings(b)) {
      return false;
    }
    for (const value of a) {
      if (this.countString(b, value) !== 1) {
        return false;
      }
    }
    return true;
  }

  private sameStringArray(a: string[], b: string[]): boolean {
    if (a.length !== b.length) {
      return false;
    }
    for (let i: number = 0; i < a.length; i++) {
      if (a[i] !== b[i]) {
        return false;
      }
    }
    return true;
  }

  private hasUniqueStrings(values: string[]): boolean {
    for (let i: number = 0; i < values.length; i++) {
      for (let j: number = i + 1; j < values.length; j++) {
        if (values[i] === values[j]) {
          return false;
        }
      }
    }
    return true;
  }

  private countString(values: string[], value: string): number {
    let count: number = 0;
    for (const candidate of values) {
      if (candidate === value) {
        count++;
      }
    }
    return count;
  }

  private async applyAddPageHistory(action: AddPageAction, isUndo: boolean): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    if (isUndo) {
      if (this.pages.length <= 1) {
        return false;
      }
      if (this.historyBridge !== null && this.pages[this.currentPageIndex].pageId === action.pageId) {
        this.historyBridge.preparePageRemoval(action.pageId);
      }
      await this.pageRepo.deletePage(this.noteId, action.pageId);
      this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
        action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    try {
      await this.pageRepo.addPage(this.noteId, action.pageAfter);
      await this.persistence.saveElements(this.noteId, action.pageId,
        action.pageStrokes, action.pageTextBlocks, action.pageElementOrder, action.pageShapes);
      await this.pageRepo.reorderPages(this.noteId, action.pageOrderAfter);
    } catch (e) {
      await this.compensateFailedPageRestore(action.pageId);
      throw new Error(`redo ADD_PAGE failed: ${JSON.stringify(e)}`);
    }
    const restored: PageInfo[] = this.pages.concat([this.clonePage(action.pageAfter)]);
    this.pages = this.orderPages(restored, action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  private async applyDeletePageHistory(action: DeletePageAction, isUndo: boolean): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    if (isUndo) {
      try {
        await this.pageRepo.addPage(this.noteId, action.pageBefore);
        await this.persistence.saveElements(this.noteId, action.pageId,
          action.pageStrokes, action.pageTextBlocks, action.pageElementOrder, action.pageShapes);
        await this.pageRepo.reorderPages(this.noteId, action.pageOrderBefore);
      } catch (e) {
        await this.compensateFailedPageRestore(action.pageId);
        throw new Error(`undo DELETE_PAGE failed: ${JSON.stringify(e)}`);
      }
      const restored: PageInfo[] = this.pages.concat([this.clonePage(action.pageBefore)]);
      this.pages = this.orderPages(restored, action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    if (this.pages.length <= 1) {
      return false;
    }
    if (this.historyBridge !== null && this.pages[this.currentPageIndex].pageId === action.pageId) {
      this.historyBridge.preparePageRemoval(action.pageId);
    }
    await this.pageRepo.deletePage(this.noteId, action.pageId);
    this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
      action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  private replacePage(page: PageInfo): void {
    const updated: PageInfo[] = this.pages.slice();
    for (let i: number = 0; i < updated.length; i++) {
      if (updated[i].pageId === page.pageId) {
        updated[i] = this.clonePage(page);
        this.pages = updated;
        return;
      }
    }
  }

  private async compensateFailedPageRestore(pageId: string): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    try {
      await this.pageRepo.deletePage(this.noteId, pageId);
    } catch (e) {
      hilog.error(0x0001, 'NotePage', 'page restore compensation failed: %{public}s', JSON.stringify(e));
    }
  }

  private orderPages(source: PageInfo[], order: string[]): PageInfo[] {
    const result: PageInfo[] = [];
    for (let index: number = 0; index < order.length; index++) {
      for (const page of source) {
        if (page.pageId === order[index]) {
          const ordered: PageInfo = this.clonePage(page);
          ordered.pageIndex = index;
          result.push(ordered);
          break;
        }
      }
    }
    return result;
  }

  private selectPageById(pageId: string): void {
    for (let i: number = 0; i < this.pages.length; i++) {
      if (this.pages[i].pageId === pageId) {
        this.currentPageIndex = i;
        return;
      }
    }
  }

  private pageIds(pages: PageInfo[]): string[] {
    const ids: string[] = [];
    for (const page of pages) {
      ids.push(page.pageId);
    }
    return ids;
  }

  private clonePage(page: PageInfo): PageInfo {
    return {
      pageId: page.pageId,
      pageIndex: page.pageIndex,
      size: page.size,
      template: page.template,
      orientation: page.orientation,
      widthMm: page.widthMm,
      heightMm: page.heightMm,
    };
  }

  private samePageSettings(a: PageInfo, b: PageInfo): boolean {
    return a.size === b.size && a.template === b.template && a.orientation === b.orientation &&
      a.widthMm === b.widthMm && a.heightMm === b.heightMm;
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
