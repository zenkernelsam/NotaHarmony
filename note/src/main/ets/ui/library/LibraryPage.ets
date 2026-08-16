// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router, promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import {
  AssetAvailabilityChange, assetAvailabilityHub,
} from '../../data/AssetAvailabilityHub';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import {
  FolderCreateResult, FolderDeleteResult, FolderMutationResult, FolderRepositoryImpl,
  NoteFolder, NoteFolderMoveResult, isFolderInSubtree,
} from '../../data/FolderRepositoryImpl';
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
  hasChildren: boolean;
  expanded: boolean;
}

@Entry
@Component
struct LibraryPage {
  // === 响应式状态 ===
  @State columns: number = 3;
  @State sidebarWidth: number = 0;
  @State showSidebar: boolean = false;
  // 原版 <840dp 使用 ModalNavigationDrawer；Harmony 侧用显式 overlay 保持同一可达性。
  @State compactFolderDrawerVisible: boolean = false;
  @State expandedFolderIds: string[] = [];
  private expandedFoldersInitialized: boolean = false;
  // === 数据状态 ===
  private viewModel: LibraryViewModel | null = null;
  @State notes: NoteMeta[] = [];
  @State libraryLoading: boolean = true;
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
  private assetAvailabilitySubscription: number = -1;
  private searchTimer: number = -1;
  private thumbnailRequestTimer: number = -1;
  private thumbnailPriorityIds: string[] = [];
  private pageActive: boolean = false;
  private lifecycleGeneration: number = 0;
  private notesRequestGeneration: number = 0;
  private readonly THUMBNAIL_CONCURRENCY: number = 3;
  private readonly MAX_THUMBNAILS: number = 64;
  private thumbnailRefreshMutex: AsyncMutex = new AsyncMutex();
  private noteRepo: NoteRepositoryImpl | null = null;
  // T-039：文件夹
  private folderRepo: FolderRepositoryImpl | null = null;
  @State folders: NoteFolder[] = [];
  @State currentFolderId: string | null = null;
  private folderReadGeneration: number = 0;
  private folderMutationGeneration: number = 0;
  @State folderDialogTitle: ResourceStr = $r('app.string.new_folder');
  @State folderDialogInitialText: string = '';
  @State folderDialogMode: number = 0;  // 0=新建 1=重命名
  @State folderDialogTargetId: string = '';
  @State folderDialogParentId: string | null = null;
  private folderDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: this.folderDialogTitle,
      initialText: this.folderDialogInitialText,
      onConfirm: (name: string): Promise<boolean> => this.onFolderDialogConfirm(name),
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
    const generation: number = this.activatePage();
    this.initData(generation);
  }

  aboutToDisappear(): void {
    this.pageActive = false;
    this.compactFolderDrawerVisible = false;
    this.lifecycleGeneration++;
    this.notesRequestGeneration++;
    if (this.assetAvailabilitySubscription >= 0) {
      assetAvailabilityHub.unsubscribe(this.assetAvailabilitySubscription);
      this.assetAvailabilitySubscription = -1;
    }
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
    this.retireThumbnailRenderer(renderer).catch((e: Error) => {
      console.warn(`ThumbnailRenderer dispose failed: ${JSON.stringify(e)}`);
    });
  }

  // The ViewModel owns async operations; each successful result publishes a fresh @State notes snapshot.
  onPageShow(): void {
    const lifecycleGeneration: number = this.activatePage();
    if (this.folderRepo !== null) {
      this.reloadFoldersBestEffort(this.folderRepo, 'page show');
    }
    if (this.viewModel !== null) {
      const vm: LibraryViewModel = this.viewModel;
      const renderer: ThumbnailRenderer = this.thumbRenderer;
      const query: string = this.searchText;
      const folderId: string | null = vm.currentFolderId;
      this.currentFolderId = folderId;
      const notesRequestGeneration: number = this.beginNotesRequest();
      if (this.notes.length === 0) {
        this.libraryLoading = true;
      }
      const context = getContext(this) as common.UIAbilityContext;
      renderer.initialize(context).then(() => vm.loadNotes(query)).then(() => {
        if (!this.isCurrentLifecycle(lifecycleGeneration, vm, renderer) ||
          !this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
          return;
        }
        this.initError = '';
        this.hasInitError = false;
        this.viewModel = vm;
        this.currentFolderId = vm.currentFolderId;
        this.notes = vm.getFilteredNotes().slice();
        this.libraryLoading = false;
        return this.refreshThumbnails();
      }).catch((e: Error) => {
        if (!this.isCurrentLifecycle(lifecycleGeneration, vm, renderer) ||
          !this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
          return;
        }
        this.libraryLoading = false;
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
    const renderer: ThumbnailRenderer = this.thumbRenderer;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const release: MutexRelease = await this.thumbnailRefreshMutex.lock();
    try {
      await this.refreshThumbnailGeneration(generation, lifecycleGeneration, renderer);
    } finally {
      release();
    }
  }

  private activatePage(): number {
    if (!this.pageActive) {
      this.pageActive = true;
      this.lifecycleGeneration++;
    }
    if (this.assetAvailabilitySubscription < 0) {
      this.assetAvailabilitySubscription = assetAvailabilityHub.subscribe(
        (change: AssetAvailabilityChange): void => this.onAssetAvailabilityChanged(change));
    }
    return this.lifecycleGeneration;
  }

  private isCurrentLifecycle(generation: number, viewModel: LibraryViewModel,
    renderer: ThumbnailRenderer): boolean {
    return this.pageActive && generation === this.lifecycleGeneration &&
      this.viewModel === viewModel && this.thumbRenderer === renderer;
  }

  private beginNotesRequest(): number {
    return ++this.notesRequestGeneration;
  }

  private isCurrentNotesRequest(generation: number, viewModel: LibraryViewModel,
    query: string, folderId: string | null): boolean {
    return this.pageActive && generation === this.notesRequestGeneration &&
      this.viewModel === viewModel && this.searchText === query &&
      this.currentFolderId === folderId && viewModel.currentFolderId === folderId;
  }

  private async retireThumbnailRenderer(renderer: ThumbnailRenderer): Promise<void> {
    const release: MutexRelease = await this.thumbnailRefreshMutex.lock();
    try {
      await renderer.dispose();
    } finally {
      release();
    }
  }

  private async refreshThumbnailGeneration(generation: number, lifecycleGeneration: number,
    renderer: ThumbnailRenderer): Promise<void> {
    if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
      !this.pageActive || this.viewModel === null ||
      renderer !== this.thumbRenderer) {
      return;
    }
    const allNoteIds: string[] = this.notes.map((note: NoteMeta) => note.id);
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
          const assetGeneration: number = assetAvailabilityHub.getNoteGeneration(noteId);
          const revision: string = thumbnailCacheKey(contentRevision,
            theme.paperBackground, theme.paperLineColor, assetGeneration);
          if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
            !this.pageActive || renderer !== this.thumbRenderer) {
            return;
          }
          const oldRevision: string | undefined = oldRevisions.get(noteId);
          const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
          if (oldRevision === revision && oldPixelMap !== undefined) {
            newRevisions.set(noteId, revision);
            newMap.set(noteId, oldPixelMap);
            continue;
          }
          const pixelMap: PixelMap | null = pageState === null ? null :
            await renderer.renderThumbnail(noteId, this.persistence, pageState.page, theme, this.db);
          if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
            !this.pageActive || renderer !== this.thumbRenderer) {
            if (pixelMap !== null) {
              pixelMap.release();
            }
            return;
          }
          if (pixelMap !== null) {
            createdMaps.push(pixelMap);
          }
          if (pixelMap !== null) {
            newRevisions.set(noteId, revision);
            newMap.set(noteId, pixelMap);
          }
        } catch (e) {
          console.error(`LibraryPage thumbnail failed note=${noteId}: ${JSON.stringify(e)}`);
          const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
          const oldRevision: string | undefined = oldRevisions.get(noteId);
          if (generation === this.thumbnailGeneration && lifecycleGeneration === this.lifecycleGeneration &&
            this.pageActive && renderer === this.thumbRenderer &&
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
    if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
      !this.pageActive || renderer !== this.thumbRenderer) {
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

  private onAssetAvailabilityChanged(change: AssetAvailabilityChange): void {
    if (!this.pageActive) {
      return;
    }
    for (const note of this.notes) {
      if (change.noteIds.indexOf(note.id) >= 0) {
        this.refreshThumbnails().catch((error: Error) => {
          console.error(`asset thumbnail refresh failed: ${JSON.stringify(error)}`);
        });
        return;
      }
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

  private async onFolderDialogConfirm(name: string): Promise<boolean> {
    const trimmed: string = name.trim();
    if (this.folderRepo === null) {
      promptAction.showToast({ message: $r('app.string.folder_operation_failed') });
      return false;
    }
    if (this.folderBusy) {
      return false;
    }
    const repo: FolderRepositoryImpl = this.folderRepo;
    this.folderBusy = true;
    let result: FolderMutationResult | null = null;
    try {
      if (this.folderDialogMode === 0) {
        const created: FolderCreateResult = await repo.createFolder(trimmed, this.folderDialogParentId);
        result = created;
      } else if (this.folderDialogMode === 1) {
        result = await repo.renameFolder(this.folderDialogTargetId, trimmed);
      } else {
        throw new Error(`unsupported folder dialog mode: ${this.folderDialogMode}`);
      }
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.folder_operation_failed') });
      console.error(`folder operation failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return false;
    }
    this.publishCommittedFolders(result.folders);
    this.reloadFoldersBestEffort(repo, 'folder create/rename');
    return true;
  }

  // 删除文件夹：内部笔记回根目录（不删笔记）
  private async deleteFolder(folderId: string): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    const repo: FolderRepositoryImpl = this.folderRepo;
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    let result: FolderDeleteResult | null = null;
    try {
      result = await repo.deleteFolder(folderId);
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.delete_folder_failed') });
      console.error(`delete folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    this.publishCommittedFolders(result.folders);
    vm.publishCommittedFolderDelete(
      result.deletedFolderIds, result.movedNoteIds, result.notes, this.searchText);
    this.currentFolderId = vm.currentFolderId;
    this.viewModel = vm;
    this.notes = vm.getFilteredNotes().slice();
    this.reloadFoldersBestEffort(repo, 'delete folder');
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`delete folder thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.reloadVisibleNotesAfterMutation(vm, 'delete folder');
  }

  private async moveFolder(folderId: string, parentId: string | null): Promise<void> {
    if (this.folderRepo === null || this.folderBusy) {
      return;
    }
    const repo: FolderRepositoryImpl = this.folderRepo;
    this.folderBusy = true;
    let result: FolderMutationResult | null = null;
    try {
      result = await repo.moveFolder(folderId, parentId);
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.move_folder_failed') });
      console.error(`move folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    this.publishCommittedFolders(result.folders);
    this.reloadFoldersBestEffort(repo, 'move folder');
  }

  // 移动笔记到文件夹（null=根目录）
  private async moveNote(noteId: string, folderId: string | null): Promise<void> {
    if (this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    const repo: FolderRepositoryImpl = this.folderRepo;
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    let result: NoteFolderMoveResult | null = null;
    try {
      result = await repo.moveNoteToFolder(noteId, folderId);
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.move_note_failed') });
      console.error(`move note failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    vm.publishCommittedNoteMove(result.noteId, result.folderId);
    this.viewModel = vm;
    this.notes = vm.getFilteredNotes().slice();
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`move note thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.reloadVisibleNotesAfterMutation(vm, 'move note');
  }

  private publishCommittedFolders(folders: NoteFolder[]): void {
    this.folderMutationGeneration++;
    this.folderReadGeneration++;
    this.publishFolderSnapshot(folders);
  }

  private publishFolderSnapshot(folders: NoteFolder[]): void {
    this.folders = folders.slice();
    this.reconcileExpandedFolders(this.folders);
    if (this.currentFolderId !== null) {
      this.expandFolderAncestors(this.currentFolderId, this.folders);
    }
  }

  private reconcileExpandedFolders(folders: NoteFolder[]): void {
    const validIds: Set<string> = new Set<string>();
    for (const folder of folders) {
      validIds.add(folder.id);
    }
    const next: string[] = [];
    for (const id of this.expandedFolderIds) {
      if (validIds.has(id) && next.indexOf(id) < 0) {
        next.push(id);
      }
    }
    // Expand only top-level folders by default; descendants follow the user's toggle.
    if (!this.expandedFoldersInitialized && folders.length > 0) {
      for (const folder of folders) {
        if (folder.parentId === null) {
          next.push(folder.id);
        }
      }
      this.expandedFoldersInitialized = true;
    }
    this.expandedFolderIds = next;
  }

  private isFolderExpanded(folderId: string): boolean {
    return this.expandedFolderIds.indexOf(folderId) >= 0;
  }

  private folderHasChildren(folderId: string): boolean {
    for (const folder of this.folders) {
      if (folder.parentId === folderId) {
        return true;
      }
    }
    return false;
  }

  private expandFolderAncestors(folderId: string, folders: NoteFolder[] = this.folders): void {
    const next: string[] = this.expandedFolderIds.slice();
    const visited: Set<string> = new Set<string>();
    let currentId: string | null = folderId;
    while (currentId !== null && !visited.has(currentId)) {
      visited.add(currentId);
      let current: NoteFolder | null = null;
      for (const folder of folders) {
        if (folder.id === currentId) {
          current = folder;
          break;
        }
      }
      if (current === null || current.parentId === null) {
        break;
      }
      if (next.indexOf(current.parentId) < 0) {
        next.push(current.parentId);
      }
      currentId = current.parentId;
    }
    this.expandedFolderIds = next;
  }

  private toggleFolderExpanded(folderId: string): void {
    const next: string[] = this.expandedFolderIds.slice();
    const index: number = next.indexOf(folderId);
    if (index >= 0) {
      next.splice(index, 1);
    } else {
      next.push(folderId);
    }
    this.expandedFolderIds = next;
  }

  private openCompactFolderDrawer(): void {
    if (this.folderBusy) {
      return;
    }
    if (this.currentFolderId !== null) {
      this.expandFolderAncestors(this.currentFolderId);
    }
    this.compactFolderDrawerVisible = true;
  }

  private closeCompactFolderDrawer(): void {
    this.compactFolderDrawerVisible = false;
  }

  private reloadFoldersBestEffort(repo: FolderRepositoryImpl, operation: string): void {
    const readGeneration: number = ++this.folderReadGeneration;
    const mutationGeneration: number = this.folderMutationGeneration;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    repo.getAllFolders().then((folders: NoteFolder[]) => {
      if (this.pageActive && this.folderRepo === repo &&
        lifecycleGeneration === this.lifecycleGeneration &&
        readGeneration === this.folderReadGeneration &&
        mutationGeneration === this.folderMutationGeneration) {
        this.publishFolderSnapshot(folders);
      }
    }).catch((e: Error) => {
      console.error(`${operation} authoritative folder refresh failed: ${JSON.stringify(e)}`);
    });
  }

  private reloadVisibleNotesAfterMutation(vm: LibraryViewModel, operation: string): void {
    if (!this.pageActive || this.viewModel !== vm) {
      return;
    }
    const query: string = this.searchText;
    const folderId: string | null = vm.currentFolderId;
    const notesRequestGeneration: number = this.beginNotesRequest();
    vm.loadNotes(query).then(() => {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
        this.notes = vm.getFilteredNotes().slice();
        return this.refreshThumbnails();
      }
      return Promise.resolve();
    }).catch((e: Error) => {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
        console.error(`${operation} authoritative note refresh failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // 切换浏览文件夹
  private async selectFolder(folderId: string | null): Promise<void> {
    if (this.viewModel === null || this.folderBusy) {
      return;
    }
    const query: string = this.searchText;
    const notesRequestGeneration: number = this.beginNotesRequest();
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    this.currentFolderId = folderId;
    try {
      await vm.setFolder(folderId, query);
      if (!this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
        return;
      }
      this.initError = '';
      this.hasInitError = false;
      this.viewModel = vm;
      this.notes = vm.getFilteredNotes().slice();
      await this.refreshThumbnails();
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
        this.closeCompactFolderDrawer();
      }
    } catch (e) {
      if (this.pageActive && notesRequestGeneration === this.notesRequestGeneration &&
        this.viewModel === vm && this.searchText === query) {
        this.currentFolderId = vm.currentFolderId;
        promptAction.showToast({ message: $r('app.string.load_notes_failed') });
        console.error(`select folder failed: ${JSON.stringify(e)}`);
      }
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
    this.notes = this.viewModel.getFilteredNotes().slice();
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

  private async initData(expectedLifecycleGeneration: number = this.lifecycleGeneration): Promise<void> {
    this.initError = '';
    this.hasInitError = false;
    if (this.notes.length === 0) {
      this.libraryLoading = true;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pref: preferences.Preferences =
        await preferences.getPreferences(context, THEME_PREFERENCES_NAME);
      if (!this.pageActive || expectedLifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
      const renderer: ThumbnailRenderer = this.thumbRenderer;
      await renderer.initialize(context);
      if (!this.pageActive || expectedLifecycleGeneration !== this.lifecycleGeneration ||
        renderer !== this.thumbRenderer) {
        return;
      }
      const noteRepo: NoteRepositoryImpl = new NoteRepositoryImpl(
        this.db, new EditorSettingsStore(context));
      const folderRepo: FolderRepositoryImpl = new FolderRepositoryImpl(this.db);
      const vm: LibraryViewModel = new LibraryViewModel(noteRepo);
      this.noteRepo = noteRepo;
      this.folderRepo = folderRepo;
      this.viewModel = vm;
      this.currentFolderId = vm.currentFolderId;
      const folderReadGeneration: number = ++this.folderReadGeneration;
      const folderMutationGeneration: number = this.folderMutationGeneration;
      try {
        const loadedFolders: NoteFolder[] = await folderRepo.getAllFolders();
        if (this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer) &&
          folderReadGeneration === this.folderReadGeneration &&
          folderMutationGeneration === this.folderMutationGeneration) {
          this.publishFolderSnapshot(loadedFolders);
        }
      } catch (folderError) {
        if (!this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer) ||
          folderReadGeneration !== this.folderReadGeneration ||
          folderMutationGeneration !== this.folderMutationGeneration) {
          return;
        }
        console.error(`LibraryPage folder load failed: ${JSON.stringify(folderError)}`);
        promptAction.showToast({ message: $r('app.string.load_folders_failed') });
      }
      // 恢复排序偏好
      const saved: number = pref.getSync(this.PREF_SORT_KEY, 0) as number;
      vm.sortMode = saved as NoteSortMode;
      const initialQuery: string = this.searchText;
      const initialFolderId: string | null = vm.currentFolderId;
      const initialNotesRequestGeneration: number = this.beginNotesRequest();
      await vm.loadNotes(initialQuery);
      if (!this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer) ||
        !this.isCurrentNotesRequest(initialNotesRequestGeneration, vm, initialQuery, initialFolderId)) {
        return;
      }
      this.viewModel = vm;
      this.currentFolderId = vm.currentFolderId;
      this.notes = vm.getFilteredNotes().slice();
      this.libraryLoading = false;
      await this.refreshThumbnails();
      if (!this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer) ||
        !this.isCurrentNotesRequest(initialNotesRequestGeneration, vm, initialQuery, initialFolderId)) {
        return;
      }
      this.persistence.backfillSearchIndex().then(() => {
        const activeViewModel: LibraryViewModel | null = this.viewModel;
        const activeQuery: string = this.searchText;
        const activeFolderId: string | null = activeViewModel === null ? null :
          activeViewModel.currentFolderId;
        if (activeViewModel !== null && this.pageActive && activeQuery.trim().length > 0 &&
          this.currentFolderId === activeFolderId) {
          const backfillRequestGeneration: number = this.beginNotesRequest();
          activeViewModel.loadNotes(activeQuery).then(() => {
            if (this.isCurrentNotesRequest(backfillRequestGeneration, activeViewModel,
              activeQuery, activeFolderId)) {
              this.viewModel = activeViewModel;
              this.notes = activeViewModel.getFilteredNotes().slice();
              return this.refreshThumbnails();
            }
            return Promise.resolve();
          }).catch((e: Error) => {
            if (this.isCurrentNotesRequest(backfillRequestGeneration, activeViewModel,
              activeQuery, activeFolderId)) {
              console.error(`refresh search after backfill failed: ${JSON.stringify(e)}`);
            }
          });
        }
      }).catch((e: Error) => {
        console.error(`search index backfill failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      if (!this.pageActive || expectedLifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.libraryLoading = false;
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

  // 原版 folder row 约 48dp：左侧 chevron 负责展开/折叠，中间整行选择，右侧保留操作菜单。
  @Builder
  FolderNavigationRow(item: FolderListItem) {
    Row() {
      if (item.hasChildren) {
        Button(item.expanded ? '⌄' : '›')
          .width(40)
          .height(44)
          .padding(0)
          .fontSize(20)
          .enabled(!this.folderBusy)
          .fontColor(this.resolveTokens().textSecondary)
          .accessibilityText(item.expanded ? $r('app.string.collapse_folder') :
            $r('app.string.expand_folder'))
          .onClick(() => {
            this.toggleFolderExpanded(item.folder.id);
          })
      } else {
        Blank().width(40).height(44)
      }
      Button() {
        Row() {
          Text(item.folder.name)
            .layoutWeight(1)
            .maxLines(1)
            .fontSize(15)
            .fontColor(this.currentFolderId === item.folder.id ? this.resolveTokens().accent :
              this.resolveTokens().textPrimary)
            .fontWeight(this.currentFolderId === item.folder.id ? FontWeight.Medium :
              FontWeight.Normal)
          if (this.currentFolderId === item.folder.id) {
            Text('✓')
              .fontSize(16)
              .fontColor(this.resolveTokens().accent)
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .height('100%')
      }
      .layoutWeight(1)
      .height(44)
      .padding({ left: 8, right: 8 })
      .enabled(!this.folderBusy)
      .backgroundColor(this.currentFolderId === item.folder.id ? this.resolveTokens().control :
        this.resolveTokens().surface)
      .borderRadius(8)
      .accessibilityText(item.folder.name)
      .onClick(() => {
        this.selectFolder(item.folder.id);
      })
      Button('...')
        .width(40)
        .height(44)
        .padding(0)
        .fontSize(14)
        .enabled(!this.folderBusy)
        .accessibilityText($r('app.string.folder_actions'))
        .bindMenu(this.buildSingleFolderMenu(item.folder))
    }
    .width('100%')
    .height(48)
    .padding({ left: item.depth * 12, right: 4 })
  }

  @Builder
  CompactFolderDrawer() {
    if (this.compactFolderDrawerVisible && !this.showSidebar) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#66000000')
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => {
            this.closeCompactFolderDrawer();
          })
        Column() {
          Row() {
            Text($r('app.string.folders'))
              .layoutWeight(1)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.resolveTokens().textPrimary)
            Button('×')
              .width(44)
              .height(44)
              .fontSize(22)
              .accessibilityText($r('app.string.close'))
              .onClick(() => {
                this.closeCompactFolderDrawer();
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 8 })

          Button() {
            Row() {
              Text($r('app.string.all_notes'))
                .layoutWeight(1)
                .fontSize(15)
                .fontColor(this.currentFolderId === null ? this.resolveTokens().accent :
                  this.resolveTokens().textPrimary)
                .fontWeight(this.currentFolderId === null ? FontWeight.Medium : FontWeight.Normal)
              if (this.currentFolderId === null) {
                Text('✓')
                  .fontSize(16)
                  .fontColor(this.resolveTokens().accent)
              }
            }
            .width('100%')
            .height('100%')
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .enabled(!this.folderBusy)
          .backgroundColor(this.currentFolderId === null ? this.resolveTokens().control :
            this.resolveTokens().surface)
          .onClick(() => {
            this.selectFolder(null);
          })

          Scroll() {
            Column() {
              ForEach(this.folderListItems(false), (item: FolderListItem) => {
                this.FolderNavigationRow(item)
              }, (item: FolderListItem) => item.folder.id)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)

          Button($r('app.string.new_folder'))
            .width('100%')
            .height(48)
            .margin({ left: 16, right: 16, bottom: 16 })
            .enabled(!this.folderBusy)
            .onClick(() => {
              this.showCreateFolderDialog();
            })
        }
        .width('86%')
        .constraintSize({ minWidth: 280, maxWidth: 320 })
        .height('100%')
        .backgroundColor(this.resolveTokens().surface)
        .hitTestBehavior(HitTestMode.Block)
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.TopStart)
      .hitTestBehavior(HitTestMode.Block)
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
          Button() {
            Row() {
              Text($r('app.string.all_notes'))
                .layoutWeight(1)
                .fontSize(15)
                .fontColor(this.currentFolderId === null ? this.resolveTokens().accent :
                  this.resolveTokens().textPrimary)
                .fontWeight(this.currentFolderId === null ? FontWeight.Medium : FontWeight.Normal)
              if (this.currentFolderId === null) {
                Text('✓').fontSize(16).fontColor(this.resolveTokens().accent)
              }
            }
            .width('100%')
            .height('100%')
          }
          .width('100%')
          .height(48)
          .padding({ left: 8, right: 8 })
          .backgroundColor(this.currentFolderId === null ? this.resolveTokens().control :
            this.resolveTokens().surface)
          .enabled(!this.folderBusy)
          .onClick(() => {
            this.selectFolder(null);
          })
          Scroll() {
            Column() {
              ForEach(this.folderListItems(false), (item: FolderListItem) => {
                this.FolderNavigationRow(item)
              }, (item: FolderListItem) => item.folder.id)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Vertical)
          Button($r('app.string.new_folder'))
            .width('100%')
            .height(48)
            .fontSize(13)
            .margin({ bottom: 16 })
            .enabled(!this.folderBusy)
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
        // 原版在窄屏使用可开合侧栏；Harmony compact 以显式 overlay drawer 保持同等语义。
        if (!this.showSidebar) {
          Row() {
            Button('☰')
              .width(44)
              .height(44)
              .fontSize(20)
              .enabled(!this.folderBusy)
              .accessibilityText($r('app.string.open_folder_drawer'))
              .onClick(() => {
                this.openCompactFolderDrawer();
              })
            Button(this.currentFolderName())
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontColor(this.resolveTokens().accent)
              .enabled(!this.folderBusy)
              .accessibilityText($r('app.string.open_folder_drawer'))
              .onClick(() => {
                this.openCompactFolderDrawer();
              })
            Button('...')
              .width(48)
              .height(44)
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
              const notesRequestGeneration: number = this.beginNotesRequest();
              if (this.searchTimer >= 0) {
                clearTimeout(this.searchTimer);
              }
              this.searchTimer = setTimeout(() => {
                this.searchTimer = -1;
                const vm: LibraryViewModel | null = this.viewModel;
                if (vm === null || !this.pageActive ||
                  notesRequestGeneration !== this.notesRequestGeneration ||
                  this.searchText !== value) {
                  return;
                }
                const folderId: string | null = vm.currentFolderId;
                vm.setSearchQuery(value).then(() => {
                  if (this.isCurrentNotesRequest(notesRequestGeneration, vm, value, folderId)) {
                    this.viewModel = vm;
                    this.currentFolderId = vm.currentFolderId;
                    this.notes = vm.getFilteredNotes().slice();
                    this.libraryLoading = false;
                    return this.refreshThumbnails();
                  }
                  return Promise.resolve();
                }).catch((e: Error) => {
                  if (this.isCurrentNotesRequest(notesRequestGeneration, vm, value, folderId)) {
                    console.error(`search notes failed: ${JSON.stringify(e)}`);
                    this.libraryLoading = false;
                    promptAction.showToast({ message: $r('app.string.search_failed') });
                  }
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
        if (this.hasInitError && this.notes.length === 0) {
          Column() {
            Text(this.initError)
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
            Button($r('app.string.retry'))
              .height(36)
              .margin({ top: 12 })
              .onClick(() => {
                const lifecycleGeneration: number = this.activatePage();
                this.initData(lifecycleGeneration);
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.viewModel !== null) {
          if (this.libraryLoading && this.notes.length === 0) {
            Text($r('app.string.loading'))
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
              .layoutWeight(1)
          } else if (this.notes.length === 0) {
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
              ForEach(this.notes, (note: NoteMeta) => {
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
    .overlay(this.CompactFolderDrawer(), { align: Alignment.TopStart })
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
      MenuItem({
        content: $r('app.string.move_to_folder'),
        builder: () => {
          this.MoveNoteSubMenu(note)
        },
      })
    }
  }

  @Builder
  MoveNoteSubMenu(note: NoteMeta) {
    Menu() {
      MenuItem({ content: $r('app.string.move_to_all_notes') })
        .enabled(note.folderId !== null)
        .onClick(() => {
          this.moveNote(note.id, null);
        })
      ForEach(this.folderListItems(), (item: FolderListItem) => {
        MenuItem({ content: this.folderIndent(item.depth) + item.folder.name })
          .enabled(note.folderId !== item.folder.id)
          .onClick(() => {
            this.moveNote(note.id, item.folder.id);
          })
      }, (item: FolderListItem) => item.folder.id)
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

  // Menus need every destination; visual navigation uses the collapsed-aware variant.
  private folderListItems(includeCollapsed: boolean = true): FolderListItem[] {
    const items: FolderListItem[] = [];
    const visited: Set<string> = new Set<string>();
    this.appendFolderChildren(items, null, 0, visited, includeCollapsed);
    // Corrupt/orphaned hierarchy remains reachable instead of disappearing from the library.
    for (const folder of this.folders) {
      // A child hidden by a collapsed valid parent is intentionally not an orphan.
      if (!visited.has(folder.id) && (folder.parentId === null || !this.folderExists(folder.parentId) ||
        this.folderHasCyclicAncestry(folder.id))) {
        visited.add(folder.id);
        items.push({
          folder: folder,
          depth: 0,
          hasChildren: this.folderHasChildren(folder.id),
          expanded: this.isFolderExpanded(folder.id),
        });
        if (includeCollapsed || this.isFolderExpanded(folder.id)) {
          this.appendFolderChildren(items, folder.id, 1, visited, includeCollapsed);
        }
      }
    }
    return items;
  }

  private folderExists(folderId: string): boolean {
    for (const folder of this.folders) {
      if (folder.id === folderId) {
        return true;
      }
    }
    return false;
  }

  private folderHasCyclicAncestry(folderId: string): boolean {
    const visited: Set<string> = new Set<string>();
    let currentId: string | null = folderId;
    while (currentId !== null) {
      if (visited.has(currentId)) {
        return true;
      }
      visited.add(currentId);
      let current: NoteFolder | null = null;
      for (const folder of this.folders) {
        if (folder.id === currentId) {
          current = folder;
          break;
        }
      }
      if (current === null || current.parentId === null) {
        return false;
      }
      currentId = current.parentId;
    }
    return false;
  }

  private appendFolderChildren(items: FolderListItem[], parentId: string | null, depth: number,
    visited: Set<string>, includeCollapsed: boolean): void {
    for (const folder of this.folders) {
      if (folder.parentId === parentId && !visited.has(folder.id)) {
        visited.add(folder.id);
        const expanded: boolean = this.isFolderExpanded(folder.id);
        items.push({
          folder: folder,
          depth: depth,
          hasChildren: this.folderHasChildren(folder.id),
          expanded: expanded,
        });
        if (includeCollapsed || expanded) {
          this.appendFolderChildren(items, folder.id, depth + 1, visited, includeCollapsed);
        }
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
    const vm: LibraryViewModel = this.viewModel;
    try {
      await vm.deleteNote(noteId);
      this.viewModel = vm;
      this.notes = vm.getFilteredNotes().slice();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.delete_note_failed') });
      console.error(`delete note failed: ${JSON.stringify(e)}`);
      return;
    } finally {
      this.deleteBusy = false;
    }
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`delete note thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.reloadVisibleNotesAfterMutation(vm, 'delete note');
  }

  private async createAndOpen(): Promise<void> {
    if (this.viewModel === null || this.createBusy) {
      return;
    }
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    let noteId: string;
    try {
      noteId = await vm.createNote(this.searchText);
      this.notes = vm.getFilteredNotes().slice();
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.create_note_failed') });
      console.error(`create note failed: ${JSON.stringify(e)}`);
      this.createBusy = false;
      return;
    }
    this.reloadVisibleNotesAfterMutation(vm, 'create note');
    try {
      await router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: noteId } });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.created_note_open_failed') });
      console.error(`open created note failed: ${JSON.stringify(e)}`);
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
    if (this.showSidebar && this.compactFolderDrawerVisible) {
      this.compactFolderDrawerVisible = false;
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
  onConfirm: (name: string) => Promise<boolean> = async (_name: string): Promise<boolean> => false;

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
            this.onConfirm(this.inputText).then((success: boolean) => {
              if (success && this.controller !== undefined) {
                this.controller.close();
              }
            }).catch((e: Error) => {
              console.error(`folder dialog confirm failed: ${JSON.stringify(e)}`);
            });
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
