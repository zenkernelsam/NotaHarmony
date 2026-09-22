// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router, promptAction } from '@kit.ArkUI';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import {
  AssetAvailabilityChange, assetAvailabilityHub,
} from '../../data/AssetAvailabilityHub';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { NoteExporter } from '../../data/NoteExporter';
import { ImportReport, ImportResult, NoteImporter } from '../../data/NoteImporter';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import { FOLDER_DEFAULT_COLOR } from '../../data/DatabaseHelper';
import {
  FolderCreateResult, FolderDeleteResult, FolderDropIntent, FolderMutationResult,
  FolderRepositoryImpl, NoteFolder, NoteFolderMoveResult, ORIGINAL_FOLDER_DRAG_INDENT,
  isFolderInSubtree, resolveFolderDrop,
} from '../../data/FolderRepositoryImpl';
import { FirstPageThumbnailState, StrokePersistence } from '../../data/StrokePersistence';
import { AsyncMutex, MutexRelease } from '../../data/AsyncMutex';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import {
  isThumbnailSourceUnchanged, prioritizeThumbnailNoteIds, thumbnailCacheKey,
} from '../../rendering/ThumbnailRenderPolicy';
import { LibrarySection, LibraryViewModel, NoteSortMode } from './LibraryViewModel';
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

// 原版文件夹自定义（e47 SyncedFolderMetadata.color/emoji + 1.0.3 文件夹对话框）。
// 原版调色板常量位于未反编译的 Compose 资源中；这里采用文档化的近似配色，
// 第一项始终等于 FOLDER_DEFAULT_COLOR（未自定义时的默认色）。
const FOLDER_COLOR_PALETTE: number[] = [
  FOLDER_DEFAULT_COLOR,
  0xFFE2574C,
  0xFFF0932B,
  0xFFF5C445,
  0xFF5FB760,
  0xFF4FA8DE,
  0xFF8B6CC1,
  0xFFE0719E,
];

// 原版 emoji 选择器是分类网格（LIBRARY_FOLDER_EMOJI_PICKER flag + du3 九类 +
// md 分类图标）；emoji 本体来自打包的 Realm EmojiInfo 库，反编译产物中不可见，
// Harmony 侧提供按原版分类序的策划子集，空字符串 = 无 emoji（pdb.d() 等价语义）。
const FOLDER_EMOJI_CATEGORY_ICONS: string[] = [
  '😀', '🧑', '🐻', '🍎', '⚽', '💡', '🚗', '🔢', '🏁',
];
const FOLDER_EMOJI_CATEGORIES: string[][] = [
  // du3.Smileys
  ['😀', '😄', '😁', '😆', '🙂', '😉', '😊', '😍', '🤩', '😎', '🤔', '😴', '😢', '😭', '😡', '🤯', '🥳', '😇', '🤠', '😅'],
  // du3.PeopleBody
  ['👋', '👍', '👎', '👏', '🙏', '💪', '🤝', '✍️', '🧠', '👀', '👶', '🧒', '🧑', '👩', '👨', '🧑‍🎓', '👩‍💻', '🧑‍🏫', '🏃', '🚶'],
  // du3.AnimalsNature
  ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🦁', '🐮', '🐷', '🐸', '🐵', '🦄', '🐢', '🐙', '🦋', '🌸', '🌵', '🌲', '🌈', '🔥'],
  // du3.FoodDrink
  ['🍎', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐', '🍑', '🥑', '🥦', '🍕', '🍔', '🌮', '🍣', '🍜', '🍰', '☕', '🧋', '🍺', '🍩'],
  // du3.Activities
  ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🎱', '🏓', '🏸', '🥊', '🎯', '🎮', '🎲', '🧩', '🎨', '🎬', '🎤', '🎧', '🎸', '🏆'],
  // du3.Objects
  ['📚', '📖', '✏️', '🖊️', '📐', '📏', '�️', '📁', '📌', '📎', '🔍', '🔬', '💡', '💻', '📱', '⌚', '📷', '🔒', '🔑', '💰'],
  // du3.TravelPlaces
  ['🚗', '🚕', '🚌', '🚲', '✈️', '🚀', '🚂', '⛵', '🏠', '🏢', '🏫', '🏥', '🏛️', '⛪', '�', '�', '�', '🏔️', '🏖️', '🏕️'],
  // du3.Symbols
  ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '✨', '⭐', '🌟', '⚠️', '✅', '❌', '➕', '➖', '♻️', '🔴', '🟢', '🔵'],
  // du3.Flags
  ['🏁', '🚩', '🏳️', '🏴', '🏳️‍🌈', '🇨🇳', '🇺🇸', '🇬🇧', '🇯🇵', '🇰🇷', '🇫🇷', '🇩🇪', '🇨🇦', '🇦🇺', '🇧🇷', '🇮🇳'],
];

