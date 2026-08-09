// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { FolderRepositoryImpl, NoteFolder, isFolderInSubtree } from '../../data/FolderRepositoryImpl';
import { FirstPageThumbnailState, StrokePersistence } from '../../data/StrokePersistence';
import { AsyncMutex, MutexRelease } from '../../data/AsyncMutex';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import {
  prioritizeThumbnailNoteIds, thumbnailCacheKey,
} from '../../rendering/ThumbnailRenderPolicy';
import { LibraryViewModel, NoteSortMode } from './LibraryViewModel';
import {
  ThemeStore, THEME_MODE_KEY, THEME_PREFERENCE_KEY, THEME_PREFERENCES_NAME, THEME_SYSTEM_DARK_KEY,
} from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

interface FolderListItem {
  folder: NoteFolder;
  depth: number;
}

@Entry
@Component
struct LibraryPage {
  // === 响应式状态 ===
  @State columns: number = 3;
  @State sidebarWidth: number = 0;
  @State showSidebar: boolean = false;
  // === 数据状态 ===
  @State viewModel: LibraryViewModel | null = null;
  @State initError: ResourceStr = '';
  @State hasInitError: boolean = false;
  @State searchText: string = '';
  @State createBusy: boolean = false;
  @State deleteBusy: boolean = false;
  @State folderBusy: boolean = false;
  // T-035：缩略图——@State 数组驱动 UI 刷新（Builder 中 Map 方法依赖收集不可靠）
  @State thumbIds: string[] = [];
  private thumbMap: Map<string, PixelMap> = new Map<string, PixelMap>();
  private thumbRevisions: Map<string, string> = new Map<string, string>();
  private thumbnailGeneration: number = 0;
  private searchTimer: number = -1;
  private thumbnailRequestTimer: number = -1;
  private thumbnailPriorityIds: string[] = [];
  private pageActive: boolean = true;
  private readonly THUMBNAIL_CONCURRENCY: number = 3;
  private readonly MAX_THUMBNAILS: number = 64;
  private thumbnailRefreshMutex: AsyncMutex = new AsyncMutex();
  private noteRepo: NoteRepositoryImpl | null = null;
  // T-039：文件夹
  private folderRepo: FolderRepositoryImpl | null = null;
  @State folders: NoteFolder[] = [];
  @State currentFolderId: string | null = null;
  @State folderDialogTitle: ResourceStr = $r('app.string.new_folder');
  @State folderDialogInitialText: string = '';
  @State folderDialogMode: number = 0;  // 0=新建 1=重命名
  @State folderDialogTargetId: string = '';
  @State folderDialogParentId: string | null = null;
  private folderDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: this.folderDialogTitle,
      initialText: this.folderDialogInitialText,
      onConfirm: (name: string) => {
        this.onFolderDialogConfirm(name).catch((e: Error) => {
          console.error(`folder dialog confirm failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });
  private persistence: StrokePersistence = new StrokePersistence();
  private thumbRenderer: ThumbnailRenderer = new ThumbnailRenderer();
  private db: DatabaseManager = DatabaseManager.getInstance();
  private readonly PREF_SORT_KEY: string = 'library_sort_mode';
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) @Watch('onSystemDarkChange') systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter（编译产物无定义，运行时为 undefined）
  // 必须用普通方法形式，否则 build 中访问 this.resolveTokens().xxx 会抛 TypeError
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.pageActive = true;
    this.initData();
  }

  aboutToDisappear(): void {
    this.pageActive = false;
    if (this.searchTimer >= 0) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
    if (this.thumbnailRequestTimer >= 0) {
      clearTimeout(this.thumbnailRequestTimer);
      this.thumbnailRequestTimer = -1;
    }
    this.thumbnailGeneration++;
    this.releaseThumbnails(this.thumbMap);
    this.thumbMap = new Map<string, PixelMap>();
    this.thumbRevisions = new Map<string, string>();
    this.thumbIds = [];
    this.thumbnailPriorityIds = [];
    const renderer: ThumbnailRenderer = this.thumbRenderer;
    this.thumbRenderer = new ThumbnailRenderer();
    renderer.dispose().catch((e: Error) => {
      console.warn(`ThumbnailRenderer dispose failed: ${JSON.stringify(e)}`);
    });
  }

  // T-040 修复：从编辑器返回时刷新列表（标题/更新时间/缩略图）
  // 注意：viewModel 是 @State 持有 @Observed 对象，内部属性变化不触发 UI 刷新，必须重新赋值
  onPageShow(): void {
    this.pageActive = true;
    if (this.viewModel !== null) {
      const vm: LibraryViewModel = this.viewModel;
      const context = getContext(this) as common.UIAbilityContext;
      this.thumbRenderer.initialize(context).then(() => vm.loadNotes()).then(() => {
        this.initError = '';
        this.hasInitError = false;
        this.viewModel = vm;
        return this.refreshThumbnails();
      }).catch((e: Error) => {
        this.initError = $r('app.string.load_notes_failed');
        this.hasInitError = true;
        promptAction.showToast({ message: $r('app.string.load_notes_failed') });
        console.error(`LibraryPage onPageShow reload failed: ${JSON.stringify(e)}`);
      });
    }
  }

  private navigateToSettings(): void {
    router.pushUrl({ url: 'ui/settings/SettingsPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  // 缩略图只由页面持有；generation 丢弃迟到结果，worker 数限制峰值内存。
  private async refreshThumbnails(): Promise<void> {
    if (this.viewModel === null) {
      return;
    }
    const generation: number = ++this.thumbnailGeneration;
    const release: MutexRelease = await this.thumbnailRefreshMutex.lock();
    try {
      await this.refreshThumbnailGeneration(generation);
    } finally {
      release();
    }
  }

  private async refreshThumbnailGeneration(generation: number): Promise<void> {
    if (generation !== this.thumbnailGeneration || !this.pageActive || this.viewModel === null) {
      return;
    }
    const allNoteIds: string[] = this.viewModel.getFilteredNotes().map((note: NoteMeta) => note.id);
    const noteIds: string[] = prioritizeThumbnailNoteIds(
      allNoteIds, this.thumbnailPriorityIds, this.MAX_THUMBNAILS);
    const theme: ThemeTokens = this.resolveTokens();
    const oldMap: Map<string, PixelMap> = this.thumbMap;
    const oldRevisions: Map<string, string> = this.thumbRevisions;
    const newMap: Map<string, PixelMap> = new Map<string, PixelMap>();
    const newRevisions: Map<string, string> = new Map<string, string>();
    const createdMaps: PixelMap[] = [];
    let nextIndex: number = 0;
    const worker = async (): Promise<void> => {
      while (true) {
        const index: number = nextIndex++;
        if (index >= noteIds.length) {
          return;
        }
        const noteId: string = noteIds[index];
        try {
          const pageState: FirstPageThumbnailState | null =
            await this.persistence.getFirstPageThumbnailState(noteId);
          const contentRevision: string = pageState === null ? 'missing' : pageState.revision;
          const revision: string = thumbnailCacheKey(contentRevision,
            theme.paperBackground, theme.paperLineColor);
          if (generation !== this.thumbnailGeneration || !this.pageActive) {
            return;
          }
          const oldRevision: string | undefined = oldRevisions.get(noteId);
          const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
          if (oldRevision === revision) {
            newRevisions.set(noteId, revision);
            if (oldPixelMap !== undefined) {
              newMap.set(noteId, oldPixelMap);
            }
            continue;
          }
          const pixelMap: PixelMap | null = pageState === null ? null :
            await this.thumbRenderer.renderThumbnail(noteId, this.persistence, pageState.page, theme);
          if (generation !== this.thumbnailGeneration || !this.pageActive) {
            if (pixelMap !== null) {
              pixelMap.release();
            }
            return;
          }
          if (pixelMap !== null) {
            createdMaps.push(pixelMap);
          }
          newRevisions.set(noteId, revision);
          if (pixelMap !== null) {
            newMap.set(noteId, pixelMap);
          }
        } catch (e) {
          console.error(`LibraryPage thumbnail failed note=${noteId}: ${JSON.stringify(e)}`);
          const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
          const oldRevision: string | undefined = oldRevisions.get(noteId);
          if (generation === this.thumbnailGeneration && this.pageActive &&
            oldPixelMap !== undefined && oldRevision !== undefined) {
            newMap.set(noteId, oldPixelMap);
            newRevisions.set(noteId, oldRevision);
          }
        }
      }
    };
    const workers: Promise<void>[] = [];
    const workerCount: number = Math.min(this.THUMBNAIL_CONCURRENCY, noteIds.length);
    for (let i: number = 0; i < workerCount; i++) {
      workers.push(worker());
    }
    await Promise.all(workers);
    if (generation !== this.thumbnailGeneration || !this.pageActive) {
      for (const pixelMap of createdMaps) {
        pixelMap.release();
      }
      return;
    }
    this.releaseReplacedThumbnails(oldMap, newMap);
    this.thumbMap = newMap;
    this.thumbRevisions = newRevisions;
    this.thumbIds = Array.from(newMap.keys());
    console.info(`LibraryPage: thumbs refreshed size=${newMap.size}`);
  }

  private releaseReplacedThumbnails(oldMap: Map<string, PixelMap>, newMap: Map<string, PixelMap>): void {
    for (const entry of oldMap.entries()) {
      if (newMap.get(entry[0]) !== entry[1]) {
        entry[1].release();
      }
    }
  }

  private releaseThumbnails(thumbnails: Map<string, PixelMap>): void {
    for (const pixelMap of thumbnails.values()) {
      pixelMap.release();
    }
  }

  private requestVisibleThumbnail(noteId: string): void {
    if (!this.pageActive) {
      return;
    }
    const nextPriority: string[] = [noteId];
    for (const existingId of this.thumbnailPriorityIds) {
      if (existingId !== noteId && nextPriority.length < this.MAX_THUMBNAILS) {
        nextPriority.push(existingId);
      }
    }
    this.thumbnailPriorityIds = nextPriority;
    if (this.thumbMap.has(noteId)) {
      return;
    }
    if (this.thumbnailRequestTimer >= 0) {
      return;
    }
    this.thumbnailRequestTimer = setTimeout(() => {
      this.thumbnailRequestTimer = -1;
      this.refreshThumbnails().catch((e: Error) => {
        console.error(`visible thumbnail refresh failed: ${JSON.stringify(e)}`);
      });
    }, 50);
  }

  // T-039：文件夹操作
  private showCreateFolderDialog(parentId: string | null = null): void {
    if (this.folderBusy) {
      return;
    }
    this.folderDialogMode = 0;
    this.folderDialogTitle = $r('app.string.new_folder');
    this.folderDialogInitialText = '';
    this.folderDialogTargetId = '';
    this.folderDialogParentId = parentId;
    this.folderDialog.open();
  }

  private showRenameFolderDialog(folder: NoteFolder): void {
    if (this.folderBusy) {
      return;
    }
    this.folderDialogMode = 1;
    this.folderDialogTitle = $r('app.string.rename');
    this.folderDialogInitialText = folder.name;
    this.folderDialogTargetId = folder.id;
    this.folderDialog.open();
  }

  private async onFolderDialogConfirm(name: string): Promise<void> {
    const trimmed: string = name.trim();
    if (trimmed.length === 0 || this.folderRepo === null || this.folderBusy) {
      return;
    }
    this.folderBusy = true;
    try {
      if (this.folderDialogMode === 0) {
        await this.folderRepo.createFolder(trimmed, this.folderDialogParentId);
      } else if (this.folderDialogMode === 1) {
        await this.folderRepo.renameFolder(this.folderDialogTargetId, trimmed);
      }
      this.folders = await this.folderRepo.getAllFolders();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.folder_operation_failed') });
      console.error(`folder operation failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
  }

  // 删除文件夹：内部笔记回根目录（不删笔记）
  private async deleteFolder(folderId: string): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    this.folderBusy = true;
    try {
      const vm: LibraryViewModel = this.viewModel;
      const selectedFolderId: string | null = this.currentFolderId;
      const removesCurrent: boolean = selectedFolderId !== null &&
        isFolderInSubtree(this.folders, folderId, selectedFolderId);
      await this.folderRepo.deleteFolder(folderId);
      this.folders = await this.folderRepo.getAllFolders();
      if (removesCurrent) {
        this.currentFolderId = null;
        await vm.setFolder(null);
      }
      this.viewModel = vm;
      await this.refreshThumbnails();
      this.persistence.backfillSearchIndex().then(() => {
        const activeViewModel: LibraryViewModel | null = this.viewModel;
        if (activeViewModel !== null && activeViewModel.searchQuery.trim().length > 0) {
          activeViewModel.loadNotes().then(() => {
            if (this.viewModel === activeViewModel) {
              this.viewModel = activeViewModel;
            }
          }).catch((e: Error) => {
            console.error(`refresh search after backfill failed: ${JSON.stringify(e)}`);
          });
        }
      }).catch((e: Error) => {
        console.error(`search index backfill failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.delete_folder_failed') });
      console.error(`delete folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
  }

  private async moveFolder(folderId: string, parentId: string | null): Promise<void> {
    if (this.folderRepo === null || this.folderBusy) {
      return;
    }
    this.folderBusy = true;
    try {
      await this.folderRepo.moveFolder(folderId, parentId);
      this.folders = await this.folderRepo.getAllFolders();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.move_folder_failed') });
      console.error(`move folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
  }

  // 移动笔记到文件夹（null=根目录）
  private async moveNote(noteId: string, folderId: string | null): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    this.folderBusy = true;
    try {
      const vm: LibraryViewModel = this.viewModel;
      await this.folderRepo.moveNoteToFolder(noteId, folderId);
      await vm.loadNotes();
      this.viewModel = vm;
      await this.refreshThumbnails();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.move_note_failed') });
      console.error(`move note failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
  }

  // 切换浏览文件夹
  private async selectFolder(folderId: string | null): Promise<void> {
    if (this.viewModel === null || this.folderBusy) {
      return;
    }
    this.folderBusy = true;
    this.currentFolderId = folderId;
    try {
      const vm: LibraryViewModel = this.viewModel;
      await vm.setFolder(folderId);
      this.initError = '';
      this.hasInitError = false;
      this.viewModel = vm;
      await this.refreshThumbnails();
    } catch (e) {
      this.currentFolderId = this.viewModel.currentFolderId;
      promptAction.showToast({ message: $r('app.string.load_notes_failed') });
      console.error(`select folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
  }

  // T-035：排序切换 + Preferences 持久化
  private setSortMode(mode: NoteSortMode): void {
    if (this.viewModel === null) {
      return;
    }
    this.viewModel.setSortMode(mode);
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`sort thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        pref.putSync(this.PREF_SORT_KEY, mode);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save sort pref flush failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save sort pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`setSortMode failed: ${JSON.stringify(e)}`);
    }
  }

  private async initData(): Promise<void> {
    this.initError = '';
    this.hasInitError = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pref: preferences.Preferences =
        await preferences.getPreferences(context, THEME_PREFERENCES_NAME);
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
      await this.thumbRenderer.initialize(context);
      this.noteRepo = new NoteRepositoryImpl(this.db);
      this.folderRepo = new FolderRepositoryImpl(this.db);
      const vm: LibraryViewModel = new LibraryViewModel(this.noteRepo);
      this.viewModel = vm;
      try {
        this.folders = await this.folderRepo.getAllFolders();
      } catch (folderError) {
        console.error(`LibraryPage folder load failed: ${JSON.stringify(folderError)}`);
        promptAction.showToast({ message: $r('app.string.load_folders_failed') });
      }
      // 恢复排序偏好
      const saved: number = pref.getSync(this.PREF_SORT_KEY, 0) as number;
      vm.sortMode = saved as NoteSortMode;
      await vm.loadNotes();
      this.viewModel = vm;
      await this.refreshThumbnails();
    } catch (e) {
      this.initError = $r('app.string.library_load_failed');
      this.hasInitError = true;
      promptAction.showToast({ message: $r('app.string.library_load_retry') });
      console.error(`LibraryPage init failed: ${JSON.stringify(e)}`);
    }
  }

  private onSystemDarkChange(): void {
    if (this.pageActive) {
      this.refreshThumbnails().catch((e: Error) => {
        console.error(`system theme thumbnail refresh failed: ${JSON.stringify(e)}`);
      });
    }
  }

  // T-038：主题切换 + 持久化
  private setThemeMode(mode: ThemeMode): void {
    ThemeStore.setMode(mode);
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`theme thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        pref.putSync(THEME_PREFERENCE_KEY, mode);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save theme pref failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save theme pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`setThemeMode failed: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Row() {
      // 侧栏（≥840vp 显示；T-039 文件夹列表）
      if (this.showSidebar) {
        Column() {
          Text($r('app.string.app_name'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.resolveTokens().textPrimary)
            .margin({ top: 16, bottom: 12 })
          // 全部笔记
          Text($r('app.string.all_notes'))
            .fontSize(15)
            .fontColor(this.currentFolderId === null ? this.resolveTokens().accent : this.resolveTokens().textPrimary)
            .fontWeight(this.currentFolderId === null ? FontWeight.Medium : FontWeight.Normal)
            .margin({ top: 4, bottom: 4 })
            .onClick(() => {
              this.selectFolder(null);
            })
          // 文件夹列表
          ForEach(this.folderListItems(), (item: FolderListItem) => {
            Text(item.folder.name)
              .fontSize(15)
              .fontColor(this.currentFolderId === item.folder.id ? this.resolveTokens().accent :
                this.resolveTokens().textPrimary)
              .fontWeight(this.currentFolderId === item.folder.id ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: item.depth * 16 })
              .margin({ top: 4, bottom: 4 })
              .onClick(() => {
                this.selectFolder(item.folder.id);
              })
              .bindMenu(this.buildSingleFolderMenu(item.folder))
          }, (item: FolderListItem) => item.folder.id)
          Blank()
          // 新建文件夹
          Button($r('app.string.new_folder'))
            .height(36)
            .fontSize(13)
            .margin({ bottom: 16 })
            .onClick(() => {
              this.showCreateFolderDialog();
            })
        }
        .width(this.sidebarWidth)
        .height('100%')
        .backgroundColor(this.resolveTokens().surface)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16, right: 8 })
      }

      // 主内容
      Column() {
        // 原版在窄屏使用可开合侧栏；Harmony compact 用原生菜单提供同等可达性。
        if (!this.showSidebar) {
          Row() {
            Button(this.currentFolderName())
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .fontColor(this.resolveTokens().accent)
              .enabled(!this.folderBusy)
              .bindMenu(this.buildFolderSelectionMenu())
            Button('...')
              .width(48)
              .height(40)
              .fontSize(14)
              .margin({ left: 8 })
              .enabled(!this.folderBusy)
              .accessibilityText($r('app.string.folder_actions'))
              .bindMenu(this.buildFolderActionMenu())
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
        }
        // 搜索栏（48vp）+ 设置入口 + 排序
        Row() {
          TextInput({ placeholder: $r('app.string.search_notes') })
            .layoutWeight(1)
            .height(40)
            .fontColor(this.resolveTokens().textPrimary)
            .placeholderColor(this.resolveTokens().textSecondary)
            .backgroundColor(this.resolveTokens().surface)
            .onChange((value: string) => {
              this.searchText = value;
              if (this.searchTimer >= 0) {
                clearTimeout(this.searchTimer);
              }
              this.searchTimer = setTimeout(() => {
                this.searchTimer = -1;
                const vm: LibraryViewModel | null = this.viewModel;
                if (vm === null || !this.pageActive) {
                  return;
                }
                vm.setSearchQuery(value).then(() => {
                  if (this.pageActive && this.viewModel === vm) {
                    this.viewModel = vm;
                    return this.refreshThumbnails();
                  }
                  return Promise.resolve();
                }).catch((e: Error) => {
                  console.error(`search notes failed: ${JSON.stringify(e)}`);
                  promptAction.showToast({ message: $r('app.string.search_failed') });
                });
              }, 180);
            })
          if (this.showSidebar) {
            Button($r('app.string.sort'))
              .height(40)
              .fontSize(13)
              .margin({ left: 8 })
              .bindMenu([
                { value: $r('app.string.recently_modified'), action: () => { this.setSortMode(NoteSortMode.UPDATED); } },
                { value: $r('app.string.recently_created'), action: () => { this.setSortMode(NoteSortMode.CREATED); } },
                { value: $r('app.string.title'), action: () => { this.setSortMode(NoteSortMode.TITLE); } },
              ])
            Button($r('app.string.theme'))
              .height(40)
              .fontSize(13)
              .margin({ left: 8 })
              .bindMenu([
                { value: $r('app.string.follow_system'), action: () => { this.setThemeMode('system'); } },
                { value: $r('app.string.light_theme'), action: () => { this.setThemeMode('light'); } },
                { value: $r('app.string.dark_theme'), action: () => { this.setThemeMode('dark'); } },
              ])
            Button($r('app.string.settings'))
              .height(40)
              .margin({ left: 8 })
              .onClick(() => {
                this.navigateToSettings();
              })
          } else {
            Button('...')
              .width(48)
              .height(40)
              .fontSize(14)
              .margin({ left: 8 })
              .accessibilityText($r('app.string.library_actions'))
              .bindMenu(this.buildLibraryActionsMenu())
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })

        // 笔记网格
        if (this.hasInitError &&
          (this.viewModel === null || this.viewModel.notes.length === 0)) {
          Column() {
            Text(this.initError)
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
            Button($r('app.string.retry'))
              .height(36)
              .margin({ top: 12 })
              .onClick(() => {
                this.initData();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.viewModel !== null) {
          if (this.viewModel.isLoading && this.viewModel.notes.length === 0) {
            Text($r('app.string.loading'))
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
              .layoutWeight(1)
          } else if (this.viewModel.getFilteredNotes().length === 0) {
            // 空结果提示（T-035）
            Column() {
              Text($r('app.string.no_matching_notes'))
                .fontSize(16)
                .fontColor(this.resolveTokens().textSecondary)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            Grid() {
              ForEach(this.viewModel.getFilteredNotes(), (note: NoteMeta) => {
                GridItem() {
                  this.NoteCard(note)
                }
              }, (note: NoteMeta) => note.id)
            }
            .columnsTemplate('1fr '.repeat(this.columns))
            .columnsGap(16)
            .rowsGap(16)
            .padding(16)
            .layoutWeight(1)
          }
        } else {
          Text($r('app.string.loading'))
            .fontSize(16)
            .fontColor(this.resolveTokens().textSecondary)
            .layoutWeight(1)
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const widthVp: number = newArea.width as number;
      this.applyBreakpoints(widthVp);
    })
    .overlay(this.FabButton(), { align: Alignment.BottomEnd })
  }

  // FAB 新建按钮（64vp 右下角）
  // T-040 修复：Button builder 形式 + Text 全铺满居中（原 Button('+') 文本基线导致“+”视觉偏移）
  @Builder
  FabButton() {
    Button() {
      Text('+')
        .fontSize(28)
        .width('100%')
        .height('100%')
        .textAlign(TextAlign.Center)
    }
    .width(64)
    .height(64)
    .borderRadius(32)
    .margin({ right: 24, bottom: 24 })
    .enabled(!this.createBusy)
    .onClick(() => {
      this.createAndOpen().catch((e: Error) => {
        console.error(`create note action failed: ${JSON.stringify(e)}`);
      });
    })
  }

  @Builder
  NoteCard(note: NoteMeta) {
    Column() {
      // 缩略图（T-035：@State thumbIds 驱动；无缩略图时灰色占位）
      if (this.thumbIds.indexOf(note.id) >= 0) {
        Image(this.thumbMap.get(note.id))
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .backgroundColor(this.resolveTokens().control)
          .borderRadius(8)
      } else {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(this.resolveTokens().control)
          .borderRadius(8)
      }
      Text(note.title)
        .fontSize(14)
        .maxLines(1)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 8 })
      Text(this.formatTime(note.updatedAt))
        .fontSize(12)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 2 })
    }
    .width('100%')
    .height(180)
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.resolveTokens().surface)
    .shadow({ radius: 4, color: this.resolveTokens().shadow, offsetY: 2 })
    .onVisibleAreaChange([0.0, 0.01], (isVisible: boolean) => {
      if (isVisible) {
        this.requestVisibleThumbnail(note.id);
      }
    })
    .onClick(() => {
      router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: note.id } })
        .catch((err: BusinessError) => {
          console.error(`pushUrl failed: ${err.code}`);
        });
    })
    .bindContextMenu(() => {
      this.NoteContextMenu(note)
    }, ResponseType.LongPress)
  }

  private confirmDelete(note: NoteMeta): void {
    if (this.deleteBusy) {
      return;
    }
    // T-033：原生 AlertDialog（getUIContext 新 API，替代弃用的 AlertDialog.show）
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_note'),
      message: $r('app.string.delete_note_message', note.title),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: this.resolveTokens().danger,
        action: () => {
          this.deleteNoteAndRefresh(note.id).catch((e: Error) => {
            console.error(`delete note action failed: ${JSON.stringify(e)}`);
          });
        },
      },
    });
  }

