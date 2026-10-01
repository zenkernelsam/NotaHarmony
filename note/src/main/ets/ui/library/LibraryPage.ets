// T-018 资料库页面（侧栏 + 笔记网格 + 响应式断点 600/840/952/1400 + 新建/删除/搜索）
// T-035：缩略图 + 排序（bindMenu + Preferences 持久化）
import { router, promptAction } from '@kit.ArkUI';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { NoteMeta, PageInfo, PaperTemplate } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import {
  AssetAvailabilityChange, assetAvailabilityHub,
} from '../../data/AssetAvailabilityHub';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { NoteExporter } from '../../data/NoteExporter';
import { ImportFileDescriptor, ImportPlan, ImportReport, ImportResult, ImportSheetPrompt, NoteImporter, PdfPasswordPrompt } from '../../data/NoteImporter';
import { PdfPasswordDialog } from '../components/PdfPasswordDialog';
import { ImportDetailsSheet } from '../components/ImportDetailsSheet';
import { drainSharedUris } from '../../data/SharedFileIngress';
import { drainLaunchRequests, LaunchRequest, LAUNCH_ACTION_CREATE_PHOTO_NOTE, LAUNCH_ACTION_CREATE_RECORDING_NOTE } from '../../data/LaunchActionIngress';
import { drainDeepLinkNoteIds } from '../../data/DeepLinkIngress';
import { drainOpenNoteIds, drainLibraryLandings, LANDING_RECENT, LANDING_FOLDER_PREFIX } from '../../data/OpenTargetIngress';
import { refreshRecentNotesForms } from '../../data/RecentNotesFormFeed';
import { refreshFolderNotesForms } from '../../data/FolderNotesFormFeed';
import { refreshNoteThumbnailForms } from '../../data/NoteThumbnailFormFeed';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import { applyBundledTemplateDefault } from '../../data/BundledPaperTemplateApply';
import { FOLDER_DEFAULT_COLOR } from '../../data/DatabaseHelper';
import {
  FolderCreateResult, FolderDeleteResult, FolderDropIntent, FolderMutationResult,
  FolderRepositoryImpl, InvalidFolderNameError, MaxFolderDepthExceededError,
  NoteFolder, NoteFolderMoveResult, ORIGINAL_FOLDER_DRAG_INDENT,
  isFolderInSubtree, resolveFolderDrop,
} from '../../data/FolderRepositoryImpl';
import { OnboardingTipBubble } from '../components/OnboardingTipBubble';
import {
  OnboardingTooltipKind, OnboardingTooltipStore,
} from '../../data/OnboardingTooltipStore';
import { FirstPageThumbnailState, StrokePersistence } from '../../data/StrokePersistence';
import { AsyncMutex, MutexRelease } from '../../data/AsyncMutex';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { DocumentScanner, DocumentScannerConfig, DocType, SaveOption } from '@kit.VisionKit';
import { image } from '@kit.ImageKit';
import { Want } from '@kit.AbilityKit';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import { buildPdf, encryptPdfFile, PdfPageImage, readFileFully, shareEntryName, shareZipExtension } from '../../data/PagePdfExporter';
import { OriginalRecordingStore } from '../../data/OriginalRecordingStore';
import { ZipWriter } from '../../data/ZipArchive';
import {
  isThumbnailSourceUnchanged, prioritizeThumbnailNoteIds, thumbnailCacheKey,
} from '../../rendering/ThumbnailRenderPolicy';
import {
  findAnyNoteCover, loadNoteCoverThumb, NoteCoverPreset,
} from '../../core/model/NoteCoverCatalog';
import {
  ACADEMIC_PLANNER, PLANNER_COVERS, PLANNER_WEEK_STARTS, PlannerCover,
  plannerPdfPath, PlannerWeekStart,
} from '../../core/model/PlannerCatalog';
import {
  formatOriginalAutoNoteTitle, ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK,
} from '../../core/model/OriginalNoteTitlePolicy';
import { LibrarySection, LibraryViewModel, NoteSortMode } from './LibraryViewModel';
import {
  ThemeStore, THEME_MODE_KEY, THEME_PREFERENCE_KEY, THEME_PREFERENCES_NAME, THEME_SYSTEM_DARK_KEY,
} from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ToolGlyph } from '../components/ToolGlyph';
import {
  matchKeyChord, ORIGIN_CHORD_BACK_TO_LIBRARY, ORIGIN_CHORD_DISMISS,
  ORIGIN_CHORD_NEW_NOTE, ORIGIN_CHORD_NEW_WINDOW, ORIGIN_CHORD_OPEN_HELP,
  ORIGIN_CHORD_OPEN_SETTINGS,
} from '../../data/OriginalKeyboardChords';
import {
  buildComingUpDays, buildComingUpWindows, ComingUpDayGroup, ComingUpEvent,
  ComingUpEventState, comingUpEventState, ComingUpWindow,
} from '../../core/model/HomeComingUpModel';
import {
  ComingUpCalendarRequestOutcome, ComingUpCalendarWindow,
  loadComingUpCalendarWindow, openComingUpCalendarSettings,
  requestComingUpCalendarPermission,
} from '../../data/OriginalComingUpCalendarGateway';

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
  ['📚', '📖', '✏️', '🖊️', '📐', '📏', '✂️', '📁', '📌', '📎', '🔍', '🔬', '💡', '💻', '📱', '⌚', '📷', '🔒', '🔑', '💰'],
  // du3.TravelPlaces
  ['🚗', '🚕', '🚌', '🚲', '✈️', '🚀', '🚂', '⛵', '🏠', '🏢', '🏫', '🏥', '🏛️', '⛪', '🕌', '🛕', '🕍', '🏔️', '🏖️', '🏕️'],
  // du3.Symbols
  ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '✨', '⭐', '🌟', '⚠️', '✅', '❌', '➕', '➖', '♻️', '🔴', '🟢', '🔵'],
  // du3.Flags
  ['🏁', '🚩', '🏳️', '🏴', '🏳️‍🌈', '🇨🇳', '🇺🇸', '🇬🇧', '🇯🇵', '🇰🇷', '🇫🇷', '🇩🇪', '🇨🇦', '🇦🇺', '🇧🇷', '🇮🇳'],
];