@Entry
@Component
struct LibraryPage {
  // === 响应式状态 ===
  @State columns: number = 3;
  @State sidebarWidth: number = 0;
  @State showSidebar: boolean = false;
  // Original ie7 view mode (z97 pref, default GRID): grid cards vs
  // compact list rows (yj9 picks b5j.b vs m5j.b per ie7.ordinal()).
  @State listView: boolean = false;
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
  // Original mw3/ksh.g: the new-note FAB expands into quick actions
  // (record audio / import file / [scan] / [capture]).
  @State createMenuOpen: boolean = false;
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
  private readonly THUMBNAIL_SOURCE_ATTEMPTS: number = 2;
  private thumbnailRefreshMutex: AsyncMutex = new AsyncMutex();
  private noteRepo: NoteRepositoryImpl | null = null;
  // T-039：文件夹
  private folderRepo: FolderRepositoryImpl | null = null;
  @State folders: NoteFolder[] = [];
  @State currentFolderId: string | null = null;
  // Original dk9 library section (ua5 chip row): applies when no folder is selected.
  @State currentSection: LibrarySection = LibrarySection.ALL_NOTES;
  private folderReadGeneration: number = 0;
  private folderMutationGeneration: number = 0;
  private folderDragVisibleIds: string[] = [];
  private folderDragVisibleDepths: number[] = [];
  private folderDragSourceIndex: number = -1;
  private folderDragDepthAnchorX: number = 0;
  private folderDragPreviewName: string = '';
  @State folderDialogTitle: ResourceStr = $r('app.string.new_folder');
  @State folderDialogInitialText: string = '';
  @State folderDialogMode: number = 0;  // 0=新建 1=重命名
  @State folderDialogTargetId: string = '';
  @State folderDialogParentId: string | null = null;
  @State folderDialogColor: number = FOLDER_DEFAULT_COLOR;
  @State folderDialogEmoji: string = '';
  private folderDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: this.folderDialogTitle,
      initialText: this.folderDialogInitialText,
      initialColor: this.folderDialogColor,
      initialEmoji: this.folderDialogEmoji,
      showDecoration: true,
      onConfirm: (name: string, color: number, emoji: string): Promise<boolean> =>
        this.onFolderDialogConfirm(name, color, emoji),
    }),
    autoCancel: true,
  });
  // 原版 d5j Rename：笔记上下文菜单首项，复用 NameDialog（无装饰区）。
  @State noteDialogNoteId: string = '';
  @State noteDialogInitialText: string = '';
  private noteDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: $r('app.string.rename'),
      initialText: this.noteDialogInitialText,
      onConfirm: (name: string, _color: number, _emoji: string): Promise<boolean> =>
        this.onRenameNoteConfirm(name),
    }),
    autoCancel: true,
  });
  private persistence: StrokePersistence = new StrokePersistence();
  private thumbRenderer: ThumbnailRenderer = new ThumbnailRenderer();
  private db: DatabaseManager = DatabaseManager.getInstance();
  private readonly PREF_SORT_KEY: string = 'library_sort_mode';
  // Original z97 persists sortField/sortDirection separately
  // ("sortDirection" defaults to DESCENDING).
  private readonly PREF_SORT_DIR_KEY: string = 'library_sort_dir';
  // Original z97 view-mode pref (ie7, default GRID).
  private readonly PREF_VIEW_MODE_KEY: string = 'library_view_mode';
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
    this.clearFolderDrag();
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
      this.currentSection = vm.currentSection;
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
        this.currentSection = vm.currentSection;
        this.notes = vm.getFilteredNotes().slice();
        this.libraryLoading = false;
        return this.refreshThumbnails();
      }).catch((e: Error) => {
        console.error(`LibraryPage onPageShow reload failed: ${JSON.stringify(e)}`);
        if (!this.isCurrentLifecycle(lifecycleGeneration, vm, renderer) ||
          !this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId)) {
          return;
        }
        this.libraryLoading = false;
        this.initError = $r('app.string.load_notes_failed');
        this.hasInitError = true;
        promptAction.showToast({ message: $r('app.string.load_notes_failed') });
      });
    }
  }

  private navigateToSettings(): void {
    if (!this.pageActive) {
      return;
    }
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
    query: string, folderId: string | null,
    lifecycleGeneration: number = this.lifecycleGeneration): boolean {
    return this.pageActive && lifecycleGeneration === this.lifecycleGeneration &&
      generation === this.notesRequestGeneration &&
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
        let requestedPageId: string | null = null;
        let requestedRevision: string | null = null;
        let unpublishedPixelMap: PixelMap | null = null;
        try {
          let pageState: FirstPageThumbnailState | null =
            await this.persistence.getFirstPageThumbnailState(noteId);
          for (let attempt: number = 0;
            attempt < this.THUMBNAIL_SOURCE_ATTEMPTS && pageState !== null; attempt++) {
            const sourceState: FirstPageThumbnailState = pageState;
            const assetGeneration: number = assetAvailabilityHub.getNoteGeneration(noteId);
            const revision: string = this.thumbnailRevision(sourceState, theme, assetGeneration);
            requestedPageId = sourceState.page.pageId;
            requestedRevision = revision;
            if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
              !this.pageActive || renderer !== this.thumbRenderer) {
              return;
            }
            const oldRevision: string | undefined = oldRevisions.get(noteId);
            const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
            if (oldRevision === revision && oldPixelMap !== undefined) {
              newRevisions.set(noteId, revision);
              newMap.set(noteId, oldPixelMap);
              break;
            }
            unpublishedPixelMap = await renderer.renderThumbnail(
              noteId, this.persistence, sourceState.page, theme, this.db);
            if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
              !this.pageActive || renderer !== this.thumbRenderer) {
              if (unpublishedPixelMap !== null) {
                await this.releaseThumbnailPixelMap(unpublishedPixelMap, 'stale generation');
                unpublishedPixelMap = null;
              }
              return;
            }
            if (unpublishedPixelMap === null) {
              break;
            }
            const verifiedState: FirstPageThumbnailState | null =
              await this.persistence.getFirstPageThumbnailState(noteId);
            const verifiedAssetGeneration: number = assetAvailabilityHub.getNoteGeneration(noteId);
            const verifiedRevision: string = verifiedState === null ? '' :
              this.thumbnailRevision(verifiedState, theme, verifiedAssetGeneration);
            if (generation !== this.thumbnailGeneration || lifecycleGeneration !== this.lifecycleGeneration ||
              !this.pageActive || renderer !== this.thumbRenderer) {
              await this.releaseThumbnailPixelMap(unpublishedPixelMap, 'stale verified generation');
              unpublishedPixelMap = null;
              return;
            }
            if (verifiedState !== null && isThumbnailSourceUnchanged(
              sourceState.page.pageId, revision, verifiedState.page.pageId, verifiedRevision)) {
              createdMaps.push(unpublishedPixelMap);
              newRevisions.set(noteId, revision);
              newMap.set(noteId, unpublishedPixelMap);
              unpublishedPixelMap = null;
              break;
            }
            await this.releaseThumbnailPixelMap(unpublishedPixelMap, 'source changed during render');
            unpublishedPixelMap = null;
            pageState = verifiedState;
          }
        } catch (e) {
          if (unpublishedPixelMap !== null) {
            await this.releaseThumbnailPixelMap(unpublishedPixelMap, 'render failure');
            unpublishedPixelMap = null;
          }
          console.error(`LibraryPage thumbnail failed note=${noteId}: ${JSON.stringify(e)}`);
          const oldPixelMap: PixelMap | undefined = oldMap.get(noteId);
          const oldRevision: string | undefined = oldRevisions.get(noteId);
          let sourceStillCurrent: boolean = false;
          try {
            const currentState: FirstPageThumbnailState | null =
              await this.persistence.getFirstPageThumbnailState(noteId);
            const currentRevision: string = currentState === null ? '' : this.thumbnailRevision(
              currentState, theme, assetAvailabilityHub.getNoteGeneration(noteId));
            sourceStillCurrent = currentState !== null && requestedPageId !== null && requestedRevision !== null &&
              isThumbnailSourceUnchanged(requestedPageId, requestedRevision,
                currentState.page.pageId, currentRevision);
          } catch (verificationError) {
            console.warn(`LibraryPage thumbnail failure verification failed note=${noteId}: ` +
              `${JSON.stringify(verificationError)}`);
          }
          if (generation === this.thumbnailGeneration && lifecycleGeneration === this.lifecycleGeneration &&
            this.pageActive && renderer === this.thumbRenderer && sourceStillCurrent &&
            oldPixelMap !== undefined && oldRevision === requestedRevision) {
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
        await this.releaseThumbnailPixelMap(pixelMap, 'discarded generation');
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
        this.releaseThumbnailPixelMap(entry[1], 'replaced cache entry');
      }
    }
  }

  private releaseThumbnails(thumbnails: Map<string, PixelMap>): void {
    for (const pixelMap of thumbnails.values()) {
      this.releaseThumbnailPixelMap(pixelMap, 'page release');
    }
  }

  private thumbnailRevision(pageState: FirstPageThumbnailState, theme: ThemeTokens,
    assetGeneration: number): string {
    return thumbnailCacheKey(pageState.revision,
      theme.paperBackground, theme.paperLineColor, assetGeneration);
  }

  private async releaseThumbnailPixelMap(pixelMap: PixelMap, reason: string): Promise<void> {
    try {
      await pixelMap.release();
    } catch (error) {
      console.warn(`LibraryPage thumbnail PixelMap release failed (${reason}): ${JSON.stringify(error)}`);
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
    const expectedLifecycleGeneration: number = this.lifecycleGeneration;
    this.thumbnailRequestTimer = setTimeout(() => {
      this.thumbnailRequestTimer = -1;
      if (!this.pageActive || this.lifecycleGeneration !== expectedLifecycleGeneration) {
        return;
      }
      this.refreshThumbnails().catch((e: Error) => {
        console.error(`visible thumbnail refresh failed: ${JSON.stringify(e)}`);
      });
    }, 50);
  }

  // T-039：文件夹操作
  private showCreateFolderDialog(parentId: string | null = null): void {
    if (!this.pageActive || this.folderBusy) {
      return;
    }
    this.folderDialogMode = 0;
    this.folderDialogTitle = $r('app.string.new_folder');
    this.folderDialogInitialText = '';
    this.folderDialogTargetId = '';
    this.folderDialogParentId = parentId;
    this.folderDialogColor = FOLDER_DEFAULT_COLOR;
    this.folderDialogEmoji = '';
    this.folderDialog.open();
  }

  private showRenameFolderDialog(folder: NoteFolder): void {
    if (!this.pageActive || this.folderBusy) {
      return;
    }
    this.folderDialogMode = 1;
    this.folderDialogTitle = $r('app.string.rename');
    this.folderDialogInitialText = folder.name;
    this.folderDialogTargetId = folder.id;
    this.folderDialogColor = folder.color;
    this.folderDialogEmoji = folder.emoji === null ? '' : folder.emoji;
    this.folderDialog.open();
  }

  private async onFolderDialogConfirm(name: string, color: number,
    emoji: string): Promise<boolean> {
    if (!this.pageActive) {
      return false;
    }
    const trimmed: string = name.trim();
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const repoCapture: FolderRepositoryImpl | null = this.folderRepo;
    if (this.folderRepo === null) {
      promptAction.showToast({ message: $r('app.string.folder_operation_failed') });
      return false;
    }
    if (repoCapture === null || this.folderBusy) {
      return false;
    }
    const repo: FolderRepositoryImpl = repoCapture;
    this.folderBusy = true;
    let result: FolderMutationResult | null = null;
    try {
      if (this.folderDialogMode === 0) {
        // 原版 id7.b：创建即提交所选颜色与可选 emoji。
        const created: FolderCreateResult = await repo.createFolder(trimmed,
          this.folderDialogParentId, color, emoji);
        result = created;
      } else if (this.folderDialogMode === 1) {
        // 原版 id7.l→beb.e：名称/颜色/emoji 单次提交，updated_at 必盖章。
        result = await repo.editFolder(this.folderDialogTargetId,
          { name: trimmed, color: color, emoji: emoji });
      } else {
        throw new Error(`unsupported folder dialog mode: ${this.folderDialogMode}`);
      }
    } catch (e) {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
        return false;
      }
      promptAction.showToast({ message: $r('app.string.folder_operation_failed') });
      console.error(`folder operation failed: ${JSON.stringify(e)}`);
      return false;
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return false;
    }
    if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
      this.folderRepo !== repo) {
      return true;
    }
    this.publishCommittedFolders(result.folders);
    this.reloadFoldersBestEffort(repo, 'folder create/rename');
    return true;
  }

  // 删除文件夹：内部笔记回根目录（不删笔记）
  private async deleteFolder(folderId: string): Promise<void> {
    if (!this.pageActive || this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const repo: FolderRepositoryImpl = this.folderRepo;
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    let result: FolderDeleteResult | null = null;
    try {
      result = await repo.deleteFolder(folderId);
    } catch (e) {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      promptAction.showToast({ message: $r('app.string.delete_folder_failed') });
      console.error(`delete folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
      this.folderRepo !== repo) {
      return;
    }
    this.publishCommittedFolders(result.folders);
    vm.publishCommittedFolderDelete(
      result.deletedFolderIds, result.movedNoteIds, result.notes, this.searchText);
    this.currentFolderId = vm.currentFolderId;
    this.currentSection = vm.currentSection;
    this.viewModel = vm;
    this.notes = vm.getFilteredNotes().slice();
    this.reloadFoldersBestEffort(repo, 'delete folder');
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`delete folder thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.reloadVisibleNotesAfterMutation(vm, 'delete folder');
  }

  private async moveFolder(folderId: string, parentId: string | null,
    insertIndex?: number): Promise<void> {
    if (!this.pageActive || this.folderRepo === null || this.folderBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const repo: FolderRepositoryImpl = this.folderRepo;
    this.folderBusy = true;
    let result: FolderMutationResult | null = null;
    try {
      result = await repo.moveFolder(folderId, parentId, insertIndex);
    } catch (e) {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      promptAction.showToast({ message: $r('app.string.move_folder_failed') });
      console.error(`move folder failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
      this.folderRepo !== repo) {
      return;
    }
    this.publishCommittedFolders(result.folders);
    this.reloadFoldersBestEffort(repo, 'move folder');
  }

  private orderedFolderSiblings(folder: NoteFolder): NoteFolder[] {
    const siblings: NoteFolder[] = this.folders.filter((candidate: NoteFolder): boolean =>
      candidate.parentId === folder.parentId);
    siblings.sort((left: NoteFolder, right: NoteFolder): number => {
      if (left.siblingOrder !== right.siblingOrder) {
        return left.siblingOrder - right.siblingOrder;
      }
      if (left.createdAt !== right.createdAt) {
        return left.createdAt - right.createdAt;
      }
      return left.id < right.id ? -1 : left.id > right.id ? 1 : 0;
    });
    return siblings;
  }

  private canMoveFolderBy(folder: NoteFolder, offset: number): boolean {
    const siblings: NoteFolder[] = this.orderedFolderSiblings(folder);
    const index: number = siblings.findIndex(
      (candidate: NoteFolder): boolean => candidate.id === folder.id);
    const target: number = index + offset;
    return index >= 0 && target >= 0 && target < siblings.length;
  }

  private moveFolderBy(folder: NoteFolder, offset: number): void {
    if (!this.pageActive || this.folderBusy) {
      return;
    }
    const siblings: NoteFolder[] = this.orderedFolderSiblings(folder);
    const index: number = siblings.findIndex(
      (candidate: NoteFolder): boolean => candidate.id === folder.id);
    const target: number = index + offset;
    if (index < 0 || target < 0 || target >= siblings.length) {
      return;
    }
    this.moveFolder(folder.id, folder.parentId, target).catch((e: Error) => {
      console.error(`move folder by index failed: ${JSON.stringify(e)}`);
    });
  }

  private clearFolderDrag(): void {
    this.folderDragVisibleIds = [];
    this.folderDragVisibleDepths = [];
    this.folderDragSourceIndex = -1;
    this.folderDragDepthAnchorX = 0;
    this.folderDragPreviewName = '';
  }

  private captureFolderDrag(event: ItemDragInfo, itemIndex: number): void {
    if (!this.pageActive || this.folderBusy) {
      this.clearFolderDrag();
      return;
    }
    const items: FolderListItem[] = this.folderListItems(false);
    this.folderDragVisibleIds = items.map((item: FolderListItem): string => item.folder.id);
    this.folderDragVisibleDepths = items.map((item: FolderListItem): number => item.depth);
    if (itemIndex < 0 || itemIndex >= this.folderDragVisibleIds.length) {
      this.clearFolderDrag();
      return;
    }
    this.folderDragSourceIndex = itemIndex;
    this.folderDragPreviewName = items[itemIndex].folder.name;
    const sourceDepth: number = this.folderDragVisibleDepths[itemIndex];
    this.folderDragDepthAnchorX = Number.isFinite(event.x) ?
      event.x - sourceDepth * ORIGINAL_FOLDER_DRAG_INDENT : -sourceDepth * ORIGINAL_FOLDER_DRAG_INDENT;
  }

  private finishFolderDrag(event: ItemDragInfo, insertIndex: number, isSuccess: boolean): void {
    if (!this.pageActive) {
      this.clearFolderDrag();
      return;
    }
    const visibleIds: string[] = this.folderDragVisibleIds.slice();
    const visibleDepths: number[] = this.folderDragVisibleDepths.slice();
    const sourceIndex: number = this.folderDragSourceIndex;
    const sourceDepth: number = sourceIndex >= 0 && sourceIndex < visibleDepths.length ?
      visibleDepths[sourceIndex] : 0;
    const requestedDepth: number = Number.isFinite(event.x) ?
      Math.floor((event.x - this.folderDragDepthAnchorX) / ORIGINAL_FOLDER_DRAG_INDENT) : sourceDepth;
    this.clearFolderDrag();
    if (!isSuccess || this.folderBusy || visibleIds.length === 0 || sourceIndex < 0) {
      return;
    }
    try {
      const intent: FolderDropIntent | null = resolveFolderDrop(
        this.folders, visibleIds, visibleDepths, sourceIndex, insertIndex, requestedDepth);
      if (intent === null) {
        return;
      }
      this.moveFolder(intent.folderId, intent.parentId, intent.insertIndex).catch((e: Error) => {
        console.error(`folder drag move failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      promptAction.showToast({ message: $r('app.string.move_folder_failed') });
      console.error(`resolve folder drag failed: ${JSON.stringify(e)}`);
    }
  }

  // 移动笔记到文件夹（null=根目录）
  private async moveNote(noteId: string, folderId: string | null): Promise<void> {
    if (!this.pageActive || this.folderRepo === null || this.viewModel === null || this.folderBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const repo: FolderRepositoryImpl = this.folderRepo;
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    let result: NoteFolderMoveResult | null = null;
    try {
      result = await repo.moveNoteToFolder(noteId, folderId);
    } catch (e) {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      promptAction.showToast({ message: $r('app.string.move_note_failed') });
      console.error(`move note failed: ${JSON.stringify(e)}`);
    } finally {
      this.folderBusy = false;
    }
    if (result === null) {
      return;
    }
    if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
      this.viewModel !== vm || this.thumbRenderer === null) {
      return;
    }
    // w09.g/h: the moved card keeps a live folder projection so the chip shows
    // the destination's name/color immediately (committed reload re-attaches).
    const movedFolderId: string | null = result.folderId;
    const targetFolder: NoteFolder | undefined = movedFolderId === null ? undefined :
      this.folders.find((folder: NoteFolder): boolean => folder.id === movedFolderId);
    vm.publishCommittedNoteMove(result.noteId, movedFolderId,
      targetFolder === undefined ? null : targetFolder.name,
      targetFolder === undefined ? null : targetFolder.color);
    this.viewModel = vm;
    this.notes = vm.getFilteredNotes().slice();
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`move note thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.reloadVisibleNotesAfterMutation(vm, 'move note');
  }

  // Original setFavorite (modifyNote{isFavorited} / d5j menu): the VM mutation
  // owns the partial write; the card list updates in place on success.
  private toggleNoteFavorite(note: NoteMeta): void {
    if (!this.pageActive || this.viewModel === null) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    vm.toggleFavorite(note.id).then(() => {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
    }).catch((e: Error) => {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        console.error(`toggle favorite failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original d5j Rename → opens the shared name dialog (no decoration area).
  private showRenameNoteDialog(note: NoteMeta): void {
    if (!this.pageActive) {
      return;
    }
    this.noteDialogNoteId = note.id;
    this.noteDialogInitialText = note.title;
    this.noteDialog.open();
  }

  private onRenameNoteConfirm(name: string): Promise<boolean> {
    if (!this.pageActive || this.viewModel === null || this.noteDialogNoteId.length === 0) {
      return Promise.resolve(false);
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    return vm.renameNote(this.noteDialogNoteId, name.trim()).then(() => {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return true;
      }
      this.notes = vm.getFilteredNotes().slice();
      return true;
    }).catch((e: Error) => {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.rename_failed') });
        console.error(`rename note failed: ${JSON.stringify(e)}`);
      }
      return false;
    });
  }

  // Original d5j Duplicate: a full-fidelity copy via the lossless package
  // round-trip (exportNote bytes → importFromData allocates a fresh note id).
  private duplicateNote(note: NoteMeta): void {
    if (!this.pageActive || this.viewModel === null) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const exporter: NoteExporter = new NoteExporter(this.db, this.persistence);
    const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
    exporter.exportNote(note.id).then(async (data: Uint8Array | null) => {
      if (data === null) {
        throw new Error('exportNote returned null');
      }
      const report: ImportReport = await importer.importFromData(data);
      if (report.noteId === null) {
        throw new Error(`duplicate import failed: ${report.message}`);
      }
    }).then(() => {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      vm.loadNotes(this.searchText).then(() => {
        if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration &&
          this.viewModel === vm) {
          this.notes = vm.getFilteredNotes().slice();
        }
      }).catch((e: Error) => {
        console.error(`post-duplicate reload failed: ${JSON.stringify(e)}`);
      });
      promptAction.showToast({ message: $r('app.string.note_duplicated') });
    }).catch((e: Error) => {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.duplicate_failed') });
        console.error(`duplicate note failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original d5j Export: single-note .note package via the existing exporter.
  private exportNote(note: NoteMeta): void {
    if (!this.pageActive) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const context = getContext(this) as common.UIAbilityContext;
    const exporter: NoteExporter = new NoteExporter(this.db, this.persistence);
    exporter.exportToFile(context, note.id, note.title).then((success: boolean) => {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      promptAction.showToast({
        message: success ? $r('app.string.export_done') : $r('app.string.export_failed'),
      });
    }).catch((e: Error) => {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.export_failed') });
        console.error(`export note failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original d5j Show in folder: navigate into the containing folder.
  private showNoteInFolder(note: NoteMeta): void {
    if (!this.pageActive || this.viewModel === null || note.folderId === null) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    vm.showNoteInFolder(note, this.searchText).then(() => {
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      this.currentFolderId = vm.currentFolderId;
      this.currentSection = vm.currentSection;
      this.notes = vm.getFilteredNotes().slice();
    }).catch((e: Error) => {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        console.error(`show in folder failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // Original d5j Copy note ID: copies the stable note identity to the
  // system pasteboard.
  private copyNoteId(note: NoteMeta): void {
    if (!this.pageActive) {
      return;
    }
    try {
      const data: pasteboard.PasteData =
        pasteboard.createPlainTextData(note.id);
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        if (this.pageActive) {
          promptAction.showToast({ message: $r('app.string.note_id_copied') });
        }
      }).catch((e: BusinessError) => {
        if (this.pageActive) {
          console.error(`copy note id failed: ${JSON.stringify(e)}`);
        }
      });
    } catch (e) {
      console.error(`copy note id failed: ${JSON.stringify(e)}`);
    }
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
    if (!this.pageActive || this.folderBusy) {
      return;
    }
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
    if (!this.pageActive || this.folderBusy) {
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
    if (!this.pageActive || this.viewModel === null || this.folderBusy) {
      return;
    }
    const query: string = this.searchText;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const notesRequestGeneration: number = this.beginNotesRequest();
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    this.currentFolderId = folderId;
    try {
      await vm.setFolder(folderId, query);
      this.currentSection = vm.currentSection;
      if (!this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId,
        lifecycleGeneration)) {
        return;
      }
      this.initError = '';
      this.hasInitError = false;
      this.viewModel = vm;
      this.notes = vm.getFilteredNotes().slice();
      await this.refreshThumbnails();
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId,
        lifecycleGeneration)) {
        this.closeCompactFolderDrawer();
      }
    } catch (e) {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, folderId,
        lifecycleGeneration)) {
        this.currentFolderId = vm.currentFolderId;
        this.currentSection = vm.currentSection;
        promptAction.showToast({ message: $r('app.string.load_notes_failed') });
        console.error(`select folder failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.folderBusy = false;
    }
  }

  // Original dk9 chip selection (ua5.java:227): a section replaces the folder
  // view — selecting one clears the folder selection and vice versa.
  private async selectSection(section: LibrarySection): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.folderBusy) {
      return;
    }
    const query: string = this.searchText;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const notesRequestGeneration: number = this.beginNotesRequest();
    const vm: LibraryViewModel = this.viewModel;
    this.folderBusy = true;
    this.currentFolderId = null;
    this.currentSection = section;
    try {
      await vm.setSection(section, query);
      this.currentSection = vm.currentSection;
      if (!this.isCurrentNotesRequest(notesRequestGeneration, vm, query, null,
        lifecycleGeneration)) {
        return;
      }
      this.initError = '';
      this.hasInitError = false;
      this.viewModel = vm;
      this.notes = vm.getFilteredNotes().slice();
      await this.refreshThumbnails();
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, null,
        lifecycleGeneration)) {
        this.closeCompactFolderDrawer();
      }
    } catch (e) {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query, null,
        lifecycleGeneration)) {
        this.currentFolderId = vm.currentFolderId;
        this.currentSection = vm.currentSection;
        promptAction.showToast({ message: $r('app.string.load_notes_failed') });
        console.error(`select section failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.folderBusy = false;
    }
  }

  // T-035：排序切换 + Preferences 持久化
  private setSortMode(mode: NoteSortMode): void {
    if (!this.pageActive || this.viewModel === null) {
      return;
    }
    this.viewModel.setSortMode(mode);
    this.notes = this.viewModel.getFilteredNotes().slice();
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`sort thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.persistSortPreferences();
  }

  // Original inh.b: the arrow button beside the field chip toggles je7
  // between ASCENDING and DESCENDING without opening the dropdown.
  private toggleSortDirection(): void {
    if (this.viewModel !== null) {
      this.setSortDescending(!this.viewModel.sortDescending);
    }
  }

  private persistSortPreferences(): void {
    if (this.viewModel === null) {
      return;
    }
    const mode: NoteSortMode = this.viewModel.sortMode;
    const descending: boolean = this.viewModel.sortDescending;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
          return;
        }
        pref.putSync(this.PREF_SORT_KEY, mode);
        pref.putSync(this.PREF_SORT_DIR_KEY, descending ? 1 : 0);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save sort pref flush failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save sort pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`persistSortPreferences failed: ${JSON.stringify(e)}`);
    }
  }

  // Original yj9:852 — "Search in {folderName}" placeholder while a
  // folder is selected.
  private searchPlaceholder(): Resource {
    const folder: NoteFolder | null = this.currentFolder();
    if (this.currentFolderId !== null && folder !== null) {
      return $r('app.string.search_in_folder', folder.name);
    }
    return $r('app.string.search_notes');
  }

  // Original bk9 toggle: widen a folder-scoped search to all notes.
  private setSearchAllNotes(on: boolean): void {
    const vm: LibraryViewModel | null = this.viewModel;
    if (!this.pageActive || vm === null) {
      return;
    }
    const query: string = this.searchText;
    const folderId: string | null = vm.currentFolderId;
    const notesRequestGeneration: number = this.beginNotesRequest();
    const lifecycleGeneration: number = this.lifecycleGeneration;
    vm.setSearchAllNotes(on, query).then(() => {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query,
        folderId, lifecycleGeneration)) {
        this.notes = vm.getFilteredNotes().slice();
        return this.refreshThumbnails();
      }
      return Promise.resolve();
    }).catch((e: Error) => {
      if (this.isCurrentNotesRequest(notesRequestGeneration, vm, query,
        folderId, lifecycleGeneration)) {
        console.error(`search-all toggle failed: ${JSON.stringify(e)}`);
        promptAction.showToast({ message: $r('app.string.search_failed') });
      }
    });
  }

  // Original inh.d: icon button dispatches the opposite ie7 mode; the
  // icon depicts the target mode (zy7 case 20: grid_view / list_bullet).
  private toggleViewMode(): void {
    if (!this.pageActive) {
      return;
    }
    this.listView = !this.listView;
    const listView: boolean = this.listView;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
          return;
        }
        pref.putSync(this.PREF_VIEW_MODE_KEY, listView ? 1 : 0);
        pref.flush().catch((e: BusinessError) => {
          console.error(`save view mode pref flush failed: ${e.code}`);
        });
      }).catch((e: BusinessError) => {
        console.error(`save view mode pref failed: ${e.code}`);
      });
    } catch (e) {
      console.error(`toggleViewMode failed: ${JSON.stringify(e)}`);
    }
  }

  // Original inh.b chip label: the current he7 field name.
  private sortFieldLabel(): Resource {
    if (this.viewModel === null) {
      return $r('app.string.sort');
    }
    if (this.viewModel.sortMode === NoteSortMode.TITLE) {
      return $r('app.string.sort_name');
    }
    if (this.viewModel.sortMode === NoteSortMode.CREATED) {
      return $r('app.string.sort_created_date');
    }
    return $r('app.string.sort_modified_date');
  }

  // Original vc2 direction rows: labels depend on the field —
  // NAME → "A to Z"/"Z to A"; date fields → "Oldest to Newest"/"Newest to Oldest".
  private sortDirectionLabels(): Resource[] {
    if (this.viewModel !== null && this.viewModel.sortMode === NoteSortMode.TITLE) {
      return [$r('app.string.sort_a_to_z'), $r('app.string.sort_z_to_a')];
    }
    return [$r('app.string.sort_oldest_to_newest'), $r('app.string.sort_newest_to_oldest')];
  }

  private buildSortMenuItems(): MenuElement[] {
    const directions: Resource[] = this.sortDirectionLabels();
    return [
      { value: $r('app.string.sort_name'), action: () => { this.setSortMode(NoteSortMode.TITLE); } },
      { value: $r('app.string.sort_created_date'), action: () => { this.setSortMode(NoteSortMode.CREATED); } },
      { value: $r('app.string.sort_modified_date'), action: () => { this.setSortMode(NoteSortMode.UPDATED); } },
      { value: directions[0], action: () => { this.setSortDescending(false); } },
      { value: directions[1], action: () => { this.setSortDescending(true); } },
    ];
  }

  private setSortDescending(descending: boolean): void {
    if (!this.pageActive || this.viewModel === null) {
      return;
    }
    this.viewModel.setSortDescending(descending);
    this.notes = this.viewModel.getFilteredNotes().slice();
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`sort thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    this.persistSortPreferences();
  }

  private async initData(expectedLifecycleGeneration: number = this.lifecycleGeneration): Promise<void> {
    this.initError = '';
    this.hasInitError = false;
    if (this.notes.length === 0) {
      this.libraryLoading = true;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const renderer: ThumbnailRenderer = this.thumbRenderer;
      const pref: preferences.Preferences =
        await preferences.getPreferences(context, THEME_PREFERENCES_NAME);
      if (!this.pageActive || expectedLifecycleGeneration !== this.lifecycleGeneration ||
        renderer !== this.thumbRenderer) {
        return;
      }
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
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
      this.currentSection = vm.currentSection;
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
      // 恢复排序偏好（original z97: field + direction, both defaulting to
      // MODIFIED_DATE/DESCENDING）
      const saved: number = pref.getSync(this.PREF_SORT_KEY, 0) as number;
      vm.sortMode = saved as NoteSortMode;
      const savedDir: number = pref.getSync(this.PREF_SORT_DIR_KEY, 1) as number;
      vm.sortDescending = savedDir !== 0;
      this.listView = (pref.getSync(this.PREF_VIEW_MODE_KEY, 0) as number) === 1;
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
      this.currentSection = vm.currentSection;
      this.notes = vm.getFilteredNotes().slice();
      this.libraryLoading = false;
      await this.refreshThumbnails();
      if (!this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer) ||
        !this.isCurrentNotesRequest(initialNotesRequestGeneration, vm, initialQuery, initialFolderId)) {
        return;
      }
      this.persistence.backfillSearchIndex().then(() => {
        if (!this.isCurrentLifecycle(expectedLifecycleGeneration, vm, renderer)) {
          return;
        }
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
      console.error(`LibraryPage init failed: ${JSON.stringify(e)}`);
      if (!this.pageActive || expectedLifecycleGeneration !== this.lifecycleGeneration) {
        return;
      }
      this.libraryLoading = false;
      this.initError = $r('app.string.library_load_failed');
      this.hasInitError = true;
      promptAction.showToast({ message: $r('app.string.library_load_retry') });
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
    if (!this.pageActive) {
      return;
    }
    ThemeStore.setMode(mode);
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`theme thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
    const lifecycleGeneration: number = this.lifecycleGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      preferences.getPreferences(context, THEME_PREFERENCES_NAME).then((pref: preferences.Preferences) => {
        if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration) {
          return;
        }
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
          // 原版文件夹装饰互斥（wm2：选 Color 清 emoji）——行内 emoji 优先，
          // 否则渲染具体颜色点（w09.folderColor / pdb.f()）。
          if (item.folder.emoji !== null) {
            Text(item.folder.emoji)
              .fontSize(15)
              .margin({ right: 8 })
          } else {
            Circle()
              .width(10)
              .height(10)
              .fill(item.folder.color)
              .margin({ right: 8 })
          }
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
    .padding({ left: item.depth * ORIGINAL_FOLDER_DRAG_INDENT, right: 4 })
  }

  @Builder
  FolderDragPreview() {
    Row() {
      Text(this.folderDragPreviewName)
        .layoutWeight(1)
        .maxLines(1)
        .fontSize(15)
        .fontColor(this.resolveTokens().textPrimary)
        .fontWeight(FontWeight.Medium)
    }
    .width(240)
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(8)
    .shadow({ radius: 8, color: this.resolveTokens().shadow, offsetY: 4 })
  }

  // Original dk9 section row (ua5 chip selection): selected when no folder is
  // active and the section matches; tap swaps the folder view for the section.
  @Builder
  SectionNavRow(label: Resource, section: LibrarySection, edgePadding: number) {
    Button() {
      Row() {
        Text(label)
          .layoutWeight(1)
          .fontSize(15)
          .fontColor(this.currentFolderId === null && this.currentSection === section ?
            this.resolveTokens().accent : this.resolveTokens().textPrimary)
          .fontWeight(this.currentFolderId === null && this.currentSection === section ?
            FontWeight.Medium : FontWeight.Normal)
        if (this.currentFolderId === null && this.currentSection === section) {
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
    .padding({ left: edgePadding, right: edgePadding })
    .enabled(!this.folderBusy)
    .backgroundColor(this.currentFolderId === null && this.currentSection === section ?
      this.resolveTokens().control : this.resolveTokens().surface)
    .onClick(() => {
      this.selectSection(section);
    })
  }

  @Builder
  FolderNavigationList() {
    List({ space: 0 }) {
      ForEach(this.folderListItems(false), (item: FolderListItem) => {
        ListItem() {
          this.FolderNavigationRow(item)
        }
        .width('100%')
        .height(48)
      }, (item: FolderListItem) => item.folder.id)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .scrollBar(BarState.Auto)
    .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
      this.captureFolderDrag(event, itemIndex);
      if (this.folderDragSourceIndex < 0) {
        return;
      }
      return this.FolderDragPreview;
    })
    .onItemDrop((event: ItemDragInfo, _itemIndex: number, insertIndex: number,
      isSuccess: boolean) => {
      this.finishFolderDrag(event, insertIndex, isSuccess);
    })
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

          this.SectionNavRow($r('app.string.all_notes'), LibrarySection.ALL_NOTES, 16)
          this.SectionNavRow($r('app.string.recent_notes'), LibrarySection.RECENT, 16)
          this.SectionNavRow($r('app.string.favorite_notes'), LibrarySection.FAVORITES, 16)
          this.SectionNavRow($r('app.string.unfiled'), LibrarySection.UNFILED, 16)

          this.FolderNavigationList()

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
          this.SectionNavRow($r('app.string.all_notes'), LibrarySection.ALL_NOTES, 8)
          this.SectionNavRow($r('app.string.recent_notes'), LibrarySection.RECENT, 8)
          this.SectionNavRow($r('app.string.favorite_notes'), LibrarySection.FAVORITES, 8)
          this.SectionNavRow($r('app.string.unfiled'), LibrarySection.UNFILED, 8)
          this.FolderNavigationList()
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
          // Original yj9:852 — placeholder is "Search in {folder}" while a
          // folder is selected, plain "Search" otherwise.
          TextInput({ placeholder: this.searchPlaceholder() })
            .layoutWeight(1)
            .height(40)
            .fontColor(this.resolveTokens().textPrimary)
            .placeholderColor(this.resolveTokens().textSecondary)
            .backgroundColor(this.resolveTokens().surface)
            .onChange((value: string) => {
              if (!this.pageActive) {
                return;
              }
              this.searchText = value;
              const notesRequestGeneration: number = this.beginNotesRequest();
              if (this.searchTimer >= 0) {
                clearTimeout(this.searchTimer);
              }
              this.searchTimer = setTimeout(() => {
                this.searchTimer = -1;
                const lifecycleGeneration: number = this.lifecycleGeneration;
                const vm: LibraryViewModel | null = this.viewModel;
                if (vm === null || !this.pageActive ||
                  lifecycleGeneration !== this.lifecycleGeneration ||
                  notesRequestGeneration !== this.notesRequestGeneration ||
                  this.searchText !== value) {
                  return;
                }
                const folderId: string | null = vm.currentFolderId;
                vm.setSearchQuery(value).then(() => {
                  if (this.isCurrentNotesRequest(notesRequestGeneration, vm, value, folderId, lifecycleGeneration)) {
                    this.viewModel = vm;
                    this.currentFolderId = vm.currentFolderId;
                    this.currentSection = vm.currentSection;
                    this.notes = vm.getFilteredNotes().slice();
                    this.libraryLoading = false;
                    return this.refreshThumbnails();
                  }
                  return Promise.resolve();
                }).catch((e: Error) => {
                  if (this.isCurrentNotesRequest(notesRequestGeneration, vm, value, folderId, lifecycleGeneration)) {
                    console.error(`search notes failed: ${JSON.stringify(e)}`);
                    this.libraryLoading = false;
                    promptAction.showToast({ message: $r('app.string.search_failed') });
                  }
                });
              }, 180);
            })
          if (this.showSidebar) {
            // Original inh.b: field chip (opens the he7 dropdown) + a
            // direction arrow button toggling je7 directly.
            Button(this.sortFieldLabel())
              .height(40)
              .fontSize(13)
              .margin({ left: 8 })
              .accessibilityText($r('app.string.sort'))
              .bindMenu(this.buildSortMenuItems())
            Button(this.viewModel !== null && this.viewModel.sortDescending ? '↓' : '↑')
              .height(40)
              .fontSize(13)
              .accessibilityText($r('app.string.sort'))
              .onClick(() => {
                this.toggleSortDirection();
              })
            // Original inh.d: the icon depicts the target mode
            // (grid mode shows list_bullet, list mode shows grid_view).
            Button(this.listView ? '⊞' : '☰')
              .width(40)
              .height(40)
              .fontSize(15)
              .accessibilityText(this.listView ?
                $r('app.string.grid_view') : $r('app.string.list_view'))
              .onClick(() => {
                this.toggleViewMode();
              })
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

        // Original bk9/mhh + yj9 folder-filter-toggle: while a folder
        // search is active, a "Search all notes" switch widens the scope.
        if (this.currentFolderId !== null && this.searchText.trim().length > 0) {
          Row() {
            Text($r('app.string.search_show_all_notes'))
              .fontSize(13)
              .fontColor(this.resolveTokens().textPrimary)
              .layoutWeight(1)
            Toggle({ type: ToggleType.Switch,
              isOn: this.viewModel !== null && this.viewModel.searchAllNotes })
              .onChange((on: boolean) => {
                this.setSearchAllNotes(on);
              })
          }
          .width('100%')
          .height(36)
          .padding({ left: 16, right: 16 })
        }

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
                if (!this.pageActive) {
                  return;
                }
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
            // 空结果提示（T-035）；原版 FAVORITES 有专属空态
            // （empty_favorite_notes_title/body）。
            Column() {
              if (this.currentFolderId === null &&
                this.currentSection === LibrarySection.FAVORITES) {
                Text($r('app.string.empty_favorite_notes_title'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textSecondary)
                Text($r('app.string.empty_favorite_notes_body'))
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textSecondary)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 8, left: 24, right: 24 })
              } else {
                Text($r('app.string.no_matching_notes'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textSecondary)
              }
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            // Original yj9: ie7.GRID renders b5j.b cards in a grid;
            // ie7.LIST renders m5j.b compact rows in a column list.
            if (this.listView) {
              List() {
                ForEach(this.notes, (note: NoteMeta) => {
                  ListItem() {
                    this.NoteListRow(note)
                  }
                }, (note: NoteMeta) => note.id)
              }
              .padding({ left: 16, right: 16 })
              .layoutWeight(1)
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
    Column() {
      // Original mw3 case 0: expanded speed-dial lists the creation actions
      // in original order — record audio, import file (scan/capture not
      // portable); "New note" leads as the card-body blank-create equivalent.
      if (this.createMenuOpen) {
        this.CreateActionChip($r('app.string.new_note'), () => {
          this.createAndOpen().catch((e: Error) => {
            console.error(`create note action failed: ${JSON.stringify(e)}`);
          });
        })
        this.CreateActionChip($r('app.string.record_audio'), () => {
          this.createAndRecord().catch((e: Error) => {
            console.error(`create recording note failed: ${JSON.stringify(e)}`);
          });
        })
        this.CreateActionChip($r('app.string.import_note_file'), () => {
          this.importAndOpen().catch((e: Error) => {
            console.error(`import note action failed: ${JSON.stringify(e)}`);
          });
        })
      }
      Button() {
        Text(this.createMenuOpen ? '×' : '+')
          .fontSize(28)
          .width('100%')
          .height('100%')
          .textAlign(TextAlign.Center)
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .margin({ top: 8 })
      .enabled(!this.createBusy)
      .onClick(() => {
        this.createMenuOpen = !this.createMenuOpen;
      })
    }
    .margin({ right: 24, bottom: 24 })
  }

  @Builder
  CreateActionChip(label: ResourceStr, action: () => void) {
    Button() {
      Text(label)
        .fontSize(14)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontColor(this.resolveTokens().textPrimary)
    }
    .height(36)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(18)
    .margin({ bottom: 8 })
    .enabled(!this.createBusy)
    .onClick(() => {
      this.createMenuOpen = false;
      action();
    })
  }

  @Builder
  NoteCard(note: NoteMeta) {
    Column() {
      // 缩略图（T-035：@State thumbIds 驱动；无缩略图时灰色占位）
      Stack({ alignContent: Alignment.TopEnd }) {
        if (this.thumbIds.indexOf(note.id) >= 0) {
          Image(this.thumbMap.get(note.id))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .backgroundColor(this.resolveTokens().control)
            .borderRadius(8)
        } else {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.resolveTokens().control)
            .borderRadius(8)
        }
        // pf9.java: w09.favorited renders the favorite_fill badge overlay.
        if (note.favorite) {
          Text('♥')
            .fontSize(16)
            .fontColor(this.resolveTokens().accent)
            .margin({ top: 6, right: 6 })
            .accessibilityText($r('app.string.favorite_notes'))
        }
      }
      .width('100%')
      .layoutWeight(1)
      Text(note.title)
        .fontSize(14)
        .maxLines(1)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 8 })
      // Original gb6.b0/c0: RECENT cards show lastOpened, others updatedAt.
      Text(this.formatTime(this.currentFolderId === null &&
        this.currentSection === LibrarySection.RECENT ? note.lastOpened : note.updatedAt))
        .fontSize(12)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 2 })
      // Original cti.c trailing row: folder chip (e5j.b -> i2j.b solid color
      // pill) when w09.g/h are non-null, plus the recordings mic (w09.l ->
      // record_mic_outline).
      Row() {
        if (note.folderName !== null && note.folderColor !== null) {
          Text(note.folderName)
            .fontSize(10)
            .maxLines(1)
            .fontColor(this.folderChipTextColor(note.folderColor))
            .backgroundColor(this.folderChipColor(note.folderColor))
            .borderRadius(4)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
        }
        if (note.hasRecordings) {
          Text('🎙')
            .fontSize(10)
            .margin({ left: 4 })
            .accessibilityText($r('app.string.recordings'))
        }
      }
      .margin({ top: 4 })
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
      if (!this.pageActive) {
        return;
      }
      router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: note.id } })
        .catch((err: BusinessError) => {
          console.error(`pushUrl failed: ${err.code}`);
        });
    })
    .bindContextMenu(() => {
      this.NoteContextMenu(note)
    }, ResponseType.LongPress)
  }

  // Original m5j.b: ie7.LIST renders a compact horizontal row — small
  // thumbnail, then title/date/chip column; same open + long-press
  // context-menu behavior as the grid card.
  @Builder
  NoteListRow(note: NoteMeta) {
    Row() {
      Stack({ alignContent: Alignment.TopEnd }) {
        if (this.thumbIds.indexOf(note.id) >= 0) {
          Image(this.thumbMap.get(note.id))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .backgroundColor(this.resolveTokens().control)
            .borderRadius(6)
        } else {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(this.resolveTokens().control)
            .borderRadius(6)
        }
        if (note.favorite) {
          Text('♥')
            .fontSize(12)
            .fontColor(this.resolveTokens().accent)
            .margin({ top: 2, right: 2 })
            .accessibilityText($r('app.string.favorite_notes'))
        }
      }
      .width(48)
      .height(64)
      Column() {
        Text(note.title)
          .fontSize(14)
          .maxLines(1)
          .fontColor(this.resolveTokens().textPrimary)
        Text(this.formatTime(this.currentFolderId === null &&
          this.currentSection === LibrarySection.RECENT ? note.lastOpened : note.updatedAt))
          .fontSize(12)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ top: 2 })
        Row() {
          if (note.folderName !== null && note.folderColor !== null) {
            Text(note.folderName)
              .fontSize(10)
              .maxLines(1)
              .fontColor(this.folderChipTextColor(note.folderColor))
              .backgroundColor(this.folderChipColor(note.folderColor))
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          }
          if (note.hasRecordings) {
            Text('🎙')
              .fontSize(10)
              .margin({ left: 4 })
              .accessibilityText($r('app.string.recordings'))
          }
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.resolveTokens().surface)
    .margin({ top: 8 })
    .onVisibleAreaChange([0.0, 0.01], (isVisible: boolean) => {
      if (isVisible) {
        this.requestVisibleThumbnail(note.id);
      }
    })
    .onClick(() => {
      if (!this.pageActive) {
        return;
      }
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
    if (!this.pageActive || this.deleteBusy) {
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
  // Original d5j menu order: Rename → Favorite/Unfavorite → Duplicate →
  // Export → Show in folder → Sort to folder → Copy note ID → Delete.
  // (export_options / open_in_new_window / report_note are not portable —
  // registered in ADR-0513.)
  @Builder
  NoteContextMenu(note: NoteMeta) {
    Menu() {
      MenuItem({ content: $r('app.string.rename') })
        .onClick(() => {
          this.showRenameNoteDialog(note);
        })
      MenuItem({
        content: note.favorite ? $r('app.string.unfavorite_note') :
          $r('app.string.favorite_note')
      })
        .onClick(() => {
          this.toggleNoteFavorite(note);
        })
      MenuItem({ content: $r('app.string.duplicate_note') })
        .onClick(() => {
          this.duplicateNote(note);
        })
      MenuItem({ content: $r('app.string.export_note') })
        .onClick(() => {
          this.exportNote(note);
        })
      MenuItem({ content: $r('app.string.show_in_folder') })
        .enabled(note.folderId !== null)
        .onClick(() => {
          this.showNoteInFolder(note);
        })
      MenuItem({
        content: $r('app.string.move_to_folder'),
        builder: () => {
          this.MoveNoteSubMenu(note)
        },
      })
      MenuItem({ content: $r('app.string.copy_note_id') })
        .onClick(() => {
          this.copyNoteId(note);
        })
      MenuItem({ content: $r('app.string.delete') })
        .onClick(() => {
          this.confirmDelete(note);
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
      if (this.canMoveFolderBy(folder, -1)) {
        items.push({ value: $r('app.string.move_folder_up'), action: () => { this.moveFolderBy(folder, -1); } });
      }
      if (this.canMoveFolderBy(folder, 1)) {
        items.push({ value: $r('app.string.move_folder_down'), action: () => { this.moveFolderBy(folder, 1); } });
      }
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
    if (this.canMoveFolderBy(folder, -1)) {
      items.push({ value: $r('app.string.move_folder_up'), action: () => { this.moveFolderBy(folder, -1); } });
    }
    if (this.canMoveFolderBy(folder, 1)) {
      items.push({ value: $r('app.string.move_folder_down'), action: () => { this.moveFolderBy(folder, 1); } });
    }
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
    const items: MenuElement[] = this.buildSortMenuItems();
    items.push(
      { value: this.listView ? $r('app.string.grid_view') : $r('app.string.list_view'),
        action: () => { this.toggleViewMode(); } },
      { value: $r('app.string.follow_system'), action: () => { this.setThemeMode('system'); } },
      { value: $r('app.string.light_theme'), action: () => { this.setThemeMode('light'); } },
      { value: $r('app.string.dark_theme'), action: () => { this.setThemeMode('dark'); } },
      { value: $r('app.string.settings'), action: () => { this.navigateToSettings(); } },
    );
    return items;
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
    if (!this.pageActive || this.folderBusy) {
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
    if (this.currentFolderId === null) {
      if (this.currentSection === LibrarySection.RECENT) {
        return $r('app.string.recent_notes');
      }
      if (this.currentSection === LibrarySection.FAVORITES) {
        return $r('app.string.favorite_notes');
      }
      if (this.currentSection === LibrarySection.UNFILED) {
        return $r('app.string.unfiled');
      }
      return $r('app.string.all_notes');
    }
    for (const f of this.folders) {
      if (f.id === this.currentFolderId) {
        return f.name;
      }
    }
    return $r('app.string.all_notes');
  }

  private async deleteNoteAndRefresh(noteId: string): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.deleteBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.deleteBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      await vm.deleteNote(noteId);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      this.viewModel = vm;
      this.notes = vm.getFilteredNotes().slice();
    } catch (e) {
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
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
    await this.createAndLaunch(false);
  }

  // Original empty_note__record_audio: creates a note and opens the editor
  // straight into an active recording capture.
  private async createAndRecord(): Promise<void> {
    await this.createAndLaunch(true);
  }

  private async createAndLaunch(autoRecord: boolean): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    let noteId: string;
    try {
      noteId = await vm.createNote(this.searchText);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        this.createBusy = false;
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
    } catch (e) {
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        this.createBusy = false;
        return;
      }
      promptAction.showToast({ message: $r('app.string.create_note_failed') });
      console.error(`create note failed: ${JSON.stringify(e)}`);
      this.createBusy = false;
      return;
    }
    this.reloadVisibleNotesAfterMutation(vm, 'create note');
    try {
      if (autoRecord) {
        await router.pushUrl({ url: 'ui/editor/NotePage',
          params: { noteId: noteId, autoRecord: '1' } });
      } else {
        await router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: noteId } });
      }
    } catch (e) {
      console.error(`open created note failed: ${JSON.stringify(e)}`);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      promptAction.showToast({ message: $r('app.string.created_note_open_failed') });
    } finally {
      this.createBusy = false;
    }
  }

  // Original empty_note__import_file: system document picker → .note import
  // → open the imported note (scan/capture actions have no portable backend).
  private async importAndOpen(): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
      const report: ImportReport = await importer.importFromFile(context);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      if (report.noteId === null) {
        if (report.result !== ImportResult.CANCELLED) {
          promptAction.showToast({ message: $r('app.string.import_failed') });
        }
        return;
      }
      await vm.loadNotes(this.searchText);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
      const openedId: string = report.noteId;
      await router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: openedId } });
    } catch (e) {
      if (lifecycleGeneration === this.lifecycleGeneration && this.pageActive) {
        promptAction.showToast({ message: $r('app.string.import_failed') });
        console.error(`import note failed: ${JSON.stringify(e)}`);
      }
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

  // Original i2j.b: the folder chip fills with the folder color — stored as a
  // (possibly signed) ARGB int, normalized to a #AARRGGBB resource string.
  private folderChipColor(color: number): string {
    return `#${(color >>> 0).toString(16).padStart(8, '0').toUpperCase()}`;
  }

  // The original chip text inherits the default style color (are.Q has none);
  // a luminance split keeps the label readable across the whole palette.
  private folderChipTextColor(color: number): string {
    const argb: number = color >>> 0;
    const r: number = (argb >> 16) & 0xFF;
    const g: number = (argb >> 8) & 0xFF;
    const b: number = argb & 0xFF;
    const luminance: number = 0.299 * r + 0.587 * g + 0.114 * b;
    return luminance >= 150 ? '#DE000000' : '#FFFFFFFF';
  }
}