  // 笔记卡片只由长按打开上下文菜单；单击始终只进入编辑器。
  @Builder
  NoteContextMenu(note: NoteMeta) {
    Menu() {
      MenuItem({ content: $r('app.string.delete') })
        .onClick(() => {
          this.confirmDelete(note);
        })
      MenuItem({ content: $r('app.string.move_to_all_notes') })
        .onClick(() => {
          this.moveNote(note.id, null);
        })
      ForEach(this.folders, (folder: NoteFolder) => {
        MenuItem({ content: $r('app.string.move_to_named_folder', folder.name) })
          .onClick(() => {
            this.moveNote(note.id, folder.id);
          })
      }, (folder: NoteFolder) => folder.id)
    }
  }

  private buildFolderSelectionMenu(): MenuElement[] {
    const items: MenuElement[] = [
      { value: $r('app.string.all_notes'), action: () => { this.selectFolder(null); } },
    ];
    for (const item of this.folderListItems()) {
      items.push({
        value: this.folderIndent(item.depth) + item.folder.name,
        action: () => { this.selectFolder(item.folder.id); },
      });
    }
    return items;
  }

  private buildFolderActionMenu(): MenuElement[] {
    const items: MenuElement[] = [
      { value: $r('app.string.create_folder'), action: () => { this.showCreateFolderDialog(); } },
    ];
    const folder: NoteFolder | null = this.currentFolder();
    if (folder !== null) {
      items.push({ value: $r('app.string.create_subfolder'), action: () => { this.showCreateFolderDialog(folder.id); } });
      items.push({ value: $r('app.string.rename'), action: () => { this.showRenameFolderDialog(folder); } });
      this.appendMoveFolderItems(items, folder);
      items.push({ value: $r('app.string.delete_folder'), action: () => { this.confirmDeleteFolder(folder); } });
    }
    return items;
  }

