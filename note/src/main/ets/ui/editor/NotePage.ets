// T-025 笔记编辑器页面（EditorToolbar + NoteCanvasView + PageManagerBar 集成）
// T-036：标题行内编辑 + 持久化
import { router, promptAction, window } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { audio } from '@kit.AudioKit';
import { NoteBackgroundSettings, NoteMeta, PageInfo } from '../../core/model/NoteTypes';
import {
  commitOriginalNoteTitleDraft, isOriginalNoteTitleWireValue,
  materializeOriginalNoteTitle, truncateOriginalNoteTitleDraft,
} from '../../core/model/OriginalNoteTitlePolicy';
import { BrushStyle, brushStyleToInkStyle, inkStyleToBrushStyle } from '../../core/model/BrushTypes';
import { InkStyle } from '../../core/model/StrokeTypes';
import {
  cloneNoteBackgroundSettings, clonePageInfo, duplicatedOriginalPageBackground,
  originalDefaultNoteBackgroundSettings, rotatedOriginalPageInfo,
  sameNoteBackgroundSettings, samePageBackground,
} from '../../core/model/PageBackgroundModel';
import { HistoryMetadata, NoteMetadataHistoryState } from '../../core/model/OpTypes';
import {
  CopiedPagePayload, copiedPagePayload, storeCopiedPage,
} from '../../rendering/OriginalPageClipboard';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteExporter } from '../../data/NoteExporter';
import { PageImageExporter, ShareImageFormat } from '../../data/PageImageExporter';
import { PagePdfExporter, PdfPageImage } from '../../data/PagePdfExporter';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PersistedOriginalNoteTitle } from '../../data/OriginalNoteTitlePersistence';
import {
  patchFromNoteMetadataState, sameNoteMetadataMutationState,
  validateNoteMetadataMutationState,
} from '../../data/NoteMetadataMutationCodec';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { ToolRepositoryImpl } from '../../data/ToolRepositoryImpl';
import { EditorSettingsStore } from '../../data/EditorSettingsStore';
import { AssetAvailabilityChange, assetAvailabilityHub } from '../../data/AssetAvailabilityHub';
import { MaterializedOriginalRecording, OriginalRecordingStore } from '../../data/OriginalRecordingStore';
import { OperationIdentity } from '../../data/OperationIdentity';
import {
  OriginalRecordingPlaybackController, OriginalRecordingPlaybackSnapshot,
  OriginalRecordingPlaybackSpeed, OriginalRecordingPlaybackState,
} from '../../core/adaptation/OriginalRecordingPlaybackController';
import {
  buildOriginalRecordingTimeline, locateOriginalRecordingTimeline,
  nextTimelineRecordingId, OriginalRecordingTimeline, OriginalRecordingTimelineLocation,
  timelinePositionForRecording,
} from '../../core/adaptation/OriginalRecordingTimeline';
import {
  effectiveOriginalAudioSegments, OriginalAudioSegmentRange, originalAudioTimeAtPosition,
} from '../../core/adaptation/OriginalAudioLinkedInkPlayback';
import { OriginalRecordingDeleteController } from
  '../../core/adaptation/OriginalRecordingDeleteController';
import {
  OriginalRecordingAudioSource, OriginalRecordingCaptureController, OriginalRecordingCaptureResult,
  OriginalRecordingCaptureState,
} from
  '../../core/adaptation/OriginalRecordingCaptureController';
import {
  HarmonyOriginalRecordingCaptureClock, OriginalRecordingMicrophoneBackend,
} from '../../core/adaptation/OriginalRecordingMicrophoneBackend';
import { OriginalRecordingInternalAudioBackend } from
  '../../core/adaptation/OriginalRecordingInternalAudioBackend';
import { OriginalRecordingSourceBackend } from
  '../../core/adaptation/OriginalRecordingSourceBackend';
import {
  isOriginalRecordingCaptureActive, OriginalRecordingSessionController,
  OriginalRecordingSessionFailure, OriginalRecordingSessionSnapshot,
} from '../../core/adaptation/OriginalRecordingSessionController';
import {
  HarmonyOriginalRecordingAudioFocusGateway, HarmonyOriginalRecordingPermissionGateway,
} from '../../core/adaptation/OriginalRecordingHarmonyGateways';
import { persistCapturedOriginalRecording } from '../../data/OriginalRecordingPersistence';
import {
  AddPageAction, DeletePageAction, DuplicatePageAction, EditorHistoryBridge,
  NoteBackgroundAction, NoteMetadataAction,
  NoteTitleAction,
  PageBookmarkAction, PageContentSnapshot, PageCopyPlan, PageSettingsAction, UndoableAction,
  UndoableActionType,
} from '../../rendering/UndoRedoManager';
import { EditorViewModel } from './EditorViewModel';
import { ThumbnailRenderer } from '../../rendering/ThumbnailRenderer';
import { EditorToolbar } from './EditorToolbar';
import { NoteCanvasView } from './NoteCanvasView';
import { PageManagerBar } from './PageManagerBar';
import { RecordingPanel } from './RecordingPanel';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

// 分享图像导出倍率：pagePixelSize（≈96dpi）×2 ≈ 192dpi 栅格。
const PAGE_EXPORT_SCALE: number = 2.0;
const EXPORT_JPEG_QUALITY: number = 92;
const PACK_BUFFER_MAX_BYTES: number = 64 * 1024 * 1024;