// 原版 ML Kit 扫描页数上限未在反编译中暴露（启动器未解出）；取 Harmony
// DocumentScanner SDK 上限 50 保持多页扫描能力。
const ORIGINAL_DOC_SCAN_MAX_PAGES: number = 50;

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
  // Original cd case 0 + ac4.a0(LIBRARY_DOC_SCAN)：FAB「Document Scan」——
  // VisionKit DocumentScanner 全屏扫描（产出 PDF）→ 新笔记；无 DocScan
  // 组件能力的设备等价原版 flag-off，不渲染入口。
  @State docScanAvailable: boolean = false;
  @State docScanOpen: boolean = false;
  private docScanConfig: DocumentScannerConfig | null = null;
  @State deleteBusy: boolean = false;
  // 原版 pk9.X/Y：库内多选态（X=模式中、Y=已选 id 集；o() 长按进入、
  // r() 翻转、p() 退出清空；ek9 = MultiSelectState 派生模型）。
  @State isMultiSelecting: boolean = false;
  @State selectedNoteIds: string[] = [];
  @State multiSelectBusy: boolean = false;
  // 原版 b7d 分享态（v6d 多选形态）：v6d.a=isMultiNote=true 时页范围行
  // 隐藏（dih.a/h 的 e() 分派跳过），格式默认 PDF（b7d 构造器
  // list.size()>1 → PDF）；include_* 初值与 v6d 构造器一致
  // （background=false、recording=true）；v6d.k 密码可空。
  @State multiShareOpen: boolean = false;
  // 原版 x2n.c/l19 计划本配置态（d2d）：sheet 开关 + weekStart 键 +
  // 封面序号 + 创建中遮罩（fel 进度模态）。
  @State plannerSheetOpen: boolean = false;
  @State plannerWeekStartKey: string = 'monday';
  @State plannerCoverIndex: number = 0;
  @State plannerCreating: boolean = false;
  @State multiShareFormat: string = 'pdf';
  @State multiShareIncludeBackground: boolean = false;
  @State multiShareIncludeRecording: boolean = true;
  @State multiSharePassword: string | null = null;
  @State multiSharePasswordDraft: string = '';
  @State multiSharePasswordConfirm: string = '';
  @State multiSharePasswordEditing: boolean = false;
  @State multiSharePasswordMismatch: boolean = false;
  @State multiShareBusy: boolean = false;
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
  // 原版 pq9/hq9 引导气泡链：FIRST_NOTE_COMPLETED（首张笔记卡右缘）与
  // COMPACT_ORGANIZE（Folders 入口下方），seen 集持久于
  // onboardingTooltipSeen。
  @State onboardingSeen: string[] = [];
  private onboardingStore: OnboardingTooltipStore | null = null;
  private onboardingSeenReady: boolean = false;
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
  // 原版 kb2/bh1 —— Home "Coming up" 面板数据：null = 尚未探测（未渲染），
  // false = 日历不可读（Connect 卡），true = 可读（分组窗口面板）。
  @State comingUpReadable: boolean | null = null;
  @State comingUpWindows: ComingUpWindow[] = [];
  // 原版 nan.i 的 rga 选中态：记录当前窗口起始日（数据重载后按日键归位，
  // 找不到即回落首窗口）。
  @State comingUpWindowKey: string | null = null;
  // 面板快照时刻：行状态（Starting soon/Happening now）按该时刻判定，
  // 每次加载刷新（等价 lb2.a(now) 重组时参数）。
  @State comingUpNowMs: number = 0;
  private comingUpBusy: boolean = false;
  @State folderDialogTargetId: string = '';
  @State folderDialogParentId: string | null = null;
  @State folderDialogColor: number = FOLDER_DEFAULT_COLOR;
  @State folderDialogEmoji: string = '';
  private folderDialog: CustomDialogController = new CustomDialogController({
    builder: NameDialog({
      title: this.folderDialogTitle,
      placeholder: $r('app.string.enter_folder_name'),
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
  // 原版 n32：unindexed 说明对话框（unindexed_notes 标题 + 崩溃说明 +
  // Close）。
  private unindexedDialog: CustomDialogController = new CustomDialogController({
    builder: UnindexedNotesDialog(),
    autoCancel: true,
  });
  // 原版 cd case 0 templatenewnote：从模板新建笔记——四款 PaperTemplate
  // 选择后走同一 create+open 管线，模板覆盖默认纸张。
  private templateDialog: CustomDialogController = new CustomDialogController({
    builder: TemplatePickerDialog({
      onPick: (template: PaperTemplate): void => {
        this.createFromTemplate(template).catch((e: Error) => {
          console.error(`create from template failed: ${JSON.stringify(e)}`);
        });
      },
    }),
    autoCancel: true,
  });
  private persistence: StrokePersistence = new StrokePersistence();
  private thumbRenderer: ThumbnailRenderer = new ThumbnailRenderer();
  private db: DatabaseManager = DatabaseManager.getInstance();
  // 原版 ou5.onPasswordSubmitted：加密 PDF 导入时弹密码框；attempt>0
  // 表示上次密码错误重试；取消（返回 null）中止该文件导入。
  @State pdfPasswordFileName: string = '';
  @State pdfPasswordAttempt: number = 0;
  private pdfPasswordResolve: ((password: string | null) => void) | null = null;
  private pdfPasswordDialog: CustomDialogController = new CustomDialogController({
    builder: PdfPasswordDialog({
      fileName: this.pdfPasswordFileName,
      attempt: this.pdfPasswordAttempt,
      onResult: (password: string | null): void => {
        const resolve: ((password: string | null) => void) | null =
          this.pdfPasswordResolve;
        this.pdfPasswordResolve = null;
        if (resolve !== null) {
          resolve(password);
        }
      },
    }),
    cancel: (): void => {
      const resolve: ((password: string | null) => void) | null =
        this.pdfPasswordResolve;
      this.pdfPasswordResolve = null;
      if (resolve !== null) {
        resolve(null);
      }
    },
    autoCancel: true,
  });
  private pdfPasswordPrompt: PdfPasswordPrompt =
    (fileName: string, attempt: number): Promise<string | null> => {
      return new Promise((resolve) => {
        this.pdfPasswordResolve = resolve;
        this.pdfPasswordFileName = fileName;
        this.pdfPasswordAttempt = attempt;
        this.pdfPasswordDialog.open();
      });
    };
  // 原版 ou5/zvh.a 导入详情页：文件列表 + 目的地（qv5 现有笔记 / sv5
  // 新建笔记 / rv5 各自笔记）+ 逐文件题。取消/遮罩 → 返回 null。
  @State importSheetFiles: ImportFileDescriptor[] = [];
  @State importSheetContext: string = 'standalone';
  @State importSheetNoteId: string = '';
  @State importSheetNotes: NoteMeta[] = [];
  @State importSheetFolders: NoteFolder[] = [];
  private importSheetResolve: ((plan: ImportPlan | null) => void) | null = null;
  private importSheetDialog: CustomDialogController = new CustomDialogController({
    builder: ImportDetailsSheet({
      files: this.importSheetFiles,
      context: this.importSheetContext,
      currentNoteId: this.importSheetNoteId,
      notes: this.importSheetNotes,
      folders: this.importSheetFolders,
      onResult: (plan: ImportPlan | null): void => {
        const resolve: ((plan: ImportPlan | null) => void) | null =
          this.importSheetResolve;
        this.importSheetResolve = null;
        if (resolve !== null) {
          resolve(plan);
        }
      },
    }),
    cancel: (): void => {
      const resolve: ((plan: ImportPlan | null) => void) | null =
        this.importSheetResolve;
      this.importSheetResolve = null;
      if (resolve !== null) {
        resolve(null);
      }
    },
    autoCancel: true,
  });
  private async prepareImportSheetData(): Promise<void> {
    try {
      this.importSheetNotes = this.noteRepo !== null ?
        await this.noteRepo.getAllNotes() : [];
    } catch (_notesError) { }
    try {
      this.importSheetFolders = this.folderRepo !== null ?
        await this.folderRepo.getAllFolders() : [];
    } catch (_foldersError) { }
  }
  private importSheetPrompt: ImportSheetPrompt =
    (files: ImportFileDescriptor[], context: string,
      currentNoteId: string): Promise<ImportPlan | null> => {
      this.importSheetFiles = files;
      this.importSheetContext = context;
      this.importSheetNoteId = currentNoteId;
      return new Promise((resolve) => {
        this.importSheetResolve = resolve;
        this.prepareImportSheetData()
          .finally((): void => this.importSheetDialog.open());
      });
    };
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
    this.initData(generation);    // 原版 lc4.a(ac4.a0) 门控：Harmony 等价门控为系统能力探测——无
    // DocScan 组件能力的设备不显示「Document Scan」入口（fail-closed）。
    this.docScanAvailable = canIUse('SystemCapability.AI.Component.DocScan');
    this.onboardingStore = new OnboardingTooltipStore(
      getContext(this) as common.UIAbilityContext);
    this.onboardingStore.getSeenKinds().then((seen: string[]): void => {
      this.onboardingSeen = seen;
      this.onboardingSeenReady = true;
    }).catch((e: Error): void => {
      console.error('onboarding seen load failed: ' + JSON.stringify(e));
    });
  }

  aboutToDisappear(): void {
    this.pageActive = false;
    if (this.pdfPasswordResolve !== null) {
      const resolve: (password: string | null) => void = this.pdfPasswordResolve;
      this.pdfPasswordResolve = null;
      resolve(null);
    }
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
  // 原版 lq7 → pk9.p：返回键在多选态先退出多选（X=false + 清 Y）。
  onBackPress(): boolean {
    if (this.isMultiSelecting) {
      this.exitMultiSelect();
      return true;
    }
    return false;
  }

  onPageShow(): void {
    const lifecycleGeneration: number = this.activatePage();
    // 原版 fag.h0 + hv7.i：冷/热启动收到的共享 want URI 在此 drain
    // 并走同一导入管线（jv5 分发语义 → 独立笔记 → 打开）。
    this.drainSharedIngress();
    // 原版 v50 快捷方式 CREATE_NOTE（new_photo 带 start_camera）
    // 在此 drain 并走与内建「+」一致的建笔记管线。
    this.drainLaunchIngress();
    // 原版 /app/note/<id> 深链（py2 → hv7.i → kx）在此 drain，
    // 命中本地笔记即打开。
    this.drainDeepLinkIngress();
    // 原版打开目标 extras（note_id / nbnote URI / show_library /
    // show_recent）在此 drain —— 笔记 ID 与深链同一打开管线，
    // 落地请求按 LibrarySection 处理。
    this.drainOpenTargetIngress();
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
        this.refreshRecentCardFeed();
        // 原版 kg3 ContentObserver 语义：日历变更即重查；Harmony 无等价全局
        // 观察 API，登记差异并在每次 Home 呈现（loadNotes 完成）时重拉。
        this.refreshComingUp(lifecycleGeneration);
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
    // 原版 d7b/iw2 封面：cover_preset 命中时库卡片渲染 covers/<key>.pdf 首页
    // 而非页缩略图；preset 键并入 revision 使封面变更能击穿缩略图缓存。
    const coverByNoteId: Map<string, string> = new Map<string, string>();
    for (const note of this.notes) {
      if (note.coverPreset !== undefined && note.coverPreset !== null &&
        note.coverPreset !== '') {
        coverByNoteId.set(note.id, note.coverPreset);
      }
    }
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
            const coverKey: string | undefined = coverByNoteId.get(noteId);
            const revision: string = this.thumbnailRevision(sourceState, theme,
              assetGeneration) + (coverKey === undefined ? '' : `|cover:${coverKey}`);
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
            // 原版 d7b 封面元素渲染：iw2 预设与 y1d 计划本封面共用一槽。
            const coverPreset: NoteCoverPreset | null =
              coverKey === undefined ? null : findAnyNoteCover(coverKey);
            if (coverPreset !== null) {
              // 原版：封面元素媒体渲染库卡片；Harmony 光栅 covers/<key>.pdf 首页。
              unpublishedPixelMap = await loadNoteCoverThumb(
                getContext(this) as common.UIAbilityContext, this.db, coverPreset);
            } else {
              // 未知 preset 键 fail-closed 回退常规页缩略图（drifted 数据不崩）。
              unpublishedPixelMap = await renderer.renderThumbnail(
                noteId, this.persistence, sourceState.page, theme, this.db);
            }
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
              this.thumbnailRevision(verifiedState, theme, verifiedAssetGeneration) +
              (coverKey === undefined ? '' : `|cover:${coverKey}`);
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
            const coverKeyHere: string | undefined = coverByNoteId.get(noteId);
            const currentRevision: string = currentState === null ? '' : this.thumbnailRevision(
              currentState, theme, assetAvailabilityHub.getNoteGeneration(noteId)) +
              (coverKeyHere === undefined ? '' : `|cover:${coverKeyHere}`);
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
    // 原版 gaj：重命名对话框标题为 enter_folder_name（创建态才是 new_folder）。
    this.folderDialogTitle = $r('app.string.enter_folder_name');
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
      promptAction.showToast({
        message: this.folderErrorToastRes(e as Error, $r('app.string.folder_operation_failed')),
      });
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

  // 原版 sad/qad：深度超限与非法名称各有专属提示，其余走通用失败文案。
  private folderErrorToastRes(e: Error, fallback: ResourceStr): ResourceStr {
    if (e instanceof MaxFolderDepthExceededError) {
      return $r('app.string.error_max_folder_depth');
    }
    if (e instanceof InvalidFolderNameError) {
      return $r('app.string.folder_name_error');
    }
    return fallback;
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
      promptAction.showToast({
        message: this.folderErrorToastRes(e as Error, $r('app.string.move_folder_failed')),
      });
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
      promptAction.showToast({
        message: this.folderErrorToastRes(e as Error, $r('app.string.move_folder_failed')),
      });
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
        this.refreshRecentCardFeed();
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
      this.refreshRecentCardFeed();
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

  // Original hf0/yw3 empty states — icon per section (xxlrg drawables
  // adapted as glyphs): favorite/recents/folder.
  private emptyStateIcon(): string {
    if (this.currentFolderId !== null) {
      return '📁';
    }
    if (this.currentSection === LibrarySection.FAVORITES) {
      return '♥';
    }
    if (this.currentSection === LibrarySection.RECENT) {
      return '🕘';
    }
    if (this.currentSection === LibrarySection.UNFILED) {
      return '📂';
    }
    return '📝';
  }

  // Sections carry a title (rw3/vw3/tw3/xw3); folders show body only
  // (sw3/uw3 call b(null, ...) — no title row).
  private emptyStateHasTitle(): boolean {
    return this.currentFolderId === null;
  }

  private emptyStateTitle(): Resource {
    if (this.currentSection === LibrarySection.FAVORITES) {
      return $r('app.string.empty_favorite_notes_title');
    }
    if (this.currentSection === LibrarySection.RECENT) {
      return $r('app.string.empty_recent_notes_title');
    }
    if (this.currentSection === LibrarySection.UNFILED) {
      return $r('app.string.empty_unfiled_notes_title');
    }
    return $r('app.string.lets_get_started');
  }

  // sw3: empty folder body; uw3: with-children variant carrying the
  // subfolder + note counts (notes are 0 here — the state only renders
  // when the folder projection is empty).
  private emptyStateBody(): Resource {
    if (this.currentFolderId !== null) {
      const childFolders: number = this.folders.filter((f: NoteFolder) =>
        f.parentId === this.currentFolderId).length;
      if (childFolders > 0) {
        // uw3 body carries pluralized counts; the folder projection is
        // empty here so the note count is always 0. This SDK only exposes
        // async getPluralString, so plurality is selected between two body
        // variants instead.
        return childFolders === 1 ?
          $r('app.string.empty_folder_with_child_body', this.notes.length) :
          $r('app.string.empty_folder_with_children_body', childFolders,
            this.notes.length);
      }
      return $r('app.string.empty_folder_body');
    }
    if (this.currentSection === LibrarySection.FAVORITES) {
      return $r('app.string.empty_favorite_notes_body');
    }
    if (this.currentSection === LibrarySection.RECENT) {
      return $r('app.string.empty_recent_notes_body');
    }
    if (this.currentSection === LibrarySection.UNFILED) {
      return $r('app.string.empty_unfiled_notes_body');
    }
    return $r('app.string.tap_to_create_notes');
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
      // 原版 qp9.O=lk3：建笔记后应用 o8b.x 打包默认模板（context+db 在本页可得）。
      const editorSettings: EditorSettingsStore = new EditorSettingsStore(context);
      const vm: LibraryViewModel = new LibraryViewModel(noteRepo,
        (noteId: string): Promise<void> =>
          applyBundledTemplateDefault(context, this.db, noteId),
        // 原版 k59.l → o8b.f → mcn.g：按 noteEditorSettings 的
        // defaultNoteTitle/includeDatePosition/includeTimePosition + 创建
        // 时刻组装标题；结果 blank → k59.l 的 "..."；工厂本身抛错由
        // LibraryViewModel.createNote 落回 "New Note"（flag-off 分支）。
        async (timestampMillis: number): Promise<string> => {
          const customTitle: string | null = await editorSettings.getDefaultNoteTitle();
          const datePosition: string = await editorSettings.getIncludeDatePosition();
          const timePosition: string = await editorSettings.getIncludeTimePosition();
          let fallbackTitle: string = 'Note';
          try {
            fallbackTitle = context.resourceManager.getStringSync(
              $r('app.string.default_note_title_fallback').id);
          } catch (_e) {
          }
          const title: string = formatOriginalAutoNoteTitle(customTitle,
            fallbackTitle, datePosition, timePosition, timestampMillis);
          return title.trim().length > 0 ? title : ORIGINAL_AUTO_TITLE_EMPTY_FALLBACK;
        });
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
      this.refreshRecentCardFeed();
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
            // 原版 b41/o94：选中指示图标 = ui_designsystem__general_check_med_reg。
            ToolGlyph({
              glyph: 'general_check_med_reg',
              contentColor: this.resolveTokens().accent,
              iconSize: 16,
            })
              .margin({ left: 8 })
              .accessibilityText($r('app.string.folder_selected'))
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
      Button() {
        // 原版文件夹条目溢出 = ui_designsystem__more（三点）。
        ToolGlyph({
          glyph: 'more',
          contentColor: this.resolveTokens().textPrimary,
          iconSize: 20,
        })
      }
        .width(40)
        .height(44)
        .padding(0)
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
          // 原版选中指示 = ui_designsystem__general_check_med_reg（accent）。
          ToolGlyph({
            glyph: 'general_check_med_reg',
            contentColor: this.resolveTokens().accent,
            iconSize: 16,
          })
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
        // 原版 d2n.c：侧栏文件夹行左滑尾缘揭出 delete（trash 图标，
        // 点击置态起 kcj 删除确认框）。
        .swipeAction({
          end: () => { this.FolderSwipeAction(item) },
          edgeEffect: SwipeEdgeEffect.Spring,
        })
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
            Button() {
              // 原版关闭抽屉 = ui_designsystem__close_med_regular。
              ToolGlyph({
                glyph: 'close_med_regular',
                contentColor: this.resolveTokens().textPrimary,
                iconSize: 22,
              })
            }
              .width(44)
              .height(44)
              .accessibilityText($r('app.string.close'))
              .onClick(() => {
                this.closeCompactFolderDrawer();
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 8 })

          // 原版 ajh:335：LIBRARY_HOME（androidLibraryHome 默认 true）→
          // Home 导航项插在 All Notes 之前（ADR-0691/0694）。
          this.SectionNavRow($r('app.string.home'), LibrarySection.HOME, 16)
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
          // 原版 ajh:335：LIBRARY_HOME 默认开 → Home 居导航首位。
          this.SectionNavRow($r('app.string.home'), LibrarySection.HOME, 8)
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
            // 原版 enh fsi.h(pq9.Q, pos2)：Folders 入口下方的整理引导气泡。
            .bindPopup(this.libraryTipVisible(OnboardingTooltipKind.COMPACT_ORGANIZE) &&
              this.showSidebar, {
              builder: (): void => {
                this.OnboardingOrganizeTip()
              },
              placement: Placement.Bottom,
              mask: false,
              autoCancel: false,
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
            Button() {
              // 原版 Folders 抽屉入口 = ui_designsystem__hamburger。
              ToolGlyph({
                glyph: 'hamburger',
                contentColor: this.resolveTokens().textPrimary,
                iconSize: 22,
              })
            }
              .width(44)
              .height(44)
              .enabled(!this.folderBusy)
              .accessibilityText($r('app.string.open_folder_drawer'))
              .onClick(() => {
                this.openCompactFolderDrawer();
              })
              // 原版 enh(pq9.Q, pos2)：compact 布局的 Folders 抽屉入口。
              .bindPopup(this.libraryTipVisible(OnboardingTooltipKind.COMPACT_ORGANIZE) &&
                !this.showSidebar, {
                builder: (): void => {
                  this.OnboardingOrganizeTip()
                },
                placement: Placement.Bottom,
                mask: false,
                autoCancel: false,
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
            Button() {
              // 原版文件夹溢出 = ui_designsystem__more（三点）。
              ToolGlyph({
                glyph: 'more',
                contentColor: this.resolveTokens().textPrimary,
                iconSize: 20,
              })
            }
              .width(48)
              .height(44)
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
        if (this.isMultiSelecting) {
          this.MultiSelectTopBar()
        } else {
        Row() {
          // Original yj9:852 — placeholder is "Search in {folder}" while a
          // folder is selected, plain "Search" otherwise.
          TextInput({ placeholder: this.searchPlaceholder() })
            .layoutWeight(1)
            .height(40)
            .fontColor(this.resolveTokens().textPrimary)
            .placeholderColor(this.resolveTokens().textSecondary)
            .backgroundColor(this.resolveTokens().surface)
            // 原版 mb7/nb7：查询非空时显示 clear_search X，点击清空并触发
            // onChange('') 重新加载。cancelButton 无独立无障碍标签，登记差异。
            .cancelButton({ style: CancelButtonStyle.INPUT })
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
              // 原版 feature_library__cd_sort：排序控件标签为 "Sort notes"。
              .accessibilityText($r('app.string.cd_sort'))
              .bindMenu(this.buildSortMenuItems())
            Button(this.viewModel !== null && this.viewModel.sortDescending ? '↓' : '↑')
              .height(40)
              .fontSize(13)
              .accessibilityText($r('app.string.sort'))
              .onClick(() => {
                this.toggleSortDirection();
              })
            // 原版 sof：图标描绘目标模式——list 态显示 grid_view、grid 态
            // 显示 list_bullet；cd 为 "Switch to grid/list view"。
            Button() {
              ToolGlyph({
                glyph: this.listView ? 'grid_view' : 'list_bullet',
                contentColor: this.resolveTokens().textPrimary,
                iconSize: 20,
              })
            }
              .width(40)
              .height(40)
              .accessibilityText(this.listView ?
                $r('app.string.cd_switch_to_grid_view') : $r('app.string.cd_switch_to_list_view'))
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
            Button() {
              // 原版库操作溢出 = ui_designsystem__more（三点）。
              ToolGlyph({
                glyph: 'more',
                contentColor: this.resolveTokens().textPrimary,
                iconSize: 20,
              })
            }
              .width(48)
              .height(40)
              .margin({ left: 8 })
              .accessibilityText($r('app.string.library_actions'))
              .bindMenu(this.buildLibraryActionsMenu())
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        }

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

        // 原版 elc.a/flc：无 search_item 覆盖的笔记不参与搜索——以横幅
        // 呈现 unindexed 计数 + Learn More 入口（n32 说明对话框）。
        if (this.viewModel !== null && this.viewModel.unindexedNoteCount > 0) {
          Row() {
            Text($r(this.viewModel.unindexedNoteCount === 1 ?
              'app.string.unindexed_note' : 'app.string.unindexed_notes_count',
              this.viewModel.unindexedNoteCount))
              .fontSize(13)
              .fontColor(this.resolveTokens().textSecondary)
              .layoutWeight(1)
            Text($r('app.string.learn_more'))
              .fontSize(13)
              .fontColor(this.resolveTokens().accent)
              .onClick(() => {
                this.unindexedDialog.open();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
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
          // 原版 vdh.b：选中 Home 导航项（ba6.o(ync, tnc.a)）时内容宿主
          // 渲染 ksh Home 视图而非分区网格；搜索非空回落正常结果网格。
          if (this.currentFolderId === null &&
            this.currentSection === LibrarySection.HOME &&
            this.searchText.trim().length === 0) {
            this.HomeContent()
          } else if (this.libraryLoading && this.notes.length === 0) {
            Text($r('app.string.loading'))
              .fontSize(16)
              .fontColor(this.resolveTokens().textSecondary)
              .layoutWeight(1)
          } else if (this.notes.length === 0) {
            // Original hf0 + yw3: each section/folder has its own empty
            // state (icon + optional title + body). An active search keeps
            // the generic no-results text instead.
            Column() {
              if (this.searchText.trim().length > 0) {
                Text($r('app.string.no_matching_notes'))
                  .fontSize(16)
                  .fontColor(this.resolveTokens().textSecondary)
              } else {
                Text(this.emptyStateIcon())
                  .fontSize(40)
                  .fontColor(this.resolveTokens().textSecondary)
                if (this.emptyStateHasTitle()) {
                  Text(this.emptyStateTitle())
                    .fontSize(16)
                    .fontColor(this.resolveTokens().textSecondary)
                    .margin({ top: 12 })
                }
                Text(this.emptyStateBody())
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textSecondary)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 8, left: 24, right: 24 })
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
                  // 原版 wbn.c/qbn.g：list 行左滑尾缘揭出 [favorite][delete]
                  // 操作条（多选态禁滑——z2/z5 门等价）。
                  .swipeAction(this.isMultiSelecting ? {} : {
                    end: () => { this.NoteSwipeActions(note) },
                    edgeEffect: SwipeEdgeEffect.Spring,
                  })
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
      this.MultiSelectActionBar()
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
    .bindSheet(this.multiShareOpen, this.MultiShareSheet(), {
      height: SheetSize.MEDIUM,
      showClose: false,
      // 原版 b7d 会话态：面板关闭即结束本次分享会话。
      onDisappear: (): void => {
        this.multiSharePasswordEditing = false;
        this.multiSharePasswordMismatch = false;
      }
    })
    .bindSheet(this.plannerSheetOpen, this.PlannerConfigSheet(), {
      height: SheetSize.LARGE,
      showClose: false,
    })
    .bindContentCover(this.docScanOpen, this.DocScanCover(), {
      // VisionKit 约束：扫描界面不得被其他组件遮挡——全屏 cover 独占；
      // 向下滑动关闭等同用户取消。
      onWillDismiss: (action: DismissContentCoverAction): void => {
        this.docScanOpen = false;
        action.dismiss();
      }
    })
    // 原版 MainActivity.dispatchKeyEvent → vla.a 查表（KeyUp 精确四元组）；
    // 未命中和弦透传冒泡。
    .onKeyEvent((event: KeyEvent): boolean => {
      return this.onLibraryKeyEvent(event);
    })
    .focusable(true)
    .defaultFocus(true)
  }

  // 原版 ksh.a Home 内容宿主：头部（应用图标 + Let's get started +
  // 副标）→ ksh.d 双 CTA 卡（Record a lecture / Take notes）→
  // "Favorite notes"（list4 非空才渲染）→ "Recent notes"（非空渲染）。
  // home_study_up_next（Learn）与 take_notes_starter 配额变体
  // 维持 fail-closed（ADR-0652/0694）。CTA 行为 = 既有
  // createAndLaunch 通道（autoRecord=true 等同录音快捷项）。
  @Builder
  private HomeContent() {
    Scroll() {
      Column() {
        Image($r('app.media.startIcon'))
          .width(96)
          .height(96)
          .margin({ top: 24 })
        Text($r('app.string.home_lets_get_started'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ top: 16 })
        Text($r('app.string.home_subtitle'))
          .fontSize(15)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ top: 8 })
        Row() {
          this.HomeCtaCard($r('app.media.widget_record'),
            $r('app.string.home_record_lecture_title'),
            $r('app.string.home_record_lecture_subtitle'),
            (): void => {
              this.createAndLaunch(true).catch((e: Error): void => {
                console.error(`home record launch failed: ${JSON.stringify(e)}`);
              });
            })
          this.HomeCtaCard($r('app.media.shortcut_new_note'),
            $r('app.string.home_take_notes'),
            $r('app.string.home_take_notes_subtitle'),
            (): void => {
              this.createAndLaunch(false).catch((e: Error): void => {
                console.error(`home take-notes launch failed: ${JSON.stringify(e)}`);
              });
            })
        }
        .width('100%')
        .margin({ top: 32 })
        // 原版 vkm.a 次序：CTA → kan.a(Coming up) → q8n.e(exams，未移植)
        // → vkm.e(unindexed) → favorites → recents → planners。
        this.HomeComingUpSection()
        if (this.viewModel !== null && this.viewModel.homeFavorites.length > 0) {
          this.HomeNoteSection($r('app.string.home_favorite_notes_title'),
            this.viewModel.homeFavorites)
        }
        if (this.viewModel !== null && this.viewModel.homeRecents.length > 0) {
          this.HomeNoteSection($r('app.string.home_recent_notes_title'),
            this.viewModel.homeRecents)
        }
        // 原版 a1n.d f8m.d + hel.c：getting-started 面 "Planners" 分区
        // （1.4.2 仅 academic_planner_2026_2027 一项；cell = 首个 y1d 封面
        // drawable + planner 标题）。点击 → x2n.c 配置 sheet。
        this.HomePlannerSection()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24, bottom: 96 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .align(Alignment.Top)
  }

  // 原版 ksh.d 单张 CTA 卡：图标 + 标题（are.E）+ 副标（are.M），
  // 双卡等宽横排（原版按文本折行自适应换为整宽堆叠——登记差异）。
  @Builder
  private HomeCtaCard(icon: Resource, title: ResourceStr, subtitle: ResourceStr,
    action: () => void) {
    Column() {
      Image(icon)
        .width(40)
        .height(40)
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 12 })
      Text(subtitle)
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(12)
    .backgroundColor(this.resolveTokens().surface)
    .shadow({ radius: 4, color: this.resolveTokens().shadow, offsetY: 2 })
    .margin({ left: 8, right: 8 })
    .enabled(!this.createBusy)
    .onClick(() => {
      action();
    })
  }

  // 原版 ksh.f/oi5：分区标题 + 横向卡片行（卡片 220vp 宽固定）。
  @Builder
  private HomeNoteSection(title: ResourceStr, notes: NoteMeta[]) {
    Column() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Scroll() {
        Row({ space: 12 }) {
          ForEach(notes, (note: NoteMeta) => {
            Column() {
              this.NoteCard(note)
            }
            .width(220)
          }, (note: NoteMeta) => note.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 32 })
  }

  // 原版 kan.a —— Coming up 分区宿主：kb2.b(可读) → nan.i 窗口面板；
  // 不可读 → e7n Connect 卡（整卡点击 = 权限请求）。
  @Builder
  private HomeComingUpSection() {
    if (this.comingUpReadable !== null) {
      Column() {
        if (this.comingUpReadable) {
          this.ComingUpPanel()
        } else {
          this.ComingUpConnectCard()
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 32 })
    }
  }

  // 原版 nan.g —— 标题 + ‹/› 翻页钮（earlier_days/later_days 无障碍标签，
  // 首/末窗口禁用）。
  @Builder
  private ComingUpPanel() {
    Column() {
      Row() {
        Text($r('app.string.home_coming_up_title'))
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
          .layoutWeight(1)
        this.ComingUpPagerButton('chevron_left',
          $r('app.string.home_coming_up_earlier_days'),
          this.comingUpWindowIndex() > 0, -1)
        this.ComingUpPagerButton('chevron_right',
          $r('app.string.home_coming_up_later_days'),
          this.comingUpWindowIndex() + 1 < this.comingUpWindows.length, 1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 16 }) {
        ForEach(this.currentComingUpWindow().groups,
          (group: ComingUpDayGroup, groupIndex: number) => {
            if (groupIndex > 0) {
              // 原版 nan.b：组间 1vp 分隔线。
              Divider()
                .strokeWidth(1)
                .color(this.resolveTokens().border)
            }
            this.ComingUpDayBlock(group)
          },
          (group: ComingUpDayGroup) => group.dateKey)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private currentComingUpWindow(): ComingUpWindow {
    const windows: ComingUpWindow[] = this.comingUpWindows;
    if (windows.length === 0) {
      return { startDateKey: '', groups: [], nextDateKey: null };
    }
    return windows[this.comingUpWindowIndex()];
  }

  @Builder
  private ComingUpPagerButton(glyphName: string, description: Resource,
    enabled: boolean, delta: number) {
    Button() {
      ToolGlyph({ glyph: glyphName, iconSize: 18,
        contentColor: enabled ? this.resolveTokens().textPrimary :
          this.resolveTokens().textSecondary })
    }
    .type(ButtonType.Normal)
    .width(32)
    .height(32)
    .backgroundColor(this.resolveTokens().control)
    .accessibilityText(description)
    .enabled(enabled)
    .onClick(() => {
      this.comingUpShiftWindow(delta);
    })
  }

  // 原版 nan.c —— 日分组行：nan.d 日期徽标 + 事件卡（weight 均分）/
  // 空组 → nan.e "No upcoming events" 空卡。
  @Builder
  private ComingUpDayBlock(group: ComingUpDayGroup) {
    Row({ space: 12 }) {
      this.ComingUpDayBadge(group.dayStartMs)
      if (group.events.length === 0) {
        this.ComingUpEmptyCard()
      } else {
        ForEach(group.events, (ev: ComingUpEvent) => {
          this.ComingUpEventCard(ev)
        }, (ev: ComingUpEvent) => ev.id)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  // 原版 nan.d —— 日徽标：日期数字（大号）+ MMM + EEE 短标签（本地语系）。
  @Builder
  private ComingUpDayBadge(dayStartMs: number) {
    Row({ space: 4 }) {
      Text(`${new Date(dayStartMs).getDate()}`)
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Column() {
        Text(new Intl.DateTimeFormat(undefined, { month: 'short' })
          .format(new Date(dayStartMs)))
          .fontSize(11)
          .fontColor(this.resolveTokens().textPrimary)
        Text(new Intl.DateTimeFormat(undefined, { weekday: 'short' })
          .format(new Date(dayStartMs)))
          .fontSize(11)
          .fontColor(this.resolveTokens().textSecondary)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .alignItems(VerticalAlign.Center)
    .margin({ top: 4 })
  }

  // 原版 nan.e/adl.b —— 空日组卡（accent 竖条 + "No upcoming events"）。
  @Builder
  private ComingUpEmptyCard() {
    Row({ space: 12 }) {
      Column()
        .width(3)
        .height('100%')
        .backgroundColor(this.resolveTokens().accent)
        .borderRadius(2)
      Text($r('app.string.home_coming_up_no_events'))
        .fontSize(15)
        .fontColor(this.resolveTokens().textSecondary)
        .layoutWeight(1)
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .layoutWeight(1)
    .shadow({ radius: 4, color: this.resolveTokens().shadow, offsetY: 2 })
  }

  // 原版 nan.f/nan.a/aa case2 —— 事件卡：3vp accent 竖条 + surface；
  // 时间副标（All day / SHORT 时间，非 UPCOMING 加 Starting soon /
  // Happening now 前缀并着 accent）+ 标题（空 → Untitled event）+
  // "Start now" 钮（ne case11 → c13.a(ik.CALENDAR) 建笔记并打开；
  // 非 UPCOMING 主色，UPCOMING 次要色）。
  @Builder
  private ComingUpEventCard(ev: ComingUpEvent) {
    Row({ space: 12 }) {
      Column()
        .width(3)
        .height('100%')
        .backgroundColor(this.resolveTokens().accent)
        .borderRadius(2)
      Column({ space: 4 }) {
        Text(this.comingUpRowSubtitle(ev,
          comingUpEventState(ev, this.comingUpNowMs)))
          .fontSize(12)
          .fontColor(comingUpEventState(ev, this.comingUpNowMs) !==
            ComingUpEventState.UPCOMING ? this.resolveTokens().accent :
            this.resolveTokens().textSecondary)
        Text(/\S/.test(ev.title) ? ev.title :
          $r('app.string.home_coming_up_untitled_event'))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().textPrimary)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button($r('app.string.home_coming_up_start_now'))
          .type(ButtonType.Normal)
          .fontSize(13)
          .fontColor(comingUpEventState(ev, this.comingUpNowMs) !==
            ComingUpEventState.UPCOMING ? this.resolveTokens().onAccent :
            this.resolveTokens().textPrimary)
          .backgroundColor(comingUpEventState(ev, this.comingUpNowMs) !==
            ComingUpEventState.UPCOMING ? this.resolveTokens().accent :
            this.resolveTokens().control)
          .borderRadius(8)
          .margin({ top: 8 })
          .enabled(!this.createBusy)
          .onClick(() => {
            this.openComingUpEventNote(ev);
          })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .layoutWeight(1)
    .shadow({ radius: 4, color: this.resolveTokens().shadow, offsetY: 2 })
  }

  // 原版 e7n —— 不可读态 Connect 卡：title + subtitle，整卡点击触发
  // oye.n0(iwc.READ_CALENDAR) 权限请求（authorize→重新装载）。
  @Builder
  private ComingUpConnectCard() {
    Column() {
      Text($r('app.string.home_coming_up_connect_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Text($r('app.string.home_coming_up_connect_subtitle'))
        .fontSize(14)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 6 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.resolveTokens().surface)
    .borderRadius(12)
    .shadow({ radius: 4, color: this.resolveTokens().shadow, offsetY: 2 })
    .enabled(!this.comingUpBusy)
    .onClick(() => {
      this.connectComingUpCalendar();
    })
  }

  // 原版 hel.c/hel.a 计划本 cell：封面 drawable 预览（y1d.b().G →
  // 首个 webp）+ 计划本标题；卡片宽度与 NoteCard 行一致（160vp）。
  @Builder
  private HomePlannerSection() {
    Column() {
      Text($r('app.string.planners_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Column() {
        Image($rawfile('planners/cover_0.webp'))
          .width(160)
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(12)
        Text(ACADEMIC_PLANNER.titleRes)
          .fontSize(13)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ top: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width(160)
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 12 })
      .enabled(!this.createBusy)
      .onClick(() => {
        // 原版 ywa.onSelectPlanner → d2d(cover=首个, weekStart=MONDAY) 默认值。
        this.plannerWeekStartKey = 'monday';
        this.plannerCoverIndex = 0;
        this.plannerSheetOpen = true;
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 32 })
  }

  // FAB 新建按钮（64vp 右下角）
  // T-040 修复：Button builder 形式 + Text 全铺满居中（原 Button('+') 文本基线导致“+”视觉偏移）
  @Builder
  FabButton() {
    if (!this.isMultiSelecting) {
    // Original: apb.d/zs.a renders the speed-dial as a Compose DropdownMenu
    // popup (dismisses on outside tap via onDismissRequest). Mirror that with a
    // fullscreen transparent dismiss layer behind the chips+FAB.
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.createMenuOpen) {
        Column()
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.createMenuOpen = false;
          })
      }
      Column() {
      // Original cd case 0: the library create FAB expands to a speed-dial in
      // original order — Import, Templates (flag-gated), Document Scan
      // (capability-gated), then Create Note last as the primary action.
      // The leading Record chip carries ADR-0655's functional equivalence for
      // the feature-flagged "Record a lecture" home card (kept, not in cd).
      // (mw3 case 0 is the in-note empty-state row, not this FAB.)
      if (this.createMenuOpen) {
        this.CreateActionChip($r('app.string.record_audio'), () => {
          this.createAndRecord().catch((e: Error) => {
            console.error(`create recording note failed: ${JSON.stringify(e)}`);
          });
        }, $r('app.media.shortcut_new_recording'))
        this.CreateActionChip($r('app.string.library_import'), () => {
          this.importAndOpen().catch((e: Error) => {
            console.error(`import note action failed: ${JSON.stringify(e)}`);
          });
        }, $r('app.media.fab_import'))
        this.CreateActionChip($r('app.string.templates'), () => {
          this.templateDialog.open();
        }, $r('app.media.fab_templates'))
        if (this.docScanAvailable) {
          this.CreateActionChip($r('app.string.docscan'), () => {
            this.docScanOpen = true;
          }, $r('app.media.fab_docscan'))
        }
        this.CreateActionChip($r('app.string.create_note'), () => {
          this.createAndOpen().catch((e: Error) => {
            console.error(`create note action failed: ${JSON.stringify(e)}`);
          });
        }, $r('app.media.fab_createnote_filled'), true)
      }
      Button() {
        // 原版创建 FAB：折叠态为 ui_designsystem__plus（+），展开态为
        // close_med_regular（×），白字形于 accent 圆钮上。
        ToolGlyph({
          glyph: this.createMenuOpen ? 'close_med_regular' : 'plus',
          contentColor: this.resolveTokens().onAccent,
          iconSize: 26,
        })
      }
      .width(64)
      .height(64)
      .borderRadius(32)
      .margin({ top: 8 })
      .enabled(!this.createBusy)
      // 原版 feature_library__cd_add_note：创建 FAB 的无障碍标签。
      .accessibilityText($r('app.string.cd_add_note'))
      .onClick(() => {
        this.createMenuOpen = !this.createMenuOpen;
      })
      }
      .margin({ right: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    }
  }

  @Builder
  // Original cwi.b: each speed-dial chip is a Button holding an icon painter
  // (go5.b) followed by the label text (tpe.b). Icons are the ported
  // feature_library__* vectors (fab_*), dark-qualified under resources/dark.
  CreateActionChip(label: ResourceStr, action: () => void, icon: ResourceStr,
    emphasized: boolean = false) {
    Button() {
      Row() {
        Image(icon)
          .width(18)
          .height(18)
          .margin({ right: 8 })
        Text(label)
          .fontSize(14)
          .fontColor(emphasized
            ? this.resolveTokens().onAccent
            : this.resolveTokens().textPrimary)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .height(36)
    .padding({ left: 16, right: 16 })
    // wp8 variant: FILLED(accent) for the primary Create Note, TINTED(surface)
    // for Import/Templates/DocScan — matching cd case 0's wp8.I vs wp8.J.
    .backgroundColor(emphasized
      ? this.resolveTokens().accent
      : this.resolveTokens().surface)
    .borderRadius(18)
    .margin({ bottom: 8 })
    .enabled(!this.createBusy)
    .onClick(() => {
      this.createMenuOpen = false;
      action();
    })
  }

  @Builder
  DocScanCover() {
    Column() {
      DocumentScanner({
        scannerConfig: this.ensureDocScanConfig(),
        onResult: (code: number, saveType: SaveOption, uris: string[]): void => {
          this.onDocScanResult(code, uris);
        }
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }

  private tipSeen(kind: OnboardingTooltipKind): boolean {
    return this.onboardingSeen.indexOf(kind) !== -1;
  }

  // 原版 fsi.g 内部校验 !seen；库侧站点上下文为 "已有笔记"（enh/yj9 调用方
  // 布尔语义）。
  private libraryTipVisible(kind: OnboardingTooltipKind): boolean {
    return this.onboardingSeenReady && this.notes.length > 0 &&
      !this.tipSeen(kind);
  }

  // 原版 js7："Got it" → pq9 写入 onboardingTooltipSeen 并持久化。
  private dismissLibraryTip(kind: OnboardingTooltipKind): void {
    if (this.onboardingSeen.indexOf(kind) === -1) {
      this.onboardingSeen = this.onboardingSeen.concat([kind]);
    }
    const store: OnboardingTooltipStore | null = this.onboardingStore;
    if (store !== null) {
      store.markSeen(kind).catch((e: Error): void => {
        console.error('onboarding markSeen failed: ' + JSON.stringify(e));
      });
    }
  }

  @Builder
  private OnboardingCompletedTip() {
    OnboardingTipBubble({
      tipText: $r('app.string.data_onboarding__first_note_completed_tooltip_text'),
      onGotIt: (): void => {
        this.dismissLibraryTip(OnboardingTooltipKind.FIRST_NOTE_COMPLETED);
      },
    })
  }

  @Builder
  private OnboardingOrganizeTip() {
    OnboardingTipBubble({
      tipText: $r('app.string.data_onboarding__compact_organize_tooltip_text'),
      onGotIt: (): void => {
        this.dismissLibraryTip(OnboardingTooltipKind.COMPACT_ORGANIZE);
      },
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
        // 原版 b5j 单元格前导槽（xj9 → tj9 case0/6 = pk9.o 长按进多选）：
        // 多选态 → o94 勾选圈；普通态 → ⋯ 溢出按钮展开 d5j 菜单。
        Row() {
          if (this.isMultiSelecting) {
            this.SelectCircle(note)
          } else {
            this.NoteMenuButton(note)
          }
        }
        .position({ x: 4, y: 4 })
        // pf9.java: w09.favorited renders the favorite_fill badge overlay.
        if (note.favorite) {
          // 原版 favorite_fill 心形徽标（accent 着色）。
          ToolGlyph({
            glyph: 'favorite_fill',
            contentColor: this.resolveTokens().accent,
            iconSize: 16,
          })
            .margin({ top: 6, right: 6 })
            .accessibilityText($r('app.string.favorite_notes'))
        }
      }
      .width('100%')
      .layoutWeight(1)
      // Original e5j.h: a null/empty materialized title renders the
      // default_note_title ("New Note") on the card, never blank.
      Text(note.title.length > 0 ? note.title : $r('app.string.untitled_note'))
        .fontSize(14)
        .maxLines(1)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 8 })
      // Original gb6.b0/c0: RECENT cards show lastOpened, others updatedAt.
      Text(this.formatLibraryDate(this.currentFolderId === null &&
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
          // 原版 w09.l 录音徽标 = ui_designsystem__record_mic_outline。
          ToolGlyph({
            glyph: 'record_mic_outline',
            contentColor: this.resolveTokens().textSecondary,
            iconSize: 12,
          })
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
    // 原版 feature_library__cd_open_note_titled / cd_open_note：卡片即
    // "Open note %1$s"；无标题时用无参变体。
    .accessibilityText(note.title.length > 0 ?
      $r('app.string.cd_open_note_titled', note.title) :
      $r('app.string.cd_open_note'))
    .onClick(() => {
      // 原版 pk9.n：多选态点击 = r() 翻转选中；普通态才打开笔记。
      if (this.isMultiSelecting) {
        this.toggleMultiSelectId(note.id);
        return;
      }
      if (!this.pageActive) {
        return;
      }
      router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: note.id } })
        .catch((err: BusinessError) => {
          console.error(`pushUrl failed: ${err.code}`);
        });
    })
    // 原版 tj9 case0/6 → pk9.o：长按进入多选并选中该笔记；d5j 菜单改由
    // ⋯ 溢出按钮触发。
    .gesture(LongPressGesture().onAction(() => {
      this.enterMultiSelect(note.id);
    }))
    // 原版 ajh fsi.h(pq9.P, pos4)：首张笔记卡的整理引导气泡。
    .bindPopup(this.libraryTipVisible(OnboardingTooltipKind.FIRST_NOTE_COMPLETED) &&
      this.notes.length > 0 && note.id === this.notes[0].id, {
      builder: (): void => {
        this.OnboardingCompletedTip()
      },
      placement: Placement.Right,
      mask: false,
      autoCancel: false,
    })
  }

  // Original m5j.b: ie7.LIST renders a compact horizontal row — small
  // thumbnail, then title/date/chip column; same open + long-press
  // context-menu behavior as the grid card.
  @Builder
  NoteListRow(note: NoteMeta) {
    Row() {
      // 原版 cti.c 行首槽：多选态 → o94 勾选圈；普通态 → ⋯ 溢出按钮。
      Row() {
        if (this.isMultiSelecting) {
          this.SelectCircle(note)
        } else {
          this.NoteMenuButton(note)
        }
      }
      .width(28)
      .justifyContent(FlexAlign.Center)
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
          // 原版 favorite_fill 心形徽标（accent 着色）。
          ToolGlyph({
            glyph: 'favorite_fill',
            contentColor: this.resolveTokens().accent,
            iconSize: 12,
          })
            .margin({ top: 2, right: 2 })
            .accessibilityText($r('app.string.favorite_notes'))
        }
      }
      .width(48)
      .height(64)
      Column() {
        // Original e5j.h: empty materialized title -> default_note_title.
        Text(note.title.length > 0 ? note.title : $r('app.string.untitled_note'))
          .fontSize(14)
          .maxLines(1)
          .fontColor(this.resolveTokens().textPrimary)
        Text(this.formatLibraryDate(this.currentFolderId === null &&
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
            // 原版 w09.l 录音徽标 = ui_designsystem__record_mic_outline。
            ToolGlyph({
              glyph: 'record_mic_outline',
              contentColor: this.resolveTokens().textSecondary,
              iconSize: 12,
            })
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
    // 原版 feature_library__cd_open_note_titled / cd_open_note：卡片即
    // "Open note %1$s"；无标题时用无参变体。
    .accessibilityText(note.title.length > 0 ?
      $r('app.string.cd_open_note_titled', note.title) :
      $r('app.string.cd_open_note'))
    .onClick(() => {
      // 原版 pk9.n：多选态点击 = r() 翻转选中；普通态才打开笔记。
      if (this.isMultiSelecting) {
        this.toggleMultiSelectId(note.id);
        return;
      }
      if (!this.pageActive) {
        return;
      }
      router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: note.id } })
        .catch((err: BusinessError) => {
          console.error(`pushUrl failed: ${err.code}`);
        });
    })
    // 原版 tj9 case0/6 → pk9.o：长按进入多选并选中该笔记；d5j 菜单改由
    // ⋯ 溢出按钮触发。
    .gesture(LongPressGesture().onAction(() => {
      this.enterMultiSelect(note.id);
    }))
    // 原版 ajh fsi.h(pq9.P, pos4)：列表变体同样锚定首行。
    .bindPopup(this.libraryTipVisible(OnboardingTooltipKind.FIRST_NOTE_COMPLETED) &&
      this.notes.length > 0 && note.id === this.notes[0].id, {
      builder: (): void => {
        this.OnboardingCompletedTip()
      },
      placement: Placement.Right,
      mask: false,
      autoCancel: false,
    })
  }

  // 卡片物化标题（e5j.h 语义：空标题 → untitled_note，与卡片 Text 显示一致）。
  private noteDisplayTitle(note: NoteMeta): string {
    if (note.title.length > 0) {
      return note.title;
    }
    try {
      return getContext(this).resourceManager.getStringSync($r('app.string.untitled_note').id);
    } catch (_e) {
      return 'New Note';
    }
  }

  // 原版 d2n.c 侧栏文件夹滑动揭示：delete（trash 图标钮）→
  // confirmDeleteFolder（kcj 九宫复数文案确认框）。
  @Builder
  FolderSwipeAction(item: FolderListItem) {
    Button() {
      ToolGlyph({
        glyph: 'trash',
        contentColor: this.resolveTokens().onAccent,
        iconSize: 20,
      })
    }
      .type(ButtonType.Normal)
      .width(48)
      .height('100%')
      .backgroundColor(this.resolveTokens().danger)
      .accessibilityText($r('app.string.delete_folder_swipe_action', item.folder.name))
      .onClick(() => {
        this.confirmDeleteFolder(item.folder);
      })
  }

  // 原版 wbn.c 滑动揭示条：左滑行尾揭出操作区，内排 favorite、
  // 边缘为 delete（cc3.l 图标钮）；点击 favorite → toggleNoteFavorite
  // （ucb.invoke），点击 delete → confirmDelete（wpa 置态起确认框）。
  @Builder
  NoteSwipeActions(note: NoteMeta) {
    Row() {
      Button() {
        ToolGlyph({
          glyph: note.favorite ? 'unfavorite_outline' : 'favorite_outline',
          contentColor: this.resolveTokens().onAccent,
          iconSize: 22,
        })
      }
        .type(ButtonType.Normal)
        .width(56)
        .height('100%')
        .backgroundColor(this.resolveTokens().accent)
        .accessibilityText(note.favorite ?
          $r('app.string.unfavorite_note_swipe_action', this.noteDisplayTitle(note)) :
          $r('app.string.favorite_note_swipe_action', this.noteDisplayTitle(note)))
        .onClick(() => {
          this.toggleNoteFavorite(note);
        })
      Button() {
        ToolGlyph({
          glyph: 'trash',
          contentColor: this.resolveTokens().onAccent,
          iconSize: 22,
        })
      }
        .type(ButtonType.Normal)
        .width(56)
        .height('100%')
        .backgroundColor(this.resolveTokens().danger)
        .accessibilityText($r('app.string.delete_note_swipe_action', this.noteDisplayTitle(note)))
        .onClick(() => {
          this.confirmDelete(note);
        })
    }
    .height('100%')
  }

  // 原版 l9b（o94 勾选圈）：checkmark_circle（已选）/circle_empty_med_outline
  // （未选），a11y 带标题——已选 "Deselect note %s"、未选 "Select note %s"。
  @Builder
  SelectCircle(note: NoteMeta) {
    if (this.selectedNoteIds.indexOf(note.id) >= 0) {
      // 原版 o94 已选 = ui_designsystem__checkmark_circle（accent 着色）。
      ToolGlyph({
        glyph: 'checkmark_circle',
        contentColor: this.resolveTokens().accent,
        iconSize: 20,
      })
        .accessibilityText($r('app.string.cd_deselect_note_titled', this.noteDisplayTitle(note)))
    } else {
      // 原版未选 = ui_designsystem__circle_empty_med_outline（空心描边圈）。
      ToolGlyph({
        glyph: 'circle_empty_med_outline',
        contentColor: this.resolveTokens().textSecondary,
        iconSize: 20,
      })
        .accessibilityText($r('app.string.cd_select_note_titled', this.noteDisplayTitle(note)))
    }
  }

  // 原版 b5j/m5j 单元格溢出按钮：点击展开 d5j 菜单（bindMenu 替代
  // bindContextMenu——长按已让位 pk9.o 多选进入）。
  @Builder
  NoteMenuButton(note: NoteMeta) {
    // 原版单元格溢出 = ui_designsystem__more（竖向三点）。
    ToolGlyph({
      glyph: 'more',
      contentColor: this.resolveTokens().textPrimary,
      iconSize: 16,
    })
      .width(28)
      .height(24)
      .accessibilityText($r('app.string.note_actions'))
      .bindMenu(() => {
        this.NoteContextMenu(note)
      })
  }

  // 原版 hof：多选顶栏——Select All/Deselect All（ek9.a：选中集 ⊇
  // 可见列表 → Deselect All）+ "N notes selected" 计数 + Done（pk9.p）。
  @Builder
  MultiSelectTopBar() {
    Row() {
      Button(this.allVisibleSelected() ?
        $r('app.string.deselect_all') : $r('app.string.select_all'))
        .height(40)
        .fontSize(13)
        .enabled(!this.multiSelectBusy)
        .onClick(() => {
          this.toggleSelectAll();
        })
      Text(this.selectedNoteIds.length === 1 ?
        $r('app.string.note_selected_singular', this.selectedNoteIds.length) :
        $r('app.string.notes_selected', this.selectedNoteIds.length))
        .fontSize(14)
        .fontColor(this.resolveTokens().textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Button($r('app.string.done'))
        .height(40)
        .fontSize(13)
        .onClick(() => {
          this.exitMultiSelect();
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }

  // 原版 l05/fj9/gj9：多选底部动作条——Duplicate / Favorite（ek9.e
  // 全已收藏 → Unfavorite）/ Delete；ek9.b：actionsEnabled=count>0；
  // Share 受 lc4 旗标门控（fail-closed 登记至 Phase 674 多笔记分享）；
  // xri.a：busy 时进度。
  @Builder
  MultiSelectActionBar() {
    if (this.isMultiSelecting) {
      Row() {
        if (this.multiSelectBusy) {
          LoadingProgress()
            .width(20)
            .height(20)
            .margin({ right: 8 })
        }
        Button($r('app.string.share'))
          .height(40)
          .fontSize(13)
          .margin({ left: 8, right: 8 })
          .enabled(this.selectedNoteIds.length > 0 && !this.multiSelectBusy &&
            !this.multiShareBusy)
          .onClick(() => {
            // 原版 l05 底栏 share 图标（lc4.a(ac4.L) 旗标本期交付）：
            // 打开 v6d.a=多笔记形态的分享面板。
            this.multiShareFormat = 'pdf';
            this.multiShareIncludeBackground = false;
            this.multiShareIncludeRecording = true;
            this.multiSharePassword = null;
            this.multiSharePasswordDraft = '';
            this.multiSharePasswordConfirm = '';
            this.multiSharePasswordEditing = false;
            this.multiSharePasswordMismatch = false;
            this.multiShareOpen = true;
          })
        Button($r('app.string.duplicate_note'))
          .height(40)
          .fontSize(13)
          .margin({ left: 8, right: 8 })
          .enabled(this.selectedNoteIds.length > 0 && !this.multiSelectBusy)
          .onClick(() => {
            this.multiDuplicate();
          })
        Button(this.allSelectedFavorited() ?
          $r('app.string.unfavorite_note') : $r('app.string.favorite_note'))
          .height(40)
          .fontSize(13)
          .margin({ left: 8, right: 8 })
          .enabled(this.selectedNoteIds.length > 0 && !this.multiSelectBusy)
          .onClick(() => {
            this.multiSetFavorite().catch((e: Error) => {
              console.error(`multi favorite failed: ${JSON.stringify(e)}`);
            });
          })
        Button($r('app.string.delete'))
          .height(40)
          .fontSize(13)
          .margin({ left: 8, right: 8 })
          .enabled(this.selectedNoteIds.length > 0 && !this.multiSelectBusy)
          .onClick(() => {
            this.confirmMultiDelete();
          })
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.resolveTokens().surface)
    }
  }

  // 原版 pk9.o：长按笔记进入多选并选中该笔记（tj9 case0/6 → o(ttf)：
  // X=true 后 r(id) 立即选中）。
  private enterMultiSelect(noteId: string): void {
    if (!this.pageActive || this.isMultiSelecting) {
      return;
    }
    this.isMultiSelecting = true;
    this.selectedNoteIds = [noteId];
  }

  // 原版 pk9.r：翻转 id 成员（X=true 时 n() 亦走这里）。
  private toggleMultiSelectId(noteId: string): void {
    const next: string[] = this.selectedNoteIds.slice();
    const idx: number = next.indexOf(noteId);
    if (idx >= 0) {
      next.splice(idx, 1);
    } else {
      next.push(noteId);
    }
    this.selectedNoteIds = next;
  }

  // 原版 pk9.p：退出多选——X=false 且清空 Y。
  private exitMultiSelect(): void {
    this.isMultiSelecting = false;
    this.selectedNoteIds = [];
    this.multiSelectBusy = false;
  }

  // 原版 MainActivity.dispatchKeyEvent（KeyEvent Up）→ vla.b 查 vla.a 表 →
  // bma.a → lra.handleNavigationShortcut（if2，feed 含 j19 时生效——
  // LibraryPage 即笔记内容面，等价恒真）。qa8 四维精确匹配：
  //   Ctrl+N        → xla（new_note）→ mqa 建并打开笔记
  //   Ctrl+Shift+N  → vla.b（new_window）——无多窗通路，消费空转（原版同样
  //                   消费："New Window chord dropped: launcher not ready"）
  //   Ctrl+,        → zla（open_settings）→ lra.U(null)
  //   Ctrl+/        → yla（open_help）→ qw6 路由——Harmony 无帮助面，
  //                   fail-closed 消费空转
  //   Ctrl+L        → wla（back_to_library）→ 回到 All Notes 根
  //   ESC           → dismiss_deselect——多选中清空选区，否则透传系统返回
  private onLibraryKeyEvent(event: KeyEvent): boolean {
    if (event.type !== KeyType.Up) {
      return false;
    }
    if (matchKeyChord(event, ORIGIN_CHORD_NEW_WINDOW) ||
      matchKeyChord(event, ORIGIN_CHORD_OPEN_HELP)) {
      return true;
    }
    if (matchKeyChord(event, ORIGIN_CHORD_NEW_NOTE)) {
      if (!this.createBusy) {
        this.createAndOpen().catch((e: Error) => {
          console.error(`kbd new note failed: ${JSON.stringify(e)}`);
        });
      }
      return true;
    }
    if (matchKeyChord(event, ORIGIN_CHORD_OPEN_SETTINGS)) {
      this.navigateToSettings();
      return true;
    }
    if (matchKeyChord(event, ORIGIN_CHORD_BACK_TO_LIBRARY)) {
      this.selectFolder(null).catch((e: Error) => {
        console.error(`kbd back-to-library failed: ${JSON.stringify(e)}`);
      });
      return true;
    }
    if (matchKeyChord(event, ORIGIN_CHORD_DISMISS)) {
      if (this.isMultiSelecting) {
        this.exitMultiSelect();
        return true;
      }
      return false;
    }
    return false;
  }

  // 原版 ek9.a：选中集 ⊇ 当前可见列表 → Deselect All，否则 Select All。
  private allVisibleSelected(): boolean {
    if (this.notes.length === 0) {
      return false;
    }
    for (const note of this.notes) {
      if (this.selectedNoteIds.indexOf(note.id) < 0) {
        return false;
      }
    }
    return true;
  }

  private toggleSelectAll(): void {
    this.selectedNoteIds = this.allVisibleSelected() ? [] :
      this.notes.map((n: NoteMeta) => n.id);
  }

  // 原版 ek9.e：allSelectedAreFavorited——驱动 Favorite/Unfavorite 翻转。
  private allSelectedFavorited(): boolean {
    if (this.selectedNoteIds.length === 0) {
      return false;
    }
    for (const id of this.selectedNoteIds) {
      const note: NoteMeta | undefined =
        this.notes.find((n: NoteMeta) => n.id === id);
      if (note === undefined || !note.favorite) {
        return false;
      }
    }
    return true;
  }

  // 原版 fj9 case1 批量 Duplicate：逐笔记 export→import 往返（同单笔记
  // duplicateNote 语义）。
  private multiDuplicate(): void {
    if (!this.pageActive || this.viewModel === null || this.multiSelectBusy ||
      this.selectedNoteIds.length === 0) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const ids: string[] = this.selectedNoteIds.slice();
    const exporter: NoteExporter = new NoteExporter(this.db, this.persistence);
    const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
    this.multiSelectBusy = true;
    const run: () => Promise<void> = async (): Promise<void> => {
      for (const id of ids) {
        const data: Uint8Array | null = await exporter.exportNote(id);
        if (data === null) {
          throw new Error('exportNote returned null');
        }
        const report: ImportReport = await importer.importFromData(data);
        if (report.noteId === null) {
          throw new Error(`duplicate import failed: ${report.message}`);
        }
      }
    };
    run().then(() => {
      this.multiSelectBusy = false;
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      promptAction.showToast({ message: $r('app.string.note_duplicated') });
      vm.loadNotes(this.searchText).then(() => {
        this.refreshRecentCardFeed();
        if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration &&
          this.viewModel === vm) {
          this.notes = vm.getFilteredNotes().slice();
          this.selectedNoteIds = this.selectedNoteIds.filter((id: string) =>
            this.notes.find((n: NoteMeta) => n.id === id) !== undefined);
        }
      }).catch((e: Error) => {
        console.error(`post-duplicate reload failed: ${JSON.stringify(e)}`);
      });
    }).catch((e: Error) => {
      this.multiSelectBusy = false;
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.multi_duplicate_failed') });
        console.error(`multi duplicate failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // 原版 gj9 case0 批量 Favorite/Unfavorite（ek9.e：全已收藏 → Unfavorite，
  // 否则全部置为收藏）。
  private async multiSetFavorite(): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.multiSelectBusy ||
      this.selectedNoteIds.length === 0) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const target: boolean = !this.allSelectedFavorited();
    this.multiSelectBusy = true;
    try {
      for (const id of this.selectedNoteIds.slice()) {
        const note: NoteMeta | undefined =
          this.notes.find((n: NoteMeta) => n.id === id);
        if (note !== undefined && note.favorite !== target) {
          await vm.toggleFavorite(id);
        }
      }
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
    } catch (e) {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.multi_favorite_failed') });
        console.error(`multi favorite failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.multiSelectBusy = false;
    }
  }

  // 原版 fj9 case2 批量 Delete → 确认后逐笔记 deleteNote（入 Recently
  // Deleted）；已删 id 从选中集剔除（ek9 重建语义），删空则退出多选。
  // 原版 dih 多笔记形态（v6d.a=true）：chip 行用 _multi 标签，
  // 页范围行整体隐藏（dih.a/h 的 e() 分派被 v6d.a 短路）；
  // PDF=dih.h 余下行（双开关 + 密码行）、NOTE=dih.d（录音开关）、
  // JPG/PNG=dih.a 余下行（背景开关）、LINK=dih.b（账号域，fail-closed）。
  // 原版 x2n.c + hel.b 计划本配置屏：返回钮 + 标题 + qmm 周起点分段行
  // + ne9.d 封面格（hel.d cell：webp 预览 + 名字 + 选中态）+ wuh.CREATE
  // "Create" CTA；创建期间 fel 模态进度（禁用返回、吞点击）。
  @Builder
  PlannerConfigSheet() {
    Column() {
      if (this.plannerCreating) {
        // 原版 fel：模态进度卡 "Creating your planner note"。
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text($r('app.string.creating_planner_note'))
            .fontSize(15)
            .fontColor(this.resolveTokens().textPrimary)
            .margin({ top: 16 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 标题行（x2n.c 顶栏：back + 计划本名）。
        Row() {
          Button() {
            ToolGlyph({
              glyph: 'chevron_left',
              contentColor: this.resolveTokens().textPrimary,
              iconSize: 22,
            })
          }
          .width(40)
          .height(40)
          .backgroundColor(Color.Transparent)
          .accessibilityText($r('app.string.back'))
          .onClick(() => {
            this.plannerSheetOpen = false;
          })
          Text(ACADEMIC_PLANNER.titleRes)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Blank().width(40)
        }
        .width('100%')
        .margin({ top: 4 })
        // hel.b 上半段：qmm 周起点分段（e2d.J 全量枚举序渲染）。
        Row() {
          ForEach(PLANNER_WEEK_STARTS, (start: PlannerWeekStart) => {
            Column() {
              Text(start.nameRes)
                .fontSize(14)
                .fontColor(this.plannerWeekStartKey === start.key
                  ? this.resolveTokens().onAccent
                  : this.resolveTokens().textPrimary)
            }
            .height(36)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .borderRadius(18)
            .backgroundColor(this.plannerWeekStartKey === start.key
              ? this.resolveTokens().accent
              : this.resolveTokens().surface)
            .margin({ left: 4, right: 4 })
            .onClick(() => {
              this.plannerWeekStartKey = start.key;
            })
          }, (start: PlannerWeekStart): string => start.key)
        }
        .width('100%')
        .margin({ top: 20, left: 8, right: 8 })
        // hel.b 下半段：ne9.d 封面格（y1d.J 枚举序，2×2）。
        Grid() {
          ForEach(PLANNER_COVERS, (cover: PlannerCover) => {
            GridItem() {
              Column() {
                Image($rawfile(cover.rawfilePath))
                  .width(120)
                  .height(150)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(10)
                  .border({
                    width: this.plannerCoverIndex === cover.index ? 2 : 0,
                    color: this.resolveTokens().accent,
                    radius: 10,
                  })
                Text(cover.nameRes)
                  .fontSize(13)
                  .fontColor(this.resolveTokens().textPrimary)
                  .margin({ top: 6 })
              }
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 12 })
              .onClick(() => {
                this.plannerCoverIndex = cover.index;
              })
            }
          }, (cover: PlannerCover): string => `${cover.index}`)
        }
        .columnsTemplate('1fr 1fr')
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 8 })
        // x2n.f wuh.CREATE —— "Create" 全宽 CTA。
        Button($r('app.string.planner_create'))
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveTokens().onAccent)
          .backgroundColor(this.resolveTokens().accent)
          .borderRadius(24)
          .margin({ top: 8 })
          .onClick(() => {
            this.createPlannerNote().catch((e: Error) => {
              console.error(`planner create failed: ${JSON.stringify(e)}`);
            });
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, bottom: 24 })
    .backgroundColor(this.resolveTokens().background)
  }

  // 原版 b13/a2d + c13.d：读 planners/<id>-<segment>.pdf 进导入管线 →
  // 物化单篇笔记 → 封面元素 = 所选 y1d（w95 case3 谓词把其它封面筛出
  // 候选池，等价于指定所选封面）；失败走 kan snackbar。
  private async createPlannerNote(): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy ||
      this.plannerCreating) {
      return;
    }
    let weekStart: PlannerWeekStart = PLANNER_WEEK_STARTS[0];
    for (const start of PLANNER_WEEK_STARTS) {
      if (start.key === this.plannerWeekStartKey) {
        weekStart = start;
        break;
      }
    }
    let cover: PlannerCover = PLANNER_COVERS[0];
    for (const item of PLANNER_COVERS) {
      if (item.index === this.plannerCoverIndex) {
        cover = item;
        break;
      }
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    this.plannerCreating = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      // 原版 a2d：planners/<id>-<e2d.F>.pdf 资产读出；strN=<标题>.pdf
      // 作为导入文件名使标题落到计划本名。
      const title: string = context.resourceManager.getStringSync(
        ACADEMIC_PLANNER.titleRes.id);
      const bytes: Uint8Array = await context.resourceManager
        .getRawFileContent(plannerPdfPath(ACADEMIC_PLANNER, weekStart));
      const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
      const report: ImportReport = await importer.importBundledPdfFromBytes(
        bytes, `${title}.pdf`);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      if (report.noteId === null) {
        // 原版 kan：planner_failed snackbar。
        promptAction.showToast({ message: $r('app.string.planner_failed') });
        return;
      }
      if (this.noteRepo !== null) {
        await this.noteRepo.setNoteCoverPreset(report.noteId, cover.presetKey);
      }
      await vm.loadNotes(this.searchText);
      this.refreshRecentCardFeed();
      this.plannerSheetOpen = false;
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
      await router.pushUrl({ url: 'ui/editor/NotePage',
        params: { noteId: report.noteId } });
    } catch (e) {
      if (lifecycleGeneration === this.lifecycleGeneration && this.pageActive) {
        promptAction.showToast({ message: $r('app.string.planner_failed') });
        console.error(`planner create failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.createBusy = false;
      this.plannerCreating = false;
    }
  }

  @Builder
  MultiShareSheet() {
    Column() {
      Text($r('app.string.share_multi_subject'))
        .fontSize(18)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 16 })
      Text($r('app.string.share_multi_subtitle'))
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 4 })
      // 原版 s6d chip 行（_multi 标签）：LINK 置灰吞点（dih.b 账号域）。
      Row() {
        this.MultiShareFormatChip('pdf', $r('app.string.share_chip_pdf_multi'))
        this.MultiShareFormatChip('note', $r('app.string.share_chip_note_multi'))
        this.MultiShareFormatChip('jpg', $r('app.string.share_chip_jpg_multi'))
        this.MultiShareFormatChip('png', $r('app.string.share_chip_png_multi'))
        this.MultiShareFormatChip('link', $r('app.string.share_link'))
      }
      .margin({ top: 16 })
      if (this.multiShareFormat === 'pdf') {
        this.MultiShareToggleRow($r('app.string.share_include_background'),
          this.multiShareIncludeBackground, (on: boolean) => {
            this.multiShareIncludeBackground = on;
          })
        this.MultiShareToggleRow($r('app.string.share_include_recording'),
          this.multiShareIncludeRecording, (on: boolean) => {
            this.multiShareIncludeRecording = on;
          })
        this.MultiSharePasswordRow()
      } else if (this.multiShareFormat === 'note') {
        this.MultiShareToggleRow($r('app.string.share_include_recording'),
          this.multiShareIncludeRecording, (on: boolean) => {
            this.multiShareIncludeRecording = on;
          })
      } else if (this.multiShareFormat === 'jpg' ||
        this.multiShareFormat === 'png') {
        this.MultiShareToggleRow($r('app.string.share_include_background'),
          this.multiShareIncludeBackground, (on: boolean) => {
            this.multiShareIncludeBackground = on;
          })
      } else {
        Text($r('app.string.share_link_unavailable'))
          .fontSize(13)
          .fontColor(this.resolveTokens().textSecondary)
          .margin({ top: 16 })
      }
      // 原版 g6d 动作行：Cancel + "Share Xs"（_multi action 标签）。
      Row() {
        Button($r('app.string.share_cancel'))
          .height(40)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ right: 8 })
          .onClick(() => {
            this.multiShareOpen = false;
          })
        Button(this.multiShareActionLabel())
          .height(40)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 8 })
          .enabled(this.multiShareFormat !== 'link' && !this.multiShareBusy)
          .onClick(() => {
            this.multiShare().catch((e: Error) => {
              console.error(`multi share failed: ${JSON.stringify(e)}`);
            });
          })
      }
      .margin({ top: 24, bottom: 16 })
    }
    .width('100%')
    .padding({ left: 24, right: 24 })
  }

  @Builder
  MultiShareFormatChip(format: string, label: Resource) {
    Button(label)
      .height(36)
      .fontSize(13)
      .margin({ right: 8 })
      .opacity(format === 'link' ? 0.4 :
        (this.multiShareFormat === format ? 1 : 0.7))
      .backgroundColor(this.multiShareFormat === format ?
        this.resolveTokens().accent : this.resolveTokens().control)
      .enabled(format !== 'link')
      .onClick(() => {
        this.multiShareFormat = format;
        this.multiSharePasswordEditing = false;
        this.multiSharePasswordMismatch = false;
      })
  }

  @Builder
  MultiShareToggleRow(label: Resource, value: boolean,
    onChange: (on: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.resolveTokens().textPrimary)
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange((on: boolean) => {
          onChange(on);
        })
    }
    .width('100%')
    .height(44)
    .margin({ top: 8 })
  }

  // 原版 zy7 密码行（On/Off）→ dih.g PASSWORD_ENTRY（草稿+确认+Save/
  // Remove；kw1：draft 空时 Save 禁用、kv1 仅在相等且非空时回写）。
  @Builder
  MultiSharePasswordRow() {
    Column() {
      Row() {
        Column() {
          Text($r('app.string.share_password'))
            .fontSize(15)
            .fontColor(this.resolveTokens().textPrimary)
          Text($r('app.string.share_password_subtitle'))
            .fontSize(12)
            .fontColor(this.resolveTokens().textSecondary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.multiSharePassword !== null ?
          $r('app.string.share_password_on') : $r('app.string.share_password_off'))
          .fontSize(14)
          .fontColor(this.resolveTokens().textSecondary)
      }
      .width('100%')
      .height(56)
      .margin({ top: 8 })
      .onClick(() => {
        this.multiSharePasswordEditing = !this.multiSharePasswordEditing;
        this.multiSharePasswordMismatch = false;
      })
      if (this.multiSharePasswordEditing) {
        TextInput({ placeholder: $r('app.string.share_password_enter'),
          text: this.multiSharePasswordDraft })
          .type(InputType.Password)
          .height(40)
          .margin({ top: 8 })
          .onChange((v: string) => {
            this.multiSharePasswordDraft = v;
            this.multiSharePasswordMismatch = false;
          })
        TextInput({ placeholder: $r('app.string.share_password_confirm'),
          text: this.multiSharePasswordConfirm })
          .type(InputType.Password)
          .height(40)
          .margin({ top: 8 })
          .onChange((v: string) => {
            this.multiSharePasswordConfirm = v;
            this.multiSharePasswordMismatch = false;
          })
        if (this.multiSharePasswordMismatch) {
          Text($r('app.string.share_password_mismatch'))
            .fontSize(12)
            .fontColor(this.resolveTokens().danger)
            .margin({ top: 4 })
        }
        Row() {
          Button($r('app.string.share_password_save'))
            .height(36)
            .fontSize(13)
            .margin({ right: 8 })
            .enabled(this.multiSharePasswordDraft.length > 0)
            .onClick(() => {
              if (this.multiSharePasswordDraft !== this.multiSharePasswordConfirm) {
                this.multiSharePasswordMismatch = true;
                return;
              }
              this.multiSharePassword = this.multiSharePasswordDraft;
              this.multiSharePasswordEditing = false;
              this.multiSharePasswordMismatch = false;
            })
          if (this.multiSharePassword !== null) {
            Button($r('app.string.share_password_remove'))
              .height(36)
              .fontSize(13)
              .onClick(() => {
                this.multiSharePassword = null;
                this.multiSharePasswordDraft = '';
                this.multiSharePasswordConfirm = '';
                this.multiSharePasswordEditing = false;
                this.multiSharePasswordMismatch = false;
              })
          }
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  private multiShareActionLabel(): Resource {
    if (this.multiShareFormat === 'pdf') {
      return $r('app.string.share_action_pdf_multi');
    }
    if (this.multiShareFormat === 'note') {
      return $r('app.string.share_action_note_multi');
    }
    if (this.multiShareFormat === 'jpg') {
      return $r('app.string.share_action_jpg_multi');
    }
    if (this.multiShareFormat === 'png') {
      return $r('app.string.share_action_png_multi');
    }
    return $r('app.string.share_action_link');
  }

  private resolveMultiShareTitle(noteId: string): string {
    const note: NoteMeta | undefined =
      this.notes.find((n: NoteMeta) => n.id === noteId);
    const title: string = note === undefined ? '' : note.title;
    return title.length > 0 ? title : 'note';
  }

  private safeShareFileName(title: string): string {
    const cleaned: string = title.replace(/[\\/:*?"<>|]/g, '_').trim();
    return cleaned.length > 0 ? cleaned : 'note';
  }

  private writeShareFile(path: string, bytes: Uint8Array): void {
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE |
      fileIo.OpenMode.TRUNC);
    try {
      let offset: number = 0;
      while (offset < bytes.byteLength) {
        offset += fileIo.writeSync(file.fd, bytes.buffer,
          { offset: offset, length: bytes.byteLength - offset });
      }
      fileIo.fsyncSync(file.fd);
    } finally {
      fileIo.closeSync(file);
    }
  }

  // 原版 b7d.i 多笔记分享：逐笔记按选中格式产出文件，经系统分享面板
  // 一次交付（ACTION_SEND_MULTIPLE 等价物 = systemShare 多 SharedRecord）。
  // v6d.a=true → 无页子集，每笔记全部页；v6d.k 密码逐 PDF 复用；
  // JPG/PNG 每笔记整册页 → page_NNN.<ext> zip（Phase 644 同构适配）。
  private async multiShare(): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.multiShareBusy ||
      this.selectedNoteIds.length === 0 || this.multiShareFormat === 'link') {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const ids: string[] = this.selectedNoteIds.slice();
    const format: string = this.multiShareFormat;
    const includeBackground: boolean = this.multiShareIncludeBackground;
    const includeRecording: boolean = this.multiShareIncludeRecording;
    const password: string | null = this.multiSharePassword;
    this.multiShareBusy = true;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const dir: string = `${context.tempDir}/multishare_${Date.now()}`;
      fileIo.mkdirSync(dir);
      const records: systemShare.SharedRecord[] = [];
      if (format === 'note') {
        const exporter: NoteExporter = new NoteExporter(this.db, this.persistence);
        for (const id of ids) {
          const title: string = this.resolveMultiShareTitle(id);
          const data: Uint8Array | null = await exporter.exportNote(id,
            includeRecording);
          if (data === null) {
            throw new Error(`exportNote returned null: ${id}`);
          }
          const path: string = `${dir}/${this.safeShareFileName(title)}.note`;
          this.writeShareFile(path, data);
          records.push({
            utd: uniformTypeDescriptor.UniformDataType.FILE,
            uri: fileUri.getUriFromPath(path),
            title: `${title}.note`,
          });
        }
      } else {
        const renderer: ThumbnailRenderer = new ThumbnailRenderer();
        const packer: image.ImagePacker = image.createImagePacker();
        const pageRepo: PageRepositoryImpl = new PageRepositoryImpl(this.db);
        try {
          await renderer.initialize(context);
          const theme: ThemeTokens = ThemeStore.resolve('light', false);
          for (const id of ids) {
            const title: string = this.resolveMultiShareTitle(id);
            const pages: PageInfo[] = await pageRepo.getPages(id);
            if (pages.length === 0) {
              continue;
            }
            const exportBackground: string = includeBackground ? 'paper' :
              (format === 'png' ? 'transparent' : 'white');
            if (format === 'pdf') {
              const imagePages: PdfPageImage[] = [];
              for (const page of pages) {
                const pixelMap: PixelMap = await renderer.renderPageExport(id,
                  this.persistence, page, theme, this.db, 2.0, exportBackground);
                try {
                  const info: image.ImageInfo = pixelMap.getImageInfoSync();
                  const data: ArrayBuffer = await packer.packToData(pixelMap, {
                    format: 'image/jpeg',
                    quality: 92,
                    bufferSize: 64 * 1024 * 1024,
                  });
                  imagePages.push({
                    jpegData: new Uint8Array(data),
                    widthPx: info.size.width,
                    heightPx: info.size.height,
                    widthMm: page.widthMm,
                    heightMm: page.heightMm,
                  });
                } finally {
                  await pixelMap.release();
                }
              }
              const pdfBytes: Uint8Array = buildPdf(imagePages);
              const path: string =
                `${dir}/${this.safeShareFileName(title)}.pdf`;
              this.writeShareFile(path, pdfBytes);
              let srcPath: string = path;
              if (password !== null && password.length > 0) {
                const encPath: string =
                  `${dir}/${this.safeShareFileName(title)}_enc.pdf`;
                encryptPdfFile(path, encPath, password);
                srcPath = encPath;
              }
              // 原版 x59/x8b：include_recording 开且录音列表非空 →
              // 该笔记产物升级为 <title>.zip（内嵌同名 .pdf +
              // Recordings/<sanitized>.<ext>，重名 " (N)" N 自 1）。
              const recordings = includeRecording ?
                await new OriginalRecordingStore(this.db).listVisible(id) : [];
              if (recordings.length > 0) {
                const zipWriter: ZipWriter = new ZipWriter();
                zipWriter.addEntry(`${shareEntryName(title)}.pdf`,
                  readFileFully(srcPath), true);
                const usedNames: Set<string> = new Set<string>();
                for (const rec of recordings) {
                  if (rec.localPath === null || rec.localPath.length === 0 ||
                    !fileIo.accessSync(rec.localPath)) {
                    continue;
                  }
                  const baseName: string = shareEntryName(rec.name);
                  const ext: string = shareZipExtension(rec.assetMimeType);
                  let entryName: string = `Recordings/${baseName}.${ext}`;
                  let dup: number = 1;
                  while (usedNames.has(entryName)) {
                    entryName = `Recordings/${baseName} (${dup}).${ext}`;
                    dup++;
                  }
                  usedNames.add(entryName);
                  zipWriter.addEntry(entryName, readFileFully(rec.localPath), true);
                }
                const zipPath: string =
                  `${dir}/${this.safeShareFileName(title)}.zip`;
                this.writeShareFile(zipPath, await zipWriter.build());
                records.push({
                  utd: uniformTypeDescriptor.UniformDataType.FILE,
                  uri: fileUri.getUriFromPath(zipPath),
                  title: `${title}.zip`,
                });
              } else {
                records.push({
                  utd: uniformTypeDescriptor.UniformDataType.PDF,
                  uri: fileUri.getUriFromPath(srcPath),
                  title: `${title}.pdf`,
                });
              }
            } else {
              const suffix: string = format === 'png' ? 'png' : 'jpg';
              const mime: string = format === 'png' ? 'image/png' : 'image/jpeg';
              const writer: ZipWriter = new ZipWriter();
              for (let i = 0; i < pages.length; i++) {
                const pixelMap: PixelMap = await renderer.renderPageExport(id,
                  this.persistence, pages[i], theme, this.db, 2.0,
                  exportBackground);
                try {
                  const data: ArrayBuffer = await packer.packToData(pixelMap, {
                    format: mime,
                    quality: format === 'png' ? 0 : 92,
                    bufferSize: 64 * 1024 * 1024,
                  });
                  const name: string =
                    `page_${('000' + (i + 1)).slice(-3)}.${suffix}`;
                  writer.addEntry(name, new Uint8Array(data), false);
                } finally {
                  await pixelMap.release();
                }
              }
              const zipBytes: Uint8Array = await writer.build();
              const path: string =
                `${dir}/${this.safeShareFileName(title)}_pages.zip`;
              this.writeShareFile(path, zipBytes);
              records.push({
                utd: uniformTypeDescriptor.UniformDataType.ZIP_ARCHIVE,
                uri: fileUri.getUriFromPath(path),
                title: `${title}_pages.zip`,
              });
            }
          }
        } finally {
          await packer.release();
          await renderer.dispose();
        }
      }
      if (records.length === 0) {
        throw new Error('no exportable notes');
      }
      const shared: systemShare.SharedData =
        new systemShare.SharedData(records[0]);
      for (let i = 1; i < records.length; i++) {
        shared.addRecord(records[i]);
      }
      const want: Want = await systemShare.getWant(shared);
      await context.startAbility(want);
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration &&
        this.viewModel === vm) {
        promptAction.showToast({ message: $r('app.string.export_done') });
        this.multiShareOpen = false;
      }
    } catch (e) {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.multi_share_failed') });
        console.error(`multi share failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.multiShareBusy = false;
    }
  }

  private confirmMultiDelete(): void {
    if (!this.pageActive || this.multiSelectBusy ||
      this.selectedNoteIds.length === 0) {
      return;
    }
    const count: number = this.selectedNoteIds.length;
    this.getUIContext().showAlertDialog({
      // 原版 feature_library__delete_note_message（i8 case4）：标题随数量复数化。
      title: count === 1 ? $r('app.string.delete_note_title_one') :
        $r('app.string.delete_notes_title_other'),
      message: count === 1 ?
        $r('app.string.delete_notes_message_one', count) :
        $r('app.string.delete_notes_message', count),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        },
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        action: () => {
          this.multiDelete().catch((e: Error) => {
            console.error(`multi delete failed: ${JSON.stringify(e)}`);
          });
        },
      },
    });
  }

  private async multiDelete(): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.multiSelectBusy) {
      return;
    }
    const vm: LibraryViewModel = this.viewModel;
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.multiSelectBusy = true;
    try {
      for (const id of this.selectedNoteIds.slice()) {
        await vm.deleteNote(id);
      }
      if (!this.pageActive || lifecycleGeneration !== this.lifecycleGeneration ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
      this.selectedNoteIds = this.selectedNoteIds.filter((id: string) =>
        this.notes.find((n: NoteMeta) => n.id === id) !== undefined);
      if (this.selectedNoteIds.length === 0) {
        this.exitMultiSelect();
      }
    } catch (e) {
      if (this.pageActive && lifecycleGeneration === this.lifecycleGeneration) {
        promptAction.showToast({ message: $r('app.string.multi_delete_failed') });
        console.error(`multi delete failed: ${JSON.stringify(e)}`);
      }
    } finally {
      this.multiSelectBusy = false;
    }
    this.refreshThumbnails().catch((e: Error) => {
      console.error(`post-delete thumbnail refresh failed: ${JSON.stringify(e)}`);
    });
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
      // 原版 d5j 菜单行为 icon+label（apb.f）。startIcon 挂原版矢量。
      MenuItem({ content: $r('app.string.rename'), startIcon: $r('app.media.edit') })
        .onClick(() => {
          this.showRenameNoteDialog(note);
        })
      MenuItem({
        content: note.favorite ? $r('app.string.unfavorite_note') :
          $r('app.string.favorite_note'),
        startIcon: note.favorite ? $r('app.media.menuicon_unfavorite') :
          $r('app.media.menuicon_favorite')
      })
        .onClick(() => {
          this.toggleNoteFavorite(note);
        })
      MenuItem({ content: $r('app.string.duplicate_note'), startIcon: $r('app.media.selmenu_duplicate') })
        .onClick(() => {
          this.duplicateNote(note);
        })
      MenuItem({ content: $r('app.string.export_note'), startIcon: $r('app.media.menuicon_export') })
        .onClick(() => {
          this.exportNote(note);
        })
      MenuItem({ content: $r('app.string.show_in_folder'), startIcon: $r('app.media.menuicon_showfolder') })
        .enabled(note.folderId !== null)
        .onClick(() => {
          this.showNoteInFolder(note);
        })
      // 原版 sort_to_folder 复用 show_in_folder 图标。
      MenuItem({
        content: $r('app.string.move_to_folder'),
        startIcon: $r('app.media.menuicon_showfolder'),
        builder: () => {
          this.MoveNoteSubMenu(note)
        },
      })
      MenuItem({ content: $r('app.string.copy_note_id'), startIcon: $r('app.media.menuicon_noteinfo') })
        .onClick(() => {
          this.copyNoteId(note);
        })
      MenuItem({ content: $r('app.string.delete'), startIcon: $r('app.media.selmenu_delete') })
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

  // 原版 kcj 九格矩阵：i=子文件夹数、i2=笔记数；0,0 返回空串（无 detail 行）。
  private folderDeleteDetail(name: string, childFolders: number,
    noteCount: number): Resource {
    if (childFolders === 0 && noteCount === 0) {
      return $r('app.string.folder_delete_detail_empty');
    }
    if (childFolders === 1 && noteCount === 0) {
      return $r('app.string.folder_delete_detail_1f', name);
    }
    if (childFolders > 1 && noteCount === 0) {
      return $r('app.string.folder_delete_detail_nf', name, childFolders);
    }
    if (childFolders === 0 && noteCount === 1) {
      return $r('app.string.folder_delete_detail_1n', name);
    }
    if (childFolders === 0) {
      return $r('app.string.folder_delete_detail_nn', name, noteCount);
    }
    if (childFolders === 1 && noteCount === 1) {
      return $r('app.string.folder_delete_detail_1f_1n', name);
    }
    if (childFolders === 1) {
      return $r('app.string.folder_delete_detail_1f_nn', name, noteCount);
    }
    if (noteCount === 1) {
      return $r('app.string.folder_delete_detail_nf_1n', name, childFolders);
    }
    return $r('app.string.folder_delete_detail_nf_nn', name, childFolders, noteCount);
  }

  private async confirmDeleteFolder(folder: NoteFolder): Promise<void> {
    if (!this.pageActive || this.folderBusy) {
      return;
    }
    // 原版 kcj：按子文件夹数 i 与笔记数 i2 选九格复数文案
    // （0,0 → 无 detail；message 仅标题 "Delete folder?"）。
    const subtreeIds: string[] = [];
    for (const f of this.folders) {
      if (isFolderInSubtree(this.folders, folder.id, f.id)) {
        subtreeIds.push(f.id);
      }
    }
    const childFolders: number = subtreeIds.length - 1;
    let noteCount: number = 0;
    try {
      const allNotes: NoteMeta[] = this.noteRepo !== null ?
        await this.noteRepo.getAllNotes() : [];
      for (const note of allNotes) {
        if (note.folderId !== null && subtreeIds.indexOf(note.folderId) >= 0) {
          noteCount++;
        }
      }
    } catch (e) {
      console.error('folder delete count query failed: ' + JSON.stringify(e));
    }
    const detail: Resource = this.folderDeleteDetail(folder.name,
      childFolders, noteCount);
    this.getUIContext().showAlertDialog({
      title: $r('app.string.delete_folder_message'),
      message: detail,
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

  private async createFromTemplate(template: PaperTemplate): Promise<void> {
    await this.createAndLaunch(false, template);
  }

  private async createAndLaunch(autoRecord: boolean,
    templateOverride?: PaperTemplate, startCamera: boolean = false,
    folderId?: string, titleOverride?: string): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    let noteId: string;
    try {
      noteId = await vm.createNote(this.searchText, templateOverride, folderId,
        titleOverride);
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
      } else if (startCamera) {
        await router.pushUrl({ url: 'ui/editor/NotePage',
          params: { noteId: noteId, startCamera: '1' } });
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

  // 原版 hv7.i 的共享 intent 路径：队列 URI 逐个物化为独立笔记后
  // 打开最后一篇（原版 kx 协程同语义）；失败弹 toast。
  private drainLaunchIngress(): void {
    const requests: LaunchRequest[] = drainLaunchRequests();
    if (requests.length === 0) {
      return;
    }
    for (const request of requests) {
      const startCamera: boolean = request.action === LAUNCH_ACTION_CREATE_PHOTO_NOTE;
      const autoRecord: boolean = request.action === LAUNCH_ACTION_CREATE_RECORDING_NOTE;
      // 原版 FolderNotesWidgetProvider 创建钮：CREATE_NOTE + folder_id
      // —— 新笔记直接建进该文件夹（不改变当前库位置）。
      this.createAndLaunch(autoRecord, undefined, startCamera,
        request.folderId ?? undefined).catch((e: Error) => {
        console.error('shortcut launch create failed: ' + JSON.stringify(e));
      });
    }
  }

  // 原版 py2.a/py2.b：/app/note/<32-hex> 深链解析出的笔记 ID 在此
  // drain。note_meta.id 直查 + note_sync_metadata.legacy_id 兜底
  // （导入改号副本）；命中即打开 NotePage。未命中 = 本地无此笔记，
  // 原版需经订阅后端同步取回 —— fail-closed 弹「无法打开链接」。
  private drainDeepLinkIngress(): void {
    // 原版 /app/note 深链（DeepLinkIngress）与打开目标 extras
    // （OpenTargetIngress：v50 近期快捷项/qk9 小部件行/bv7 新窗口）
    // 共用同一 note-meta 解析与打开管线。
    const noteIds: string[] = [...drainDeepLinkNoteIds(), ...drainOpenNoteIds()];
    if (noteIds.length === 0) {
      return;
    }
    this.openDeepLinkNotes(noteIds).catch((e: Error) => {
      console.error('deep link open failed: ' + JSON.stringify(e));
    });
  }

  // 原版 RecentNotesWidgetProvider 的数据在 Realm 变更时推送刷新；
  // Harmony 侧每次 loadNotes 完成后推送到已注册的 recent_notes_card
  // 实例（标题 + 缩略图 formImages），等价原版观察者刷新。
  private refreshRecentCardFeed(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const theme: ThemeTokens = this.resolveTokens();
    refreshRecentNotesForms(context, theme).catch((e: Error) => {
      console.error(`recent card feed failed: ${JSON.stringify(e)}`);
    });
    refreshFolderNotesForms(context, theme).catch((e: Error) => {
      console.error(`folder card feed failed: ${JSON.stringify(e)}`);
    });
    refreshNoteThumbnailForms(context, theme).catch((e: Error) => {
      console.error(`thumb card feed failed: ${JSON.stringify(e)}`);
    });
  }

  // 原版 y14.a()+jt1 查询 + m70 case7 + nan.i 窗口化的一次装载；
  // kg3 ContentObserver 无等价 → 每次 Home 呈现时刷新。
  private refreshComingUp(lifecycleGeneration: number): void {
    if (this.comingUpBusy) {
      return;
    }
    const context = getContext(this) as common.UIAbilityContext;
    this.comingUpBusy = true;
    loadComingUpCalendarWindow(context, Date.now()).then(
      (window: ComingUpCalendarWindow): void => {
        this.comingUpBusy = false;
        if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive) {
          return;
        }
        const nowMs: number = Date.now();
        const days: ComingUpDayGroup[] = buildComingUpDays(window.events, nowMs);
        this.comingUpWindows = buildComingUpWindows(days);
        this.comingUpReadable = window.isReadable;
        this.comingUpNowMs = nowMs;
      }).catch((e: Error): void => {
        this.comingUpBusy = false;
        console.error(`coming-up load failed: ${JSON.stringify(e)}`);
        if (lifecycleGeneration === this.lifecycleGeneration && this.pageActive &&
          this.comingUpReadable === null) {
          this.comingUpReadable = false;
        }
      });
  }

  // 原版 e7n Connect 卡点击 → oye.n0(iwc.READ_CALENDAR, …)：发起系统授权，
  // 授权成功后重拉；授权弹窗展示后被拒 → 停留 Connect 卡；系统不再弹窗
  // （永久拒绝）→ he0 case11/jwc.c=true → l8n.d「Access Required」对话框。
  private connectComingUpCalendar(): void {
    if (this.comingUpBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    const context = getContext(this) as common.UIAbilityContext;
    requestComingUpCalendarPermission(context)
      .then((outcome: ComingUpCalendarRequestOutcome): void => {
        if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive) {
          return;
        }
        if (outcome === ComingUpCalendarRequestOutcome.GRANTED) {
          this.refreshComingUp(lifecycleGeneration);
          return;
        }
        this.comingUpReadable = false;
        if (outcome === ComingUpCalendarRequestOutcome.DENIED_HIDDEN) {
          this.showCalendarAccessDialog();
        }
      }).catch((e: Error): void => {
        console.error(`coming-up connect failed: ${JSON.stringify(e)}`);
      });
  }

  /**
   * 原版 oye.n0 内 l8n.d 对话框：jwc.c=true 时渲染——标题 = iwc.G
   * （calendar_access_required），正文 = iwc.H（calendar_access_rationale），
   * 按钮 = Dismiss（hwc/o9n.a）+ Go to Settings（b8 case9 → s86 case19
   * ACTION_APPLICATION_DETAILS_SETTINGS；Harmony = requestPermissionOnSetting）。
   */
  private showCalendarAccessDialog(): void {
    const accent: string = this.resolveTokens().accent;
    promptAction.showDialog({
      title: $r('app.string.calendar_access_required'),
      message: $r('app.string.calendar_access_rationale'),
      buttons: [
        { text: $r('app.string.go_to_settings'), color: accent },
        { text: $r('app.string.dismiss'), color: accent },
      ],
    }).then((response: promptAction.ShowDialogSuccessResponse): void => {
      if (response.index === 0 && this.pageActive) {
        const context = getContext(this) as common.UIAbilityContext;
        openComingUpCalendarSettings(context);
      }
    }).catch((e: Error): void => {
      console.error(`coming-up access dialog failed: ${JSON.stringify(e)}`);
    });
  }

  // 原版 nan.j —— ‹/› 在窗口序列上移动选中日键；边界由渲染层禁用。
  private comingUpShiftWindow(delta: number): void {
    const windows: ComingUpWindow[] = this.comingUpWindows;
    const next: number = this.comingUpWindowIndex() + delta;
    if (next < 0 || next >= windows.length) {
      return;
    }
    this.comingUpWindowKey = windows[next].startDateKey;
  }

  // nan.i rga → 窗口序号：按起始日键定位，找不到回落首窗口。
  private comingUpWindowIndex(): number {
    const windows: ComingUpWindow[] = this.comingUpWindows;
    if (windows.length === 0) {
      return 0;
    }
    const key: string | null = this.comingUpWindowKey;
    if (key === null) {
      return 0;
    }
    for (let i: number = 0; i < windows.length; i++) {
      if (windows[i].startDateKey === key) {
        return i;
      }
    }
    return 0;
  }

  // 原版 ne case11 → c13.a(…, ik.CALENDAR, title, …)：事件行 "Start now"
  // 以事件标题建笔记并打开（标题空 → 走默认标题管线，等同 str==null 分支）。
  private openComingUpEventNote(ev: ComingUpEvent): void {
    const title: string | undefined = /\S/.test(ev.title) ? ev.title : undefined;
    this.createAndLaunch(false, undefined, false, undefined, title)
      .catch((e: Error): void => {
        console.error(`coming-up note launch failed: ${JSON.stringify(e)}`);
      });
  }

  // 原版 nan.f/aa case2 —— 行内时间副标：全天 → "All day"；否则
  // ofLocalizedTime(SHORT)；STARTING_SOON/HAPPENING_NOW 包装
  // "%1$s • …" 富态前缀。
  private comingUpRowSubtitle(ev: ComingUpEvent, state: ComingUpEventState): string {
    const time: string = ev.isAllDay ?
      this.getStringSync($r('app.string.home_coming_up_all_day')) :
      new Intl.DateTimeFormat(undefined, { timeStyle: 'short' }).format(new Date(ev.startMs));
    if (state === ComingUpEventState.STARTING_SOON) {
      return this.getStringSync($r('app.string.home_coming_up_starting_soon'), time);
    }
    if (state === ComingUpEventState.HAPPENING_NOW) {
      return this.getStringSync($r('app.string.home_coming_up_happening_now'), time);
    }
    return time;
  }

  private getStringSync(res: Resource, ...args: string[]): string {
    try {
      return getContext(this).resourceManager.getStringSync(res.id, ...args);
    } catch (_e) {
      return args.length > 0 ? args[0] : '';
    }
  }

  // 原版 MainActivity 的 wu7.a 落地目标：show_library →
  // ALL_NOTES 区（资料库根视图）；RecentNotesWidgetProvider 本体
  // 的 show_recent → RECENT 区（dk9 区段同语义）。
  private drainOpenTargetIngress(): void {
    const landings: string[] = drainLibraryLandings();
    if (landings.length === 0) {
      return;
    }
    const last: string = landings[landings.length - 1];
    if (last.startsWith(LANDING_FOLDER_PREFIX)) {
      // 原版 FolderNotesWidgetProvider 头部：VIEW+folder_id →
      // 落进该文件夹视图；文件夹缺失时原版 g() 返回 null ——
      // 先校验存在再落地，缺失即 fail-closed 不动。
      const folderId: string = last.slice(LANDING_FOLDER_PREFIX.length);
      this.landInFolder(folderId).catch((e: Error) => {
        console.error('folder landing failed: ' + JSON.stringify(e));
      });
      return;
    }
    const section: LibrarySection = last === LANDING_RECENT ?
      LibrarySection.RECENT : LibrarySection.ALL_NOTES;
    this.selectSection(section).catch((e: Error) => {
      console.error('open-target landing failed: ' + JSON.stringify(e));
    });
  }

  private async landInFolder(folderId: string): Promise<void> {
    const db: DatabaseManager = DatabaseManager.getInstance();
    const folderRepo: FolderRepositoryImpl = new FolderRepositoryImpl(db);
    const folders: NoteFolder[] = await folderRepo.getAllFolders();
    const exists: boolean = folders.some((f: NoteFolder) => f.id === folderId);
    if (!exists || !this.pageActive || this.viewModel === null) {
      return;
    }
    await this.viewModel.setFolder(folderId, this.searchText);
    if (this.viewModel !== null) {
      this.notes = this.viewModel.getFilteredNotes().slice();
    }
  }

  private async openDeepLinkNotes(noteIds: string[]): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      const repo: NoteRepositoryImpl = new NoteRepositoryImpl(this.db);
      for (const deepLinkId of noteIds) {
        const noteId: string | null = await repo.resolveDeepLinkNoteId(deepLinkId);
        if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
          this.viewModel !== vm) {
          return;
        }
        if (noteId === null) {
          promptAction.showToast({ message: $r('app.string.deep_link_note_missing') });
          continue;
        }
        await vm.loadNotes(this.searchText);
          this.refreshRecentCardFeed();
        if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
          this.viewModel !== vm) {
          return;
        }
        this.notes = vm.getFilteredNotes().slice();
        await router.pushUrl({ url: 'ui/editor/NotePage', params: { noteId: noteId } });
      }
    } finally {
      this.createBusy = false;
    }
  }

  private drainSharedIngress(): void {
    const uris: string[] = drainSharedUris();
    if (uris.length === 0) {
      return;
    }
    this.importSharedAndOpen(uris).catch((e: Error) => {
      console.error(`shared ingress import failed: ${JSON.stringify(e)}`);
    });
  }

  // 原版 vs8 → ui_fileimport__pdfs_truncated：PDF 页数超上限截断导入后
  // 提示（one=单文件、other=多文件各取前 N 页）。
  private toastTruncatedPages(report: ImportReport): void {
    const pages: number = report.truncatedPages ?? 0;
    if (pages <= 0) {
      return;
    }
    const count: number = report.truncatedCount ?? 1;
    promptAction.showToast({
      message: count > 1 ?
        $r('app.string.import_pdfs_truncated_other', pages) :
        $r('app.string.import_pdf_truncated_one', pages) });
  }

  private async importSharedAndOpen(uris: string[]): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
      const report: ImportReport =
        await importer.importSharedUris(uris, this.pdfPasswordPrompt,
          this.importSheetPrompt);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      if (report.noteId === null) {
        if (report.result !== ImportResult.CANCELLED) {
          // 原版 vs8：打开失败按 gr9 分类——TooLarge 走 open_pdf_too_large，
          // 其余走 open_pdf_failed（密码保护由 pdfPasswordPrompt 交互流程
          // 覆盖，比原版 toast 更强，见 ADR-0669 偏差记录）。
          promptAction.showToast({
            message: report.result === ImportResult.TOO_LARGE ?
              $r('app.string.open_pdf_too_large') :
              $r('app.string.open_pdf_failed') });
        }
        return;
      }
      this.toastTruncatedPages(report);
      await vm.loadNotes(this.searchText);
          this.refreshRecentCardFeed();
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
        console.error(`shared ingress import failed: ${JSON.stringify(e)}`);
      }
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
      const report: ImportReport =
        await importer.importFromFile(context, this.pdfPasswordPrompt,
          this.importSheetPrompt);
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
      this.toastTruncatedPages(report);
      await vm.loadNotes(this.searchText);
          this.refreshRecentCardFeed();
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

  // 原版 ib7/pk9.onDocScanned(uri, title, success, failure)：VisionKit 回调
  // code 200=成功、-1=无结果（用户取消，静默）、1008601001=uri 无效。
  private onDocScanResult(code: number, uris: string[]): void {
    this.docScanOpen = false;
    if (code !== 200 || uris.length === 0) {
      if (code !== -1) {
        promptAction.showToast({ message: $r('app.string.doc_scan_failed') });
      }
      return;
    }
    this.importScannedAndOpen(uris).catch((e: Error) => {
      console.error(`doc scan import failed: ${JSON.stringify(e)}`);
    });
  }

  private ensureDocScanConfig(): DocumentScannerConfig {
    if (this.docScanConfig === null) {
      const config: DocumentScannerConfig = new DocumentScannerConfig();
      // 对齐原版 ML Kit 语义：文档类型、允许图库导入、产出 PDF、关闭
      // 自带分享钮（扫描结果只进新建笔记管线）。
      config.supportType = [DocType.DOC];
      config.saveOptions = [SaveOption.PDF];
      config.maxShotCount = ORIGINAL_DOC_SCAN_MAX_PAGES;
      config.isShareable = false;
      this.docScanConfig = config;
    }
    return this.docScanConfig;
  }

  // Original onDocScanned → scanned_document_title 新笔记：扫描 PDF uri
  // 经 sv5 CreateSingleNewNote 语义物化后打开（原版随后 onShowNoteInFolder）。
  private async importScannedAndOpen(uris: string[]): Promise<void> {
    if (!this.pageActive || this.viewModel === null || this.createBusy) {
      return;
    }
    const lifecycleGeneration: number = this.lifecycleGeneration;
    this.createBusy = true;
    const vm: LibraryViewModel = this.viewModel;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const importer: NoteImporter = new NoteImporter(this.db, this.persistence);
      const title: string = context.resourceManager.getStringSync(
        $r('app.string.scanned_document_title').id,
        this.formatLibraryDateTime(Date.now()));
      const report: ImportReport = await importer.importScannedDocument(
        uris, title, this.currentFolderId, this.pdfPasswordPrompt);
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      if (report.noteId === null) {
        promptAction.showToast({ message: $r('app.string.doc_scan_failed') });
        return;
      }
      await vm.loadNotes(this.searchText);
      this.refreshRecentCardFeed();
      if (lifecycleGeneration !== this.lifecycleGeneration || !this.pageActive ||
        this.viewModel !== vm) {
        return;
      }
      this.notes = vm.getFilteredNotes().slice();
      await router.pushUrl({ url: 'ui/editor/NotePage',
        params: { noteId: report.noteId } });
    } catch (e) {
      if (lifecycleGeneration === this.lifecycleGeneration && this.pageActive) {
        promptAction.showToast({ message: $r('app.string.doc_scan_failed') });
        console.error(`doc scan import failed: ${JSON.stringify(e)}`);
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

  // Original z5c.n: the library-card subtitle is formatted with
  // DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM) over
  // Instant.ofEpochMilli — a locale-aware medium date with no time component.
  private formatLibraryDate(timestamp: number): string {
    try {
      return new Intl.DateTimeFormat(undefined,
        { dateStyle: 'medium' }).format(new Date(timestamp));
    } catch (_error) {
      const d: Date = new Date(timestamp);
      return d.getMonth() + 1 + '/' + d.getDate() + '/' + d.getFullYear();
    }
  }

  // The scanned-document default title keeps a date-time (z5c.j-style
  // ofLocalizedDateTime(MEDIUM, SHORT)) so consecutive scans stay unique.
  private formatLibraryDateTime(timestamp: number): string {
    try {
      return new Intl.DateTimeFormat(undefined,
        { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(timestamp));
    } catch (_error) {
      return this.formatLibraryDate(timestamp);
    }
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
  // 原版 gaj：文件夹场景字段标签同为 enter_folder_name；笔记重命名保持 name。
  placeholder: ResourceStr = $r('app.string.name');
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
      TextInput({ text: this.inputText, placeholder: this.placeholder })
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

// 原版 n32/elc.a：unindexed-notes 说明对话框——unindexed_notes 标题 +
// "If the note causes the app to crash..." 正文 + 单个 Close。
@CustomDialog
struct UnindexedNotesDialog {
  controller?: CustomDialogController;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text($r('app.string.unindexed_notes'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Text($r('app.string.unindexed_explainer'))
        .fontSize(13)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 12 })
      Button($r('app.string.close'))
        .height(36)
        .fontSize(14)
        .width('100%')
        .margin({ top: 16 })
        .onClick(() => {
          if (this.controller !== undefined) {
            this.controller.close();
          }
        })
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}

// 原版 cd case 0 templatenewnote：新建表单的模板选择——四款 PaperTemplate
// （PLAIN/LINES/GRID/DOTS）2x2 网格；选中即建笔记并套用该纸张模板。
@CustomDialog
struct TemplatePickerDialog {
  controller?: CustomDialogController;
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  onPick: (template: PaperTemplate) => void = (_template: PaperTemplate): void => {
  };

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  @Builder
  private templateTile(template: PaperTemplate, label: ResourceStr): void {
    Column() {
      Column()
        .width('100%')
        .height(56)
        .backgroundColor(this.resolveTokens().control)
        .borderRadius(6)
        .borderWidth(template === PaperTemplate.PLAIN ? 0 : 1)
        .borderColor(this.resolveTokens().textSecondary)
      Text(label)
        .fontSize(13)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .padding(4)
    .onClick(() => {
      if (this.controller !== undefined) {
        this.controller.close();
      }
      this.onPick(template);
    })
  }

  build() {
    Column() {
      Text($r('app.string.templates'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Grid() {
        GridItem() {
          this.templateTile(PaperTemplate.PLAIN, $r('app.string.template_plain'))
        }
        GridItem() {
          this.templateTile(PaperTemplate.LINES, $r('app.string.template_lines'))
        }
        GridItem() {
          this.templateTile(PaperTemplate.GRID, $r('app.string.template_grid'))
        }
        GridItem() {
          this.templateTile(PaperTemplate.DOTS, $r('app.string.template_dots'))
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(16)
    .width(320)
    .backgroundColor(this.resolveTokens().surface)
  }
}