  private buildSingleFolderMenu(folder: NoteFolder): MenuElement[] {
    const items: MenuElement[] = [
      { value: $r('app.string.create_subfolder'), action: () => { this.showCreateFolderDialog(folder.id); } },
      { value: $r('app.string.rename'), action: () => { this.showRenameFolderDialog(folder); } },
    ];
    this.appendMoveFolderItems(items, folder);
    items.push({ value: $r('app.string.delete'), action: () => { this.confirmDeleteFolder(folder); } });
    return items;
  }

  private appendMoveFolderItems(items: MenuElement[], folder: NoteFolder): void {
    if (folder.parentId !== null) {
      items.push({ value: $r('app.string.move_to_top_level'), action: () => { this.moveFolder(folder.id, null); } });
    }
    for (const candidate of this.folderListItems()) {
      if (!isFolderInSubtree(this.folders, folder.id, candidate.folder.id) &&
        candidate.folder.id !== folder.parentId) {
        items.push({
          value: $r('app.string.move_to_folder_path',
            this.folderIndent(candidate.depth) + candidate.folder.name),
          action: () => { this.moveFolder(folder.id, candidate.folder.id); },
        });
      }
    }
  }

  private folderListItems(): FolderListItem[] {
    const items: FolderListItem[] = [];
    const visited: Set<string> = new Set<string>();
    this.appendFolderChildren(items, null, 0, visited);
    // Corrupt/orphaned hierarchy remains reachable instead of disappearing from the library.
    for (const folder of this.folders) {
      if (!visited.has(folder.id)) {
        visited.add(folder.id);
        items.push({ folder: folder, depth: 0 });
        this.appendFolderChildren(items, folder.id, 1, visited);
      }
    }
    return items;
  }