@Entry
@Component
struct NotePage {
  private noteId: string = '';
  @State viewModel: EditorViewModel = new EditorViewModel();
  @State pages: PageInfo[] = [];
  @State noteBackground: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
  @State currentPageIndex: number = 0;
  @State undoSignal: number = 0;
  @State redoSignal: number = 0;
  @State mathInsertSignal: number = 0;
  @State photoInsertSignal: number = 0;
  @State cameraCaptureSignal: number = 0;
  @State selectionStyleSignal: number = 0;
  @State selectionInkStyle: InkStyle = InkStyle.FIXED_WIDTH;
  @State selectionColorSignal: number = 0;
  @State selectionInkColor: number = -16777216;
  @State selectionWidthSignal: number = 0;
  @State clearPageSignal: number = 0;
  @State pageClipboardVersion: number = 0;
  @State tapeToggleSignal: number = 0;
  // 原版 jg9.n / uf0 case4：当前页 tape 数 + 是否存在已揭示 tape，驱动菜单标签。
  @State pageTapeCount: number = 0;
  @State anyTapeRevealed: boolean = false;
  @State selectionInkWidth: number = 5;
  @State selectionWidthMinimum: number = 0.5;
  @State selectionWidthMaximum: number = 30;
  @State selectionVariableStyleEnabled: boolean = true;
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;
  @State pageOperationBusy: boolean = false;
  @State photoImportLeaseActive: boolean = false;
  private pageStructureLeaseActive: boolean = false;
  @State pageLoading: boolean = false;
  @State historyPending: boolean = false;
  @State pageLoadFailed: boolean = false;
  // Original u49.a / vc9 states: open-time failures surface as a terminal
  // dialog — 'deleted' (uc9, note unavailable) vs 'failed' (rc9, load failed).
  @State pageLoadFailureKind: string = '';
  private failureDismissHandled: boolean = false;
  private failureDialog: CustomDialogController = new CustomDialogController({
    builder: NoteFailureDialog({
      deleted: this.pageLoadFailureKind === 'deleted',
      onDismiss: (): void => {
        this.dismissLoadFailure();
      },
    }),
    autoCancel: true,
    cancel: (): void => {
      this.dismissLoadFailure();
    },
  });
  @State noteTitle: string = '';          // T-036：标题
  @State editingTitle: boolean = false;   // T-036：标题编辑态
  @State titleDraft: string = '';
  @State recordings: MaterializedOriginalRecording[] = [];
  @State recordingsLoading: boolean = false;
  @State showRecordings: boolean = false;
  @State playbackSnapshot: OriginalRecordingPlaybackSnapshot = {
    state: OriginalRecordingPlaybackState.IDLE, recordingId: null,
    positionMs: 0, durationMs: 0, error: null,
  };
  @State playbackCumulativePositionMs: number = 0;
  @State playbackCumulativeDurationMs: number = 0;
  @State recordingPlaybackSpeed: OriginalRecordingPlaybackSpeed =
    OriginalRecordingPlaybackSpeed.SPEED_1_0;
  @State pendingRecordingDeleteIds: string[] = [];
  @State recordingSessionSnapshot: OriginalRecordingSessionSnapshot = {
    captureState: OriginalRecordingCaptureState.IDLE, elapsedMs: 0,
    preparing: false, saving: false,
    failure: OriginalRecordingSessionFailure.NONE, failureSequence: 0,
  };
  @State recordingPauseSupported: boolean = true;
  @State audioPlaybackTime: string | null = null;
  @State audioPlaybackSegments: OriginalAudioSegmentRange[] = [];
  private noteRepo: NoteRepositoryImpl | null = null;
  private titleSaveQueue: Promise<void> = Promise.resolve();
  private titleSaveGeneration: number = 0;
  private editorDisposed: boolean = false;
  private autoRecordRequested: boolean = false;
  private editorLeavePromise: Promise<void> | null = null;
  private titleSaveInFlightCount: number = 0;
  private pageRepo: PageRepositoryImpl | null = null;
  private persistence: StrokePersistence = new StrokePersistence();
  private historyBridge: EditorHistoryBridge | null = null;
  private pageLoadGeneration: number = 0;
  // 原版 keep_device_awake：编辑器前台时按设置保持屏幕常亮。
  private keepAwakeGeneration: number = 0;
  private keepScreenOnApplied: boolean = false;
  // 原版 hide_status_bar / hide_navigation_bar：note view 沉浸模式开关。
  private systemBarsGeneration: number = 0;
  private statusBarHiddenApplied: boolean = false;
  private navigationBarHiddenApplied: boolean = false;
  // 原版 note_view_night_mode：编辑器内纸墨以深色外观渲染。
  @State noteViewNightMode: boolean = false;
  private nightModeGeneration: number = 0;
  private pageLoadInFlight: boolean = false;
  private recordingStore: OriginalRecordingStore | null = null;
  private recordingController: OriginalRecordingPlaybackController =
    new OriginalRecordingPlaybackController();
  private recordingDeleteController: OriginalRecordingDeleteController =
    new OriginalRecordingDeleteController(async (recordingIds: string[]): Promise<void> => {
      await this.commitRecordingDeletes(recordingIds);
    });
  private recordingSessionController: OriginalRecordingSessionController | null = null;
  private recordingSessionTimer: number = -1;
  private recordingFailureSequence: number = 0;
  private assetAvailabilitySubscription: number = -1;
  private recordingLoadGeneration: number = 0;
  private recordingTimeline: OriginalRecordingTimeline = {
    entries: [], boundaryTimesMs: [], totalDurationMs: 0,
  };
  private completionAdvanceCount: number = 0;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    // 原版 note_view_night_mode：开启时编辑器（含纸墨）按深色渲染。
    return ThemeStore.resolve(this.noteViewNightMode ? 'dark' :
      this.themeMode as ThemeMode, this.systemDark);
  }

  // 原版编辑器分享面板 NOTE 行（s6d.NOTE / atc case5）：导出当前笔记为
  // .note 包并交系统保存对话框，与库级 exportNote 同一管线。
  private shareNoteAsFile(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const exporter: NoteExporter = new NoteExporter(DatabaseManager.getInstance(), this.persistence);
    exporter.exportToFile(context, this.noteId, this.noteTitle).then((success: boolean) => {
      promptAction.showToast({
        message: success ? $r('app.string.export_done') : $r('app.string.export_failed'),
      });
    }).catch((e: Error) => {
      promptAction.showToast({ message: $r('app.string.export_failed') });
      console.error(`share note export failed: ${JSON.stringify(e)}`);
    });
  }

  // 原版 s6d.JPG/PNG（atc case6/7）：所选页按 pagePixelSize×2 整页
  // 栅格化（含纸面/PDF 背景/全部元素栈），编码后交系统保存对话框。
  // 页选择集合（v6d.l）的 Harmony 子集：当前页单文件直存；全部页面
  // 逐页打包 page_NNN.<ext> 进单个 zip 再保存。
  // 导出色恒取亮主题（原版导出的是笔记固有颜色，不受夜间模式影响）。
  private sharePagesAsImages(format: string, allPages: boolean): void {
    if (this.pages.length === 0 || this.currentPageIndex < 0 ||
      this.currentPageIndex >= this.pages.length) {
      return;
    }
    const pages: PageInfo[] = allPages ? this.pages.slice() :
      [this.pages[this.currentPageIndex]];
    const shareFormat: ShareImageFormat = format === 'png' ? 'png' : 'jpeg';
    const context = getContext(this) as common.UIAbilityContext;
    const theme: ThemeTokens = ThemeStore.resolve('light', false);
    const db: DatabaseManager = DatabaseManager.getInstance();
    const renderer: ThumbnailRenderer = new ThumbnailRenderer();
    const exporter: PageImageExporter = new PageImageExporter();
    let packer: image.ImagePacker | null = null;
    const encodedPages: Uint8Array[] = [];
    let singlePixelMap: PixelMap | null = null;
    renderer.initialize(context)
      .then(async (): Promise<void> => {
        if (pages.length === 1) {
          singlePixelMap = await renderer.renderPageExport(this.noteId,
            this.persistence, pages[0], theme, db, PAGE_EXPORT_SCALE);
          const success: boolean = await exporter.exportPageImage(context,
            singlePixelMap, this.noteTitle, shareFormat);
          promptAction.showToast({
            message: success ? $r('app.string.export_done') : $r('app.string.export_failed'),
          });
          return;
        }
        packer = image.createImagePacker();
        const pagePacker: image.ImagePacker = packer;
        for (const page of pages) {
          const pixelMap: PixelMap = await renderer.renderPageExport(this.noteId,
            this.persistence, page, theme, db, PAGE_EXPORT_SCALE);
          try {
            const data: ArrayBuffer = await pagePacker.packToData(pixelMap, {
              format: shareFormat === 'png' ? 'image/png' : 'image/jpeg',
              quality: shareFormat === 'jpeg' ? EXPORT_JPEG_QUALITY : 0,
              bufferSize: PACK_BUFFER_MAX_BYTES,
            });
            encodedPages.push(new Uint8Array(data));
          } finally {
            await pixelMap.release();
          }
        }
        const success: boolean = await exporter.exportPageImagesZip(context,
          encodedPages, this.noteTitle, shareFormat);
        promptAction.showToast({
          message: success ? $r('app.string.export_done') : $r('app.string.export_failed'),
        });
      })
      .catch((e: Error) => {
        promptAction.showToast({ message: $r('app.string.export_failed') });
        console.error(`share page image export failed: ${JSON.stringify(e)}`);
      })
      .finally(async (): Promise<void> => {
        if (singlePixelMap !== null) {
          await singlePixelMap.release();
        }
        if (packer !== null) {
          await packer.release();
        }
        await renderer.dispose();
      });
  }

  // 原版 s6d.PDF（atc case4）：所选页逐页按 pagePixelSize×2 栅格化，
  // 每页压为 JPEG 后嵌入单 PDF（DCTDecode 直通），交系统保存对话框。
  // 页序取 this.pages 快照序（= 原版页序）；allPages=false 时仅当前页。
  // 导出色恒取亮主题。
  private shareNoteAsPdf(allPages: boolean): void {
    if (this.pages.length === 0 || this.currentPageIndex < 0 ||
      this.currentPageIndex >= this.pages.length) {
      return;
    }
    const pages: PageInfo[] = allPages ? this.pages.slice() :
      [this.pages[this.currentPageIndex]];
    const context = getContext(this) as common.UIAbilityContext;
    const theme: ThemeTokens = ThemeStore.resolve('light', false);
    const db: DatabaseManager = DatabaseManager.getInstance();
    const renderer: ThumbnailRenderer = new ThumbnailRenderer();
    const packer: image.ImagePacker = image.createImagePacker();
    const imagePages: PdfPageImage[] = [];
    renderer.initialize(context)
      .then(async (): Promise<void> => {
        for (const page of pages) {
          const pixelMap: PixelMap = await renderer.renderPageExport(this.noteId,
            this.persistence, page, theme, db, PAGE_EXPORT_SCALE);
          try {
            const info: image.ImageInfo = pixelMap.getImageInfoSync();
            const data: ArrayBuffer = await packer.packToData(pixelMap, {
              format: 'image/jpeg',
              quality: EXPORT_JPEG_QUALITY,
              bufferSize: PACK_BUFFER_MAX_BYTES,
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
        const exporter: PagePdfExporter = new PagePdfExporter();
        const success: boolean = await exporter.exportPdf(context, imagePages,
          this.noteTitle);
        promptAction.showToast({
          message: success ? $r('app.string.export_done') : $r('app.string.export_failed'),
        });
      })
      .catch((e: Error) => {
        promptAction.showToast({ message: $r('app.string.export_failed') });
        console.error(`share note pdf export failed: ${JSON.stringify(e)}`);
      })
      .finally(async (): Promise<void> => {
        await packer.release();
        await renderer.dispose();
      });
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== undefined && params !== null && params['noteId'] !== undefined) {
      this.noteId = params['noteId'];
      // Original empty_note__record_audio: library record-audio entry opens
      // the editor straight into capture after the note loads.
      this.autoRecordRequested = params['autoRecord'] === '1';
    }
    if (this.recordingSessionController === null) {
      const context = getContext(this) as common.UIAbilityContext;
      const sourceBackend: OriginalRecordingSourceBackend = new OriginalRecordingSourceBackend(
        new OriginalRecordingMicrophoneBackend(context.tempDir),
        new OriginalRecordingInternalAudioBackend(context.tempDir));
      const capture = new OriginalRecordingCaptureController(sourceBackend,
        new HarmonyOriginalRecordingCaptureClock(), sourceBackend);
      this.recordingSessionController = new OriginalRecordingSessionController(
        capture, new HarmonyOriginalRecordingPermissionGateway(context),
        new HarmonyOriginalRecordingAudioFocusGateway(),
        async (result: OriginalRecordingCaptureResult): Promise<void> => {
          await this.persistCapturedRecording(result);
        },
        async (): Promise<void> => {
          await this.recordingController.unload();
        });
      this.recordingSessionController.setListener((snapshot: OriginalRecordingSessionSnapshot): void => {
        this.onRecordingSessionSnapshot(snapshot);
      });
    }
    this.recordingController.setListener((snapshot: OriginalRecordingPlaybackSnapshot): void => {
      this.onRecordingPlaybackSnapshot(snapshot);
    });
    this.recordingDeleteController.setListener((pendingIds: string[]): void => {
      if (this.editorDisposed) {
        return;
      }
      this.pendingRecordingDeleteIds = pendingIds;
      this.rebuildRecordingTimeline();
    });
    this.recordingDeleteController.setFailureListener((error: Object): void => {
      console.error(`Recording delete failed: ${JSON.stringify(error)}`);
      if (this.editorDisposed) {
        return;
      }
      try {
        promptAction.showToast({ message: $r('app.string.recording_delete_failed'), duration: 2500 });
      } catch (_toastError) {
      }
    });
    if (this.assetAvailabilitySubscription < 0) {
      this.assetAvailabilitySubscription = assetAvailabilityHub.subscribe(
        (change: AssetAvailabilityChange): void => this.onRecordingAssetAvailabilityChanged(change));
    }
    this.applyKeepDeviceAwakeSetting();
    this.applyHideSystemBarsSetting();
    this.applyNoteViewNightModeSetting();
    this.loadPages();
  }

  // T-040 修复：路由返回时 TextInput 的 onBlur 不保证触发，必须在页面销毁时兜底保存标题
  aboutToDisappear(): void {
    this.editorDisposed = true;
    this.pageLoadGeneration++;
    this.recordingLoadGeneration++;
    this.keepAwakeGeneration++;
    if (this.keepScreenOnApplied) {
      this.keepScreenOnApplied = false;
      this.setKeepScreenOn(false);
    }
    this.systemBarsGeneration++;
    this.nightModeGeneration++;
    if (this.statusBarHiddenApplied || this.navigationBarHiddenApplied) {
      this.statusBarHiddenApplied = false;
      this.navigationBarHiddenApplied = false;
      this.setSystemBarHidden('status', false);
      this.setSystemBarHidden('navigation', false);
      this.setSystemBarHidden('navigationIndicator', false);
    }
    this.cancelRecordingSessionRefresh();
    if (this.editingTitle) {
      this.saveTitle();
    }
    if (this.assetAvailabilitySubscription >= 0) {
      assetAvailabilityHub.unsubscribe(this.assetAvailabilitySubscription);
      this.assetAvailabilitySubscription = -1;
    }
    this.recordingController.release().catch((error: Object) => {
      console.warn(`Recording player release failed: ${JSON.stringify(error)}`);
    });
    this.recordingDeleteController.flush().catch((error: Object) => {
      console.warn(`Recording delete flush failed: ${JSON.stringify(error)}`);
    });
    this.finishRecordingSession();
  }

  onBackPress(): boolean {
    this.leaveEditor();
    return true;
  }

  // Original u8(function0, ...): both the dialog button and outside dismissal
  // invoke the same dismiss callback — route back exactly once.
  private dismissLoadFailure(): void {
    if (this.failureDismissHandled || this.editorDisposed) {
      return;
    }
    this.failureDismissHandled = true;
    router.back();
  }

  private leaveEditor(): Promise<void> {
    if (this.editorLeavePromise !== null) {
      return this.editorLeavePromise;
    }
    this.editorLeavePromise = this.performLeaveEditor();
    return this.editorLeavePromise;
  }

  private async performLeaveEditor(): Promise<void> {
    if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
      return;
    }
    if (this.editingTitle) {
      await this.saveTitle();
    } else {
      // onSubmit/onBlur may already have hidden the editor while their durable
      // SET_METADATA transaction is still running.  Navigation must wait for it.
      await this.titleSaveQueue;
    }
    if (this.historyBridge !== null && !await this.historyBridge.flushCurrentPage()) {
      return;
    }
    if (this.editorDisposed) {
      return;
    }
    await this.viewModel.flushToolState();
    await this.recordingDeleteController.flush();
    if (this.editorDisposed) {
      return;
    }
    await this.finishRecordingSession();
    await this.recordingController.release();
    router.back();
  }

  // 原版 feature_settings__keep_device_awake：设置开启时编辑器前台
  // 保持屏幕常亮；页面销毁时释放。失败静默降级（不影响编辑）。
  private async applyKeepDeviceAwakeSetting(): Promise<void> {
    const generation: number = ++this.keepAwakeGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const enabled: boolean =
        await new EditorSettingsStore(context).getKeepDeviceAwake();
      if (this.editorDisposed || generation !== this.keepAwakeGeneration) {
        return;
      }
      if (enabled === this.keepScreenOnApplied) {
        return;
      }
      this.keepScreenOnApplied = enabled;
      this.setKeepScreenOn(enabled);
    } catch (e) {
      console.error(`keep-device-awake load failed: ${JSON.stringify(e)}`);
    }
  }

  // 原版 feature_settings__hide_status_bar / hide_navigation_bar：开启时
  // 编辑器前台隐藏对应系统栏（沉浸模式）；页面销毁时恢复。
  private async applyHideSystemBarsSetting(): Promise<void> {
    const generation: number = ++this.systemBarsGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const store: EditorSettingsStore = new EditorSettingsStore(context);
      const hideStatus: boolean = await store.getHideStatusBar();
      const hideNav: boolean = await store.getHideNavigationBar();
      if (this.editorDisposed || generation !== this.systemBarsGeneration) {
        return;
      }
      if (hideStatus !== this.statusBarHiddenApplied) {
        this.statusBarHiddenApplied = hideStatus;
        this.setSystemBarHidden('status', hideStatus);
      }
      if (hideNav !== this.navigationBarHiddenApplied) {
        this.navigationBarHiddenApplied = hideNav;
        // 三键导航与手势条是两种导航栏实现；逐个独立降级。
        this.setSystemBarHidden('navigation', hideNav);
        this.setSystemBarHidden('navigationIndicator', hideNav);
      }
    } catch (e) {
      console.error(`hide-system-bars load failed: ${JSON.stringify(e)}`);
    }
  }

  // 原版 note_view_night_mode：设置开启时编辑器内纸墨深色渲染；
  // 经 noteViewNightMode 状态驱动 chrome + canvas 双重 token 解析。
  private async applyNoteViewNightModeSetting(): Promise<void> {
    const generation: number = ++this.nightModeGeneration;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const enabled: boolean =
        await new EditorSettingsStore(context).getNoteViewNightMode();
      if (this.editorDisposed || generation !== this.nightModeGeneration) {
        return;
      }
      this.noteViewNightMode = enabled;
    } catch (e) {
      console.error(`note-view-night-mode load failed: ${JSON.stringify(e)}`);
    }
  }

  private setSystemBarHidden(name: string, hidden: boolean): void {
    try {
      window.getLastWindow(getContext(this)).then((win: window.Window) => {
        win.setSpecificSystemBarEnabled(name as window.SpecificSystemBar,
          !hidden).catch((e: Object) => {
          console.error(`setSpecificSystemBarEnabled(${name}) failed: ${JSON.stringify(e)}`);
        });
      }).catch((e: Object) => {
        console.error(`getLastWindow failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      console.error(`getLastWindow failed: ${JSON.stringify(e)}`);
    }
  }

  private setKeepScreenOn(enabled: boolean): void {
    try {
      window.getLastWindow(getContext(this)).then((win: window.Window) => {
        win.setWindowKeepScreenOn(enabled);
      }).catch((e: Object) => {
        console.error(`setWindowKeepScreenOn failed: ${JSON.stringify(e)}`);
      });
    } catch (e) {
      console.error(`getLastWindow failed: ${JSON.stringify(e)}`);
    }
  }

  private async loadPages(): Promise<void> {
    if (this.editorDisposed || this.pageLoadInFlight) {
      return;
    }
    const loadGeneration: number = ++this.pageLoadGeneration;
    this.pageLoadInFlight = true;
    this.pageLoading = true;
    this.pageLoadFailed = false;
    this.pageLoadFailureKind = '';
    this.failureDismissHandled = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.pageRepo = new PageRepositoryImpl(db);
      this.persistence.initialize(db);
      this.recordingStore = new OriginalRecordingStore(db);
      this.viewModel.onPersistenceError = (message: string): void => {
        hilog.error(0x0001, 'NotePage', '%{public}s', message);
        if (this.editorDisposed) {
          return;
        }
        try {
          promptAction.showToast({ message: 'Tool settings could not be saved', duration: 2500 });
        } catch (toastError) {
          console.error(`Tool settings toast failed: ${JSON.stringify(toastError)}`);
        }
      };
      const editorSettingsStore: EditorSettingsStore = new EditorSettingsStore(context);
      await this.viewModel.initialize(
        new ToolRepositoryImpl(db), 'primary-editor', editorSettingsStore,
        (): boolean => !this.editorDisposed && loadGeneration === this.pageLoadGeneration);
      // T-036：加载标题
      this.noteRepo = new NoteRepositoryImpl(db);
      const note: NoteMeta | null = await this.noteRepo.getNote(this.noteId);
      if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {
        return;
      }
      if (note === null || note.deletedAt !== null) {
        // Original uc9: a missing or deleted note is the "Note unavailable"
        // terminal dialog, not a retryable load failure.
        this.pageLoadFailureKind = 'deleted';
        throw new Error('note unavailable');
      }
      this.noteTitle = note.title;
      // Original setLastOpened partial update (dk9.RECENT feed): opening the
      // editor stamps last_opened without touching createdAt/updatedAt.
      this.noteRepo.touchNoteLastOpened(this.noteId, Date.now()).catch((e: Error) => {
        console.error(`lastOpened touch failed: ${JSON.stringify(e)}`);
      });
      const loaded: PageInfo[] = await this.pageRepo.getPages(this.noteId);
      if (loaded.length === 0) {
        // Legacy/corrupt zero-page recovery only. Normal original blank-note creation has
        // already committed two inherited Letter pages before this editor can open it.
        const fallback: NoteBackgroundSettings = originalDefaultNoteBackgroundSettings();
        const defaultPage: PageInfo = {
          pageId: this.generateId(),
          pageIndex: 0,
          size: fallback.size,
          template: fallback.template,
          orientation: fallback.orientation,
          widthMm: fallback.widthMm,
          heightMm: fallback.heightMm,
        };
        const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, defaultPage);
        if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {
          return;
        }
        this.pages = [assignedPage];
      } else {
        this.pages = loaded;
      }
      if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {
        return;
      }
      const loadedBackground: NoteBackgroundSettings =
        await this.pageRepo.getNoteBackground(this.noteId);
      if (this.editorDisposed || loadGeneration !== this.pageLoadGeneration) {
        return;
      }
      this.noteBackground = loadedBackground;
      this.currentPageIndex = 0;
      this.pageLoadFailed = false;
      await this.loadRecordings();
      if (this.autoRecordRequested && !this.editorDisposed &&
        loadGeneration === this.pageLoadGeneration) {
        this.autoRecordRequested = false;
        this.showRecordings = true;
        this.startRecording().catch((e: Error) => {
          console.error(`auto-record start failed: ${JSON.stringify(e)}`);
        });
      }
    } catch (e) {
      if (loadGeneration !== this.pageLoadGeneration || this.editorDisposed) {
        return;
      }
      this.recordingLoadGeneration++;
      this.recordingsLoading = false;
      this.pages = [];
      this.noteBackground = originalDefaultNoteBackgroundSettings();
      this.currentPageIndex = 0;
      this.historyBridge = null;
      this.pageRepo = null;
      this.noteRepo = null;
      this.recordingStore = null;
      this.recordings = [];
      this.rebuildRecordingTimeline();
      this.pageLoadFailed = true;
      if (this.pageLoadFailureKind === '') {
        this.pageLoadFailureKind = 'failed';
      }
      console.error(`NotePage loadPages failed: ${JSON.stringify(e)}`);
      // Original u49.a: the failure surfaces as a terminal AlertDialog whose
      // dismiss/button both route back — no inline retry affordance.
      try {
        this.failureDialog.open();
      } catch (dialogError) {
        console.error(`Note page failure dialog failed: ${JSON.stringify(dialogError)}`);
      }
    } finally {
      if (loadGeneration === this.pageLoadGeneration) {
        this.pageLoading = false;
        this.pageLoadInFlight = false;
      }
    }
  }

  // Original title commits are serialized so onSubmit + onBlur + route teardown cannot
  // race two SET_METADATA operations or let navigation overtake an earlier save.
  private saveTitle(): Promise<void> {
    this.editingTitle = false;
    const requested: string = commitOriginalNoteTitleDraft(this.titleDraft);
    const generation: number = ++this.titleSaveGeneration;
    const queued: Promise<void> = this.titleSaveQueue.then(
      async (): Promise<void> => this.commitTitle(requested, generation));
    // Keep the tail usable even if an unexpected exception escapes commitTitle.
    // Callers can await `queued`, while the internal chain remains available to a
    // later edit instead of being permanently poisoned by one transient failure.
    this.titleSaveInFlightCount++;
    this.titleSaveQueue = queued.catch((_error: Object): void => {
    });
    void queued.finally((): void => {
      this.titleSaveInFlightCount--;
    });
    return queued;
  }

  private async commitTitle(requested: string, generation: number): Promise<void> {
    const previousTitle: string = this.noteTitle;
    if (requested === previousTitle) {
      this.publishTitleDraft(requested, generation);
      return;
    }
    if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
      return;
    }
    try {
      if (this.noteRepo === null) {
        throw new Error('note repository is unavailable');
      }
      if (this.pages.length === 0 || this.currentPageIndex < 0 ||
        this.currentPageIndex >= this.pages.length) {
        throw new Error('note title requires a live selected page');
      }
      const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
      const action: NoteTitleAction = {
        type: UndoableActionType.NOTE_TITLE,
        noteId: this.noteId,
        pageId: selectedPageId,
        titleBefore: previousTitle,
        titleAfter: requested,
      };
      const bridge: EditorHistoryBridge | null = this.historyBridge;
      const history: HistoryMetadata | undefined = bridge === null
        ? undefined : bridge.preparePageAction(action);
      this.noteTitle = requested;
      this.publishTitleDraft(requested, generation);
      const persisted: PersistedOriginalNoteTitle = await this.noteRepo.updateNoteTitle(
        this.noteId, requested, selectedPageId, history);
      if (this.editorDisposed) {
        return;
      }
      if (this.pages[this.currentPageIndex]?.pageId !== selectedPageId) {
        this.noteTitle = persisted.materializedTitle;
        return;
      }
      action.titleBefore = persisted.before;
      action.titleAfter = persisted.after;
      this.noteTitle = persisted.materializedTitle;
      this.publishTitleDraft(persisted.materializedTitle, generation);
      if (bridge !== null) {
        try {
          bridge.pushPageAction(action, history);
        } catch (historyError) {
          // The SQLite transaction already committed both the original operation and
          // its durable history companion.  A runtime-stack race must not present the
          // old title again while reopening the note would materialize the new one.
          console.error(`saveTitle runtime history sync failed after durable commit: ${JSON.stringify(historyError)}`);
        }
      }
    } catch (e) {
      if (this.editorDisposed) {
        return;
      }
      this.noteTitle = previousTitle;
      this.publishTitleDraft(previousTitle, generation);
      console.error(`saveTitle failed: ${JSON.stringify(e)}`);
      try {
        promptAction.showToast({ message: $r('app.string.note_save_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Title save failure toast failed: ${JSON.stringify(toastError)}`);
      }
    }
  }

  private publishTitleDraft(value: string, generation: number): void {
    // A completed older save must not overwrite a newer queued draft or text the
    // user has already started editing while the database operation was in flight.
    if (generation === this.titleSaveGeneration && !this.editingTitle) {
      this.titleDraft = value;
    }
  }

  private async loadRecordings(): Promise<void> {
    if (this.recordingStore === null || this.noteId.length === 0) {
      return;
    }
    const generation: number = ++this.recordingLoadGeneration;
    this.recordingsLoading = true;
    try {
      const recordings: MaterializedOriginalRecording[] =
        await this.recordingStore.listVisible(this.noteId);
      if (this.editorDisposed || generation !== this.recordingLoadGeneration) {
        return;
      }
      if (generation === this.recordingLoadGeneration) {
        this.recordings = recordings;
        this.rebuildRecordingTimeline();
      }
    } catch (error) {
      if (this.editorDisposed || generation !== this.recordingLoadGeneration) {
        return;
      }
      this.recordings = [];
      this.rebuildRecordingTimeline();
      console.error(`Recording list load failed: ${JSON.stringify(error)}`);
      try {
        promptAction.showToast({ message: $r('app.string.recordings_load_failed'), duration: 2500 });
      } catch (_toastError) {
      }
    } finally {
      if (generation === this.recordingLoadGeneration) {
        this.recordingsLoading = false;
      }
    }
  }

  private async persistCapturedRecording(capture: OriginalRecordingCaptureResult): Promise<void> {
    await persistCapturedOriginalRecording(DatabaseManager.getInstance(), this.noteId, capture);
    if (this.editorDisposed) {
      return;
    }
    await this.loadRecordings();
    if (this.editorDisposed) {
      return;
    }
    this.rebuildRecordingTimeline();
  }

  private onRecordingSessionSnapshot(snapshot: OriginalRecordingSessionSnapshot): void {
    if (this.editorDisposed) {
      return;
    }
    this.recordingSessionSnapshot = snapshot;
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    this.recordingPauseSupported = session === null ? true : session.canPause();
    if (snapshot.failureSequence !== this.recordingFailureSequence) {
      this.recordingFailureSequence = snapshot.failureSequence;
      this.showRecordingFailure(snapshot.failure);
    }
    if (snapshot.preparing || snapshot.saving ||
      isOriginalRecordingCaptureActive(snapshot.captureState)) {
      this.scheduleRecordingSessionRefresh();
    } else {
      this.cancelRecordingSessionRefresh();
    }
  }

  private scheduleRecordingSessionRefresh(): void {
    if (this.recordingSessionTimer >= 0) {
      return;
    }
    this.recordingSessionTimer = setTimeout((): void => {
      this.recordingSessionTimer = -1;
      if (this.editorDisposed) {
        return;
      }
      const session: OriginalRecordingSessionController | null = this.recordingSessionController;
      if (session !== null) {
        this.onRecordingSessionSnapshot(session.getSnapshot());
      }
    }, 250);
  }

  private cancelRecordingSessionRefresh(): void {
    if (this.recordingSessionTimer >= 0) {
      clearTimeout(this.recordingSessionTimer);
      this.recordingSessionTimer = -1;
    }
  }

  private showRecordingFailure(failure: OriginalRecordingSessionFailure): void {
    if (this.editorDisposed) {
      return;
    }
    if (failure === OriginalRecordingSessionFailure.NONE) {
      return;
    }
    if (failure === OriginalRecordingSessionFailure.PERMISSION_DENIED) {
      promptAction.showDialog({
        title: $r('app.string.microphone_permission_title'),
        message: $r('app.string.microphone_permission_message'),
        buttons: [{ text: $r('app.string.dismiss'), color: this.resolveTokens().accent }],
      }).catch((_error: Object): void => {});
      return;
    }
    const message: ResourceStr = failure === OriginalRecordingSessionFailure.SAVE_FAILED ?
      $r('app.string.recording_save_failed') : $r('app.string.recording_start_failed');
    try {
      promptAction.showToast({ message: message, duration: 2500 });
    } catch (_toastError) {
    }
  }

  private async startRecording(): Promise<void> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session === null) {
      return;
    }
    let musicActive: boolean = false;
    try {
      musicActive = audio.getAudioManager().getStreamManager().isStreamActive(
        audio.StreamUsage.STREAM_USAGE_MUSIC);
    } catch (_error) {
    }
    if (!musicActive) {
      await session.start(OriginalRecordingAudioSource.MICROPHONE);
      return;
    }
    try {
      const response: promptAction.ShowDialogSuccessResponse = await promptAction.showDialog({
        title: $r('app.string.select_audio_source'),
        buttons: [
          { text: $r('app.string.audio_source_microphone'), color: this.resolveTokens().textPrimary },
          { text: $r('app.string.audio_source_internal'), color: this.resolveTokens().textPrimary },
        ],
      });
      if (response.index === 0) {
        if (this.editorDisposed) {
          return;
        }
        await session.start(OriginalRecordingAudioSource.MICROPHONE);
      } else if (response.index === 1) {
        if (this.editorDisposed) {
          return;
        }
        await session.start(OriginalRecordingAudioSource.DEVICE_ONLY);
      }
    } catch (_error) {
    }
  }

  private async pauseRecording(): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.pause();
    }
  }

  private async resumeRecording(): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.resume();
    }
  }

  private async stopRecording(): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session !== null) {
      await session.stop();
    }
  }

  private closeRecordings(): void {
    this.showRecordings = false;
  }

  // 原版 rh8.f/ke1 ⋮ 选项菜单（options_menu）：生产构建中
  // "App settings" 无条件渲染；Template settings(ac4.P) 与
  // Version history(ac4.d0) 为远端旗标项，Inky(sc9.j) 与
  // Disconnect stylus(t9f.e) 依赖 Harmony 不存在的状态面，故均不移植。
  private buildEditorOptionsMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    // 原版 o94 case14：Hide/Reveal Tapes 作用于全部可见 tape 元素
    // （oh9 → ti9:360 → np0 case5 并/差集）；无 tape 时该行不出现。
    if (this.pageTapeCount > 0) {
      items.push({
        value: this.anyTapeRevealed ?
          $r('app.string.hide_tapes') : $r('app.string.reveal_tapes'),
        action: () => { this.tapeToggleSignal++; },
      });
    }
    items.push({ value: $r('app.string.options_menu_app_settings'),
      action: () => { this.navigateToSettings(); } });
    return items;
  }

  private navigateToSettings(): void {
    if (this.photoImportLeaseActive || this.pageLoadFailed || this.pageLoading ||
      this.editorDisposed) {
      return;
    }
    router.pushUrl({ url: 'ui/settings/SettingsPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  private async finishRecordingSession(): Promise<boolean> {
    const session: OriginalRecordingSessionController | null = this.recordingSessionController;
    if (session === null) {
      return true;
    }
    this.recordingSessionController = null;
    this.cancelRecordingSessionRefresh();
    try {
      return await session.finishAndRelease();
    } catch (error) {
      console.warn(`Recording session release failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  private async toggleRecording(recordingId: string): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const selected: MaterializedOriginalRecording | null = this.findRecording(recordingId);
    if (selected === null) {
      return;
    }
    if (this.playbackSnapshot.recordingId !== recordingId) {
      await this.recordingController.load(selected, true);
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.PLAYING) {
      await this.recordingController.pause();
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.LOADING) {
      return;
    }
    if (this.playbackSnapshot.state === OriginalRecordingPlaybackState.FAILED) {
      await this.recordingController.load(selected, true);
      return;
    }
    await this.recordingController.play();
  }

  private findRecording(recordingId: string): MaterializedOriginalRecording | null {
    for (const recording of this.recordings) {
      if (recording.id === recordingId) {
        return recording;
      }
    }
    return null;
  }

  private visiblePlaybackRecordings(): MaterializedOriginalRecording[] {
    return this.recordings.filter((recording: MaterializedOriginalRecording): boolean =>
      this.pendingRecordingDeleteIds.indexOf(recording.id) < 0);
  }

  private rebuildRecordingTimeline(): void {
    this.recordingTimeline = buildOriginalRecordingTimeline(this.visiblePlaybackRecordings());
    this.playbackCumulativeDurationMs = this.recordingTimeline.totalDurationMs;
    this.rebuildAudioPlaybackSegments();
    this.updateCumulativePlaybackPosition(this.playbackSnapshot);
    this.updateAudioPlaybackTime(this.playbackSnapshot);
  }

  private onRecordingPlaybackSnapshot(snapshot: OriginalRecordingPlaybackSnapshot): void {
    if (this.editorDisposed) {
      return;
    }
    this.playbackSnapshot = snapshot;
    this.updateCumulativePlaybackPosition(snapshot);
    this.updateAudioPlaybackTime(snapshot);
    if (snapshot.state !== OriginalRecordingPlaybackState.COMPLETED) {
      return;
    }
    if (snapshot.recordingId !== null) {
      this.completionAdvanceCount++;
      this.advanceAfterRecordingCompletion(snapshot.recordingId)
        .finally((): void => {
          this.completionAdvanceCount--;
        });
    }
  }

  private updateCumulativePlaybackPosition(snapshot: OriginalRecordingPlaybackSnapshot): void {
    if (snapshot.recordingId === null) {
      this.playbackCumulativePositionMs = 0;
      return;
    }
    const localPosition: number = snapshot.state === OriginalRecordingPlaybackState.COMPLETED ?
      Number.MAX_SAFE_INTEGER : snapshot.positionMs;
    this.playbackCumulativePositionMs = timelinePositionForRecording(
      this.recordingTimeline, snapshot.recordingId, localPosition);
  }

  private rebuildAudioPlaybackSegments(): void {
    const result: OriginalAudioSegmentRange[] = [];
    for (const recording of this.visiblePlaybackRecordings()) {
      const sourceSegments: OriginalAudioSegmentRange[] = [];
      for (const segment of recording.segments) {
        sourceSegments.push({ startTime: segment.startTime, endTime: segment.endTime });
      }
      const ranges: OriginalAudioSegmentRange[] = effectiveOriginalAudioSegments(
        sourceSegments, recording.startTime, recording.endTime);
      result.push(...ranges);
    }
    this.audioPlaybackSegments = result;
  }

  private updateAudioPlaybackTime(snapshot: OriginalRecordingPlaybackSnapshot): void {
    if (snapshot.recordingId === null || snapshot.state === OriginalRecordingPlaybackState.IDLE ||
      snapshot.state === OriginalRecordingPlaybackState.FAILED ||
      snapshot.state === OriginalRecordingPlaybackState.RELEASED) {
      this.audioPlaybackTime = null;
      return;
    }
    const recording: MaterializedOriginalRecording | null = this.findRecording(snapshot.recordingId);
    if (recording === null) {
      this.audioPlaybackTime = null;
      return;
    }
    let range: OriginalAudioSegmentRange;
    if (recording.segments.length === 0) {
      range = { startTime: recording.startTime, endTime: recording.endTime };
    } else {
      range = { startTime: recording.segments[0].startTime,
        endTime: recording.segments[0].endTime };
    }
    const localPosition: number = snapshot.state === OriginalRecordingPlaybackState.COMPLETED ?
      Number.MAX_SAFE_INTEGER : snapshot.positionMs;
    try {
      this.audioPlaybackTime = originalAudioTimeAtPosition(
        range.startTime, range.endTime, localPosition);
    } catch (_error) {
      this.audioPlaybackTime = null;
    }
  }

  private async advanceAfterRecordingCompletion(recordingId: string): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    if (this.pendingRecordingDeleteIds.indexOf(recordingId) >= 0) {
      return;
    }
    const nextId: string | null = nextTimelineRecordingId(this.recordingTimeline, recordingId);
    if (nextId === null) {
      return;
    }
    const next: MaterializedOriginalRecording | null = this.findRecording(nextId);
    if (next !== null) {
      await this.recordingController.load(next, true);
    }
  }

  private async seekRecordingTimeline(positionMs: number): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const location: OriginalRecordingTimelineLocation | null =
      locateOriginalRecordingTimeline(this.recordingTimeline, positionMs);
    if (location === null) {
      return;
    }
    if (this.playbackSnapshot.recordingId === location.recordingId) {
      this.recordingController.seek(location.localPositionMs);
      return;
    }
    const recording: MaterializedOriginalRecording | null = this.findRecording(location.recordingId);
    if (recording === null) {
      return;
    }
    const resumePlayback: boolean =
      this.playbackSnapshot.state === OriginalRecordingPlaybackState.PLAYING;
    await this.recordingController.load(recording, resumePlayback, location.localPositionMs);
    if (this.editorDisposed) {
      return;
    }
  }

  private changeRecordingPlaybackSpeed(speed: OriginalRecordingPlaybackSpeed): void {
    if (this.recordingController.setSpeed(speed)) {
      this.recordingPlaybackSpeed = speed;
    }
  }

  private async requestRecordingDelete(recordingId: string): Promise<void> {
    if (this.editorDisposed) {
      return;
    }
    const recording: MaterializedOriginalRecording | null = this.findRecording(recordingId);
    if (recording === null || !this.recordingDeleteController.request(recordingId)) {
      return;
    }
    if (this.playbackSnapshot.recordingId === recordingId) {
      await this.recordingController.unload();
    }
  }

  private undoRecordingDelete(recordingId: string): void {
    if (this.editorDisposed) {
      return;
    }
    this.recordingDeleteController.undo(recordingId);
  }

  private async commitRecordingDeletes(recordingIds: string[]): Promise<void> {
    if (this.recordingStore === null) {
      throw new Error('recording store is unavailable');
    }
    const targets: MaterializedOriginalRecording[] = [];
    for (const recordingId of recordingIds) {
      const recording: MaterializedOriginalRecording | null = this.findRecording(recordingId);
      if (recording === null) {
        throw new Error('pending recording delete target disappeared');
      }
      targets.push(recording);
    }
    await this.recordingStore.deleteVisible(this.noteId, targets.map(
      (recording: MaterializedOriginalRecording): OperationIdentity => ({
        timestamp: recording.timestamp, siteId: recording.siteId,
      })));
    if (this.editorDisposed) {
      return;
    }
    await this.loadRecordings();
    if (this.editorDisposed) {
      return;
    }
  }

  private onRecordingAssetAvailabilityChanged(change: AssetAvailabilityChange): void {
    if (this.editorDisposed) {
      return;
    }
    if (change.noteIds.indexOf(this.noteId) >= 0) {
      this.loadRecordings();
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
            await this.leaveEditor();
          })
        if (this.editingTitle) {
          // T-036：标题编辑态（TextInput，失焦/回车保存）
          TextInput({ text: this.titleDraft })
            .layoutWeight(1)
            .height(36)
            .fontSize(16)
            .margin({ left: 12 })
            .onChange((value: string) => {
              if (this.photoImportLeaseActive || this.pageLoadFailed || this.pageLoading) {
                return;
              }
              this.titleDraft = truncateOriginalNoteTitleDraft(value);
            })
            .onSubmit(() => {
              if (this.photoImportLeaseActive || this.pageLoadFailed || this.pageLoading) {
                return;
              }
              this.saveTitle();
            })
            .onBlur(() => {
              if (this.photoImportLeaseActive || this.pageLoadFailed || this.pageLoading) {
                return;
              }
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
              if (this.photoImportLeaseActive) {
                return;
              }
              if (this.pageLoadFailed || this.pageLoading) {
                return;
              }
              this.titleDraft = this.noteTitle;
              this.editingTitle = true;
            })
        }
        // 原版 rej.a：录制会话活跃（含暂停）时，编辑器顶部居中
        // 显示 "Recording in progress" 徽标；Harmony 落在导航行。
        if (isOriginalRecordingCaptureActive(this.recordingSessionSnapshot.captureState)) {
          Row() {
            Circle({ width: 8, height: 8 })
              .fill('#D64545')
            Text($r('app.string.presence_recording'))
              .fontSize(12)
              .fontColor(this.resolveTokens().textSecondary)
              .margin({ left: 4 })
          }
          .margin({ left: 8 })
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(12)
          .backgroundColor(this.resolveTokens().control)
          .accessibilityText($r('app.string.presence_recording'))
        }
        Button($r('app.string.recordings'))
          .height(36)
          .fontSize(13)
          .margin({ left: 8 })
          .enabled(!this.pageLoading && !this.pageLoadFailed &&
            !this.photoImportLeaseActive)
          .onClick(() => {
            if (this.photoImportLeaseActive) {
              return;
            }
            if (this.showRecordings) {
              this.closeRecordings();
            } else {
              this.showRecordings = true;
            }
          })
        // 原版 rh8.f：编辑器 ⋮ 选项菜单无条件渲染在工具行尾端；
        // 菜单中仅 "App settings" 无条件可见（rh8.java apb.f 无旗标包裹）。
        Button('...')
          .height(36)
          .fontSize(13)
          .margin({ left: 8 })
          .enabled(!this.pageLoading && !this.pageLoadFailed &&
            !this.photoImportLeaseActive)
          .accessibilityText($r('app.string.toolbar_more_menu'))
          .bindMenu(this.buildEditorOptionsMenu())
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
          tapeCount: this.pageTapeCount,
          anyTapeRevealed: this.anyTapeRevealed,
          onTapeToggle: (): void => {
            this.tapeToggleSignal++;
          },
          onUndo: () => {
            if (!this.photoImportLeaseActive && !this.pageOperationBusy &&
              !this.historyPending) {
              this.undoSignal++;
            }
          },
          onRedo: () => {
            if (!this.photoImportLeaseActive && !this.pageOperationBusy &&
              !this.historyPending) {
              this.redoSignal++;
            }
          },
          // 原版编辑器右上角 Share（x90.g，ac4.L=NOTE_SHARE）：
          // 分享面板 NOTE 行复用库级 exportToFile 管线导出 .note 包。
          onShareNote: () => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending) {
              return;
            }
            this.shareNoteAsFile();
          },
          // 原版 s6d.JPG/PNG：分享面板图像格式行，导出所选页栅格。
          onShareImage: (format: string, allPages: boolean) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending) {
              return;
            }
            this.sharePagesAsImages(format, allPages);
          },
          // 原版 s6d.PDF（atc case4）：所选页逐页栅格化导出单个 PDF。
          onSharePdf: (allPages: boolean) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending) {
              return;
            }
            this.shareNoteAsPdf(allPages);
          },
          onInsertMath: () => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.mathInsertSignal++;
          },
          onInsertPhotos: () => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.photoImportLeaseActive = true;
            this.photoInsertSignal++;
          },
          // Take Photo (qc.java menu slot): same ingress lease as photo insert.
          onTakePhoto: () => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.photoImportLeaseActive = true;
            this.cameraCaptureSignal++;
          },
          onSelectionStyle: (style: BrushStyle) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.selectionInkStyle = brushStyleToInkStyle(style);
            this.selectionStyleSignal++;
          },
          selectionColor: this.selectionInkColor,
          selectionWidth: this.selectionInkWidth,
          selectionWidthMinimum: this.selectionWidthMinimum,
          selectionWidthMaximum: this.selectionWidthMaximum,
          selectionVariableStyleEnabled: this.selectionVariableStyleEnabled,
          selectionStyle: inkStyleToBrushStyle(this.selectionInkStyle),
          photoImportLeaseActive: this.photoImportLeaseActive,
          onSelectionColor: (color: number) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.selectionInkColor = color;
            this.selectionColorSignal++;
          },
          onSelectionWidth: (width: number) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            this.selectionInkWidth = width;
            this.selectionWidthSignal++;
          },
        })
      }

      if (this.showRecordings && this.pages.length > 0) {
        RecordingPanel({
          recordings: this.recordings,
          loading: this.recordingsLoading,
          snapshot: this.playbackSnapshot,
          cumulativePositionMs: this.playbackCumulativePositionMs,
          cumulativeDurationMs: this.playbackCumulativeDurationMs,
          playbackSpeed: this.recordingPlaybackSpeed,
          pendingDeleteIds: this.pendingRecordingDeleteIds,
          captureSnapshot: this.recordingSessionSnapshot,
          capturePauseSupported: this.recordingPauseSupported,
          photoImportLeaseActive: this.photoImportLeaseActive,
          onRecord: () => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.startRecording();
          },
          onPauseCapture: () => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.pauseRecording();
          },
          onResumeCapture: () => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.resumeRecording();
          },
          onStopCapture: () => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.stopRecording();
          },
          onToggle: (recordingId: string) => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.toggleRecording(recordingId);
          },
          onSeek: (positionMs: number) => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.seekRecordingTimeline(positionMs);
          },
          onSpeedChange: (speed: OriginalRecordingPlaybackSpeed) => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.changeRecordingPlaybackSpeed(speed);
          },
          onDelete: (recordingId: string) => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.requestRecordingDelete(recordingId);
          },
          onUndoDelete: (recordingId: string) => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.undoRecordingDelete(recordingId);
          },
          onClose: () => {
            if (this.photoImportLeaseActive || this.pageStructureLeaseActive) {
              return;
            }
            this.closeRecordings();
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
          mathInsertSignal: this.mathInsertSignal,
          photoInsertSignal: this.photoInsertSignal,
          cameraCaptureSignal: this.cameraCaptureSignal,
          onPhotoIngressFinished: () => {
            this.photoImportLeaseActive = false;
          },
          selectionStyleSignal: this.selectionStyleSignal,
          selectionInkStyle: this.selectionInkStyle,
          selectionColorSignal: this.selectionColorSignal,
          selectionInkColor: this.selectionInkColor,
          selectionWidthSignal: this.selectionWidthSignal,
          selectionInkWidth: this.selectionInkWidth,
          clearPageSignal: this.clearPageSignal,
          tapeToggleSignal: this.tapeToggleSignal,
          onTapeRevealStateChanged: (tapeCount: number, anyRevealed: boolean): void => {
            this.pageTapeCount = tapeCount;
            this.anyTapeRevealed = anyRevealed;
          },
          // 原版 note_view_night_mode：纸墨深色渲染直通画布 token 解析。
          nightMode: this.noteViewNightMode,
          playbackAudioTime: this.audioPlaybackTime,
          playbackAudioSegments: this.audioPlaybackSegments,
          readRecordingAudioTime: (): string | null => {
            const session: OriginalRecordingSessionController | null =
              this.recordingSessionController;
            return session === null ? null : session.getCurrentAudioTime();
          },
          onUndoRedoChanged: (u: boolean, r: boolean) => {
            hilog.info(0x0001, 'NotePage', 'undoRedoChanged u=%{public}s r=%{public}s',
              u.toString(), r.toString());
            this.canUndo = u;
            this.canRedo = r;
          },
          onRequestPage: (pageId: string) => {
            if (this.photoImportLeaseActive || this.pageOperationBusy ||
              this.historyPending || this.pageStructureLeaseActive) {
              return;
            }
            for (let i: number = 0; i < this.pages.length; i++) {
              if (this.pages[i].pageId === pageId) {
                this.currentPageIndex = i;
                this.historyPending = true;
                return;
              }
            }
            hilog.error(0x0001, 'NotePage', 'history requested missing page %{public}s', pageId);
          },
          onPageHistorySettled: (pending: boolean) => {
            this.historyPending = pending;
          },
          onApplyNoteTitleHistory: (action: UndoableAction, isUndo: boolean,
            history: HistoryMetadata): Promise<boolean> => {
            if (this.pageOperationBusy || this.titleSaveInFlightCount > 0) {
              return Promise.resolve(false);
            }
            return this.runPageHistoryOperation(action, isUndo, history);
          },
          onHistoryBridgeReady: (bridge: EditorHistoryBridge) => {
            this.historyBridge = bridge;
          },
          onApplyNoteMetadataHistory: (action: UndoableAction, isUndo: boolean,
            history: HistoryMetadata): Promise<boolean> => {
            if (this.pageOperationBusy || this.titleSaveInFlightCount > 0) {
              return Promise.resolve(false);
            }
            return this.runPageHistoryOperation(action, isUndo, history);
          },
          onSelectionInkControlsChanged: (color: number | null, width: number | null,
            minimum: number, maximum: number, variableStyleEnabled: boolean,
            style: InkStyle | null) => {
            this.selectionWidthMinimum = minimum;
            this.selectionWidthMaximum = maximum;
            this.selectionVariableStyleEnabled = variableStyleEnabled;
            if (color !== null) {
              this.selectionInkColor = color;
            }
            if (width !== null) {
              this.selectionInkWidth = width;
            }
            if (style !== null) {
              this.selectionInkStyle = style;
            }
          },
          onApplyPageHistory: async (action: UndoableAction, isUndo: boolean,
            history: HistoryMetadata): Promise<boolean> =>
            this.runPageHistoryOperation(action, isUndo, history),
        })
          .layoutWeight(1)
      } else if (this.pageLoadFailed) {
        // Original u49: the scaffold stays behind the terminal dialog; the
        // original offers no retry affordance on this surface.
        Column() {
          Text(this.pageLoadFailureKind === 'deleted'
            ? $r('app.string.note_unavailable_title')
            : $r('app.string.note_load_failed_title'))
            .fontSize(16)
            .fontColor(this.resolveTokens().textSecondary)
            .textAlign(TextAlign.Center)
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
          currentPageBookmarked: this.pages[this.currentPageIndex].bookmarked === true,
          noteBackground: this.noteBackground,
          photoImportLeaseActive: this.photoImportLeaseActive,
          busy: this.photoImportLeaseActive || this.pageOperationBusy,
          onPrev: () => {
            if (!this.pageLoading && !this.pageOperationBusy && !this.historyPending &&
              !this.pageStructureLeaseActive &&
              this.currentPageIndex > 0) {
              this.currentPageIndex--;
            }
          },
          onNext: () => {
            if (!this.pageLoading && !this.pageOperationBusy &&
              !this.historyPending && !this.pageStructureLeaseActive &&
              this.currentPageIndex < this.pages.length - 1) {
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
          onToggleBookmark: () => {
            this.runPageOperation(async (): Promise<void> => this.toggleCurrentPageBookmark());
          },
          // Original n9j Paste item is gated on mg2.b != null (clipboard
          // non-empty); pageClipboardVersion forces a re-render after
          // copy/cut. Image-bearing pages stay same-note only (asset linkage).
          canPastePage: this.pageClipboardVersion >= 0 && this.canPasteCopiedPage(),
          onCutPage: () => {
            this.runPageOperation(async (): Promise<void> => this.cutCurrentPage());
          },
          onCopyPage: () => {
            this.runPageOperation(async (): Promise<void> => this.copyCurrentPage());
          },
          onPastePage: () => {
            this.runPageOperation(async (): Promise<void> => this.pasteCopiedPage());
          },
          onDuplicatePage: () => {
            this.runPageOperation(async (): Promise<void> => this.duplicateCurrentPage());
          },
          onRotatePage: () => {
            this.runPageOperation(async (): Promise<void> => this.rotateCurrentPage());
          },
          onClearPage: () => {
            this.clearPageSignal++;
          },
          // Original ke1/n8 jump-to-page: the indicator tap opens a dialog;
          // Go lands on the validated 0-based index under the same page-guard
          // set as prev/next navigation.
          onJumpToPage: (pageIndex: number) => {
            if (!this.pageLoading && !this.pageOperationBusy &&
              !this.historyPending && !this.pageStructureLeaseActive &&
              pageIndex >= 0 && pageIndex < this.pages.length) {
              this.currentPageIndex = pageIndex;
            }
          },
          onApplyNoteBackground: (settings: NoteBackgroundSettings) => {
            this.runPageOperation(
              async (): Promise<void> => this.applyNoteBackgroundSettings(settings));
          },
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }

  // Original 1.0.3 applies size/template/orientation through note-level SET_METADATA.
  private async applyNoteBackgroundSettings(settings: NoteBackgroundSettings): Promise<void> {
    if (this.photoImportLeaseActive || this.pageStructureLeaseActive ||
      this.pageRepo === null) {
      return;
    }
    const before: NoteBackgroundSettings = cloneNoteBackgroundSettings(this.noteBackground);
    if (sameNoteBackgroundSettings(before, settings)) {
      return;
    }
    const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
    const action: NoteBackgroundAction = {
      type: UndoableActionType.NOTE_BACKGROUND,
      noteId: this.noteId,
      pageId: selectedPageId,
      selectedPageId: selectedPageId,
      backgroundBefore: before,
      backgroundAfter: cloneNoteBackgroundSettings(settings),
    };
    const history: HistoryMetadata | undefined = this.historyBridge === null
      ? undefined : this.historyBridge.preparePageAction(action);
    const materialized: NoteBackgroundSettings = await this.pageRepo.updateNoteBackground(
      this.noteId, settings, selectedPageId, history);
    if (this.editorDisposed) {
      return;
    }
    this.selectPageById(selectedPageId);
    action.backgroundAfter = cloneNoteBackgroundSettings(materialized);
    this.pages = await this.pageRepo.getPages(this.noteId);
    if (this.editorDisposed) {
      return;
    }
    this.noteBackground = materialized;
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction(action, history);
    }
  }

  private async runPageOperation(operation: () => Promise<void>): Promise<void> {
    if (this.photoImportLeaseActive || this.pageOperationBusy || this.historyPending ||
      this.pageStructureLeaseActive) {
      return;
    }
    this.pageOperationBusy = true;
    try {
      await operation();
    } catch (e) {
      hilog.error(0x0001, 'NotePage', 'page operation failed: %{public}s', JSON.stringify(e));
      if (this.editorDisposed) {
        return;
      }
      try {
        promptAction.showToast({ message: $r('app.string.page_operation_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Page operation toast failed: ${JSON.stringify(toastError)}`);
      }
    } finally {
      this.pageOperationBusy = false;
    }
  }

  private async runPageHistoryOperation(action: UndoableAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageOperationBusy) {
      return false;
    }
    this.pageOperationBusy = true;
    try {
      return await this.applyPageHistory(action, isUndo, history);
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
    // Original n9j Add Page (zd2 variant 0 -> u5j.i at selectedIndex + 1):
    // the new page lands immediately after the current one and inherits the
    // note default background (haj.a emits a null nz9).
    const insertIndex: number = this.currentPageIndex + 1;
    const page: PageInfo = {
      pageId: this.generateId(),
      pageIndex: insertIndex,
      size: this.noteBackground.size,
      template: this.noteBackground.template,
      orientation: this.noteBackground.orientation,
      widthMm: this.noteBackground.widthMm,
      heightMm: this.noteBackground.heightMm,
      background: null,
    };
    const orderAfter: string[] = orderBefore.slice(0, insertIndex).concat(
      [page.pageId], orderBefore.slice(insertIndex));
    const action: AddPageAction = {
      type: UndoableActionType.ADD_PAGE,
      noteId: this.noteId,
      pageId: page.pageId,
      pageAfter: this.clonePage(page),
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
      pageStrokes: [],
      pageTextBlocks: [],
      pageShapes: [],
      pageImages: [],
      pageMathBlocks: [],
      pageElementOrder: [],
      selectedPageIdBefore: selectedBefore,
      selectedPageIdAfter: page.pageId,
    };
    const history: HistoryMetadata | undefined = this.historyBridge === null
      ? undefined : this.historyBridge.preparePageAction(action);
    const assignedPage: PageInfo = await this.pageRepo.addPage(
      this.noteId, page, history, selectedBefore);
    if (this.editorDisposed) {
      return;
    }
    if (this.pages[this.currentPageIndex]?.pageId !== selectedBefore) {
      return;
    }
    this.currentPageIndex = this.pages.findIndex((page: PageInfo): boolean =>
      page.pageId === assignedPage.pageId);
    action.pageId = assignedPage.pageId;
    action.pageAfter = this.clonePage(assignedPage);
    action.pageOrderAfter = orderBefore.slice(0, insertIndex).concat(
      [assignedPage.pageId], orderBefore.slice(insertIndex));
    action.selectedPageIdAfter = assignedPage.pageId;
    const updated: PageInfo[] = this.pages.slice();
    updated.splice(insertIndex, 0, assignedPage);
    for (let index: number = insertIndex + 1; index < updated.length; index++) {
      updated[index] = this.clonePage(updated[index]);
      updated[index].pageIndex = index;
    }
    this.pages = updated;
    this.currentPageIndex = insertIndex;
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction(action, history);
    }
  }

  private async deleteCurrentPage(): Promise<void> {
    // Original de2.i: deleting is never blocked by page count — when the
    // remainder would drop below two, the same op stream inserts a blank
    // compensation page (u5j.i at size - 1), so the note always retains one.
    if (this.pageRepo === null || this.pages.length === 0 || this.historyBridge === null) {
      return;
    }
    this.pageStructureLeaseActive = true;
    const historyBridge: EditorHistoryBridge = this.historyBridge;
    try {
      await this.deleteCurrentPageLocked(historyBridge);
    } finally {
      this.pageStructureLeaseActive = false;
    }
  }

  private async deleteCurrentPageLocked(historyBridge: EditorHistoryBridge): Promise<void> {
    const deletedPage: PageInfo = this.clonePage(this.pages[this.currentPageIndex]);
    const pageId: string = deletedPage.pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    // de2.i: `list2.size() - list.size() < 2` — for a single-page delete the
    // compensation fires exactly when the note holds at most two pages.
    const compensated: boolean = orderBefore.length <= 2;
    const orderAfter: string[] = orderBefore.filter((id: string): boolean => id !== pageId);
    const selectedBefore: string = pageId;
    const selectedAfter: string = compensated ? pageId :
      orderAfter[Math.min(this.currentPageIndex, orderAfter.length - 1)];
    if (!await historyBridge.flushCurrentPage()) {
      throw new Error('deleteCurrentPage could not flush the current page');
    }
    if (this.pages[this.currentPageIndex]?.pageId !== pageId) {
      return;
    }
    const snapshot: PageContentSnapshot = historyBridge.captureCurrentPage();
    const action: DeletePageAction = {
      type: UndoableActionType.DELETE_PAGE,
      noteId: this.noteId,
      pageId: pageId,
      pageBefore: deletedPage,
      pageOrderBefore: orderBefore,
      pageOrderAfter: compensated ? orderBefore.slice() : orderAfter,
      pageStrokes: snapshot.strokes,
      pageTextBlocks: snapshot.textBlocks,
      pageShapes: snapshot.shapes,
      pageImages: snapshot.images,
      pageMathBlocks: snapshot.mathBlocks,
      pageElementOrder: snapshot.elementOrder,
      selectedPageIdBefore: selectedBefore,
      selectedPageIdAfter: selectedAfter,
    };
    const history: HistoryMetadata = historyBridge.preparePageAction(action);
    historyBridge.preparePageRemoval(pageId);
    let compensation: PageInfo | null = null;
    try {
      const pageRepository: PageRepositoryImpl | null = this.pageRepo;
      if (pageRepository === null) {
        return;
      }
      if (compensated) {
        compensation = await pageRepository.deletePageWithCompensation(this.noteId, pageId, history);
      } else {
        await pageRepository.deletePageWithCheckpoint(this.noteId, pageId, history);
      }
    } catch (e) {
      historyBridge.cancelPageRemoval(pageId);
      throw new Error(`deleteCurrentPage failed: ${JSON.stringify(e)}`);
    }
    if (this.editorDisposed) {
      return;
    }
    const updated: PageInfo[] = [];
    for (const p of this.pages) {
      if (p.pageId !== pageId) {
        updated.push(p);
      }
    }
    if (compensation !== null) {
      updated.splice(Math.min(orderBefore.indexOf(pageId), updated.length), 0, compensation);
      for (let index: number = 0; index < updated.length; index++) {
        updated[index] = this.clonePage(updated[index]);
        updated[index].pageIndex = index;
      }
      action.compensationPage = this.clonePage(compensation);
      action.pageOrderAfter = this.pageIds(updated);
      action.selectedPageIdAfter = compensation.pageId;
    }
    this.pages = updated;
    this.selectPageById(compensation !== null ? compensation.pageId : selectedAfter);
    historyBridge.pushPageAction(action, history);
    // 原版 n9j：页删除成功经 snackbar 提示 content_manager_page_deleted（Harmony 用 toast）。
    if (!this.editorDisposed) {
      promptAction.showToast({ message: $r('app.string.page_deleted') });
    }
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
    const action: UndoableAction = {
      type: UndoableActionType.REORDER_PAGES,
      noteId: this.noteId,
      pageId: selectedPageId,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderAfter,
    };
    const history: HistoryMetadata = this.historyBridge.preparePageAction(action);
    await this.pageRepo.reorderPages(this.noteId, orderAfter, selectedPageId, history);
    if (this.editorDisposed) {
      return;
    }
    if (this.pages[this.currentPageIndex]?.pageId !== selectedPageId) {
      return;
    }
    this.pages = this.orderPages(this.pages, orderAfter);
    this.currentPageIndex = targetIndex;
    this.historyBridge.pushPageAction(action, history);
  }

  // ae2 parity: the content-manager bookmark action toggles the selected page —
  // BOOKMARKED when it is currently UNBOOKMARKED, otherwise UNBOOKMARKED. The
  // original sends u5j.s (ModifyPage field 3, oz9) through the journaled x82.I
  // channel with the dof "undoable" marker (cof is the explicit NotUndoable
  // alternative), so the toggle is one undoable action. The wz9 register write
  // is not a structural mutation, so a PAGE_BOOKMARK companion carries history.
  private async toggleCurrentPageBookmark(): Promise<void> {
    if (this.pageRepo === null || this.pages.length === 0) {
      return;
    }
    const selectedPageId: string = this.pages[this.currentPageIndex].pageId;
    const current: PageInfo = this.pages[this.currentPageIndex];
    const next: boolean = current.bookmarked !== true;
    const action: PageBookmarkAction = {
      type: UndoableActionType.PAGE_BOOKMARK,
      noteId: this.noteId,
      pageId: selectedPageId,
      bookmarkedBefore: current.bookmarked === true,
      bookmarkedAfter: next,
    };
    const historyBridge: EditorHistoryBridge | null = this.historyBridge;
    const history: HistoryMetadata | undefined = historyBridge === null
      ? undefined : historyBridge.preparePageAction(action);
    const persisted: PageInfo = await this.pageRepo.setPageBookmarked(
      this.noteId, selectedPageId, next, history);
    if (this.editorDisposed) {
      return;
    }
    const updated: PageInfo[] = this.pages.slice();
    const index: number = updated.findIndex((page: PageInfo): boolean =>
      page.pageId === selectedPageId);
    if (index < 0) {
      return;
    }
    updated[index] = this.clonePage(persisted);
    this.pages = updated;
    if (historyBridge !== null && history !== undefined) {
      historyBridge.pushPageAction(action, history);
    }
  }

  // Original zd2 case 1 (content-manager Rotate Page): steps the page's nz9
  // rotation register one cardinal turn via a per-page ModifyPage write, then
  // rides the existing PAGE_SETTINGS history channel for undo/redo.
  private async rotateCurrentPage(): Promise<void> {
    if (this.pageRepo === null || this.pages.length === 0) {
      return;
    }
    const before: PageInfo = this.clonePage(this.pages[this.currentPageIndex]);
    const rotated: PageInfo | null = rotatedOriginalPageInfo(before);
    if (rotated === null) {
      return;
    }
    const action: PageSettingsAction = {
      type: UndoableActionType.PAGE_SETTINGS,
      noteId: this.noteId,
      pageId: before.pageId,
      pageBefore: before,
      pageAfter: rotated,
    };
    const history: HistoryMetadata | undefined = this.historyBridge === null
      ? undefined : this.historyBridge.preparePageAction(action);
    await this.pageRepo.updatePage(rotated, history);
    if (this.editorDisposed) {
      return;
    }
    this.pages = await this.pageRepo.getPages(this.noteId);
    if (this.editorDisposed) {
      return;
    }
    const materialized: PageInfo | undefined = this.pages.find(
      (page: PageInfo): boolean => page.pageId === before.pageId);
    if (materialized !== undefined) {
      action.pageAfter = this.clonePage(materialized);
    }
    this.selectPageById(before.pageId);
    if (this.historyBridge !== null) {
      this.historyBridge.pushPageAction(action, history);
    }
  }

  // Original n9j Duplicate (fd2 case5 → de2.r → ae2 default → de2.j anchor):
  // copies the current page immediately after itself. The page metadata op
  // stream is persistOriginalDuplicatePage (effective nz9 + l7j.c PDF
  // collapse); the entity stream is the shared clipboard transcode with fresh
  // element identities. A DUPLICATE_PAGE companion op owns durable history;
  // undo hides the copy via the original page-visibility write, redo unhides.
  private async duplicateCurrentPage(): Promise<void> {
    if (this.pageRepo === null || this.pages.length === 0 || this.historyBridge === null) {
      return;
    }
    const historyBridge: EditorHistoryBridge = this.historyBridge;
    if (!await historyBridge.flushCurrentPage()) {
      throw new Error('duplicateCurrentPage could not flush the current page');
    }
    const sourceIndex: number = this.currentPageIndex;
    const sourcePageId: string = this.pages[sourceIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const snapshot: PageContentSnapshot = historyBridge.captureCurrentPage();
    const action: DuplicatePageAction = {
      type: UndoableActionType.DUPLICATE_PAGE,
      noteId: this.noteId,
      pageId: sourcePageId,
      sourcePageId: sourcePageId,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderBefore.slice(),
    };
    const history: HistoryMetadata = historyBridge.preparePageAction(action);
    const duplicated: PageInfo = await this.pageRepo.duplicatePage(
      this.noteId, sourcePageId, history);
    action.pageId = duplicated.pageId;
    action.pageOrderAfter = orderBefore.slice(0, sourceIndex + 1)
      .concat([duplicated.pageId]).concat(orderBefore.slice(sourceIndex + 1));
    let contentError: Object | null = null;
    if (snapshot.elementOrder.length > 0) {
      try {
        await historyBridge.commitDuplicatePageContent(duplicated.pageId, snapshot, history);
      } catch (e) {
        contentError = e;
      }
    }
    if (this.editorDisposed) {
      return;
    }
    this.pages = await this.pageRepo.getPages(this.noteId);
    if (this.editorDisposed) {
      return;
    }
    if (this.pages.length !== action.pageOrderAfter.length ||
      !this.sameStringArray(this.pageIds(this.pages), action.pageOrderAfter)) {
      throw new Error('duplicate page materialized an unexpected page order');
    }
    this.selectPageById(duplicated.pageId);
    this.historyBridge.pushPageAction(action, history);
    if (contentError !== null) {
      throw new Error(`duplicate page content write failed: ${JSON.stringify(contentError)}`);
    }
  }

  // Paste is offered when the process-scoped page clipboard holds a payload
  // (original: mg2.b != null gates the item). Cross-note paste is allowed for
  // every payload: the copied page's image and PDF-asset references are merged
  // into the target note by mergeImageAssetReference/mergePdfAsset inside the
  // CREATE_BLOCK/CREATE_PAGE appliers, and the bytes live in the shared
  // content-addressed asset store.
  private canPasteCopiedPage(): boolean {
    const payload: CopiedPagePayload | null = copiedPagePayload();
    return payload !== null && this.pages.length > 0;
  }

  // Original n9j Copy (ae2 case 2): u5j.e serializes the page payload into the
  // process-scoped page clipboard mg2.b = dg2 (CopiedPagesData). Harmony stores
  // the materialized payload — effective background, bookmark, element plan —
  // deep-cloned so later edits cannot mutate the clipboard record.
  private async copyCurrentPage(): Promise<void> {
    if (this.pages.length === 0 || this.historyBridge === null) {
      return;
    }
    const historyBridge: EditorHistoryBridge = this.historyBridge;
    if (!await historyBridge.flushCurrentPage()) {
      throw new Error('copyCurrentPage could not flush the current page');
    }
    const source: PageInfo = this.pages[this.currentPageIndex];
    const plan: PageCopyPlan = historyBridge.captureCurrentPageCopyPlan();
    const payload: CopiedPagePayload = {
      noteId: this.noteId,
      sourcePageId: source.pageId,
      background: duplicatedOriginalPageBackground(source),
      bookmarked: source.bookmarked === true,
      plan: plan,
    };
    storeCopiedPage(payload);
    if (!this.editorDisposed) {
      this.pageClipboardVersion++;
    }
  }

  // Original n9j Cut (ae2 case 3): copy into the page clipboard, then apply the
  // same de2.i delete ops as Delete Pages — so the journal entry is the
  // existing DELETE_PAGE action and undo restores the page verbatim.
  private async cutCurrentPage(): Promise<void> {
    if (this.pages.length === 0 || this.historyBridge === null) {
      return;
    }
    await this.copyCurrentPage();
    await this.deleteCurrentPage();
  }

  // Original n9j Paste (mg2.b -> lg2/m1d.c0 apply): replays the clipboard
  // payload through the same anchored CreatePage + transcode path as
  // Duplicate. The durable journal is identical (insert one page after the
  // anchor, hide on undo, restore on redo), so the action reuses
  // DUPLICATE_PAGE exactly as the original's op stream cannot tell the two
  // gestures apart.
  private async pasteCopiedPage(): Promise<void> {
    const payload: CopiedPagePayload | null = copiedPagePayload();
    if (this.pageRepo === null || this.pages.length === 0 || this.historyBridge === null ||
      payload === null) {
      return;
    }
    const historyBridge: EditorHistoryBridge = this.historyBridge;
    if (!await historyBridge.flushCurrentPage()) {
      throw new Error('pasteCopiedPage could not flush the current page');
    }
    const anchorIndex: number = this.currentPageIndex;
    const anchorPageId: string = this.pages[anchorIndex].pageId;
    const orderBefore: string[] = this.pageIds(this.pages);
    const action: DuplicatePageAction = {
      type: UndoableActionType.DUPLICATE_PAGE,
      noteId: this.noteId,
      pageId: anchorPageId,
      sourcePageId: anchorPageId,
      pageOrderBefore: orderBefore,
      pageOrderAfter: orderBefore.slice(),
    };
    const history: HistoryMetadata = historyBridge.preparePageAction(action);
    const pasted: PageInfo = await this.pageRepo.insertCopiedPage(
      this.noteId, anchorPageId, payload.background, payload.bookmarked, history);
    action.pageId = pasted.pageId;
    action.pageOrderAfter = orderBefore.slice(0, anchorIndex + 1)
      .concat([pasted.pageId]).concat(orderBefore.slice(anchorIndex + 1));
    let contentError: Object | null = null;
    if (payload.plan.elementOrder.length > 0) {
      try {
        await historyBridge.commitCopiedPageContent(pasted.pageId, payload.plan, history);
      } catch (e) {
        contentError = e;
      }
    }
    if (this.editorDisposed) {
      return;
    }
    this.pages = await this.pageRepo.getPages(this.noteId);
    if (this.editorDisposed) {
      return;
    }
    if (this.pages.length !== action.pageOrderAfter.length ||
      !this.sameStringArray(this.pageIds(this.pages), action.pageOrderAfter)) {
      throw new Error('pasted page materialized an unexpected page order');
    }
    this.selectPageById(pasted.pageId);
    this.historyBridge.pushPageAction(action, history);
    if (contentError !== null) {
      throw new Error(`paste page content write failed: ${JSON.stringify(contentError)}`);
    }
  }

  private async applyPageHistory(action: UndoableAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    const pageRepository: PageRepositoryImpl | null = this.pageRepo;
    if (action.noteId !== this.noteId) {
      hilog.error(0x0001, 'NotePage',
        'page history note mismatch, actionNote=%{public}s currentNote=%{public}s', action.noteId, this.noteId);
      return false;
    }
    if ((action.type === UndoableActionType.NOTE_TITLE ||
      action.type === UndoableActionType.NOTE_METADATA) && this.noteRepo === null) {
      return false;
    }
    if (action.type !== UndoableActionType.NOTE_TITLE &&
      action.type !== UndoableActionType.NOTE_METADATA && pageRepository === null) {
      return false;
    }
    if (!this.validatePageActionState(action, isUndo)) {
      hilog.error(0x0001, 'NotePage',
        'page history source state mismatch, type=%{public}d undo=%{public}s', action.type, isUndo.toString());
      return false;
    }
    try {
      if (action.type === UndoableActionType.NOTE_TITLE) {
        const repository: NoteRepositoryImpl | null = this.noteRepo;
        if (repository === null) {
          return false;
        }
        const title: string | null = isUndo ? action.titleBefore : action.titleAfter;
        const persisted: PersistedOriginalNoteTitle = await repository.updateNoteTitle(
          this.noteId, title, action.pageId, history);
        if (this.editorDisposed) {
          return false;
        }
        this.noteTitle = persisted.materializedTitle;
        this.titleDraft = persisted.materializedTitle;
        return true;
      }
      if (action.type === UndoableActionType.NOTE_METADATA) {
        const repository: NoteRepositoryImpl | null = this.noteRepo;
        if (repository === null) {
          return false;
        }
        const source: NoteMetadataHistoryState = isUndo
          ? action.metadataAfter : action.metadataBefore;
        const target: NoteMetadataHistoryState = isUndo
          ? action.metadataBefore : action.metadataAfter;
        const patch = patchFromNoteMetadataState(target, action.fieldMask);
        await repository.updateOriginalNoteMetadata(
          this.noteId, patch, action.selectedPageId, history, source);
        if (this.editorDisposed) {
          return false;
        }
        return true;
      }
      if (pageRepository === null) {
        return false;
      }
      if (action.type === UndoableActionType.ADD_PAGE) {
        return await this.applyAddPageHistory(action, isUndo, history);
      }
      if (action.type === UndoableActionType.DELETE_PAGE) {
        return await this.applyDeletePageHistory(action, isUndo, history);
      }
      if (action.type === UndoableActionType.DUPLICATE_PAGE) {
        return await this.applyDuplicatePageHistory(action, isUndo, history);
      }
      if (action.type === UndoableActionType.PAGE_BOOKMARK) {
        const target: boolean = isUndo ? action.bookmarkedBefore : action.bookmarkedAfter;
        const persisted: PageInfo = await pageRepository.setPageBookmarked(
          this.noteId, action.pageId, target, history);
        if (this.editorDisposed) {
          return false;
        }
        this.replacePage(persisted);
        return true;
      }
      if (action.type === UndoableActionType.PAGE_SETTINGS) {
        const page: PageInfo = isUndo ? action.pageBefore : action.pageAfter;
        await pageRepository.updatePage(page, history);
        if (this.editorDisposed) {
          return false;
        }
        this.replacePage(page);
        this.selectPageById(page.pageId);
        return true;
      }
      if (action.type === UndoableActionType.NOTE_BACKGROUND) {
        const settings: NoteBackgroundSettings = isUndo
          ? action.backgroundBefore : action.backgroundAfter;
        const materialized: NoteBackgroundSettings = await pageRepository.updateNoteBackground(
          this.noteId, settings, action.selectedPageId, history);
        if (this.editorDisposed) {
          return false;
        }
        this.pages = await pageRepository.getPages(this.noteId);
        if (this.editorDisposed) {
          return false;
        }
        this.noteBackground = materialized;
        this.selectPageById(action.selectedPageId);
        return true;
      }
      if (action.type === UndoableActionType.REORDER_PAGES) {
        const order: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
        await pageRepository.reorderPages(this.noteId, order, action.pageId, history);
        if (this.editorDisposed) {
          return false;
        }
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
      if (action.compensationPage !== undefined && action.compensationPage !== null) {
        const compensationId: string = action.compensationPage.pageId;
        return action.pageId === action.pageBefore.pageId &&
          compensationId.length !== 0 && compensationId !== action.pageId &&
          this.sameStringArray(currentOrder, sourceOrder) &&
          this.isDeleteCompensationTransition(sourceOrder, targetOrder, action.pageId,
            compensationId, !isUndo) &&
          this.countString(sourceOrder, sourceSelection) === 1 &&
          this.countString(targetOrder, targetSelection) === 1;
      }
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
    if (action.type === UndoableActionType.DUPLICATE_PAGE) {
      const sourceOrder: string[] = isUndo ? action.pageOrderAfter : action.pageOrderBefore;
      const targetOrder: string[] = isUndo ? action.pageOrderBefore : action.pageOrderAfter;
      if (action.sourcePageId === action.pageId ||
        !this.sameStringArray(currentOrder, sourceOrder) ||
        !this.isSinglePageTransition(sourceOrder, targetOrder, action.pageId, isUndo) ||
        this.countString(targetOrder, action.sourcePageId) !== 1) {
        return false;
      }
      const sourceIndex: number = targetOrder.indexOf(action.sourcePageId);
      return sourceIndex >= 0 && targetOrder[sourceIndex + 1] === action.pageId;
    }
    if (action.type === UndoableActionType.PAGE_BOOKMARK) {
      if (action.bookmarkedBefore === action.bookmarkedAfter) {
        return false;
      }
      const expected: boolean = isUndo ? action.bookmarkedAfter : action.bookmarkedBefore;
      let matched: number = 0;
      for (const page of this.pages) {
        if (page.pageId === action.pageId && (page.bookmarked === true) === expected) {
          matched++;
        }
      }
      return matched === 1;
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
    if (action.type === UndoableActionType.NOTE_BACKGROUND) {
      const source: NoteBackgroundSettings = isUndo
        ? action.backgroundAfter : action.backgroundBefore;
      return action.pageId === action.selectedPageId &&
        this.countString(currentOrder, action.selectedPageId) === 1 &&
        sameNoteBackgroundSettings(this.noteBackground, source);
    }
    if (action.type === UndoableActionType.NOTE_TITLE) {
      const source: string | null = isUndo ? action.titleAfter : action.titleBefore;
      return action.titleBefore !== action.titleAfter &&
        isOriginalNoteTitleWireValue(action.titleBefore) &&
        isOriginalNoteTitleWireValue(action.titleAfter) &&
        this.countString(currentOrder, action.pageId) === 1 &&
        this.noteTitle === materializeOriginalNoteTitle(source);
    }
    if (action.type === UndoableActionType.NOTE_METADATA) {
      if (action.pageId !== action.selectedPageId ||
        this.countString(currentOrder, action.selectedPageId) !== 1) {
        return false;
      }
      try {
        validateNoteMetadataMutationState(action.metadataBefore, action.fieldMask, 'history before');
        validateNoteMetadataMutationState(action.metadataAfter, action.fieldMask, 'history after');
        return !sameNoteMetadataMutationState(
          action.metadataBefore, action.metadataAfter, action.fieldMask);
      } catch (_error) {
        return false;
      }
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

  // A compensated delete swaps exactly one member in-place: the victim's slot
  // becomes the blank's slot and every other page keeps its index.
  private isDeleteCompensationTransition(source: string[], target: string[],
    deletedId: string, compensationId: string, sourceContainsDeleted: boolean): boolean {
    if (!this.hasUniqueStrings(source) || !this.hasUniqueStrings(target) ||
      source.length !== target.length || source.length === 0) {
      return false;
    }
    const sourceId: string = sourceContainsDeleted ? deletedId : compensationId;
    const targetId: string = sourceContainsDeleted ? compensationId : deletedId;
    if (this.countString(source, sourceId) !== 1 || this.countString(source, targetId) !== 0 ||
      this.countString(target, targetId) !== 1 || this.countString(target, sourceId) !== 0) {
      return false;
    }
    const expected: string[] = [];
    for (const id of source) {
      expected.push(id === sourceId ? targetId : id);
    }
    return this.sameStringArray(expected, target);
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

  private async applyAddPageHistory(action: AddPageAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    // A user-created page is appended empty at the recorded position (original
    // u5j.i inserts after the selected page, not always at the tail). Keeping
    // the empty-content invariant makes ADD_PAGE history a single
    // page-mutation transaction; populated page restoration belongs to
    // DELETE_PAGE checkpoints.
    if (action.pageStrokes.length !== 0 || action.pageTextBlocks.length !== 0 ||
      action.pageShapes.length !== 0 || action.pageImages.length !== 0 ||
      (action.pageMathBlocks ?? []).length !== 0 ||
      action.pageElementOrder.length !== 0 ||
      action.pageOrderAfter.length === 0 ||
      this.countString(action.pageOrderAfter, action.pageId) !== 1) {
      return false;
    }
    if (isUndo) {
      if (this.pages.length <= 1) {
        return false;
      }
      if (this.historyBridge !== null && this.pages[this.currentPageIndex].pageId === action.pageId) {
        this.historyBridge.preparePageRemoval(action.pageId);
      }
      await this.pageRepo.deletePage(this.noteId, action.pageId, history);
      if (this.editorDisposed) {
        return false;
      }
      this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
        action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    const assignedPage: PageInfo = await this.pageRepo.addPage(this.noteId, action.pageAfter, history);
    if (this.editorDisposed) {
      return false;
    }
    if (assignedPage.pageId !== action.pageId) {
      throw new Error('ADD_PAGE redo changed the original page identity');
    }
    const restored: PageInfo[] = this.pages.concat([this.clonePage(assignedPage)]);
    this.pages = this.orderPages(restored, action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  private async applyDeletePageHistory(action: DeletePageAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    if (action.compensationPage !== undefined && action.compensationPage !== null) {
      return await this.applyDeletePageCompensationHistory(action, action.compensationPage,
        isUndo, history);
    }
    if (isUndo) {
      await this.pageRepo.restoreDeletedPage(this.noteId, history.actionId, history);
      if (this.editorDisposed) {
        return false;
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
    await this.pageRepo.deletePageWithCheckpoint(this.noteId, action.pageId, history);
    if (this.editorDisposed) {
      return false;
    }
    this.pages = this.orderPages(this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
      action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  // Original de2.i: undo of a compensated delete removes the blank and
  // restores the victim; redo deletes the victim and recreates the blank.
  private async applyDeletePageCompensationHistory(action: DeletePageAction,
    compensationPage: PageInfo, isUndo: boolean, history: HistoryMetadata): Promise<boolean> {
    const pageRepository: PageRepositoryImpl | null = this.pageRepo;
    if (pageRepository === null) {
      return false;
    }
    if (isUndo) {
      if (this.historyBridge !== null &&
        this.pages[this.currentPageIndex]?.pageId === compensationPage.pageId) {
        this.historyBridge.preparePageRemoval(compensationPage.pageId);
      }
      await pageRepository.undoDeletePageWithCompensation(this.noteId, history.actionId,
        compensationPage.pageId, history);
      if (this.editorDisposed) {
        return false;
      }
      const restored: PageInfo[] = [];
      for (const page of this.pages) {
        if (page.pageId !== compensationPage.pageId) {
          restored.push(page);
        }
      }
      restored.push(this.clonePage(action.pageBefore));
      this.pages = this.orderPages(restored, action.pageOrderBefore);
      this.selectPageById(action.selectedPageIdBefore);
      return true;
    }
    if (this.historyBridge !== null &&
      this.pages[this.currentPageIndex]?.pageId === action.pageId) {
      this.historyBridge.preparePageRemoval(action.pageId);
    }
    await pageRepository.redoDeletePageWithCompensation(this.noteId, history.actionId,
      compensationPage, history);
    if (this.editorDisposed) {
      return false;
    }
    const updated: PageInfo[] = [];
    for (const page of this.pages) {
      if (page.pageId !== action.pageId) {
        updated.push(page);
      }
    }
    updated.push(this.clonePage(compensationPage));
    this.pages = this.orderPages(updated, action.pageOrderAfter);
    this.selectPageById(action.selectedPageIdAfter);
    return true;
  }

  // Duplicate undo rides the original page-visibility write (the copy's
  // elements are never removed); redo restores visibility at its recorded slot.
  private async applyDuplicatePageHistory(action: DuplicatePageAction, isUndo: boolean,
    history: HistoryMetadata): Promise<boolean> {
    if (this.pageRepo === null) {
      return false;
    }
    if (isUndo) {
      if (this.pages.length <= 1) {
        return false;
      }
      if (this.historyBridge !== null &&
        this.pages[this.currentPageIndex]?.pageId === action.pageId) {
        this.historyBridge.preparePageRemoval(action.pageId);
      }
      await this.pageRepo.deletePage(this.noteId, action.pageId, history);
      if (this.editorDisposed) {
        return false;
      }
      this.pages = this.orderPages(
        this.pages.filter((page: PageInfo) => page.pageId !== action.pageId),
        action.pageOrderBefore);
      this.selectPageById(action.sourcePageId);
      return true;
    }
    await this.pageRepo.restoreDuplicatedPage(this.noteId, action.pageId, history);
    if (this.editorDisposed) {
      return false;
    }
    this.pages = await this.pageRepo.getPages(this.noteId);
    if (this.editorDisposed) {
      return false;
    }
    this.pages = this.orderPages(this.pages, action.pageOrderAfter);
    this.selectPageById(action.pageId);
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
    return clonePageInfo(page);
  }

  private samePageSettings(a: PageInfo, b: PageInfo): boolean {
    return a.size === b.size && a.template === b.template && a.orientation === b.orientation &&
      a.widthMm === b.widthMm && a.heightMm === b.heightMm &&
      a.originalPageInAsset === b.originalPageInAsset &&
      samePageBackground(a.background, b.background) &&
      samePageBackground(a.noteBackgroundFallback, b.noteBackgroundFallback);
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}

// Original u49.a + vc9 states: terminal open-failure dialog. deleted=true maps
// uc9 (note_deleted → "Note unavailable"/Done); deleted=false maps rc9
// (load_failed → "Unable to open note"/OK). qc9 download_failed and pc9
// access_denied have no portable trigger (no cloud-stub or shared notes).
@CustomDialog
struct NoteFailureDialog {
  controller?: CustomDialogController;
  deleted: boolean = false;
  onDismiss: () => void = (): void => {
  };
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  build() {
    Column() {
      Text(this.deleted
        ? $r('app.string.note_unavailable_title')
        : $r('app.string.note_load_failed_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveTokens().textPrimary)
      Text(this.deleted
        ? $r('app.string.note_unavailable_message')
        : $r('app.string.note_load_failed_message'))
        .fontSize(14)
        .fontColor(this.resolveTokens().textSecondary)
        .margin({ top: 12 })
      Button(this.deleted
        ? $r('app.string.done')
        : $r('app.string.note_load_failed_button'))
        .height(36)
        .fontSize(14)
        .margin({ top: 16 })
        .onClick(() => {
          this.onDismiss();
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