// T-039：名称输入对话框（@CustomDialog 原生）
@CustomDialog
struct NameDialog {
  controller?: CustomDialogController;
  title: ResourceStr = '';
  initialText: string = '';
  initialColor: number = FOLDER_DEFAULT_COLOR;
  initialEmoji: string = '';
  // 原版 gaj：装饰页签仅在 flag 开启（文件夹场景）出现；笔记重命名复用同一
  // 对话框但不含装饰区。
  showDecoration: boolean = false;
  @State inputText: string = '';
  @State selectedColor: number = FOLDER_DEFAULT_COLOR;
  @State selectedEmoji: string = '';
  // 原版 hq4 装饰页签：0 = Color，1 = Emoji；gaj.fsi.T：已有 emoji 时落在
  // Emoji 页，否则 Color 页。
  @State decorationTab: number = 0;
  @State emojiCategory: number = 0;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onConfirm: (name: string, color: number, emoji: string) => Promise<boolean> =
    async (_name: string, _color: number, _emoji: string): Promise<boolean> => false;

  aboutToAppear(): void {
    this.inputText = this.initialText;
    this.selectedColor = this.initialColor;
    this.selectedEmoji = this.initialEmoji;
    this.decorationTab = this.initialEmoji.length > 0 ? 1 : 0;
  }

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // 原版 q31 页签行 + wm2：切到 Color 页会清空已选 emoji（装饰互斥）。
  @Builder
  private decorationTabButton(tab: number, label: ResourceStr): void {
    Text(label)
      .fontSize(13)
      .fontColor(this.decorationTab === tab ? this.resolveTokens().textPrimary :
        this.resolveTokens().textSecondary)
      .fontWeight(this.decorationTab === tab ? FontWeight.Medium : FontWeight.Normal)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.decorationTab === tab ? this.resolveTokens().control :
        this.resolveTokens().surface)
      .borderRadius(14)
      .margin({ right: 8 })
      .onClick(() => {
        if (tab === 0) {
          this.selectedEmoji = '';
        }
        this.decorationTab = tab;
      })
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
      // 原版文件夹对话框（gaj）：名称 + hq4 装饰页签（Color|Emoji，flag 门控）
      // + 分页内容——Color 页为调色板，Emoji 页为 du3 九类分类网格。
      if (this.showDecoration) {
        Row() {
          this.decorationTabButton(0, $r('app.string.decoration_color'))
          this.decorationTabButton(1, $r('app.string.decoration_emoji'))
        }
        .width('100%')
        .margin({ top: 14 })
      }
      if (this.showDecoration && this.decorationTab === 0) {
        Row() {
          ForEach(FOLDER_COLOR_PALETTE, (color: number) => {
            Circle()
              .width(22)
              .height(22)
              .fill(color)
              .border({
                width: this.selectedColor === color ? 2 : 0,
                color: this.resolveTokens().textPrimary,
              })
              .margin({ right: 8 })
              .onClick(() => {
                this.selectedColor = color;
              })
          }, (color: number): string => color.toString())
        }
        .width('100%')
      } else if (this.showDecoration) {
        Row() {
          ForEach(FOLDER_EMOJI_CATEGORY_ICONS, (icon: string, index: number) => {
            Text(icon)
              .fontSize(15)
              .padding(3)
              .borderRadius(6)
              .backgroundColor(this.emojiCategory === index ? this.resolveTokens().control :
                this.resolveTokens().surface)
              .accessibilityText($r('app.string.emoji_category_' + index.toString()))
              .onClick(() => {
                this.emojiCategory = index;
              })
          }, (icon: string, index: number): string => index.toString())
        }
        .width('100%')
        .margin({ top: 4 })
        Grid() {
          GridItem() {
            Text('∅')
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
              .padding(4)
              .border({
                width: this.selectedEmoji.length === 0 ? 1 : 0,
                color: this.resolveTokens().accent,
                radius: 6,
              })
              .onClick(() => {
                this.selectedEmoji = '';
              })
          }
          ForEach(FOLDER_EMOJI_CATEGORIES[this.emojiCategory], (emoji: string) => {
            GridItem() {
              Text(emoji)
                .fontSize(18)
                .padding(4)
                .border({
                  width: this.selectedEmoji === emoji ? 1 : 0,
                  color: this.resolveTokens().accent,
                  radius: 6,
                })
                .onClick(() => {
                  this.selectedEmoji = emoji;
                })
            }
          }, (emoji: string): string => emoji)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
        .columnsGap(4)
        .rowsGap(4)
        .width('100%')
        .height(132)
        .margin({ top: 8 })
      }
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
            this.onConfirm(this.inputText, this.selectedColor, this.selectedEmoji).then((success: boolean) => {
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