  private appendFolderChildren(items: FolderListItem[], parentId: string | null, depth: number,
    visited: Set<string>): void {
    for (const folder of this.folders) {
      if (folder.parentId === parentId && !visited.has(folder.id)) {
        visited.add(folder.id);
        items.push({ folder: folder, depth: depth });
        this.appendFolderChildren(items, folder.id, depth + 1, visited);
      }
    }
  }

  private folderIndent(depth: number): string {
    let indent: string = '';
    for (let i: number = 0; i < depth; i++) {
      indent += '  ';
    }
    return indent;
  }

  private buildLibraryActionsMenu(): MenuElement[] {
    return [
      { value: $r('app.string.recently_modified'), action: () => { this.setSortMode(NoteSortMode.UPDATED); } },
      { value: $r('app.string.recently_created'), action: () => { this.setSortMode(NoteSortMode.CREATED); } },
      { value: $r('app.string.title'), action: () => { this.setSortMode(NoteSortMode.TITLE); } },
      { value: $r('app.string.follow_system'), action: () => { this.setThemeMode('system'); } },
      { value: $r('app.string.light_theme'), action: () => { this.setThemeMode('light'); } },
      { value: $r('app.string.dark_theme'), action: () => { this.setThemeMode('dark'); } },
      { value: $r('app.string.settings'), action: () => { this.navigateToSettings(); } },
    ];
  }

