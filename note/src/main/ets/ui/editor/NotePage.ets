// T-025 笔记编辑器页面（EditorToolbar + NoteCanvasView + PageManagerBar 集成）
// T-036：标题行内编辑 + 持久化
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { NoteMeta, PageInfo } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
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
  @State noteTitle: string = '';          // T-036：标题
  @State editingTitle: boolean = false;   // T-036：标题编辑态
  @State titleDraft: string = '';
  private noteRepo: NoteRepositoryImpl | null = null;
  private pageRepo: PageRepositoryImpl | null = null;
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

  private async loadPages(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.pageRepo = new PageRepositoryImpl(db);
      // T-036：加载标题
      this.noteRepo = new NoteRepositoryImpl(db);
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      this.noteTitle = note !== null ? note.title : '';
      const loaded: PageInfo[] = await this.pageRepo.getPages(this.noteId);
      if (loaded.length === 0) {
        // 创建默认首页（A4 / PLAIN）
        const defaultPage: PageInfo = {
          pageId: this.generateId(),
          size: 1,
          template: 0,
          orientation: 0,
          widthMm: 210.0,
          heightMm: 297.0,
        };
        await this.pageRepo.addPage(this.noteId, defaultPage);
        this.pages = [defaultPage];
      } else {
        this.pages = loaded;
      }
      this.currentPageIndex = 0;
    } catch (e) {
      console.error(`NotePage loadPages failed: ${JSON.stringify(e)}`);
    }
  }

  // T-036：标题编辑保存（updateNote 持久化）
  private async saveTitle(): Promise<void> {
    this.editingTitle = false;
    const draft: string = this.titleDraft.trim();
    if (draft.length === 0) {
      return;  // 空标题不保存（显示占位）
    }
    this.noteTitle = draft;
    if (this.noteRepo !== null) {
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      if (note !== null) {
        note.title = draft;
        await this.noteRepo.updateNote(note);
      }
    }
  }

  build() {
    Column() {
      // 顶部导航行（48vp）
      Row() {
        Button('← Back')
          .height(36)
          .fontSize(14)
          .onClick(async () => {
            // T-040 修复：先等待标题保存完成再返回，避免与 LibraryPage onPageShow 刷新竞态
            if (this.editingTitle) {
              await this.saveTitle();
            }
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
          Text(this.noteTitle.length > 0 ? this.noteTitle : '未命名笔记')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary)
            .margin({ left: 12 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .onClick(() => {
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
        })
          .layoutWeight(1)
      } else {
        Text('Loading note...')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }

      // 页面管理条（56vp 底部；T-037 页面设置）
      PageManagerBar({
        currentPageIndex: this.currentPageIndex,
        pageCount: this.pages.length,
        currentPage: this.pages[this.currentPageIndex],
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
          this.addPage();
        },
        onDelete: () => {
          this.deleteCurrentPage();
        },
        onApplyPage: (page: PageInfo) => {
          this.applyPageSettings(page);
        },
      })
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
    await this.pageRepo.updatePage(page);
    const updated: PageInfo[] = this.pages.slice();
    updated[this.currentPageIndex] = page;
    this.pages = updated;
  }

  private async addPage(): Promise<void> {
    if (this.pageRepo === null) {
      return;
    }
    const page: PageInfo = {
      pageId: this.generateId(),
      size: 1,
      template: 0,
      orientation: 0,
      widthMm: 210.0,
      heightMm: 297.0,
    };
    await this.pageRepo.addPage(this.noteId, page);
    const updated: PageInfo[] = this.pages.slice();
    updated.push(page);
    this.pages = updated;
    this.currentPageIndex = this.pages.length - 1;
  }

  private async deleteCurrentPage(): Promise<void> {
    if (this.pageRepo === null || this.pages.length <= 1) {
      return;
    }
    const pageId: string = this.pages[this.currentPageIndex].pageId;
    await this.pageRepo.deletePage(this.noteId, pageId);
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
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