  private currentFolder(): NoteFolder | null {
    for (const folder of this.folders) {
      if (folder.id === this.currentFolderId) {
        return folder;
      }
    }
    return null;
  }

  private confirmDeleteFolder(folder: NoteFolder): void {
    if (this.folderBusy) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_folder'),
      message: $r('app.string.delete_folder_message', folder.name),
      primaryButton: { value: $r('app.string.cancel'), action: () => {} },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: this.resolveTokens().danger,
        action: () => {
          this.deleteFolder(folder.id).catch((e: Error) => {
            console.error(`delete folder action failed: ${JSON.stringify(e)}`);
          });
        },
      },
    });
  }

  // 当前文件夹名（顶部显示）
  private currentFolderName(): ResourceStr {
    for (const f of this.folders) {
      if (f.id === this.currentFolderId) {
        return f.name;
      }
    }
    return $r('app.string.all_notes');
  }

  private async deleteNoteAndRefresh(noteId: string): Promise<void> {
    if (this.viewModel === null || this.deleteBusy) {
      return;
    }
    this.deleteBusy = true;
    try {
      const vm: LibraryViewModel = this.viewModel;
      await vm.deleteNote(noteId);
      this.viewModel = vm;
      await this.refreshThumbnails();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.delete_note_failed') });
      console.error(`delete note failed: ${JSON.stringify(e)}`);
    } finally {
      this.deleteBusy = false;
    }
  }

  private async createAndOpen(): Promise<void> {
    if (this.viewModel === null || this.createBusy) {
      return;
    }
    this.createBusy = true;
    try {
      const noteId: string = await this.viewModel.createNote();
      await router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: noteId } });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.create_note_failed') });
      console.error(`createAndOpen failed: ${JSON.stringify(e)}`);
    } finally {
      this.createBusy = false;
    }
  }

  // 响应式断点（§39.4：600/840/952/1400vp）
  private applyBreakpoints(widthVp: number): void {
    if (widthVp >= 1400) {
      this.columns = 4;
      this.sidebarWidth = 332;
      this.showSidebar = true;
    } else if (widthVp >= 952) {
      this.columns = 3;
      this.sidebarWidth = 332;
      this.showSidebar = true;
    } else if (widthVp >= 840) {
      this.columns = 2;
      this.sidebarWidth = 280;
      this.showSidebar = true;
    } else {
      this.columns = widthVp >= 600 ? 3 : 2;
      this.sidebarWidth = 0;
      this.showSidebar = false;
    }
  }

  private formatTime(timestamp: number): string {
    const d: Date = new Date(timestamp);
    return d.getMonth() + 1 + '/' + d.getDate() + ' ' + d.getHours() + ':' +
      (d.getMinutes() < 10 ? '0' : '') + d.getMinutes();
  }
}

// T-039：名称输入对话框（@CustomDialog 原生）
@CustomDialog
struct NameDialog {
  controller?: CustomDialogController;
  title: ResourceStr = '';
  initialText: string = '';
  @State inputText: string = '';
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onConfirm: (name: string) => void = () => {
  };

  aboutToAppear(): void {
    this.inputText = this.initialText;
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      TextInput({ text: this.inputText, placeholder: $r('app.string.name') })
        .width('100%')
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().control)
        .margin({ top: 12 })
        .onChange((value: string) => {
          this.inputText = value;
        })
      Row() {
        Button($r('app.string.cancel'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            if (this.controller !== undefined) {
              this.controller.close();
            }
          })
        Button($r('app.string.confirm'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.onConfirm(this.inputText);
            if (this.controller !== undefined) {
              this.controller.close();
            }
          })
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}
