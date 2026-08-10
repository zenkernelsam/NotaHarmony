// T-020/T-025 画布视图组件（Phase 2 NoteCanvasPage 重构为可嵌入 @Component）
// 集成：纸张背景 / 笔迹渲染 / UndoRedo / 形状识别 / 选区变换 / 文本框 / 持久化
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RawPointerEvent } from '../../core/adaptation/InkInputProvider';
import { InkInputProviderImpl } from '../../core/adaptation/InkInputProviderImpl';
import { PenKitPredictor } from '../../core/adaptation/PenKitPredictor';
import { PredictionCoordinates } from '../../core/adaptation/Predictor';
import { Canvas2DStrokeRenderer, Canvas2DRenderContext } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { Canvas2DTextRenderer } from '../../core/adaptation/Canvas2DTextRenderer';
import { LoadedPencilTexture, loadOriginalPencilTexture } from '../../core/adaptation/PencilTextureLoader';
import { ImageAssetLoader, ImageAssetLoadState, LoadedImageAsset } from
  '../../core/adaptation/ImageAssetLoader';
import { StrokeLayerManager } from '../../rendering/StrokeLayerManager';
import { StrokeCanvasPainter } from '../../rendering/StrokeCanvasPainter';
import { ShapeCanvasRenderer } from '../../rendering/ShapeCanvasRenderer';
import { ImageCanvasRenderer } from '../../rendering/ImageCanvasRenderer';
import { MathCanvasRenderer } from '../../rendering/MathCanvasRenderer';
import { BitmapTransferMetrics, BitmapTransferTracker } from '../../core/adaptation/BitmapTransferTracker';
import { CanvasViewport, CumulativeGestureTracker } from '../../rendering/CanvasViewport';
import { pagePixelSize, PAGE_UNITS_PER_MM, PagePixelSize } from '../../core/model/PageCoordinateSpace';
import { StrokeSession } from '../../rendering/StrokeSession';
import { EraserEngine, EraserMode } from '../../rendering/EraserEngine';
import { PaperRenderer } from '../../rendering/PaperRenderer';
import {
  EditorHistoryBridge, HistoryMove, PageContentSnapshot, UndoRedoManager, UndoableAction,
  UndoableActionType,
} from '../../rendering/UndoRedoManager';
import { HistoryMetadata, Op } from '../../core/model/OpTypes';
import { SelectionTool, SelectionMode } from '../../rendering/SelectionTool';
import { ClipboardPasteResult, StrokeClipboard } from '../../rendering/StrokeClipboard';
import { TextBlockTool } from '../../rendering/TextBlockTool';
import { ShapeDetector } from '../../core/algorithm/ShapeDetector';
import {
  decodePersistedElement, encodePersistedElement, HistoryPageSnapshot, PersistedElement, StrokePersistence,
} from '../../data/StrokePersistence';
import { SearchSourceElement } from '../../data/SearchIndexPolicy';
import { DatabaseManager } from '../../data/DatabaseManager';
import {
  AssetAvailabilityChange, assetAvailabilityHub,
} from '../../data/AssetAvailabilityHub';
import { OpStoreImpl, PersistentHistoryReplay } from '../../data/OpStoreImpl';
import {
  materializePersistentHistory, replayPersistentPageMutations, RestoredHistoryState,
} from '../../data/PersistentHistory';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import {
  InkPathCommand, InkStyleMapEntry, RenderSpec, StrokeElementData, StrokePathPoint,
  InputBatch, InputBatchKind,
  PencilSplatPoint,
} from '../../core/model/StrokeTypes';
import { ToolType } from '../../core/model/BrushTypes';
import {
  ImageElement, MathElement, ShapeElement, TextBlockElement,
} from '../../core/model/ElementTypes';
import {
  cloneImageElement, eraserPathHitsImageBlock, imageBlockWorldBounds, originalAssetStorageHash,
  transformImageElements,
} from '../../core/model/ImageBlockGeometry';
import {
  cloneShapeElement, eraserPathHitsShape, recomputeShapeBounds, transformShapeElements,
} from '../../core/model/ShapeGeometry';
import { prepareRecognizedShapes } from '../../core/model/ShapeRecognition';
import {
  cloneTextBlockElement, eraserPathHitsTextBlock, pointHitsTextBlock, textBlockTransformComponents,
  textBlockWorldBounds, transformTextBlockElements,
} from '../../core/model/TextBlockGeometry';
import { Point2D, Rect2D, CubicSegment } from '../../core/model/GeometryTypes';
import { cloneMathElement, mathBlockWorldBounds } from '../../core/model/MathBlockGeometry';
import {
  CURRENT_VIEW_COORDINATE_MODEL_VERSION, isCurrentViewCoordinateModel, PageInfo,
} from '../../core/model/NoteTypes';
import {
  appendPageElementRefs, clonePageElementOrder, materializePageElements, movePageElementRefs,
  normalizePageElementOrder, OrderedPageElement, PageElementKind, PageElementRef,
  removePageElementRefs, requiresUnifiedElementRender, samePageElementMembers, samePageElementOrder,
} from '../../core/model/PageElementOrder';
import { EditorViewModel } from './EditorViewModel';
import { SelectionOverlay, SelectionMenuAction } from '../components/SelectionOverlay';
import {
  SELECTION_MENU_BUTTON_HEIGHT, SELECTION_MENU_BUTTON_WIDTH, SelectionOverlayPosition,
  selectionOverlayPosition,
} from '../components/SelectionOverlayLayout';
import { TextBlockOverlay } from '../components/TextBlockOverlay';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ArkUIStylusAdapter, ArkUIStylusSample } from './ArkUIStylusAdapter';
import {
  PointerInputBatches, PointerRawSample, PointerSampleStream,
} from '../../core/adaptation/PointerSampleStream';

const HISTORY_CHECKPOINT_TAIL_OPERATIONS: number = 256;
const HISTORY_CHECKPOINT_MAX_ACTIONS: number = 128;
const HISTORY_REPLAY_ATTEMPTS: number = 4;

interface ShapeDetectionAttempt {
  shapes: ShapeElement[];
  replaced: boolean;
}

@Component
export struct NoteCanvasView {
  // === 外部输入 ===
  @ObjectLink viewModel: EditorViewModel;
  @Prop noteId: string = '';
  // T-040 修复：页面设置（模板/尺寸/方向）变化时重绘画布
  @Prop @Watch('onPageChange') currentPage: PageInfo = {
    pageId: '', pageIndex: 0, size: 1, template: 0, orientation: 0, widthMm: 210, heightMm: 297,
  };
  @Prop @Watch('onUndoSignalChange') undoSignal: number = 0;
  @Prop @Watch('onRedoSignalChange') redoSignal: number = 0;
  // MyScript 的精确 hold 时长未出现在反编译配置中；保留注入点供设备对照后收敛。
  @Prop shapeHoldDelayMs: number = 500;
  onUndoRedoChanged: (canUndo: boolean, canRedo: boolean) => void = () => {
  };
  onRequestPage: (pageId: string) => void = () => {
  };
  onHistoryBridgeReady: (bridge: EditorHistoryBridge) => void = () => {
  };
  onApplyPageHistory: (action: UndoableAction, isUndo: boolean,
    history: HistoryMetadata) => Promise<boolean> =
    async (_action: UndoableAction, _isUndo: boolean, _history: HistoryMetadata): Promise<boolean> => false;

  // === 内部模块 ===
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderCtx: Canvas2DRenderContext = new Canvas2DRenderContext(this.canvasCtx);
  private inputProvider: InkInputProviderImpl = InkInputProviderImpl.createForArkUI();
  private predictor: PenKitPredictor = new PenKitPredictor();
  private bitmapTransferTracker: BitmapTransferTracker = new BitmapTransferTracker();
  private renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer(this.bitmapTransferTracker);
  private strokePainter: StrokeCanvasPainter = new StrokeCanvasPainter(this.renderer, this.bitmapTransferTracker);
  private shapeRenderer: ShapeCanvasRenderer = new ShapeCanvasRenderer();
  private imageRenderer: ImageCanvasRenderer = new ImageCanvasRenderer();
  private mathRenderer: MathCanvasRenderer = new MathCanvasRenderer();
  private textRenderer: Canvas2DTextRenderer = new Canvas2DTextRenderer();
  private pencilPixelMap: image.PixelMap | null = null;
  private pencilTextureLoading: boolean = false;
  private lifecycleActive: boolean = false;
  private layerManager: StrokeLayerManager = new StrokeLayerManager(this.renderer, this.bitmapTransferTracker);
  private strokeSession: StrokeSession | null = null;
  private activePointerId: number = -1;
  private pointerStream: PointerSampleStream = new PointerSampleStream();
  private eraserEngine: EraserEngine = new EraserEngine(EraserMode.WHOLE, 20);
  private paperRenderer: PaperRenderer = new PaperRenderer();
  private undoRedo: UndoRedoManager = new UndoRedoManager();
  private shapeDetector: ShapeDetector = new ShapeDetector();
  private persistence: StrokePersistence = new StrokePersistence();
  private database: DatabaseManager | null = null;
  private imageAssetLoader: ImageAssetLoader | null = null;
  private imageAssets: Map<string, LoadedImageAsset> = new Map<string, LoadedImageAsset>();
  private imageAssetGeneration: number = 0;
  private assetAvailabilitySubscription: number = -1;
  private selectionTool: SelectionTool = new SelectionTool();
  private strokeClipboard: StrokeClipboard = new StrokeClipboard();
  private clipboardIdCounter: number = 0;
  private textBlockTool: TextBlockTool = new TextBlockTool();
  // T-034：画布视口（缩放/平移）
  private viewport: CanvasViewport = new CanvasViewport();
  private viewportSaveTimer: number = -1;   // 防抖定时器
  private gestureTracker: CumulativeGestureTracker = new CumulativeGestureTracker();
  @State zoomPercent: number = 100;         // 控制条显示（100 = 100%）
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  // === 画布状态 ===
  private completedStrokes: StrokeElementData[] = [];
  private textBlocks: TextBlockElement[] = [];
  private shapes: ShapeElement[] = [];
  private imageBlocks: ImageElement[] = [];
  private mathBlocks: MathElement[] = [];
  private elementOrder: PageElementRef[] = [];
  private eraserPath: Point2D[] = [];
  private isDrawing: boolean = false;
  private eraserActive: boolean = false;
  private selectionDrawing: boolean = false;
  private selectionDrag: boolean = false;
  private dragBeforeStrokes: StrokeElementData[] = [];
  private dragBeforeShapes: ShapeElement[] = [];
  private dragBeforeTextBlocks: TextBlockElement[] = [];
  private dragBeforeImages: ImageElement[] = [];
  private lastDragPoint: Point2D = { x: 0, y: 0 };
  private lastTapTime: number = 0;
  private lastTapPos: Point2D = { x: 0, y: 0 };
  private loaded: boolean = false;
  private loadedPageId: string = '';
  @State dataLoading: boolean = true;
  @State dataLoadFailed: boolean = false;
  private pageLoadPromise: Promise<void> = Promise.resolve();
  private viewportInitialized: boolean = false;
  private shapeHoldTimer: number = -1;
  private heldShapes: ShapeElement[] = [];
  // -1: undo, 1: redo, 0: none. Cross-page history resumes after page data finishes loading.
  private pendingHistoryDirection: number = 0;
  private historyBusy: boolean = false;
  private skipSavePageId: string = '';
  private pageLoadGeneration: number = 0;
  private saveFailed: boolean = false;
  private lastQueuedHistoryRevision: number = 0;
  private historyLoaded: boolean = false;
  private historyRecoveryRequired: boolean = false;
  private historyRecoveryPrompted: boolean = false;
  private historyRecoveryBusy: boolean = false;
  @State textEditing: boolean = false;
  @State editingTextBlock: TextBlockElement | null = null;
  private editingOriginalTextBlock: TextBlockElement | null = null;
  private editingDraftText: string = '';
  @State editingTextLayoutWidth: number = 0;
  @State selectionRect: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @State selectionVisible: boolean = false;
  @State clipboardAvailable: boolean = false;
  @State overlayWidth: number = 0;
  @State overlayHeight: number = 0;

  aboutToAppear(): void {
    this.lifecycleActive = true;
    if (this.assetAvailabilitySubscription < 0) {
      this.assetAvailabilitySubscription = assetAvailabilityHub.subscribe(
        (change: AssetAvailabilityChange): void => this.onImageAssetAvailabilityChanged(change));
    }
    this.onHistoryBridgeReady({
      preparePageAction: (action: UndoableAction): HistoryMetadata =>
        this.preparePageHistory(action),
      pushPageAction: (action: UndoableAction, history?: HistoryMetadata): void => {
        if (this.historyBusy) {
          throw new Error('page history cannot change during an active history command');
        }
        this.undoRedo.push(action, history);
        this.notifyUndoRedo();
      },
      captureCurrentPage: (): PageContentSnapshot => this.captureCurrentPage(),
      preparePageRemoval: (pageId: string): void => {
        this.skipSavePageId = pageId;
        if (this.loadedPageId === pageId) {
          this.dataLoading = true;
        }
      },
      cancelPageRemoval: (pageId: string): void => {
        if (this.skipSavePageId === pageId) {
          this.skipSavePageId = '';
          this.dataLoading = false;
        }
      },
      flushCurrentPage: async (): Promise<boolean> => this.flushCurrentPage(),
    });
    this.pageLoadPromise = this.loadNoteData();
  }

  // === 数据加载与持久化 ===
  private async loadNoteData(): Promise<void> {
    const generation: number = ++this.pageLoadGeneration;
    const targetPageId: string = this.currentPage.pageId;
    this.dataLoading = true;
    this.dataLoadFailed = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.database = db;
      this.imageAssetLoader = new ImageAssetLoader(db);
      this.persistence.initialize(db);
      const loaded = await this.persistence.loadElements(this.noteId, targetPageId);
      if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== targetPageId) {
        return;
      }
      this.completedStrokes = loaded.strokes;
      this.textBlocks = loaded.textBlocks;
      this.shapes = loaded.shapes;
      this.imageBlocks = loaded.images;
      this.mathBlocks = loaded.mathBlocks;
      this.elementOrder = loaded.elementOrder;
      this.loadedPageId = targetPageId;
      if (!this.historyLoaded) {
        const restored: RestoredHistoryState | null = await this.readPersistentHistory(db, targetPageId);
        if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== targetPageId) {
          return;
        }
        if (restored === null) {
          this.undoRedo.clear();
        } else {
          this.undoRedo.restore(restored.undo, restored.redo);
          if (restored.legacyOperationCount > 0) {
            hilog.info(0x0001, 'NoteCanvasView',
              'history restored after %{public}d legacy operation boundaries', restored.legacyOperationCount);
          }
        }
        this.notifyUndoRedo();
        this.historyLoaded = true;
      }
      // T-034：恢复视口（zoom/scroll）
      const noteRepo = new NoteRepositoryImpl(db);
      const state = await noteRepo.getViewState(this.noteId);
      if (state !== null && isCurrentViewCoordinateModel(state.coordinateModelVersion)) {
        const restoredZoom: boolean = this.viewport.setZoomRaw(state.zoom);
        const restoredScroll: boolean = this.viewport.setScroll(state.scrollOffsetX, state.scrollOffsetY);
        this.zoomPercent = Math.round(this.viewport.zoom * 100);
        if (restoredZoom || restoredScroll) {
          this.viewportInitialized = true;
        }
      }
      this.loaded = true;
      this.dataLoadFailed = false;
      if (this.layerManager.isInitialized()) {
        if (!this.viewportInitialized) {
          this.centerPaperInViewport();
        }
        this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
        this.renderFrame(true);
      }
      this.refreshImageAssets(generation, targetPageId);
      this.promptPersistentHistoryRecovery();
    } catch (e) {
      if (generation === this.pageLoadGeneration) {
        this.enterLoadFailureState();
        this.reportLoadFailure(e as Object);
      }
      console.error(`NoteCanvasView load failed: ${JSON.stringify(e)}`);
    } finally {
      if (generation === this.pageLoadGeneration) {
        this.dataLoading = false;
      }
    }
  }

  private async readPersistentHistory(db: DatabaseManager,
    currentPageId: string): Promise<RestoredHistoryState | null> {
    let lastError: Object = new Error('persistent history replay failed');
    for (let attempt: number = 1; attempt <= HISTORY_REPLAY_ATTEMPTS; attempt++) {
      try {
        const opStore: OpStoreImpl = new OpStoreImpl(db);
        const replay: PersistentHistoryReplay = await opStore.getPersistentHistory(this.noteId);
        const checkpoints = await new PageRepositoryImpl(db).getDeleteCheckpoints(this.noteId);
        const restored: RestoredHistoryState = materializePersistentHistory(
          replay.state, currentPageId, checkpoints);
        if (replay.tailOperationCount >= HISTORY_CHECKPOINT_TAIL_OPERATIONS) {
          try {
            await opStore.checkpointPersistentHistory(this.noteId, HISTORY_CHECKPOINT_MAX_ACTIONS);
          } catch (checkpointError) {
            hilog.error(0x0001, 'NoteCanvasView',
              'persistent history checkpoint skipped: %{public}s', JSON.stringify(checkpointError));
          }
        }
        this.historyRecoveryRequired = false;
        return restored;
      } catch (e) {
        lastError = e as Object;
        hilog.error(0x0001, 'NoteCanvasView',
          'persistent history replay attempt %{public}d/%{public}d failed: %{public}s',
          attempt, HISTORY_REPLAY_ATTEMPTS, JSON.stringify(e));
      }
    }
    // Corrupt history must not make the note unreadable. Strict replay remains unavailable.
    this.historyRecoveryRequired = true;
    hilog.error(0x0001, 'NoteCanvasView',
      'persistent history disabled after retries: %{public}s', JSON.stringify(lastError));
    return null;
  }

  private persist(): void {
    if (this.loaded && !this.dataLoading && !this.dataLoadFailed && this.persistence.isReady() &&
      this.noteId.length > 0 && this.loadedPageId.length > 0 &&
      this.loadedPageId !== this.skipSavePageId) {
      const pageId: string = this.loadedPageId;
      try {
        const historyRevision: number = this.undoRedo.getHistoryRevision();
        const preserveActionBoundary: boolean = historyRevision !== this.lastQueuedHistoryRevision;
        const history = preserveActionBoundary ? this.undoRedo.getLatestHistoryMetadata() : undefined;
        this.persistence.queueSaveElements(this.noteId, pageId, this.completedStrokes, this.textBlocks,
          this.elementOrder, this.shapes, preserveActionBoundary, history === null ? undefined : history,
          this.imageBlocks, this.mathBlocks);
        this.lastQueuedHistoryRevision = historyRevision;
        this.persistence.flush(this.noteId, pageId).then(() => {
          if (!this.persistence.hasDirtySave(this.noteId, pageId)) {
            this.saveFailed = false;
          }
        }).catch((e: Object) => this.reportSaveFailure(e));
      } catch (e) {
        this.reportSaveFailure(e as Object);
      }
    }
  }

  private async flushCurrentPage(): Promise<boolean> {
    await this.pageLoadPromise;
    if (!this.loaded || this.dataLoadFailed) {
      return true;
    }
    if (!this.persistence.isReady() || this.noteId.length === 0 || this.loadedPageId.length === 0) {
      return true;
    }
    if (this.textEditing && this.editingTextBlock !== null) {
      this.onTextCommit(this.editingDraftText);
    } else if (this.loadedPageId !== this.skipSavePageId) {
      this.persistence.queueSaveElements(this.noteId, this.loadedPageId,
        this.completedStrokes, this.textBlocks, this.elementOrder, this.shapes,
        false, undefined, this.imageBlocks, this.mathBlocks);
    }
    try {
      await this.persistence.flush(this.noteId, this.loadedPageId);
      this.saveFailed = false;
      await this.maintainPersistentHistoryCheckpoint();
      return true;
    } catch (e) {
      this.reportSaveFailure(e as Object);
      return false;
    }
  }

  private async maintainPersistentHistoryCheckpoint(): Promise<void> {
    if (this.database === null || this.noteId.length === 0 || this.historyRecoveryRequired) {
      return;
    }
    try {
      const opStore: OpStoreImpl = new OpStoreImpl(this.database);
      const replay: PersistentHistoryReplay = await opStore.getPersistentHistory(this.noteId);
      if (replay.tailOperationCount >= HISTORY_CHECKPOINT_TAIL_OPERATIONS) {
        await opStore.checkpointPersistentHistory(this.noteId, HISTORY_CHECKPOINT_MAX_ACTIONS);
      }
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView',
        'persistent history checkpoint maintenance skipped: %{public}s', JSON.stringify(e));
    }
  }

  private promptPersistentHistoryRecovery(): void {
    if (!this.lifecycleActive || !this.historyRecoveryRequired || this.historyRecoveryPrompted) {
      return;
    }
    this.historyRecoveryPrompted = true;
    try {
      this.getUIContext().showAlertDialog({
        title: $r('app.string.history_recovery_title'),
        message: $r('app.string.history_recovery_message'),
        primaryButton: {
          value: $r('app.string.continue_editing'),
          action: () => {
          },
        },
        secondaryButton: {
          value: $r('app.string.reset_undo_history'),
          fontColor: this.resolveTokens().danger,
          action: () => {
            this.resetPersistentHistory().catch((e: Object) => {
              hilog.error(0x0001, 'NoteCanvasView',
                'persistent history reset action failed: %{public}s', JSON.stringify(e));
            });
          },
        },
      });
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView',
        'persistent history recovery dialog failed: %{public}s', JSON.stringify(e));
      this.showHistoryRecoveryToast($r('app.string.history_recovery_needed'));
    }
  }

  private async resetPersistentHistory(): Promise<void> {
    if (this.historyRecoveryBusy || this.historyBusy ||
      !this.historyRecoveryRequired || this.database === null) {
      return;
    }
    this.historyRecoveryBusy = true;
    this.historyBusy = true;
    try {
      await new OpStoreImpl(this.database).resetPersistentHistory(this.noteId);
      this.undoRedo.clear();
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.historyRecoveryRequired = false;
      this.notifyUndoRedo();
      this.showHistoryRecoveryToast($r('app.string.history_recovery_complete'));
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView',
        'persistent history reset failed: %{public}s', JSON.stringify(e));
      this.showHistoryRecoveryToast($r('app.string.history_recovery_failed'));
    } finally {
      this.historyBusy = false;
      this.historyRecoveryBusy = false;
    }
  }

  private showHistoryRecoveryToast(message: ResourceStr): void {
    try {
      promptAction.showToast({ message: message, duration: 3000 });
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView',
        'persistent history recovery toast failed: %{public}s', JSON.stringify(e));
    }
  }

  private reportSaveFailure(error: Object): void {
    console.error(`NoteCanvasView save failed: ${JSON.stringify(error)}`);
    if (!this.saveFailed) {
      this.saveFailed = true;
      try {
        promptAction.showToast({ message: $r('app.string.note_save_failed'), duration: 2500 });
      } catch (toastError) {
        console.error(`Save failure toast failed: ${JSON.stringify(toastError)}`);
      }
    }
  }

  private reportLoadFailure(error: Object, returnedToPreviousPage: boolean = false): void {
    console.error(`NoteCanvasView data load failed: ${JSON.stringify(error)}`);
    try {
      promptAction.showToast({
        message: returnedToPreviousPage ? $r('app.string.page_load_returned') :
          $r('app.string.page_load_stopped'),
        duration: 2500,
      });
    } catch (toastError) {
      console.error(`Load failure toast failed: ${JSON.stringify(toastError)}`);
    }
  }

  private notifyUndoRedo(): void {
    this.onUndoRedoChanged(this.undoRedo.canUndo(), this.undoRedo.canRedo());
  }

  // === 外部命令（父组件工具栏按钮）===
  onUndoSignalChange(_propName: string): void {
    hilog.info(0x0001, 'NoteCanvasView', 'undo signal received, canUndo=%{public}s',
      this.undoRedo.canUndo().toString());
    this.undoStroke();
  }

  // T-040 修复：页面设置变化 → 重绘（@Prop 更新不会自动触发 renderFrame）
  onPageChange(_propName: string): void {
    this.pageLoadPromise = this.switchPageData();
  }

  aboutToDisappear(): void {
    this.lifecycleActive = false;
    if (this.assetAvailabilitySubscription >= 0) {
      assetAvailabilityHub.unsubscribe(this.assetAvailabilitySubscription);
      this.assetAvailabilitySubscription = -1;
    }
    this.releaseImageAssets();
    this.strokeClipboard.clear();
    this.clipboardAvailable = false;
    this.cancelShapeDetectionTimer();
    if (this.viewportSaveTimer >= 0) {
      clearTimeout(this.viewportSaveTimer);
      this.viewportSaveTimer = -1;
    }
    this.saveViewportState();
    if (this.textEditing && this.editingTextBlock !== null) {
      this.onTextCommit(this.editingDraftText);
    } else {
      this.persist();
    }
    const renderMetrics: BitmapTransferMetrics = this.layerManager.getRenderMetrics();
    hilog.info(0x0001, 'NoteCanvasView',
      'render metrics frames=%{public}d full=%{public}d transfers=%{public}d completed=%{public}d ' +
      'isolated=%{public}d pencilTint=%{public}d pencilTexture=%{public}d ' +
      'maxPerFrame=%{public}d maxDirtyRegions=%{public}d',
      renderMetrics.frameCount, renderMetrics.fullFrameCount, renderMetrics.totalTransfers,
      renderMetrics.completedLayerTransfers, renderMetrics.isolatedMaskTransfers,
      renderMetrics.pencilTintTransfers, renderMetrics.pencilTextureTransfers,
      renderMetrics.maxFrameTransfers, renderMetrics.maxDirtyRegionCount);
    this.layerManager.dispose();
    this.renderer.dispose();
    if (this.pencilPixelMap !== null) {
      this.pencilPixelMap.release().catch((e: Object) => {
        console.warn(`Pencil PixelMap release failed: ${JSON.stringify(e)}`);
      });
      this.pencilPixelMap = null;
    }
  }

  private async switchPageData(): Promise<void> {
    if (!this.loaded) {
      await this.loadNoteData();
      return;
    }
    if (this.currentPage.pageId === this.loadedPageId) {
      this.initializeLayerForPage();
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
      this.renderFrame(true);
      return;
    }
    const generation: number = ++this.pageLoadGeneration;
    const fromPageId: string = this.loadedPageId;
    const targetPageId: string = this.currentPage.pageId;
    const snapshot: PageContentSnapshot = this.captureCurrentPage();
    const fromPageWasRemoved: boolean = fromPageId === this.skipSavePageId;
    let previousPageSaved: boolean = false;
    this.dataLoading = true;
    this.dataLoadFailed = false;
    try {
      if (fromPageId.length > 0) {
        if (fromPageId !== this.skipSavePageId) {
          this.persistence.queueSaveElements(this.noteId, fromPageId, snapshot.strokes, snapshot.textBlocks,
            snapshot.elementOrder, snapshot.shapes, false, undefined, snapshot.images,
            snapshot.mathBlocks);
          await this.persistence.flush(this.noteId, fromPageId);
        } else {
          this.skipSavePageId = '';
        }
      }
      previousPageSaved = true;
      const loaded = await this.persistence.loadElements(this.noteId, targetPageId);
      if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== targetPageId) {
        return;
      }
      this.completedStrokes = loaded.strokes;
      this.textBlocks = loaded.textBlocks;
      this.shapes = loaded.shapes;
      this.imageBlocks = loaded.images;
      this.mathBlocks = loaded.mathBlocks;
      this.elementOrder = loaded.elementOrder;
      this.loadedPageId = targetPageId;
      this.loaded = true;
      this.dataLoadFailed = false;
      this.selectionTool.deselect();
      this.selectionVisible = false;
      this.initializeLayerForPage();
      this.centerPaperInViewport();
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
      this.notifyUndoRedo();
      this.renderFrame(true);
      this.refreshImageAssets(generation, targetPageId);
      this.resumePendingHistory();
    } catch (e) {
      if (generation === this.pageLoadGeneration) {
        if (previousPageSaved) {
          this.reportLoadFailure(e as Object, !fromPageWasRemoved && fromPageId.length > 0);
        } else {
          this.reportSaveFailure(e as Object);
        }
        if (!fromPageWasRemoved && fromPageId.length > 0) {
          this.completedStrokes = snapshot.strokes;
          this.textBlocks = snapshot.textBlocks;
          this.shapes = snapshot.shapes;
          this.imageBlocks = snapshot.images;
          this.mathBlocks = snapshot.mathBlocks;
          this.elementOrder = snapshot.elementOrder;
          this.loadedPageId = fromPageId;
          this.loaded = true;
          this.dataLoadFailed = false;
          this.refreshImageAssets(generation, fromPageId);
          this.onRequestPage(fromPageId);
        } else {
          this.enterLoadFailureState();
        }
      }
      console.error(`NoteCanvasView page switch failed: ${JSON.stringify(e)}`);
    } finally {
      if (generation === this.pageLoadGeneration) {
        this.dataLoading = false;
      }
    }
  }

  private enterLoadFailureState(): void {
    this.releaseImageAssets();
    this.loaded = false;
    this.loadedPageId = '';
    this.completedStrokes = [];
    this.textBlocks = [];
    this.shapes = [];
    this.imageBlocks = [];
    this.mathBlocks = [];
    this.elementOrder = [];
    this.dataLoadFailed = true;
    this.cancelActiveInteraction();
    this.selectionTool.deselect();
    this.selectionVisible = false;
    if (this.layerManager.isInitialized()) {
      this.initializeLayerForPage();
      this.layerManager.rebuildFromStrokes([], this.renderCtx);
      this.renderFrame(true);
    }
  }

  onRedoSignalChange(_propName: string): void {
    hilog.info(0x0001, 'NoteCanvasView', 'redo signal received, canRedo=%{public}s',
      this.undoRedo.canRedo().toString());
    this.redoStroke();
  }

  // === 画布初始化 ===
  private onCanvasReady(): void {
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    this.ensurePencilTexture();
    this.initializeLayerForPage();
    this.renderer.setEraserMaskWidth(20);
    this.predictor.reset();
    if (this.loaded) {
      if (!this.viewportInitialized) {
        this.centerPaperInViewport();
      }
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    }
    this.renderFrame(true);
  }

  private async ensurePencilTexture(): Promise<void> {
    if (this.pencilTextureLoading || this.pencilPixelMap !== null) {
      return;
    }
    this.pencilTextureLoading = true;
    let pixelMap: image.PixelMap | null = null;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const loadedTexture: LoadedPencilTexture = await loadOriginalPencilTexture(context);
      const texture: ImageBitmap = loadedTexture.bitmap;
      pixelMap = loadedTexture.pixelMap;
      if (!this.lifecycleActive) {
        texture.close();
        try {
          await pixelMap.release();
        } catch (e) {
          console.warn(`Unused pencil PixelMap release failed: ${JSON.stringify(e)}`);
        } finally {
          pixelMap = null;
        }
        return;
      }
      this.pencilPixelMap = pixelMap;
      pixelMap = null;
      this.renderer.setSplatTexture(texture);
      if (this.layerManager.isInitialized()) {
        this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
        this.renderFrame(true);
      }
    } catch (e) {
      console.error(`Original pencil texture load failed: ${JSON.stringify(e)}`);
      if (this.lifecycleActive) {
        this.renderer.setSplatTexture(Canvas2DStrokeRenderer.generatePencilTexture(this.bitmapTransferTracker));
        if (this.layerManager.isInitialized()) {
          this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
          this.renderFrame(true);
        }
      }
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (releaseError) {
          console.warn(`Pencil PixelMap cleanup failed: ${JSON.stringify(releaseError)}`);
        }
      }
    } finally {
      this.pencilTextureLoading = false;
    }
  }

  // === 每帧渲染（背景 + 已完成层 + 当前笔画 + 文本框）===
  // T-034：视口变换（translate + scale）后以画布坐标绘制，背景铺满视口可见区
  private renderFrame(forceFull: boolean = false): void {
    if (!this.layerManager.isInitialized()) {
      return;
    }
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    const theme: ThemeTokens = ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
    const sessionStroke: StrokeElementData | null = this.strokeSession !== null && this.strokeSession.isActive()
      ? this.strokeSession.getCurrentStroke() : null;
    const current: StrokeElementData | null = this.heldShapes.length === 0 ? sessionStroke : null;
    const orderedRender: boolean = this.requiresOrderedElementRender() || this.heldShapes.length > 0;
    const fullRedraw: boolean = forceFull || orderedRender;
    if (fullRedraw) {
      this.canvasCtx.clearRect(0, 0, w, h);
      this.canvasCtx.fillStyle = theme.background;
      this.canvasCtx.fillRect(0, 0, w, h);
    }
    this.canvasCtx.save();
    this.canvasCtx.translate(this.viewport.scrollX, this.viewport.scrollY);
    this.canvasCtx.scale(this.viewport.zoom, this.viewport.zoom);
    if (orderedRender) {
      this.renderPaper(theme);
      this.renderOrderedElements();
      for (const heldShape of this.heldShapes) {
        this.shapeRenderer.renderShape(heldShape, this.renderCtx);
      }
      if (current !== null) {
        this.strokePainter.renderStroke(current, this.renderCtx, this.getPaperWidth(), this.getPaperHeight());
      }
    } else if (forceFull) {
      this.renderPaper(theme);
      this.layerManager.compositeFull(this.canvasCtx, current, this.renderCtx);
      this.renderTextBlocks();
    } else {
      this.layerManager.composite(this.canvasCtx, current, this.renderCtx, () => {
        const visibleLeft: number = -this.viewport.scrollX / this.viewport.zoom;
        const visibleTop: number = -this.viewport.scrollY / this.viewport.zoom;
        this.canvasCtx.fillStyle = theme.background;
        this.canvasCtx.fillRect(visibleLeft, visibleTop, w / this.viewport.zoom, h / this.viewport.zoom);
        this.renderPaper(theme);
      }, () => {
        this.renderTextBlocks();
      }, this.viewport.zoom);
    }
    this.canvasCtx.restore();
  }

  private renderPaper(theme: ThemeTokens): void {
    this.paperRenderer.renderBackground(this.canvasCtx, this.getPaperWidth(), this.getPaperHeight(),
      this.currentPage, this.viewport.zoom, theme);
  }

  private renderTextBlocks(): void {
    for (const textBlock of this.textBlocks) {
      this.textRenderer.renderText(textBlock, this.renderCtx);
    }
  }

  private requiresOrderedElementRender(): boolean {
    return requiresUnifiedElementRender(this.elementOrder);
  }

  private renderOrderedElements(): void {
    const elements: OrderedPageElement[] = materializePageElements(
      this.elementOrder, this.completedStrokes, this.textBlocks, this.shapes, this.imageBlocks,
      this.mathBlocks);
    for (const element of elements) {
      if (element.kind === PageElementKind.STROKE) {
        this.strokePainter.renderStroke(element.data, this.renderCtx, this.getPaperWidth(), this.getPaperHeight());
      } else if (element.kind === PageElementKind.TEXT) {
        this.textRenderer.renderText(element.data, this.renderCtx);
      } else if (element.kind === PageElementKind.SHAPE) {
        this.shapeRenderer.renderShape(element.data, this.renderCtx);
      } else if (element.kind === PageElementKind.IMAGE) {
        const loaded: LoadedImageAsset | undefined = this.imageAssets.get(
          originalAssetStorageHash(element.data.assetHashBits));
        if (loaded !== undefined && loaded.state === ImageAssetLoadState.READY && loaded.bitmap !== null) {
          this.imageRenderer.renderImage(element.data, loaded.bitmap, this.renderCtx);
        }
      } else if (element.kind === PageElementKind.MATH) {
        this.mathRenderer.renderMath(element.data, this.renderCtx);
      }
    }
  }

  private refreshImageAssets(pageGeneration: number, pageId: string): void {
    const loader: ImageAssetLoader | null = this.imageAssetLoader;
    this.releaseImageAssets();
    if (loader === null || this.imageBlocks.length === 0) {
      return;
    }
    const assetGeneration: number = this.imageAssetGeneration;
    const seen: Set<string> = new Set<string>();
    for (const block of this.imageBlocks) {
      const storageHash: string = originalAssetStorageHash(block.assetHashBits);
      if (seen.has(storageHash)) {
        continue;
      }
      seen.add(storageHash);
      this.loadImageAsset(block, storageHash, loader, pageGeneration, assetGeneration, pageId);
    }
  }

  private onImageAssetAvailabilityChanged(change: AssetAvailabilityChange): void {
    if (!this.lifecycleActive || change.noteIds.indexOf(this.noteId) < 0 || this.loadedPageId.length === 0) {
      return;
    }
    for (const block of this.imageBlocks) {
      if (originalAssetStorageHash(block.assetHashBits) === change.storageHash) {
        this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
        return;
      }
    }
  }

  private async loadImageAsset(block: ImageElement, storageHash: string, loader: ImageAssetLoader,
    pageGeneration: number, assetGeneration: number, pageId: string): Promise<void> {
    const loaded: LoadedImageAsset = await loader.load(block);
    if (!this.lifecycleActive || pageGeneration !== this.pageLoadGeneration ||
      assetGeneration !== this.imageAssetGeneration || this.loadedPageId !== pageId) {
      loader.release(loaded);
      return;
    }
    this.imageAssets.set(storageHash, loaded);
    if (loaded.state !== ImageAssetLoadState.READY) {
      hilog.warn(0x0001, 'NoteCanvasView',
        'image asset unavailable block=%{public}s state=%{public}d reason=%{public}s',
        block.id, loaded.state, loaded.error === null ? '' : loaded.error);
    }
    if (this.layerManager.isInitialized()) {
      this.renderFrame(true);
    }
  }

  private releaseImageAssets(): void {
    this.imageAssetGeneration++;
    const loader: ImageAssetLoader | null = this.imageAssetLoader;
    if (loader !== null) {
      this.imageAssets.forEach((loaded: LoadedImageAsset): void => loader.release(loaded));
    }
    this.imageAssets.clear();
  }

  // === T-034：视口操作 ===
  private onViewportChanged(): void {
    this.zoomPercent = Math.round(this.viewport.zoom * 100);
    if (this.selectionVisible) {
      this.updateSelectionOverlay();
    }
    this.renderFrame(true);
    this.scheduleViewportSave();
  }

  // 缩放/滚动持久化（防抖 500ms）
  private scheduleViewportSave(): void {
    if (this.viewportSaveTimer >= 0) {
      clearTimeout(this.viewportSaveTimer);
    }
    this.viewportSaveTimer = setTimeout(() => {
      this.viewportSaveTimer = -1;
      this.saveViewportState();
    }, 500);
  }

  private async saveViewportState(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      const noteRepo = new NoteRepositoryImpl(db);
      await noteRepo.saveViewState({
        noteId: this.noteId,
        zoom: this.viewport.zoom,
        scrollOffsetX: this.viewport.scrollX,
        scrollOffsetY: this.viewport.scrollY,
        coordinateModelVersion: CURRENT_VIEW_COORDINATE_MODEL_VERSION,
      });
    } catch (e) {
      console.error(`saveViewportState failed: ${JSON.stringify(e)}`);
    }
  }

  // 缩放控制条操作
  private zoomStep(delta: number): void {
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    this.viewport.zoomAt(w / 2, h / 2, 1 + delta);
    this.onViewportChanged();
  }

  private zoomFitWidth(): void {
    // T-040 修复：适配宽度以当前纸张实际宽度为基准（mm×3.78），铺满 85% 宽度
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    const paperW: number = this.getPaperWidth();
    const paperH: number = this.getPaperHeight();
    const fit: number = (w * 0.85) / paperW;
    const clamped: number = fit < 0.25 ? 0.25 : (fit > 4.0 ? 4.0 : fit);
    this.viewport.setZoomRaw(clamped);
    const scrollX: number = (w - paperW * clamped) / 2;
    const scrollY: number = Math.max(16, (h - paperH * clamped) / 2);
    this.viewport.setScroll(scrollX, scrollY);
    this.onViewportChanged();
  }

  // === 触摸事件 ===
  private onCanvasTouch(event: TouchEvent): void {
    if (!this.loaded || this.dataLoading || this.dataLoadFailed || this.historyBusy) {
      return;
    }
    if (event.type === TouchType.Down) {
      this.onTouchDown(event);
    } else if (event.type === TouchType.Move) {
      this.onTouchMove(event);
    } else if (event.type === TouchType.Up) {
      this.onTouchUp(event);
    } else if (event.type === TouchType.Cancel) {
      this.cancelActiveInteraction();
    }
  }

  private onTouchDown(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }
    // T-034：双指手势接管（捏合缩放/双指平移），单指书写
    if (event.touches.length > 1) {
      this.cancelActiveInteraction();
      return;
    }
    const touch: TouchObject = event.touches[0];
    // 原版工具枚举没有 TEXT；移植侧用 DEFAULT 表示临时文本输入模式。
    // 只有该模式响应标准双击，避免橡皮、选区和书写快速点按误建文本框。
    if (this.viewModel.currentTool === ToolType.DEFAULT) {
      const now: number = Date.now();
      const dx: number = touch.x - this.lastTapPos.x;
      const dy: number = touch.y - this.lastTapPos.y;
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (now - this.lastTapTime <= 300 && dist <= 8) {
        this.lastTapTime = 0;
        this.beginTextEditingAt(this.viewport.screenToCanvas(touch.x, touch.y));
      } else {
        this.lastTapTime = now;
        this.lastTapPos = { x: touch.x, y: touch.y };
      }
      return;
    }
    this.lastTapTime = 0;

    // T-034：后续逻辑统一使用画布坐标（视口逆映射）
    const canvasP: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);

    // 选区菜单区域：交给 SelectionOverlay 按钮处理，不进入画布逻辑
    // （避免 Canvas onTouch 触发 rebuild 导致按钮 click 识别失效；菜单按钮为屏幕坐标）
    if (this.selectionVisible && this.isInSelectionMenu(touch.x, touch.y)) {
      return;
    }

    this.activePointerId = touch.id;

    if (this.viewModel.isEraserActive()) {
      this.eraserEngine.setMode(this.viewModel.eraserIsPartial ? EraserMode.PARTIAL : EraserMode.WHOLE);
      this.eraserActive = true;
      this.eraserPath = [];
      this.isDrawing = true;
      this.collectEraserPoint(touch);
      return;
    }
    if (this.viewModel.isSelectionActive()) {
      // 已选中且按下点在选区内 → 拖拽移动（画布坐标）
      hilog.info(0x0001, 'NoteCanvasView', 'selDown visible=%{public}s x=%{public}f y=%{public}f rect=(%{public}f,%{public}f,%{public}f,%{public}f)',
        this.selectionVisible.toString(), touch.x, touch.y, this.selectionRect.left,
        this.selectionRect.top, this.selectionRect.right, this.selectionRect.bottom);
      if (this.selectionVisible && this.pointInRect({ x: touch.x, y: touch.y }, this.selectionRect)) {
        hilog.info(0x0001, 'NoteCanvasView', 'selection drag start at (%{public}f,%{public}f) rect=(%{public}f,%{public}f)-(%{public}f,%{public}f)',
          canvasP.x, canvasP.y, this.selectionRect.left, this.selectionRect.top,
          this.selectionRect.right, this.selectionRect.bottom);
        this.selectionDrag = true;
        this.dragBeforeStrokes = this.completedStrokes.slice();
        this.dragBeforeShapes = this.shapes.slice();
        this.dragBeforeTextBlocks = this.textBlocks.slice();
        this.dragBeforeImages = this.imageBlocks.slice();
        this.lastDragPoint = { x: canvasP.x, y: canvasP.y };
      } else {
        hilog.info(0x0001, 'NoteCanvasView', 'selection begin at (%{public}f,%{public}f) visible=%{public}s',
          canvasP.x, canvasP.y, this.selectionVisible.toString());
        this.selectionDrawing = true;
        this.selectionTool.beginSelection(
          this.viewModel.selectionIsFreehand ? SelectionMode.LASSO : SelectionMode.RECTANGLE,
          canvasP);
        this.selectionVisible = false;
      }
      this.isDrawing = true;
      return;
    }
    // 笔画工具
    const spec: RenderSpec = this.makeRenderSpec();
    if (this.strokeSession === null) {
      this.strokeSession = new StrokeSession(spec);
    }
    this.pointerStream.begin(touch.id);
    const batches: PointerInputBatches = this.pointerStream.append(
      this.collectPointerSamples(event, touch));
    const startTime: number = this.firstBatchTimestamp(batches, event.timestamp);
    // T-040 审核修复：传入当前 zoom（拟合容差按屏幕空间计算）
    this.strokeSession.beginStroke(spec, startTime, this.viewport.zoom);
    this.inputProvider.beginStroke(startTime);
    this.predictor.reset();
    this.addPointerBatches(batches);
    this.addPredictionPreview(event, touch);
    this.scheduleShapeDetection();
    this.isDrawing = true;
    this.renderFrame();
  }

  private onTouchMove(event: TouchEvent): void {
    if (!this.isDrawing) {
      return;
    }
    // T-034：双指手势接管
    if (event.touches.length > 1) {
      this.cancelActiveInteraction();
      return;
    }
    const touch: TouchObject | null = this.findTouchById(event.touches, this.activePointerId);
    if (touch === null) {
      this.cancelActiveInteraction();
      return;
    }
    if (this.eraserActive) {
      this.collectEraserPoint(touch);
      return;
    }
    if (this.selectionDrawing) {
      const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
      this.selectionTool.updateSelection(p);
      return;
    }
    if (this.selectionDrag) {
      const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
      const dx: number = p.x - this.lastDragPoint.x;
      const dy: number = p.y - this.lastDragPoint.y;
      this.lastDragPoint = { x: p.x, y: p.y };
      this.selectionTool.moveSelected(dx, dy);
      this.applySelectionTransform(false, false);  // 移动中不 push undo（结束时统一 push）
      return;
    }
    const batches: PointerInputBatches = this.pointerStream.append(
      this.collectPointerSamples(event, touch));
    if (this.strokeSession !== null) {
      this.addPointerBatches(batches);
      this.addPredictionPreview(event, touch);
      this.scheduleShapeDetection();
    }
    this.renderFrame();
  }

  private onTouchUp(event: TouchEvent): void {
    if (!this.isDrawing) {
      return;
    }
    if (event.touches.length > 0) {
      this.cancelActiveInteraction();
      return;
    }
    const finalTouch: TouchObject | null = this.findTouchById(
      event.changedTouches, this.activePointerId);
    if (finalTouch !== null) {
      if (this.eraserActive) {
        this.collectEraserPoint(finalTouch);
      } else if (this.selectionDrawing) {
        const p: Point2D = this.viewport.screenToCanvas(finalTouch.x, finalTouch.y);
        this.selectionTool.updateSelection(p);
      } else if (this.selectionDrag) {
        const p: Point2D = this.viewport.screenToCanvas(finalTouch.x, finalTouch.y);
        const dx: number = p.x - this.lastDragPoint.x;
        const dy: number = p.y - this.lastDragPoint.y;
        this.lastDragPoint = { x: p.x, y: p.y };
        this.selectionTool.moveSelected(dx, dy);
        this.applySelectionTransform(false, false);
      } else if (this.strokeSession !== null && this.strokeSession.isActive()) {
        const batches: PointerInputBatches = this.pointerStream.append(
          this.collectPointerSamples(event, finalTouch));
        this.addPointerBatches(batches);
      }
    }
    this.cancelShapeDetectionTimer();
    if (this.eraserActive) {
      this.applyEraser();
      this.eraserActive = false;
      this.eraserPath = [];
    } else if (this.selectionDrawing) {
      const ids: string[] = this.selectionTool.finalizeSelection(
        this.completedStrokes, this.shapes, this.textBlocks, this.imageBlocks);
      this.selectionDrawing = false;
      hilog.info(0x0001, 'NoteCanvasView', 'selection finalized, ids=%{public}d strokes=%{public}d',
        ids.length, this.completedStrokes.length);
      if (ids.length > 0) {
        this.updateSelectionOverlay();
      } else {
        this.selectionVisible = false;
      }
    } else if (this.selectionDrag) {
      this.selectionDrag = false;
      const selectedStrokeIds: string[] = this.selectionTool.getState().selectedStrokeIds.slice();
      const selectedShapeIds: string[] = this.selectionTool.getState().selectedShapeIds.slice();
      const selectedTextBlockIds: string[] = this.selectionTool.getState().selectedTextBlockIds.slice();
      const selectedImageIds: string[] = this.selectionTool.getState().selectedImageIds.slice();
      if (!this.isIdentityTransform(this.selectionTool.getState().transform)) {
        this.undoRedo.push({
          type: UndoableActionType.TRANSFORM_ELEMENTS,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          beforeStrokes: this.filterStrokesByIds(this.dragBeforeStrokes, selectedStrokeIds),
          afterStrokes: this.filterStrokesByIds(this.completedStrokes, selectedStrokeIds),
          beforeShapes: this.filterShapesByIds(this.dragBeforeShapes, selectedShapeIds),
          afterShapes: this.filterShapesByIds(this.shapes, selectedShapeIds),
          beforeTextBlocks: this.filterTextBlocksByIds(this.dragBeforeTextBlocks, selectedTextBlockIds),
          afterTextBlocks: this.filterTextBlocksByIds(this.textBlocks, selectedTextBlockIds),
          beforeImages: this.filterImagesByIds(this.dragBeforeImages, selectedImageIds),
          afterImages: this.filterImagesByIds(this.imageBlocks, selectedImageIds),
        });
        this.persist();
        this.notifyUndoRedo();
      }
      this.selectionTool.selectElementIds(
        selectedStrokeIds, selectedShapeIds, selectedTextBlockIds, selectedImageIds);
    } else if (this.strokeSession !== null && this.strokeSession.isActive()) {
      const stroke: StrokeElementData = this.strokeSession.finishStroke();
      hilog.info(0x0001, 'NoteCanvasView', 'stroke finished, pts=%{public}d', stroke.pathPoints.length);
      // 只有落笔后静止按住达到阈值，计时器才会提供形状候选。
      const finalShapes: ShapeElement[] = this.heldShapes;
      this.heldShapes = [];
      const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
      if (finalShapes.length > 0) {
        this.shapes = this.shapes.concat(finalShapes);
        const shapeIds: string[] = finalShapes.map((shape: ShapeElement): string => shape.id);
        this.elementOrder = appendPageElementRefs(
          this.elementOrder, PageElementKind.SHAPE, shapeIds);
        const addedElementOrder: PageElementRef[] = appendPageElementRefs(
          [], PageElementKind.SHAPE, shapeIds);
        this.undoRedo.push({
          type: UndoableActionType.ADD_ELEMENTS,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          addedStrokes: [],
          addedShapes: finalShapes,
          addedTextBlocks: [],
          addedImages: [],
          addedElementOrder: addedElementOrder,
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(this.elementOrder),
        });
      } else {
        this.completedStrokes.push(stroke);
        this.elementOrder = appendPageElementRefs(
          this.elementOrder, PageElementKind.STROKE, [stroke.id]);
        this.undoRedo.push({
          type: UndoableActionType.ADD_STROKE,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          addedStrokes: [stroke],
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(this.elementOrder),
        });
        this.layerManager.commitStroke(stroke, this.renderCtx, this.viewport.zoom);
      }
      hilog.info(0x0001, 'NoteCanvasView', 'pushed drawing element, canUndo=%{public}s',
        this.undoRedo.canUndo().toString());
      this.persist();
      this.notifyUndoRedo();
      hilog.info(0x0001, 'NoteCanvasView', 'after notify, canUndo=%{public}s',
        this.undoRedo.canUndo().toString());
    }
    this.isDrawing = false;
    this.resetPointerTracking();
    this.renderFrame();
  }

  private cancelActiveInteraction(): void {
    if (!this.isDrawing) {
      this.resetPointerTracking();
      return;
    }
    this.cancelShapeDetectionTimer();
    this.heldShapes = [];
    if (this.strokeSession !== null && this.strokeSession.isActive()) {
      this.strokeSession.cancelStroke();
    }
    if (this.selectionDrag) {
      this.completedStrokes = this.dragBeforeStrokes.slice();
      this.shapes = this.dragBeforeShapes.slice();
      this.textBlocks = this.dragBeforeTextBlocks.slice();
      this.imageBlocks = this.dragBeforeImages.slice();
      if (this.layerManager.isInitialized()) {
        this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
      }
    }
    if (this.selectionDrawing || this.selectionDrag) {
      this.selectionTool.deselect();
      this.selectionVisible = false;
    }
    this.eraserActive = false;
    this.eraserPath = [];
    this.selectionDrawing = false;
    this.selectionDrag = false;
    this.dragBeforeStrokes = [];
    this.dragBeforeShapes = [];
    this.dragBeforeTextBlocks = [];
    this.dragBeforeImages = [];
    this.isDrawing = false;
    this.resetPointerTracking();
    this.renderFrame();
  }

  // === 形状识别 ===
  private scheduleShapeDetection(): void {
    this.cancelShapeDetectionTimer();
    this.heldShapes = [];
    const tool: ToolType = this.viewModel.currentTool;
    const drawingTool: boolean = tool === ToolType.PEN || tool === ToolType.PENCIL || tool === ToolType.HIGHLIGHTER;
    if (!drawingTool || !this.viewModel.shapeDetectionEnabled) {
      return;
    }
    const holdDelay: number = Number.isFinite(this.shapeHoldDelayMs) && this.shapeHoldDelayMs >= 0
      ? this.shapeHoldDelayMs : 500;
    this.shapeHoldTimer = setTimeout(() => {
      if (!this.isDrawing || this.strokeSession === null || !this.strokeSession.isActive()) {
        return;
      }
      const current: StrokeElementData | null = this.strokeSession.getCurrentRealStroke();
      if (current === null) {
        return;
      }
      const attempt: ShapeDetectionAttempt = this.tryShapeDetect(current);
      this.heldShapes = attempt.replaced ? attempt.shapes : [];
      if (attempt.replaced) {
        this.renderFrame();
      }
    }, holdDelay);
  }

  private cancelShapeDetectionTimer(): void {
    if (this.shapeHoldTimer !== -1) {
      clearTimeout(this.shapeHoldTimer);
      this.shapeHoldTimer = -1;
    }
  }

  private tryShapeDetect(stroke: StrokeElementData): ShapeDetectionAttempt {
    const pts: Point2D[] = [];
    for (const p of stroke.pathPoints) {
      pts.push(p.position);
    }
    const result = this.shapeDetector.recognizeShape(pts);
    if (result === null || result.elements.length === 0) {
      hilog.info(0x0001, 'NoteCanvasView', 'shape detect: no match, pts=%{public}d', pts.length);
      return { shapes: [], replaced: false };
    }
    hilog.info(0x0001, 'NoteCanvasView', 'shape detect: match confidence=%{public}f', result.confidence);
    const shapes: ShapeElement[] = prepareRecognizedShapes(
      result.elements, stroke.id, stroke.renderSpec.color, stroke.renderSpec.brushWidth);
    return { shapes: shapes, replaced: shapes.length > 0 };
  }

  // 识别元素 → 形状笔画（采样点序列，保持渲染链不变）
  // === 橡皮擦 ===
  private applyEraser(): void {
    if (this.eraserPath.length === 0) {
      return;
    }
    const before: StrokeElementData[] = this.completedStrokes.slice();
    const beforeShapes: ShapeElement[] = this.shapes.slice();
    const beforeTextBlocks: TextBlockElement[] = this.textBlocks.slice();
    const beforeImages: ImageElement[] = this.imageBlocks.slice();
    const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const result = this.eraserEngine.erase(this.eraserPath, this.completedStrokes);
    for (const id of result.deletedStrokeIds) {
      const remaining: StrokeElementData[] = [];
      for (const s of this.completedStrokes) {
        if (s.id !== id) {
          remaining.push(s);
        }
      }
      this.completedStrokes = remaining;
    }
    for (const updated of result.affectedStrokes) {
      for (let i = 0; i < this.completedStrokes.length; i++) {
        if (this.completedStrokes[i].id === updated.id) {
          this.completedStrokes[i] = updated;
          break;
        }
      }
    }
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.STROKE, result.deletedStrokeIds);
    // 记录 undo（擦除）
    const removed: StrokeElementData[] = [];
    const removedIndices: number[] = [];
    for (let beforeIndex: number = 0; beforeIndex < before.length; beforeIndex++) {
      const s: StrokeElementData = before[beforeIndex];
      let stillThere: boolean = false;
      for (const cur of this.completedStrokes) {
        if (cur.id === s.id) {
          stillThere = true;
          break;
        }
      }
      if (!stillThere) {
        removed.push(s);
        removedIndices.push(beforeIndex);
      }
    }
    // T-040 审核修复：PARTIAL 擦除（maskPath 挖洞）也需入栈可撤销
    // （before=受影响笔画擦除前快照，after=擦除后快照；undo 恢复原笔画，redo 重新挖洞）
    const removedShapes: ShapeElement[] = [];
    const removedShapeIndices: number[] = [];
    for (let shapeIndex: number = 0; shapeIndex < beforeShapes.length; shapeIndex++) {
      const shape: ShapeElement = beforeShapes[shapeIndex];
      if (eraserPathHitsShape(this.eraserPath, shape, this.eraserEngine.getWidth())) {
        removedShapes.push(shape);
        removedShapeIndices.push(shapeIndex);
        this.removeShapeById(shape.id);
      }
    }
    const removedShapeIds: string[] = removedShapes.map((shape: ShapeElement): string => shape.id);
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.SHAPE, removedShapeIds);
    const removedTextBlocks: TextBlockElement[] = [];
    const removedTextBlockIndices: number[] = [];
    for (let textIndex: number = 0; textIndex < beforeTextBlocks.length; textIndex++) {
      const textBlock: TextBlockElement = beforeTextBlocks[textIndex];
      if (eraserPathHitsTextBlock(this.eraserPath, textBlock, this.eraserEngine.getWidth())) {
        removedTextBlocks.push(textBlock);
        removedTextBlockIndices.push(textIndex);
        this.removeTextBlockById(textBlock.id);
      }
    }
    const removedTextIds: string[] = removedTextBlocks.map(
      (textBlock: TextBlockElement): string => textBlock.id);
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.TEXT, removedTextIds);
    const removedImages: ImageElement[] = [];
    const removedImageIndices: number[] = [];
    for (let imageIndex: number = 0; imageIndex < beforeImages.length; imageIndex++) {
      const image: ImageElement = beforeImages[imageIndex];
      if (eraserPathHitsImageBlock(this.eraserPath, image, this.eraserEngine.getWidth())) {
        removedImages.push(image);
        removedImageIndices.push(imageIndex);
        this.removeImageById(image.id);
      }
    }
    const removedImageIds: string[] = removedImages.map((image: ImageElement): string => image.id);
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.IMAGE, removedImageIds);
    const partialBefore: StrokeElementData[] = [];
    const partialAfter: StrokeElementData[] = [];
    for (const updated of result.affectedStrokes) {
      for (const s of before) {
        if (s.id === updated.id) {
          partialBefore.push(s);
          partialAfter.push(updated);
          break;
        }
      }
    }
    if (partialBefore.length > 0 || removed.length > 0 || removedShapes.length > 0 ||
      removedTextBlocks.length > 0 || removedImages.length > 0) {
      this.undoRedo.push({
        type: UndoableActionType.ERASE_ELEMENTS,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        removedStrokes: removed,
        removedStrokeIndices: removedIndices,
        beforeModifiedStrokes: partialBefore,
        afterModifiedStrokes: partialAfter,
        removedShapes: removedShapes,
        removedShapeIndices: removedShapeIndices,
        removedTextBlocks: removedTextBlocks,
        removedTextBlockIndices: removedTextBlockIndices,
        removedImages: removedImages,
        removedImageIndices: removedImageIndices,
        elementOrderBefore: elementOrderBefore,
        elementOrderAfter: clonePageElementOrder(this.elementOrder),
      });
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.notifyUndoRedo();
    if (removedImages.length > 0) {
      this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
    }
  }

  private collectEraserPoint(touch: TouchObject): void {
    const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
    this.eraserPath.push({
      x: Math.min(Math.max(p.x, 0), this.getPaperWidth()),
      y: Math.min(Math.max(p.y, 0), this.getPaperHeight()),
    });
  }

  // === Undo / Redo ===
  private undoStroke(): void {
    hilog.info(0x0001, 'NoteCanvasView', 'undoStroke called, canUndo=%{public}s',
      this.undoRedo.canUndo().toString());
    this.performHistory(true);
  }

  private redoStroke(): void {
    this.performHistory(false);
  }

  private performHistory(isUndo: boolean): void {
    if (this.historyBusy || this.pendingHistoryDirection !== 0) {
      return;
    }
    const group: HistoryMove[] = isUndo ? this.undoRedo.peekUndoGroup() : this.undoRedo.peekRedoGroup();
    if (group.length === 0) {
      hilog.info(0x0001, 'NoteCanvasView', 'history: no action');
      return;
    }
    const action: UndoableAction = group[0].action;
    if (action.noteId !== this.noteId) {
      hilog.error(0x0001, 'NoteCanvasView',
        'history note mismatch, actionNote=%{public}s currentNote=%{public}s', action.noteId, this.noteId);
      return;
    }
    if (group.length > 1 && this.isSinglePageElementGroup(group)) {
      if (action.pageId !== this.loadedPageId) {
        this.pendingHistoryDirection = isUndo ? -1 : 1;
        this.onRequestPage(action.pageId);
        return;
      }
      this.historyBusy = true;
      this.applyElementHistoryGroup(group, isUndo).finally(() => {
        this.historyBusy = false;
      });
      return;
    }
    if (this.isPageAction(action.type)) {
      const history: HistoryMetadata | null = this.undoRedo.getHistoryMetadataForMove(action, isUndo);
      if (history === null) {
        hilog.error(0x0001, 'NoteCanvasView', 'page history metadata is stale');
        return;
      }
      this.historyBusy = true;
      this.onApplyPageHistory(action, isUndo, history).then((applied: boolean) => {
        if (applied) {
          this.commitHistory(action, isUndo);
        } else {
          hilog.error(0x0001, 'NoteCanvasView', 'page history apply rejected, type=%{public}d', action.type);
        }
        this.historyBusy = false;
      }).catch((e: Object) => {
        hilog.error(0x0001, 'NoteCanvasView', 'page history apply failed: %{public}s', JSON.stringify(e));
        this.historyBusy = false;
      });
      return;
    }
    if (action.pageId !== this.loadedPageId) {
      this.pendingHistoryDirection = isUndo ? -1 : 1;
      this.onRequestPage(action.pageId);
      return;
    }
    if (this.applyAction(action, isUndo)) {
      this.commitHistory(action, isUndo);
    }
  }

  private preparePageHistory(action: UndoableAction): HistoryMetadata {
    if (this.historyBusy) {
      throw new Error('page history cannot start during an active history command');
    }
    return this.undoRedo.prepareHistoryMetadata(action);
  }

  private isSinglePageElementGroup(group: HistoryMove[]): boolean {
    if (group.length === 0 || this.isPageAction(group[0].action.type)) {
      return false;
    }
    const pageId: string = group[0].action.pageId;
    for (const move of group) {
      if (move.action.noteId !== this.noteId || move.action.pageId !== pageId ||
        this.isPageAction(move.action.type)) {
        return false;
      }
    }
    return true;
  }

  private async applyElementHistoryGroup(group: HistoryMove[], isUndo: boolean): Promise<void> {
    const rollbackElements: SearchSourceElement[] = this.currentMutationElements();
    const touchesImages: boolean = group.some(
      (move: HistoryMove): boolean => this.actionTouchesImages(move.action));
    try {
      await this.persistence.flush(this.noteId, this.loadedPageId);
      const initial: HistoryPageSnapshot = this.captureHistoryPageSnapshot();
      const steps: HistoryPageSnapshot[] = [];
      for (const move of group) {
        if (!this.applyAction(move.action, isUndo, false)) {
          this.restoreHistoryPage(rollbackElements);
          if (touchesImages) {
            this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
          }
          hilog.error(0x0001, 'NoteCanvasView',
            'history group source state mismatch, type=%{public}d', move.action.type);
          return;
        }
        steps.push(this.captureHistoryPageSnapshot(move.history));
      }
      await this.persistence.saveHistoryGroup(this.noteId, this.loadedPageId, initial, steps);
      const committed: boolean = isUndo
        ? this.undoRedo.commitUndoGroup(group) : this.undoRedo.commitRedoGroup(group);
      if (!committed) {
        throw new Error('history group stack changed after durable apply');
      }
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.notifyUndoRedo();
      if (touchesImages) {
        this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
      }
    } catch (e) {
      this.restoreHistoryPage(rollbackElements);
      if (touchesImages) {
        this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
      }
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView', 'history group apply failed: %{public}s', JSON.stringify(e));
    }
  }

  private captureHistoryPageSnapshot(history?: HistoryMetadata): HistoryPageSnapshot {
    return {
      strokes: this.completedStrokes.slice(),
      textBlocks: this.textBlocks.slice(),
      elementOrder: clonePageElementOrder(this.elementOrder),
      shapes: this.shapes.slice(),
      images: this.imageBlocks.map((image: ImageElement): ImageElement => cloneImageElement(image)),
      history: history,
    };
  }

  private restoreHistoryPage(elements: SearchSourceElement[]): void {
    this.installMutationElements(elements);
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.renderFrame();
  }

  private commitHistory(action: UndoableAction, isUndo: boolean): void {
    const committed: boolean = isUndo
      ? this.undoRedo.commitUndo(action) : this.undoRedo.commitRedo(action);
    if (!committed) {
      hilog.error(0x0001, 'NoteCanvasView', 'history commit rejected after apply, type=%{public}d', action.type);
    } else if (!this.isPageAction(action.type)) {
      this.persist();
    }
    this.notifyUndoRedo();
  }

  private resumePendingHistory(): void {
    if (this.pendingHistoryDirection === 0) {
      return;
    }
    const isUndo: boolean = this.pendingHistoryDirection < 0;
    this.pendingHistoryDirection = 0;
    this.performHistory(isUndo);
  }

  private isPageAction(type: UndoableActionType): boolean {
    return type === UndoableActionType.ADD_PAGE || type === UndoableActionType.DELETE_PAGE ||
      type === UndoableActionType.REORDER_PAGES || type === UndoableActionType.PAGE_SETTINGS;
  }

  // isUndo=true 执行反向；false 执行正向
  private applyAction(action: UndoableAction, isUndo: boolean, refreshImages: boolean = true): boolean {
    if (!this.validateActionState(action, isUndo)) {
      hilog.error(0x0001, 'NoteCanvasView',
        'history source state mismatch, type=%{public}d undo=%{public}s', action.type, isUndo.toString());
      return false;
    }
    this.selectionTool.deselect();
    this.selectionVisible = false;
    if (action.type === UndoableActionType.ADD_STROKE) {
      const added: StrokeElementData[] = action.addedStrokes;
      if (added.length === 0) {
        hilog.error(0x0001, 'NoteCanvasView', 'ADD_STROKE history has no strokes');
        return false;
      }
      if (isUndo) {
        for (const stroke of added) {
          this.removeStrokeById(stroke.id);
        }
      } else {
        for (const stroke of added) {
          this.completedStrokes.push(stroke);
        }
      }
    } else if (action.type === UndoableActionType.ERASE_ELEMENTS) {
      if (isUndo) {
        this.restoreRemovedStrokes(action.removedStrokes, action.removedStrokeIndices);
        this.restoreRemovedShapes(action.removedShapes, action.removedShapeIndices);
        this.restoreRemovedTextBlocks(action.removedTextBlocks, action.removedTextBlockIndices);
        this.restoreRemovedImages(action.removedImages, action.removedImageIndices);
        this.replaceStrokesById(action.beforeModifiedStrokes);
      } else {
        for (const s of action.removedStrokes) {
          this.removeStrokeById(s.id);
        }
        for (const shape of action.removedShapes) {
          this.removeShapeById(shape.id);
        }
        for (const textBlock of action.removedTextBlocks) {
          this.removeTextBlockById(textBlock.id);
        }
        for (const image of action.removedImages) {
          this.removeImageById(image.id);
        }
        this.replaceStrokesById(action.afterModifiedStrokes);
      }
    } else if (action.type === UndoableActionType.DELETE_STROKE) {
      if (isUndo) {
        this.restoreRemovedStrokes(action.removedStrokes, action.removedStrokeIndices);
      } else {
        for (const s of action.removedStrokes) {
          this.removeStrokeById(s.id);
        }
      }
    } else if (action.type === UndoableActionType.TRANSFORM_STROKES) {
      // T-040 审核修复：按 id 替换（before/after 可为选中笔画子集快照，避免整表替换丢失其他笔画）
      const target: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      for (const t of target) {
        for (let i = 0; i < this.completedStrokes.length; i++) {
          if (this.completedStrokes[i].id === t.id) {
            this.completedStrokes[i] = t;
            break;
          }
        }
      }
    } else if (action.type === UndoableActionType.ADD_ELEMENT) {
      // T-036：文本框创建
      if (isUndo) {
        this.removeTextBlockById(action.addedElement.id);
      } else {
        this.textBlocks.push(action.addedElement);
      }
    } else if (action.type === UndoableActionType.DELETE_ELEMENT) {
      // T-036：文本框删除
      if (isUndo) {
        for (const t of action.removedElements) {
          this.textBlocks.push(t);
        }
      } else {
        for (const t of action.removedElements) {
          this.removeTextBlockById(t.id);
        }
      }
    } else if (action.type === UndoableActionType.REPLACE_ELEMENT) {
      const targetElements: TextBlockElement[] = isUndo ? action.beforeElements : action.afterElements;
      for (const element of targetElements) {
        for (let i: number = 0; i < this.textBlocks.length; i++) {
          if (this.textBlocks[i].id === element.id) {
            this.textBlocks[i] = element;
            break;
          }
        }
      }
      const targetStrokes: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      for (const stroke of targetStrokes) {
        for (let i: number = 0; i < this.completedStrokes.length; i++) {
          if (this.completedStrokes[i].id === stroke.id) {
            this.completedStrokes[i] = stroke;
            break;
          }
        }
      }
    } else if (action.type === UndoableActionType.REORDER_ELEMENTS) {
      // Element order is applied atomically below after the source state has been validated.
    } else if (action.type === UndoableActionType.ADD_SHAPE) {
      if (isUndo) {
        this.removeShapeById(action.addedShape.id);
      } else {
        this.shapes.push(action.addedShape);
      }
    } else if (action.type === UndoableActionType.ADD_ELEMENTS) {
      if (isUndo) {
        for (const stroke of action.addedStrokes) {
          this.removeStrokeById(stroke.id);
        }
        for (const shape of action.addedShapes) {
          this.removeShapeById(shape.id);
        }
        for (const textBlock of action.addedTextBlocks) {
          this.removeTextBlockById(textBlock.id);
        }
        for (const image of action.addedImages) {
          this.removeImageById(image.id);
        }
      } else {
        this.completedStrokes = this.completedStrokes.concat(action.addedStrokes);
        this.shapes = this.shapes.concat(action.addedShapes);
        this.textBlocks = this.textBlocks.concat(action.addedTextBlocks);
        this.imageBlocks = this.imageBlocks.concat(action.addedImages);
      }
    } else if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      if (isUndo) {
        this.restoreRemovedStrokes(action.removedStrokes, action.removedStrokeIndices);
        this.restoreRemovedShapes(action.removedShapes, action.removedShapeIndices);
        this.restoreRemovedTextBlocks(action.removedTextBlocks, action.removedTextBlockIndices);
        this.restoreRemovedImages(action.removedImages, action.removedImageIndices);
      } else {
        for (const stroke of action.removedStrokes) {
          this.removeStrokeById(stroke.id);
        }
        for (const shape of action.removedShapes) {
          this.removeShapeById(shape.id);
        }
        for (const textBlock of action.removedTextBlocks) {
          this.removeTextBlockById(textBlock.id);
        }
        for (const image of action.removedImages) {
          this.removeImageById(image.id);
        }
      }
    } else if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
      this.replaceStrokesById(isUndo ? action.beforeStrokes : action.afterStrokes);
      this.replaceShapesById(isUndo ? action.beforeShapes : action.afterShapes);
      this.replaceTextBlocksById(isUndo ? action.beforeTextBlocks : action.afterTextBlocks);
      this.replaceImagesById(isUndo ? action.beforeImages : action.afterImages);
    } else if (action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS) {
      if (!this.applyPersistedPageMutations(action.operations, isUndo)) {
        return false;
      }
    } else {
      hilog.error(0x0001, 'NoteCanvasView', 'unsupported history action type=%{public}d', action.type);
      return false;
    }
    const targetOrder: PageElementRef[] | null = this.getActionTargetOrder(action, isUndo);
    if (targetOrder !== null) {
      this.elementOrder = clonePageElementOrder(targetOrder);
      this.synchronizeElementArraysByOrder();
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.renderFrame();
    if (refreshImages && this.actionTouchesImages(action)) {
      this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
    }
    return true;
  }

  private validateActionState(action: UndoableAction, isUndo: boolean): boolean {
    if (action.noteId !== this.noteId || action.pageId !== this.loadedPageId) {
      return false;
    }
    if (!this.validateElementOrderAction(action, isUndo)) {
      return false;
    }
    if (action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS) {
      return action.operations.length > 0;
    }
    if (action.type === UndoableActionType.ADD_STROKE) {
      return action.addedStrokes.length > 0 && this.hasUniqueStrokeIds(action.addedStrokes) &&
        (isUndo ? this.allStrokeIdsPresent(action.addedStrokes) : this.allStrokeIdsAbsent(action.addedStrokes));
    }
    if (action.type === UndoableActionType.DELETE_STROKE) {
      if (action.removedStrokes.length === 0 || !this.hasUniqueStrokeIds(action.removedStrokes)) {
        return false;
      }
      if (!isUndo) {
        return this.allStrokeIdsPresent(action.removedStrokes);
      }
      if (!this.allStrokeIdsAbsent(action.removedStrokes) ||
        action.removedStrokeIndices.length !== action.removedStrokes.length) {
        return false;
      }
      let previous: number = -1;
      for (let i: number = 0; i < action.removedStrokeIndices.length; i++) {
        const index: number = action.removedStrokeIndices[i];
        if (!Number.isInteger(index) || index < previous || index < 0 || index > this.completedStrokes.length + i) {
          return false;
        }
        previous = index;
      }
      return true;
    }
    if (action.type === UndoableActionType.ERASE_ELEMENTS) {
      const hasChange: boolean = action.removedStrokes.length > 0 ||
        action.beforeModifiedStrokes.length > 0 || action.removedShapes.length > 0 ||
        action.removedTextBlocks.length > 0 || action.removedImages.length > 0;
      const sourceModified: StrokeElementData[] = isUndo
        ? action.afterModifiedStrokes : action.beforeModifiedStrokes;
      if (!hasChange || !this.hasUniqueStrokeIds(action.removedStrokes) ||
        !this.sameStrokeIds(action.beforeModifiedStrokes, action.afterModifiedStrokes) ||
        !this.hasUniqueShapeIds(action.removedShapes) ||
        !this.hasUniqueTextBlockIds(action.removedTextBlocks) ||
        !this.hasUniqueImageIds(action.removedImages) || !this.allStrokeIdsPresent(sourceModified)) {
        return false;
      }
      if (!isUndo) {
        return this.allStrokeIdsPresent(action.removedStrokes) &&
          this.allShapeIdsPresent(action.removedShapes) &&
          this.allTextBlockIdsPresent(action.removedTextBlocks) &&
          this.allImageIdsPresent(action.removedImages);
      }
      return this.validateRemovedStrokeIndices(action.removedStrokes, action.removedStrokeIndices) &&
        this.validateRemovedShapeIndices(action.removedShapes, action.removedShapeIndices) &&
        this.validateRemovedTextBlockIndices(action.removedTextBlocks, action.removedTextBlockIndices) &&
        this.validateRemovedImageIndices(action.removedImages, action.removedImageIndices);
    }
    if (action.type === UndoableActionType.TRANSFORM_STROKES) {
      const source: StrokeElementData[] = isUndo ? action.afterStrokes : action.beforeStrokes;
      const target: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      return source.length > 0 && this.sameStrokeIds(source, target) && this.allStrokeIdsPresent(source);
    }
    if (action.type === UndoableActionType.ADD_ELEMENT) {
      return isUndo ? this.countTextBlockId(action.addedElement.id) === 1 :
        this.countTextBlockId(action.addedElement.id) === 0;
    }
    if (action.type === UndoableActionType.DELETE_ELEMENT) {
      return action.removedElements.length > 0 && this.hasUniqueTextBlockIds(action.removedElements) &&
        (isUndo ? this.allTextBlockIdsAbsent(action.removedElements) :
          this.allTextBlockIdsPresent(action.removedElements));
    }
    if (action.type === UndoableActionType.REPLACE_ELEMENT) {
      const sourceStrokes: StrokeElementData[] = isUndo ? action.afterStrokes : action.beforeStrokes;
      const targetStrokes: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      const sourceElements: TextBlockElement[] = isUndo ? action.afterElements : action.beforeElements;
      const targetElements: TextBlockElement[] = isUndo ? action.beforeElements : action.afterElements;
      const hasReplacement: boolean = sourceStrokes.length > 0 || sourceElements.length > 0;
      return hasReplacement && this.sameStrokeIds(sourceStrokes, targetStrokes) &&
        this.sameTextBlockIds(sourceElements, targetElements) && this.allStrokeIdsPresent(sourceStrokes) &&
        this.allTextBlockIdsPresent(sourceElements);
    }
    if (action.type === UndoableActionType.REORDER_ELEMENTS) {
      return samePageElementMembers(action.elementOrderBefore, action.elementOrderAfter);
    }
    if (action.type === UndoableActionType.ADD_SHAPE) {
      return isUndo ? this.countShapeId(action.addedShape.id) === 1 :
        this.countShapeId(action.addedShape.id) === 0;
    }
    if (action.type === UndoableActionType.ADD_ELEMENTS) {
      const hasAdded: boolean = action.addedStrokes.length > 0 || action.addedShapes.length > 0 ||
        action.addedTextBlocks.length > 0 || action.addedImages.length > 0;
      if (!hasAdded || !this.hasUniqueStrokeIds(action.addedStrokes) ||
        !this.hasUniqueShapeIds(action.addedShapes) || !this.hasUniqueTextBlockIds(action.addedTextBlocks) ||
        !this.hasUniqueImageIds(action.addedImages) ||
        !this.sameAddedElementRefs(
          action.addedStrokes, action.addedShapes, action.addedTextBlocks, action.addedImages,
          action.addedElementOrder)) {
        return false;
      }
      return isUndo
        ? this.allStrokeIdsPresent(action.addedStrokes) && this.allShapeIdsPresent(action.addedShapes) &&
          this.allTextBlockIdsPresent(action.addedTextBlocks)
          && this.allImageIdsPresent(action.addedImages)
        : this.allPageElementIdsAbsent(
          action.addedStrokes, action.addedShapes, action.addedTextBlocks, action.addedImages);
    }
    if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      const hasRemoved: boolean = action.removedStrokes.length > 0 || action.removedShapes.length > 0 ||
        action.removedTextBlocks.length > 0 || action.removedImages.length > 0;
      if (!hasRemoved || !this.hasUniqueStrokeIds(action.removedStrokes) ||
        !this.hasUniqueShapeIds(action.removedShapes) ||
        !this.hasUniqueTextBlockIds(action.removedTextBlocks) ||
        !this.hasUniqueImageIds(action.removedImages)) {
        return false;
      }
      if (!isUndo) {
        return this.allStrokeIdsPresent(action.removedStrokes) &&
          this.allShapeIdsPresent(action.removedShapes) &&
          this.allTextBlockIdsPresent(action.removedTextBlocks) &&
          this.allImageIdsPresent(action.removedImages);
      }
      return this.validateRemovedStrokeIndices(action.removedStrokes, action.removedStrokeIndices) &&
        this.validateRemovedShapeIndices(action.removedShapes, action.removedShapeIndices) &&
        this.validateRemovedTextBlockIndices(action.removedTextBlocks, action.removedTextBlockIndices) &&
        this.validateRemovedImageIndices(action.removedImages, action.removedImageIndices);
    }
    if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
      const sourceStrokes: StrokeElementData[] = isUndo ? action.afterStrokes : action.beforeStrokes;
      const sourceShapes: ShapeElement[] = isUndo ? action.afterShapes : action.beforeShapes;
      const sourceTextBlocks: TextBlockElement[] = isUndo ? action.afterTextBlocks : action.beforeTextBlocks;
      const sourceImages: ImageElement[] = isUndo ? action.afterImages : action.beforeImages;
      const hasTransform: boolean = sourceStrokes.length > 0 || sourceShapes.length > 0 ||
        sourceTextBlocks.length > 0 || sourceImages.length > 0;
      return hasTransform && this.sameStrokeIds(action.beforeStrokes, action.afterStrokes) &&
        this.sameShapeIds(action.beforeShapes, action.afterShapes) &&
        this.sameTextBlockIds(action.beforeTextBlocks, action.afterTextBlocks) &&
        this.sameImageIds(action.beforeImages, action.afterImages) &&
        this.allStrokeIdsPresent(sourceStrokes) && this.allShapeIdsPresent(sourceShapes) &&
        this.allTextBlockIdsPresent(sourceTextBlocks) && this.allImageIdsPresent(sourceImages);
    }
    return false;
  }

  private applyPersistedPageMutations(operations: Op[], isUndo: boolean): boolean {
    try {
      const current: SearchSourceElement[] = replayPersistentPageMutations(
        this.currentMutationElements(), operations, isUndo);
      this.installMutationElements(current);
      return true;
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView', 'persisted mutation replay rejected: %{public}s', JSON.stringify(e));
      return false;
    }
  }

  private currentMutationElements(): SearchSourceElement[] {
    const ordered: OrderedPageElement[] = materializePageElements(
      this.elementOrder, this.completedStrokes, this.textBlocks, this.shapes, this.imageBlocks,
      this.mathBlocks);
    const result: SearchSourceElement[] = [];
    for (const element of ordered) {
      const kind: string = element.kind === PageElementKind.STROKE ? 'stroke' :
        (element.kind === PageElementKind.TEXT ? 'text' :
          (element.kind === PageElementKind.SHAPE ? 'shape' :
            (element.kind === PageElementKind.IMAGE ? 'image' : 'math')));
      const persisted: PersistedElement = { kind: kind, data: element.data };
      result.push({ elementId: element.elementId, kind: element.kind,
        payload: encodePersistedElement(persisted) });
    }
    return result;
  }

  private installMutationElements(elements: SearchSourceElement[]): void {
    const strokes: StrokeElementData[] = [];
    const texts: TextBlockElement[] = [];
    const shapes: ShapeElement[] = [];
    const images: ImageElement[] = [];
    const mathBlocks: MathElement[] = [];
    const order: PageElementRef[] = [];
    for (const element of elements) {
      const persisted: PersistedElement = decodePersistedElement(element.payload);
      if (element.kind === PageElementKind.STROKE && persisted.kind === 'stroke') {
        const stroke: StrokeElementData = persisted.data as StrokeElementData;
        strokes.push(stroke);
      } else if (element.kind === PageElementKind.TEXT && persisted.kind === 'text') {
        const text: TextBlockElement = cloneTextBlockElement(persisted.data as TextBlockElement);
        text.bounds = textBlockWorldBounds(text);
        texts.push(text);
      } else if (element.kind === PageElementKind.SHAPE && persisted.kind === 'shape') {
        const shape: ShapeElement = cloneShapeElement(persisted.data as ShapeElement);
        shape.bounds = recomputeShapeBounds(shape);
        shapes.push(shape);
      } else if (element.kind === PageElementKind.IMAGE && persisted.kind === 'image') {
        const image: ImageElement = cloneImageElement(persisted.data as ImageElement);
        image.bounds = imageBlockWorldBounds(image);
        images.push(image);
      } else if (element.kind === PageElementKind.MATH && persisted.kind === 'math') {
        const math: MathElement = cloneMathElement(persisted.data as MathElement);
        math.bounds = mathBlockWorldBounds(math);
        mathBlocks.push(math);
      } else {
        throw new Error('persisted mutation element kind mismatch');
      }
      order.push({ kind: element.kind, elementId: element.elementId, zIndex: order.length });
    }
    this.completedStrokes = strokes;
    this.textBlocks = texts;
    this.shapes = shapes;
    this.imageBlocks = images;
    this.mathBlocks = mathBlocks;
    this.elementOrder = order;
  }

  private validateElementOrderAction(action: UndoableAction, isUndo: boolean): boolean {
    const source: PageElementRef[] | null = this.getActionSourceOrder(action, isUndo);
    if (source === null) {
      return true;
    }
    if (!samePageElementOrder(this.elementOrder, source)) {
      return false;
    }
    if (action.type === UndoableActionType.ADD_STROKE) {
      const ids: string[] = action.addedStrokes.map((stroke: StrokeElementData): string => stroke.id);
      return samePageElementOrder(action.elementOrderAfter,
        appendPageElementRefs(action.elementOrderBefore, PageElementKind.STROKE, ids));
    }
    if (action.type === UndoableActionType.DELETE_STROKE) {
      const ids: string[] = action.removedStrokes.map((stroke: StrokeElementData): string => stroke.id);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(action.elementOrderBefore, PageElementKind.STROKE, ids));
    }
    if (action.type === UndoableActionType.ERASE_ELEMENTS) {
      const strokeIds: string[] = action.removedStrokes.map(
        (stroke: StrokeElementData): string => stroke.id);
      const shapeIds: string[] = action.removedShapes.map((shape: ShapeElement): string => shape.id);
      const textIds: string[] = action.removedTextBlocks.map(
        (textBlock: TextBlockElement): string => textBlock.id);
      const imageIds: string[] = action.removedImages.map((image: ImageElement): string => image.id);
      const withoutStrokes: PageElementRef[] = removePageElementRefs(
        action.elementOrderBefore, PageElementKind.STROKE, strokeIds);
      const withoutShapes: PageElementRef[] = removePageElementRefs(
        withoutStrokes, PageElementKind.SHAPE, shapeIds);
      const withoutTexts: PageElementRef[] = removePageElementRefs(
        withoutShapes, PageElementKind.TEXT, textIds);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(withoutTexts, PageElementKind.IMAGE, imageIds));
    }
    if (action.type === UndoableActionType.ADD_ELEMENT) {
      return samePageElementOrder(action.elementOrderAfter,
        appendPageElementRefs(action.elementOrderBefore, PageElementKind.TEXT, [action.addedElement.id]));
    }
    if (action.type === UndoableActionType.DELETE_ELEMENT) {
      const ids: string[] = action.removedElements.map((element: TextBlockElement): string => element.id);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(action.elementOrderBefore, PageElementKind.TEXT, ids));
    }
    if (action.type === UndoableActionType.ADD_SHAPE) {
      return samePageElementOrder(action.elementOrderAfter,
        appendPageElementRefs(action.elementOrderBefore, PageElementKind.SHAPE, [action.addedShape.id]));
    }
    if (action.type === UndoableActionType.ADD_ELEMENTS) {
      const expected: PageElementRef[] | null = this.appendMixedElementRefs(
        action.elementOrderBefore, action.addedElementOrder);
      return expected !== null && samePageElementOrder(action.elementOrderAfter, expected);
    }
    if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      const strokeIds: string[] = action.removedStrokes.map(
        (stroke: StrokeElementData): string => stroke.id);
      const shapeIds: string[] = action.removedShapes.map((shape: ShapeElement): string => shape.id);
      const textIds: string[] = action.removedTextBlocks.map(
        (textBlock: TextBlockElement): string => textBlock.id);
      const imageIds: string[] = action.removedImages.map((image: ImageElement): string => image.id);
      const withoutStrokes: PageElementRef[] = removePageElementRefs(
        action.elementOrderBefore, PageElementKind.STROKE, strokeIds);
      const withoutShapes: PageElementRef[] = removePageElementRefs(
        withoutStrokes, PageElementKind.SHAPE, shapeIds);
      const withoutTexts: PageElementRef[] = removePageElementRefs(
        withoutShapes, PageElementKind.TEXT, textIds);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(withoutTexts, PageElementKind.IMAGE, imageIds));
    }
    return action.type === UndoableActionType.REORDER_ELEMENTS &&
      samePageElementMembers(action.elementOrderBefore, action.elementOrderAfter);
  }

  private getActionSourceOrder(action: UndoableAction, isUndo: boolean): PageElementRef[] | null {
    if (action.type === UndoableActionType.ADD_STROKE || action.type === UndoableActionType.DELETE_STROKE ||
      action.type === UndoableActionType.ERASE_ELEMENTS || action.type === UndoableActionType.ADD_ELEMENT ||
      action.type === UndoableActionType.DELETE_ELEMENT || action.type === UndoableActionType.REORDER_ELEMENTS ||
      action.type === UndoableActionType.ADD_SHAPE || action.type === UndoableActionType.ADD_ELEMENTS ||
      action.type === UndoableActionType.DELETE_ELEMENTS) {
      return isUndo ? action.elementOrderAfter : action.elementOrderBefore;
    }
    return null;
  }

  private getActionTargetOrder(action: UndoableAction, isUndo: boolean): PageElementRef[] | null {
    if (action.type === UndoableActionType.ADD_STROKE || action.type === UndoableActionType.DELETE_STROKE ||
      action.type === UndoableActionType.ERASE_ELEMENTS || action.type === UndoableActionType.ADD_ELEMENT ||
      action.type === UndoableActionType.DELETE_ELEMENT || action.type === UndoableActionType.REORDER_ELEMENTS ||
      action.type === UndoableActionType.ADD_SHAPE || action.type === UndoableActionType.ADD_ELEMENTS ||
      action.type === UndoableActionType.DELETE_ELEMENTS) {
      return isUndo ? action.elementOrderBefore : action.elementOrderAfter;
    }
    return null;
  }

  private countTextBlockId(id: string): number {
    let count: number = 0;
    for (const element of this.textBlocks) {
      if (element.id === id) {
        count++;
      }
    }
    return count;
  }

  private countShapeId(id: string): number {
    let count: number = 0;
    for (const shape of this.shapes) {
      if (shape.id === id) {
        count++;
      }
    }
    return count;
  }

  private countImageId(id: string): number {
    let count: number = 0;
    for (const image of this.imageBlocks) {
      if (image.id === id) {
        count++;
      }
    }
    return count;
  }

  private hasUniqueStrokeIds(strokes: StrokeElementData[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const stroke of strokes) {
      if (ids.has(stroke.id)) {
        return false;
      }
      ids.add(stroke.id);
    }
    return true;
  }

  private hasUniqueTextBlockIds(elements: TextBlockElement[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const element of elements) {
      if (ids.has(element.id)) {
        return false;
      }
      ids.add(element.id);
    }
    return true;
  }

  private hasUniqueShapeIds(shapes: ShapeElement[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const shape of shapes) {
      if (ids.has(shape.id)) {
        return false;
      }
      ids.add(shape.id);
    }
    return true;
  }

  private hasUniqueImageIds(images: ImageElement[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const image of images) {
      if (ids.has(image.id)) {
        return false;
      }
      ids.add(image.id);
    }
    return true;
  }

  private sameStrokeIds(a: StrokeElementData[], b: StrokeElementData[]): boolean {
    if (a.length !== b.length || !this.hasUniqueStrokeIds(a) || !this.hasUniqueStrokeIds(b)) {
      return false;
    }
    const targetIds: Set<string> = new Set<string>();
    for (const stroke of b) {
      targetIds.add(stroke.id);
    }
    for (const stroke of a) {
      if (!targetIds.has(stroke.id)) {
        return false;
      }
    }
    return true;
  }

  private sameTextBlockIds(a: TextBlockElement[], b: TextBlockElement[]): boolean {
    if (a.length !== b.length || !this.hasUniqueTextBlockIds(a) || !this.hasUniqueTextBlockIds(b)) {
      return false;
    }
    const targetIds: Set<string> = new Set<string>();
    for (const element of b) {
      targetIds.add(element.id);
    }
    for (const element of a) {
      if (!targetIds.has(element.id)) {
        return false;
      }
    }
    return true;
  }

  private sameShapeIds(a: ShapeElement[], b: ShapeElement[]): boolean {
    if (a.length !== b.length || !this.hasUniqueShapeIds(a) || !this.hasUniqueShapeIds(b)) {
      return false;
    }
    const ids: Set<string> = new Set<string>();
    for (const shape of b) {
      ids.add(shape.id);
    }
    for (const shape of a) {
      if (!ids.has(shape.id)) {
        return false;
      }
    }
    return true;
  }

  private sameImageIds(a: ImageElement[], b: ImageElement[]): boolean {
    if (a.length !== b.length || !this.hasUniqueImageIds(a) || !this.hasUniqueImageIds(b)) {
      return false;
    }
    const ids: Set<string> = new Set<string>();
    for (const image of b) {
      ids.add(image.id);
    }
    for (const image of a) {
      if (!ids.has(image.id)) {
        return false;
      }
    }
    return true;
  }

  private filterStrokesByIds(strokes: StrokeElementData[], ids: string[]): StrokeElementData[] {
    const selected: Set<string> = new Set<string>(ids);
    const result: StrokeElementData[] = [];
    for (const stroke of strokes) {
      if (selected.has(stroke.id)) {
        result.push(stroke);
      }
    }
    return result;
  }

  private filterShapesByIds(shapes: ShapeElement[], ids: string[]): ShapeElement[] {
    const selected: Set<string> = new Set<string>(ids);
    const result: ShapeElement[] = [];
    for (const shape of shapes) {
      if (selected.has(shape.id)) {
        result.push(shape);
      }
    }
    return result;
  }

  private filterTextBlocksByIds(textBlocks: TextBlockElement[], ids: string[]): TextBlockElement[] {
    const selected: Set<string> = new Set<string>(ids);
    const result: TextBlockElement[] = [];
    for (const textBlock of textBlocks) {
      if (selected.has(textBlock.id)) {
        result.push(textBlock);
      }
    }
    return result;
  }

  private filterImagesByIds(images: ImageElement[], ids: string[]): ImageElement[] {
    const selected: Set<string> = new Set<string>(ids);
    const result: ImageElement[] = [];
    for (const image of images) {
      if (selected.has(image.id)) {
        result.push(image);
      }
    }
    return result;
  }

  private isIdentityTransform(transform: number[]): boolean {
    const identity: number[] = [1, 0, 0, 0, 1, 0, 0, 0, 1];
    if (transform.length !== identity.length) {
      return false;
    }
    for (let i: number = 0; i < identity.length; i++) {
      if (Math.abs(transform[i] - identity[i]) > 0.0000001) {
        return false;
      }
    }
    return true;
  }

  private sameAddedElementRefs(strokes: StrokeElementData[], shapes: ShapeElement[],
    textBlocks: TextBlockElement[], images: ImageElement[], refs: PageElementRef[]): boolean {
    if (refs.length !== strokes.length + shapes.length + textBlocks.length + images.length) {
      return false;
    }
    const expected: Set<string> = new Set<string>();
    for (const stroke of strokes) {
      expected.add(`${PageElementKind.STROKE}:${stroke.id}`);
    }
    for (const shape of shapes) {
      expected.add(`${PageElementKind.SHAPE}:${shape.id}`);
    }
    for (const textBlock of textBlocks) {
      expected.add(`${PageElementKind.TEXT}:${textBlock.id}`);
    }
    for (const image of images) {
      expected.add(`${PageElementKind.IMAGE}:${image.id}`);
    }
    if (expected.size !== refs.length) {
      return false;
    }
    const actual: Set<string> = new Set<string>();
    for (const ref of refs) {
      if ((ref.kind !== PageElementKind.STROKE && ref.kind !== PageElementKind.SHAPE &&
        ref.kind !== PageElementKind.TEXT && ref.kind !== PageElementKind.IMAGE) ||
        ref.elementId.length === 0 || actual.has(`${ref.kind}:${ref.elementId}`)) {
        return false;
      }
      actual.add(`${ref.kind}:${ref.elementId}`);
    }
    if (actual.size !== expected.size) {
      return false;
    }
    for (const key of expected) {
      if (!actual.has(key)) {
        return false;
      }
    }
    return true;
  }

  private allPageElementIdsAbsent(strokes: StrokeElementData[], shapes: ShapeElement[],
    textBlocks: TextBlockElement[], images: ImageElement[]): boolean {
    const existing: Set<string> = new Set<string>();
    for (const stroke of this.completedStrokes) {
      existing.add(stroke.id);
    }
    for (const shape of this.shapes) {
      existing.add(shape.id);
    }
    for (const block of this.textBlocks) {
      existing.add(block.id);
    }
    for (const image of this.imageBlocks) {
      existing.add(image.id);
    }
    const added: Set<string> = new Set<string>();
    for (const stroke of strokes) {
      if (existing.has(stroke.id) || added.has(stroke.id)) {
        return false;
      }
      added.add(stroke.id);
    }
    for (const shape of shapes) {
      if (existing.has(shape.id) || added.has(shape.id)) {
        return false;
      }
      added.add(shape.id);
    }
    for (const textBlock of textBlocks) {
      if (existing.has(textBlock.id) || added.has(textBlock.id)) {
        return false;
      }
      added.add(textBlock.id);
    }
    for (const image of images) {
      if (existing.has(image.id) || added.has(image.id)) {
        return false;
      }
      added.add(image.id);
    }
    return true;
  }

  private appendMixedElementRefs(order: PageElementRef[], refs: PageElementRef[]): PageElementRef[] | null {
    const result: PageElementRef[] = clonePageElementOrder(order);
    const appended: Set<string> = new Set<string>();
    for (const ref of refs) {
      const key: string = `${ref.kind}:${ref.elementId}`;
      if ((ref.kind !== PageElementKind.STROKE && ref.kind !== PageElementKind.SHAPE &&
        ref.kind !== PageElementKind.TEXT && ref.kind !== PageElementKind.IMAGE) ||
        ref.elementId.length === 0 || appended.has(key)) {
        return null;
      }
      appended.add(key);
      result.push({ kind: ref.kind, elementId: ref.elementId, zIndex: result.length });
    }
    return result;
  }

  private allStrokeIdsPresent(strokes: StrokeElementData[]): boolean {
    const counts: Map<string, number> = new Map<string, number>();
    for (const current of this.completedStrokes) {
      counts.set(current.id, (counts.get(current.id) ?? 0) + 1);
    }
    for (const stroke of strokes) {
      if (counts.get(stroke.id) !== 1) {
        return false;
      }
    }
    return true;
  }

  private allStrokeIdsAbsent(strokes: StrokeElementData[]): boolean {
    const currentIds: Set<string> = new Set<string>();
    for (const current of this.completedStrokes) {
      currentIds.add(current.id);
    }
    for (const stroke of strokes) {
      if (currentIds.has(stroke.id)) {
        return false;
      }
    }
    return true;
  }

  private allTextBlockIdsPresent(elements: TextBlockElement[]): boolean {
    const counts: Map<string, number> = new Map<string, number>();
    for (const current of this.textBlocks) {
      counts.set(current.id, (counts.get(current.id) ?? 0) + 1);
    }
    for (const element of elements) {
      if (counts.get(element.id) !== 1) {
        return false;
      }
    }
    return true;
  }

  private allTextBlockIdsAbsent(elements: TextBlockElement[]): boolean {
    const currentIds: Set<string> = new Set<string>();
    for (const current of this.textBlocks) {
      currentIds.add(current.id);
    }
    for (const element of elements) {
      if (currentIds.has(element.id)) {
        return false;
      }
    }
    return true;
  }

  private allShapeIdsPresent(shapes: ShapeElement[]): boolean {
    for (const shape of shapes) {
      if (this.countShapeId(shape.id) !== 1) {
        return false;
      }
    }
    return true;
  }

  private allShapeIdsAbsent(shapes: ShapeElement[]): boolean {
    for (const shape of shapes) {
      if (this.countShapeId(shape.id) !== 0) {
        return false;
      }
    }
    return true;
  }

  private allImageIdsPresent(images: ImageElement[]): boolean {
    for (const image of images) {
      if (this.countImageId(image.id) !== 1) {
        return false;
      }
    }
    return true;
  }

  private allImageIdsAbsent(images: ImageElement[]): boolean {
    for (const image of images) {
      if (this.countImageId(image.id) !== 0) {
        return false;
      }
    }
    return true;
  }

  private validateRemovedStrokeIndices(strokes: StrokeElementData[], indices: number[]): boolean {
    if (!this.allStrokeIdsAbsent(strokes) || indices.length !== strokes.length) {
      return false;
    }
    let previous: number = -1;
    for (let i: number = 0; i < indices.length; i++) {
      const index: number = indices[i];
      if (!Number.isInteger(index) || index < previous || index < 0 ||
        index > this.completedStrokes.length + i) {
        return false;
      }
      previous = index;
    }
    return true;
  }

  private validateRemovedShapeIndices(shapes: ShapeElement[], indices: number[]): boolean {
    if (!this.allShapeIdsAbsent(shapes) || indices.length !== shapes.length) {
      return false;
    }
    let previous: number = -1;
    for (let i: number = 0; i < indices.length; i++) {
      const index: number = indices[i];
      if (!Number.isInteger(index) || index < previous || index < 0 || index > this.shapes.length + i) {
        return false;
      }
      previous = index;
    }
    return true;
  }

  private validateRemovedTextBlockIndices(textBlocks: TextBlockElement[], indices: number[]): boolean {
    if (!this.allTextBlockIdsAbsent(textBlocks) || indices.length !== textBlocks.length) {
      return false;
    }
    let previous: number = -1;
    for (let i: number = 0; i < indices.length; i++) {
      const index: number = indices[i];
      if (!Number.isInteger(index) || index < previous || index < 0 || index > this.textBlocks.length + i) {
        return false;
      }
      previous = index;
    }
    return true;
  }

  private validateRemovedImageIndices(images: ImageElement[], indices: number[]): boolean {
    if (!this.allImageIdsAbsent(images) || indices.length !== images.length) {
      return false;
    }
    let previous: number = -1;
    for (let i: number = 0; i < indices.length; i++) {
      const index: number = indices[i];
      if (!Number.isInteger(index) || index < previous || index < 0 || index > this.imageBlocks.length + i) {
        return false;
      }
      previous = index;
    }
    return true;
  }

  private removeTextBlockById(id: string): void {
    const remaining: TextBlockElement[] = [];
    for (const t of this.textBlocks) {
      if (t.id !== id) {
        remaining.push(t);
      }
    }
    this.textBlocks = remaining;
  }

  private restoreRemovedStrokes(strokes: StrokeElementData[], indices: number[]): void {
    for (let i: number = 0; i < strokes.length; i++) {
      this.completedStrokes.splice(indices[i], 0, strokes[i]);
    }
  }

  private restoreRemovedShapes(shapes: ShapeElement[], indices: number[]): void {
    for (let i: number = 0; i < shapes.length; i++) {
      this.shapes.splice(indices[i], 0, shapes[i]);
    }
  }

  private restoreRemovedTextBlocks(textBlocks: TextBlockElement[], indices: number[]): void {
    for (let i: number = 0; i < textBlocks.length; i++) {
      this.textBlocks.splice(indices[i], 0, textBlocks[i]);
    }
  }

  private restoreRemovedImages(images: ImageElement[], indices: number[]): void {
    for (let i: number = 0; i < images.length; i++) {
      this.imageBlocks.splice(indices[i], 0, images[i]);
    }
  }

  private replaceStrokesById(replacements: StrokeElementData[]): void {
    for (const replacement of replacements) {
      for (let i: number = 0; i < this.completedStrokes.length; i++) {
        if (this.completedStrokes[i].id === replacement.id) {
          this.completedStrokes[i] = replacement;
          break;
        }
      }
    }
  }

  private replaceShapesById(replacements: ShapeElement[]): void {
    for (const replacement of replacements) {
      for (let i: number = 0; i < this.shapes.length; i++) {
        if (this.shapes[i].id === replacement.id) {
          this.shapes[i] = replacement;
          break;
        }
      }
    }
  }

  private replaceTextBlocksById(replacements: TextBlockElement[]): void {
    for (const replacement of replacements) {
      for (let i: number = 0; i < this.textBlocks.length; i++) {
        if (this.textBlocks[i].id === replacement.id) {
          this.textBlocks[i] = replacement;
          break;
        }
      }
    }
  }

  private replaceImagesById(replacements: ImageElement[]): void {
    for (const replacement of replacements) {
      for (let i: number = 0; i < this.imageBlocks.length; i++) {
        if (this.imageBlocks[i].id === replacement.id) {
          this.imageBlocks[i] = replacement;
          break;
        }
      }
    }
  }

  private actionTouchesImages(action: UndoableAction): boolean {
    if (action.type === UndoableActionType.ERASE_ELEMENTS ||
      action.type === UndoableActionType.DELETE_ELEMENTS) {
      return action.removedImages.length > 0;
    }
    if (action.type === UndoableActionType.ADD_ELEMENTS) {
      return action.addedImages.length > 0;
    }
    return false;
  }

  private synchronizeElementArraysByOrder(): void {
    const normalized: PageElementRef[] = normalizePageElementOrder(
      this.elementOrder, this.completedStrokes, this.textBlocks, this.shapes, this.imageBlocks,
      this.mathBlocks);
    const ordered: OrderedPageElement[] = materializePageElements(
      normalized, this.completedStrokes, this.textBlocks, this.shapes, this.imageBlocks,
      this.mathBlocks);
    const strokes: StrokeElementData[] = [];
    const textBlocks: TextBlockElement[] = [];
    const shapes: ShapeElement[] = [];
    const images: ImageElement[] = [];
    const mathBlocks: MathElement[] = [];
    for (const element of ordered) {
      if (element.kind === PageElementKind.STROKE) {
        strokes.push(element.data);
      } else if (element.kind === PageElementKind.TEXT) {
        textBlocks.push(element.data);
      } else if (element.kind === PageElementKind.SHAPE) {
        shapes.push(element.data);
      } else if (element.kind === PageElementKind.IMAGE) {
        images.push(element.data);
      } else if (element.kind === PageElementKind.MATH) {
        mathBlocks.push(element.data);
      }
    }
    this.elementOrder = normalized;
    this.completedStrokes = strokes;
    this.textBlocks = textBlocks;
    this.shapes = shapes;
    this.imageBlocks = images;
    this.mathBlocks = mathBlocks;
  }

  private replaceTextBlock(replacement: TextBlockElement): void {
    for (let i: number = 0; i < this.textBlocks.length; i++) {
      if (this.textBlocks[i].id === replacement.id) {
        this.textBlocks[i] = replacement;
        return;
      }
    }
    this.textBlocks.push(replacement);
  }

  private removeStrokeById(id: string): void {
    const remaining: StrokeElementData[] = [];
    for (const s of this.completedStrokes) {
      if (s.id !== id) {
        remaining.push(s);
      }
    }
    this.completedStrokes = remaining;
  }

  // === 选区 ===
  private updateSelectionOverlay(): void {
    const state = this.selectionTool.getState();
    let rect: Rect2D | null = null;
    for (const s of this.completedStrokes) {
      if (state.selectedStrokeIds.indexOf(s.id) >= 0) {
        if (rect === null) {
          rect = {
            left: s.bounds.left,
            top: s.bounds.top,
            right: s.bounds.right,
            bottom: s.bounds.bottom,
          };
        } else {
          rect = {
            left: Math.min(rect.left, s.bounds.left),
            top: Math.min(rect.top, s.bounds.top),
            right: Math.max(rect.right, s.bounds.right),
            bottom: Math.max(rect.bottom, s.bounds.bottom),
          };
        }
      }
    }
    for (const shape of this.shapes) {
      if (state.selectedShapeIds.indexOf(shape.id) >= 0) {
        if (rect === null) {
          rect = { left: shape.bounds.left, top: shape.bounds.top,
            right: shape.bounds.right, bottom: shape.bounds.bottom };
        } else {
          rect = { left: Math.min(rect.left, shape.bounds.left),
            top: Math.min(rect.top, shape.bounds.top),
            right: Math.max(rect.right, shape.bounds.right),
            bottom: Math.max(rect.bottom, shape.bounds.bottom) };
        }
      }
    }
    for (const textBlock of this.textBlocks) {
      if (state.selectedTextBlockIds.indexOf(textBlock.id) >= 0) {
        if (rect === null) {
          rect = { left: textBlock.bounds.left, top: textBlock.bounds.top,
            right: textBlock.bounds.right, bottom: textBlock.bounds.bottom };
        } else {
          rect = { left: Math.min(rect.left, textBlock.bounds.left),
            top: Math.min(rect.top, textBlock.bounds.top),
            right: Math.max(rect.right, textBlock.bounds.right),
            bottom: Math.max(rect.bottom, textBlock.bounds.bottom) };
        }
      }
    }
    for (const image of this.imageBlocks) {
      if (state.selectedImageIds.indexOf(image.id) >= 0) {
        if (rect === null) {
          rect = { left: image.bounds.left, top: image.bounds.top,
            right: image.bounds.right, bottom: image.bounds.bottom };
        } else {
          rect = { left: Math.min(rect.left, image.bounds.left),
            top: Math.min(rect.top, image.bounds.top),
            right: Math.max(rect.right, image.bounds.right),
            bottom: Math.max(rect.bottom, image.bounds.bottom) };
        }
      }
    }
    if (rect !== null) {
      // T-034：画布坐标 → 屏幕坐标（覆盖层 position 用屏幕坐标）
      const tl: Point2D = this.viewport.canvasToScreen(rect.left, rect.top);
      const br: Point2D = this.viewport.canvasToScreen(rect.right, rect.bottom);
      this.selectionRect = { left: tl.x, top: tl.y, right: br.x, bottom: br.y };
      this.selectionVisible = true;
    }
  }

  // 应用选区变换到笔画；pushUndo 控制是否记录撤销（移动结束时统一记录）
  private applySelectionTransform(notifyPersist: boolean, pushUndo: boolean): void {
    const selectedStrokeIds: string[] = this.selectionTool.getState().selectedStrokeIds;
    const selectedShapeIds: string[] = this.selectionTool.getState().selectedShapeIds;
    const selectedTextBlockIds: string[] = this.selectionTool.getState().selectedTextBlockIds;
    const selectedImageIds: string[] = this.selectionTool.getState().selectedImageIds;
    const before: StrokeElementData[] = this.filterStrokesByIds(this.completedStrokes, selectedStrokeIds);
    const beforeShapes: ShapeElement[] = this.filterShapesByIds(this.shapes, selectedShapeIds);
    const beforeTextBlocks: TextBlockElement[] = this.filterTextBlocksByIds(
      this.textBlocks, selectedTextBlockIds);
    const beforeImages: ImageElement[] = this.filterImagesByIds(this.imageBlocks, selectedImageIds);
    const source: StrokeElementData[] = this.selectionDrag ? this.dragBeforeStrokes : this.completedStrokes;
    const sourceShapes: ShapeElement[] = this.selectionDrag ? this.dragBeforeShapes : this.shapes;
    const sourceTextBlocks: TextBlockElement[] = this.selectionDrag ? this.dragBeforeTextBlocks : this.textBlocks;
    const sourceImages: ImageElement[] = this.selectionDrag ? this.dragBeforeImages : this.imageBlocks;
    this.completedStrokes = this.selectionTool.applyTransform(source);
    this.shapes = transformShapeElements(sourceShapes,
      this.selectionTool.getState().selectedShapeIds, this.selectionTool.getState().transform);
    this.textBlocks = transformTextBlockElements(
      sourceTextBlocks, selectedTextBlockIds, this.selectionTool.getState().transform);
    this.imageBlocks = transformImageElements(
      sourceImages, selectedImageIds, this.selectionTool.getState().transform);
    if (pushUndo) {
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_ELEMENTS,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        beforeStrokes: before,
        afterStrokes: this.filterStrokesByIds(this.completedStrokes, selectedStrokeIds),
        beforeShapes: beforeShapes,
        afterShapes: this.filterShapesByIds(this.shapes, selectedShapeIds),
        beforeTextBlocks: beforeTextBlocks,
        afterTextBlocks: this.filterTextBlocksByIds(this.textBlocks, selectedTextBlockIds),
        beforeImages: beforeImages,
        afterImages: this.filterImagesByIds(this.imageBlocks, selectedImageIds),
      });
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.updateSelectionOverlay();
    if (notifyPersist) {
      this.persist();
      this.notifyUndoRedo();
    }
    this.renderFrame();
  }

  onSelectionMenuAction(action: SelectionMenuAction): void {
    if (this.historyBusy) {
      return;
    }
    hilog.info(0x0001, 'NoteCanvasView', 'selection menu action=%{public}d', action);
    const state = this.selectionTool.getState();
    if (action === SelectionMenuAction.DELETE || action === SelectionMenuAction.CUT) {
      const ids: string[] = state.selectedStrokeIds.slice();
      const shapeIds: string[] = state.selectedShapeIds.slice();
      const textIds: string[] = state.selectedTextBlockIds.slice();
      const imageIds: string[] = state.selectedImageIds.slice();
      if (action === SelectionMenuAction.CUT && !this.copySelectedToClipboard(
        ids, shapeIds, textIds, imageIds)) {
        return;
      }
      this.selectionTool.deleteSelected();
      const removed: StrokeElementData[] = [];
      const removedIndices: number[] = [];
      const removedShapes: ShapeElement[] = [];
      const removedShapeIndices: number[] = [];
      const removedTextBlocks: TextBlockElement[] = [];
      const removedTextBlockIndices: number[] = [];
      const removedImages: ImageElement[] = [];
      const removedImageIndices: number[] = [];
      const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
      for (let strokeIndex: number = 0; strokeIndex < this.completedStrokes.length; strokeIndex++) {
        const s: StrokeElementData = this.completedStrokes[strokeIndex];
        if (ids.indexOf(s.id) >= 0) {
          removed.push(s);
          removedIndices.push(strokeIndex);
        }
      }
      for (const s of removed) {
        this.removeStrokeById(s.id);
      }
      for (let shapeIndex: number = 0; shapeIndex < this.shapes.length; shapeIndex++) {
        if (shapeIds.indexOf(this.shapes[shapeIndex].id) >= 0) {
          removedShapes.push(this.shapes[shapeIndex]);
          removedShapeIndices.push(shapeIndex);
        }
      }
      for (const shape of removedShapes) {
        this.removeShapeById(shape.id);
      }
      for (let textIndex: number = 0; textIndex < this.textBlocks.length; textIndex++) {
        if (textIds.indexOf(this.textBlocks[textIndex].id) >= 0) {
          removedTextBlocks.push(this.textBlocks[textIndex]);
          removedTextBlockIndices.push(textIndex);
        }
      }
      for (const textBlock of removedTextBlocks) {
        this.removeTextBlockById(textBlock.id);
      }
      for (let imageIndex: number = 0; imageIndex < this.imageBlocks.length; imageIndex++) {
        if (imageIds.indexOf(this.imageBlocks[imageIndex].id) >= 0) {
          removedImages.push(this.imageBlocks[imageIndex]);
          removedImageIndices.push(imageIndex);
        }
      }
      for (const image of removedImages) {
        this.removeImageById(image.id);
      }
      this.elementOrder = removePageElementRefs(this.elementOrder, PageElementKind.STROKE, ids);
      this.elementOrder = removePageElementRefs(this.elementOrder, PageElementKind.SHAPE, shapeIds);
      this.elementOrder = removePageElementRefs(this.elementOrder, PageElementKind.TEXT, textIds);
      this.elementOrder = removePageElementRefs(this.elementOrder, PageElementKind.IMAGE, imageIds);
      if (removedShapes.length > 0 || removedTextBlocks.length > 0 || removedImages.length > 0) {
        this.undoRedo.push({
          type: UndoableActionType.DELETE_ELEMENTS,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          removedStrokes: removed,
          removedStrokeIndices: removedIndices,
          removedShapes: removedShapes,
          removedShapeIndices: removedShapeIndices,
          removedTextBlocks: removedTextBlocks,
          removedTextBlockIndices: removedTextBlockIndices,
          removedImages: removedImages,
          removedImageIndices: removedImageIndices,
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(this.elementOrder),
        });
      } else if (removed.length > 0) {
        this.undoRedo.push({
          type: UndoableActionType.DELETE_STROKE,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          removedStrokes: removed,
          removedStrokeIndices: removedIndices,
          beforeModifiedStrokes: [],
          afterModifiedStrokes: [],
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(this.elementOrder),
        });
      }
      this.selectionVisible = false;
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
      this.persist();
      this.notifyUndoRedo();
      this.renderFrame();
      if (removedImages.length > 0) {
        this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
      }
    } else if (action === SelectionMenuAction.DESELECT) {
      this.selectionTool.deselect();
      this.selectionVisible = false;
    } else if (action === SelectionMenuAction.SEND_FORWARD || action === SelectionMenuAction.SEND_BACKWARD) {
      this.reorderSelected(state.selectedStrokeIds, state.selectedShapeIds,
        state.selectedTextBlockIds, state.selectedImageIds,
        action === SelectionMenuAction.SEND_FORWARD);
    } else if (action === SelectionMenuAction.FLIP_H || action === SelectionMenuAction.FLIP_V) {
      this.flipSelected(state.selectedStrokeIds, state.selectedShapeIds,
        state.selectedTextBlockIds, state.selectedImageIds, action === SelectionMenuAction.FLIP_H);
    } else if (action === SelectionMenuAction.COPY) {
      this.copySelectedToClipboard(
        state.selectedStrokeIds, state.selectedShapeIds, state.selectedTextBlockIds, state.selectedImageIds);
    } else if (action === SelectionMenuAction.PASTE) {
      this.pasteClipboard();
    }
  }

  private reorderSelected(ids: string[], shapeIds: string[], textIds: string[], imageIds: string[],
    forward: boolean): void {
    const before: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const after: PageElementRef[] = movePageElementRefs(before, ids, shapeIds, forward, textIds, imageIds);
    if (samePageElementOrder(before, after)) {
      return;
    }
    this.elementOrder = after;
    this.synchronizeElementArraysByOrder();
    this.undoRedo.push({
      type: UndoableActionType.REORDER_ELEMENTS,
      noteId: this.noteId,
      pageId: this.currentPage.pageId,
      elementOrderBefore: before,
      elementOrderAfter: clonePageElementOrder(after),
    });
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private flipSelected(ids: string[], shapeIds: string[], textIds: string[], imageIds: string[],
    horizontal: boolean): void {
    let minX: number = Number.MAX_VALUE;
    let minY: number = Number.MAX_VALUE;
    let maxX: number = -Number.MAX_VALUE;
    let maxY: number = -Number.MAX_VALUE;
    for (const s of this.completedStrokes) {
      if (ids.indexOf(s.id) >= 0) {
        if (s.bounds.left < minX) {
          minX = s.bounds.left;
        }
        if (s.bounds.top < minY) {
          minY = s.bounds.top;
        }
        if (s.bounds.right > maxX) {
          maxX = s.bounds.right;
        }
        if (s.bounds.bottom > maxY) {
          maxY = s.bounds.bottom;
        }
      }
    }
    for (const shape of this.shapes) {
      if (shapeIds.indexOf(shape.id) >= 0) {
        minX = Math.min(minX, shape.bounds.left);
        minY = Math.min(minY, shape.bounds.top);
        maxX = Math.max(maxX, shape.bounds.right);
        maxY = Math.max(maxY, shape.bounds.bottom);
      }
    }
    for (const textBlock of this.textBlocks) {
      if (textIds.indexOf(textBlock.id) >= 0) {
        minX = Math.min(minX, textBlock.bounds.left);
        minY = Math.min(minY, textBlock.bounds.top);
        maxX = Math.max(maxX, textBlock.bounds.right);
        maxY = Math.max(maxY, textBlock.bounds.bottom);
      }
    }
    for (const image of this.imageBlocks) {
      if (imageIds.indexOf(image.id) >= 0) {
        minX = Math.min(minX, image.bounds.left);
        minY = Math.min(minY, image.bounds.top);
        maxX = Math.max(maxX, image.bounds.right);
        maxY = Math.max(maxY, image.bounds.bottom);
      }
    }
    const cx: number = (minX + maxX) / 2;
    const cy: number = (minY + maxY) / 2;
    const flip: number[] = horizontal ? [-1, 0, cx * 2, 0, 1, 0, 0, 0, 1] : [1, 0, 0, 0, -1, cy * 2, 0, 0, 1];
    this.selectionTool.getState().transform = flip;
    this.applySelectionTransform(true, true);
    this.selectionTool.getState().transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  private copySelectedToClipboard(ids: string[], shapeIds: string[] = [],
    textIds: string[] = [], imageIds: string[] = []): boolean {
    const selected: StrokeElementData[] = [];
    for (const s of this.completedStrokes) {
      if (ids.indexOf(s.id) >= 0) {
        selected.push(s);
      }
    }
    const selectedShapes: ShapeElement[] = [];
    for (const shape of this.shapes) {
      if (shapeIds.indexOf(shape.id) >= 0) {
        selectedShapes.push(shape);
      }
    }
    const selectedTextBlocks: TextBlockElement[] = [];
    for (const textBlock of this.textBlocks) {
      if (textIds.indexOf(textBlock.id) >= 0) {
        selectedTextBlocks.push(textBlock);
      }
    }
    const selectedImages: ImageElement[] = [];
    for (const image of this.imageBlocks) {
      if (imageIds.indexOf(image.id) >= 0) {
        selectedImages.push(image);
      }
    }
    const selectedOrder: PageElementRef[] = [];
    for (const ref of this.elementOrder) {
      if ((ref.kind === PageElementKind.STROKE && ids.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.SHAPE && shapeIds.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.TEXT && textIds.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.IMAGE && imageIds.indexOf(ref.elementId) >= 0)) {
        selectedOrder.push({ kind: ref.kind, elementId: ref.elementId, zIndex: selectedOrder.length });
      }
    }
    if (!this.strokeClipboard.copy(
      selected, this.loadedPageId, selectedShapes, selectedOrder, selectedTextBlocks, selectedImages)) {
      return false;
    }
    this.clipboardAvailable = true;
    return true;
  }

  private removeShapeById(id: string): void {
    const remaining: ShapeElement[] = [];
    for (const shape of this.shapes) {
      if (shape.id !== id) {
        remaining.push(shape);
      }
    }
    this.shapes = remaining;
  }

  private removeImageById(id: string): void {
    const remaining: ImageElement[] = [];
    for (const image of this.imageBlocks) {
      if (image.id !== id) {
        remaining.push(image);
      }
    }
    this.imageBlocks = remaining;
  }

  private pasteClipboard(): void {
    if (!this.loaded || this.dataLoading || this.dataLoadFailed || this.historyBusy ||
      this.loadedPageId !== this.currentPage.pageId) {
      return;
    }
    const result: ClipboardPasteResult | null = this.strokeClipboard.paste(
      this.getPaperWidth(), this.getPaperHeight(),
      (sourceId: string, sequence: number, index: number): string =>
        this.createClipboardElementId(sourceId, sequence, index));
    if (result === null || (result.strokes.length === 0 && result.shapes.length === 0 &&
      result.textBlocks.length === 0 && result.images.length === 0)) {
      return;
    }
    const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    this.completedStrokes = this.completedStrokes.concat(result.strokes);
    this.shapes = this.shapes.concat(result.shapes);
    this.textBlocks = this.textBlocks.concat(result.textBlocks);
    this.imageBlocks = this.imageBlocks.concat(result.images);
    const pastedIds: string[] = result.strokes.map((stroke: StrokeElementData): string => stroke.id);
    const pastedShapeIds: string[] = result.shapes.map((shape: ShapeElement): string => shape.id);
    const pastedTextIds: string[] = result.textBlocks.map(
      (textBlock: TextBlockElement): string => textBlock.id);
    const pastedImageIds: string[] = result.images.map((image: ImageElement): string => image.id);
    const elementOrderAfter: PageElementRef[] | null = this.appendMixedElementRefs(
      this.elementOrder, result.elementOrder);
    if (elementOrderAfter === null) {
      this.completedStrokes.splice(this.completedStrokes.length - result.strokes.length, result.strokes.length);
      this.shapes.splice(this.shapes.length - result.shapes.length, result.shapes.length);
      this.textBlocks.splice(this.textBlocks.length - result.textBlocks.length, result.textBlocks.length);
      this.imageBlocks.splice(this.imageBlocks.length - result.images.length, result.images.length);
      return;
    }
    this.elementOrder = elementOrderAfter;
    this.undoRedo.push({
      type: UndoableActionType.ADD_ELEMENTS,
      noteId: this.noteId,
      pageId: this.loadedPageId,
      addedStrokes: result.strokes,
      addedShapes: result.shapes,
      addedTextBlocks: result.textBlocks,
      addedImages: result.images,
      addedElementOrder: clonePageElementOrder(result.elementOrder),
      elementOrderBefore: elementOrderBefore,
      elementOrderAfter: clonePageElementOrder(this.elementOrder),
    });
    this.selectionTool.selectElementIds(pastedIds, pastedShapeIds, pastedTextIds, pastedImageIds);
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.updateSelectionOverlay();
    this.persist();
    this.notifyUndoRedo();
    this.renderFrame();
    if (result.images.length > 0) {
      this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
    }
  }

  private createClipboardElementId(sourceId: string, pasteSequence: number, index: number): string {
    while (true) {
      this.clipboardIdCounter++;
      const id: string = `${Date.now().toString(36)}-${this.clipboardIdCounter.toString(36)}-` +
        `${pasteSequence.toString(36)}-${index.toString(36)}-${sourceId.slice(-6)}`;
      let exists: boolean = false;
      for (const stroke of this.completedStrokes) {
        if (stroke.id === id) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        for (const shape of this.shapes) {
          if (shape.id === id) {
            exists = true;
            break;
          }
        }
      }
      if (!exists) {
        for (const block of this.textBlocks) {
          if (block.id === id) {
            exists = true;
            break;
          }
        }
      }
      if (!exists) {
        for (const image of this.imageBlocks) {
          if (image.id === id) {
            exists = true;
            break;
          }
        }
      }
      if (!exists) {
        return id;
      }
    }
  }

  private captureCurrentPage(): PageContentSnapshot {
    const strokes: StrokeElementData[] = [];
    for (const stroke of this.completedStrokes) {
      strokes.push(this.cloneStrokeSnapshot(stroke));
    }
    const textBlocks: TextBlockElement[] = [];
    for (const block of this.textBlocks) {
      textBlocks.push(cloneTextBlockElement(block));
    }
    const shapes: ShapeElement[] = [];
    for (const shape of this.shapes) {
      shapes.push(cloneShapeElement(shape));
    }
    const images: ImageElement[] = [];
    for (const image of this.imageBlocks) {
      images.push(cloneImageElement(image));
    }
    const mathBlocks: MathElement[] = [];
    for (const math of this.mathBlocks) {
      mathBlocks.push(cloneMathElement(math));
    }
    return { strokes: strokes, textBlocks: textBlocks, shapes: shapes, images: images,
      mathBlocks: mathBlocks, elementOrder: clonePageElementOrder(this.elementOrder) };
  }

  private cloneStrokeSnapshot(s: StrokeElementData): StrokeElementData {
    return {
      id: s.id,
      pathPoints: s.pathPoints.map((point: StrokePathPoint): StrokePathPoint => ({
        position: { x: point.position.x, y: point.position.y },
        widthFactor: point.widthFactor,
        pressure: point.pressure,
        altitudeAngleRadians: point.altitudeAngleRadians,
        azimuthUnitX: point.azimuthUnitX,
        azimuthUnitY: point.azimuthUnitY,
      })),
      cubicSegments: s.cubicSegments.map((segment: CubicSegment): CubicSegment => ({
        p0: { x: segment.p0.x, y: segment.p0.y },
        p1: { x: segment.p1.x, y: segment.p1.y },
        p2: { x: segment.p2.x, y: segment.p2.y },
        p3: { x: segment.p3.x, y: segment.p3.y },
      })),
      splatPoints: s.splatPoints.map((splat: PencilSplatPoint): PencilSplatPoint => ({
        x: splat.x, y: splat.y, rotation: splat.rotation,
        scale: splat.scale, opacity: splat.opacity,
      })),
      renderSpec: {
        color: s.renderSpec.color,
        brushWidth: s.renderSpec.brushWidth,
        inkStyle: s.renderSpec.inkStyle,
        isHighlighter: s.renderSpec.isHighlighter,
        isPencil: s.renderSpec.isPencil,
      },
      transform: s.transform.slice(),
      bounds: {
        left: s.bounds.left, top: s.bounds.top,
        right: s.bounds.right, bottom: s.bounds.bottom,
      },
      maskPath: s.maskPath.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
      customPath: s.customPath === undefined || s.customPath === null ? null :
        s.customPath.map((command: InkPathCommand): InkPathCommand => ({
          type: command.type,
          points: command.points.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
        })),
      fillPath: s.fillPath === undefined || s.fillPath === null ? null :
        s.fillPath.map((command: InkPathCommand): InkPathCommand => ({
          type: command.type,
          points: command.points.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
        })),
      fillColor: s.fillColor === undefined ? null : s.fillColor,
      styleMap: s.styleMap === undefined ? [] :
        s.styleMap.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
          backingPencilSeed: entry.backingPencilSeed,
          backingPencilReferencePoint: {
            x: entry.backingPencilReferencePoint.x, y: entry.backingPencilReferencePoint.y,
          },
          backingDashPhase: entry.backingDashPhase,
          backingDashPeriod: entry.backingDashPeriod,
        })),
      isFinished: s.isFinished,
    };
  }

  private pointInRect(p: Point2D, r: Rect2D): boolean {
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
  }

  // selectionRect 与触点均为屏幕坐标；命中区域必须复用覆盖层的钳制布局。
  private isInSelectionMenu(x: number, y: number): boolean {
    const position: SelectionOverlayPosition = selectionOverlayPosition(
      this.selectionRect, this.overlayWidth, this.overlayHeight, this.clipboardAvailable);
    return x >= position.x && x <= position.x + SELECTION_MENU_BUTTON_WIDTH &&
      y >= position.actionY && y <= position.actionY + SELECTION_MENU_BUTTON_HEIGHT;
  }

  // === 文本框 ===
  private createTextBlockAt(position: Point2D): void {
    const element: TextBlockElement = this.textBlockTool.createTextBlock(position,
      this.viewModel.brushColor, 24);
    this.textBlocks.push(element);
    this.elementOrder = appendPageElementRefs(this.elementOrder, PageElementKind.TEXT, [element.id]);
    this.editingTextBlock = element;
    this.editingOriginalTextBlock = null;
    this.editingDraftText = '';
    this.editingTextLayoutWidth = element.blockWidth;
    this.textEditing = true;
    this.renderFrame(true);
  }

  private beginTextEditingAt(position: Point2D): void {
    for (let i: number = this.textBlocks.length - 1; i >= 0; i--) {
      if (pointHitsTextBlock(position, this.textBlocks[i])) {
        this.editingTextBlock = this.textBlocks[i];
        this.editingOriginalTextBlock = this.textBlocks[i];
        this.editingDraftText = this.textBlocks[i].richText;
        this.editingTextLayoutWidth = this.textBlocks[i].blockWidth;
        this.textEditing = true;
        this.renderFrame(true);
        return;
      }
    }
    this.createTextBlockAt(position);
  }

  private textBlockScreenBounds(element: TextBlockElement | null): Rect2D {
    if (element === null) {
      return { left: 0, top: 0, right: 0, bottom: 0 };
    }
    const topLeft: Point2D = this.viewport.canvasToScreen(element.bounds.left, element.bounds.top);
    const bottomRight: Point2D = this.viewport.canvasToScreen(element.bounds.right, element.bounds.bottom);
    return { left: topLeft.x, top: topLeft.y, right: bottomRight.x, bottom: bottomRight.y };
  }

  private fitEditedTextWidth(element: TextBlockElement): TextBlockElement {
    if (element.resizesWidthToFitText !== true) {
      return element;
    }
    const measuredWidth: number = this.textRenderer.measureNaturalWidth(element, this.renderCtx);
    return this.textBlockTool.updateWidthToFit(element, measuredWidth);
  }

  onTextCommit(text: string): void {
    if (this.historyBusy) {
      return;
    }
    let changed: boolean = false;
    if (this.editingTextBlock !== null) {
      if (text.trim().length === 0) {
        this.onTextCancel();
        return;
      }
      if (this.editingOriginalTextBlock === null) {
        let updated: TextBlockElement = this.textBlockTool.updateText(this.editingTextBlock, text);
        updated = this.fitEditedTextWidth(updated);
        this.replaceTextBlock(updated);
        const elementOrderAfter: PageElementRef[] = clonePageElementOrder(this.elementOrder);
        this.undoRedo.push({
          type: UndoableActionType.ADD_ELEMENT,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          addedElement: updated,
          elementOrderBefore: removePageElementRefs(
            elementOrderAfter, PageElementKind.TEXT, [updated.id]),
          elementOrderAfter: elementOrderAfter,
        });
        changed = true;
      } else if (this.editingOriginalTextBlock.richText !== text) {
        let updated: TextBlockElement = this.textBlockTool.updateText(this.editingTextBlock, text);
        updated = this.fitEditedTextWidth(updated);
        this.replaceTextBlock(updated);
        this.undoRedo.push({
          type: UndoableActionType.REPLACE_ELEMENT,
          noteId: this.noteId,
          pageId: this.currentPage.pageId,
          beforeStrokes: [],
          afterStrokes: [],
          beforeElements: [this.editingOriginalTextBlock],
          afterElements: [updated],
        });
        changed = true;
      }
    }
    this.textEditing = false;
    this.editingTextBlock = null;
    this.editingOriginalTextBlock = null;
    this.editingDraftText = '';
    this.editingTextLayoutWidth = 0;
    this.notifyUndoRedo();
    if (changed) {
      this.persist();
    }
    this.renderFrame(true);
  }

  onTextCancel(): void {
    if (this.historyBusy) {
      return;
    }
    if (this.editingTextBlock !== null && this.editingOriginalTextBlock === null) {
      const id: string = this.editingTextBlock.id;
      const remaining: TextBlockElement[] = [];
      for (const t of this.textBlocks) {
        if (t.id !== id) {
          remaining.push(t);
        }
      }
      this.textBlocks = remaining;
      this.elementOrder = removePageElementRefs(this.elementOrder, PageElementKind.TEXT, [id]);
      // T-040 审核修复：取消编辑 = 放弃创建，不应入栈
      // （原实现 push DELETE_ELEMENT，undo 后会恢复一个空文本框）
    }
    this.textEditing = false;
    this.editingTextBlock = null;
    this.editingOriginalTextBlock = null;
    this.editingDraftText = '';
    this.editingTextLayoutWidth = 0;
    this.persist();
    this.renderFrame(true);
  }

  // === RenderSpec 构建 ===
  private makeRenderSpec(): RenderSpec {
    return this.viewModel.getRenderSpec();
  }

  // === TouchPoint → RawPointerEvent 转换 ===
  // T-034：坐标经视口逆映射（屏幕 → 画布）
  // T-040 修复：TouchObject.pressure 已是 [0,1] 归一化值，不能再除以 65535
  // （原实现导致所有笔画 pressure≈0 → widthFactor 恒为下限 0.3）
  // T-040 修复：输入坐标限制在纸张范围内（原版笔画不能超出页面边缘）
  private toRawPointerEvent(touch: TouchObject, isHistorical: boolean,
    event: TouchEvent, timestamp: number, pressureOverride?: number,
    includeStylusAngles: boolean = true): RawPointerEvent {
    const stylus: ArkUIStylusSample = ArkUIStylusAdapter.fromTouch(
      touch, event, pressureOverride, includeStylusAngles);
    const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
    const cx: number = Math.min(Math.max(p.x, 0), this.getPaperWidth());
    const cy: number = Math.min(Math.max(p.y, 0), this.getPaperHeight());
    return {
      x: cx,
      y: cy,
      pressure: stylus.pressure,
      tiltRadians: stylus.altitudeAngleRadians,
      orientationRadians: stylus.orientationRadians,
      toolType: stylus.toolType,
      timestamp: timestamp,
      isHistorical: isHistorical,
    };
  }

  private findTouchById(touches: TouchObject[], pointerId: number): TouchObject | null {
    for (let i: number = 0; i < touches.length; i++) {
      if (touches[i].id === pointerId) {
        return touches[i];
      }
    }
    return null;
  }

  private collectPointerSamples(event: TouchEvent, currentTouch: TouchObject): PointerRawSample[] {
    const samples: PointerRawSample[] = [];
    const historicalPoints: HistoricalPoint[] = event.getHistoricalPoints();
    for (let i: number = 0; i < historicalPoints.length; i++) {
      const historical: HistoricalPoint = historicalPoints[i];
      if (historical.touchObject.id !== this.activePointerId) {
        continue;
      }
      samples.push({
        pointerId: historical.touchObject.id,
        event: this.toRawPointerEvent(historical.touchObject, true, event,
          historical.timestamp, historical.force, false),
      });
    }
    samples.push({
      pointerId: currentTouch.id,
      event: this.toRawPointerEvent(currentTouch, false, event, event.timestamp),
    });
    return samples;
  }

  private firstBatchTimestamp(batches: PointerInputBatches, fallback: number): number {
    if (batches.historical.length > 0) {
      return batches.historical[0].timestamp;
    }
    if (batches.real.length > 0) {
      return batches.real[0].timestamp;
    }
    return fallback;
  }

  private addPointerBatches(batches: PointerInputBatches): void {
    if (this.strokeSession === null) {
      return;
    }
    if (batches.historical.length > 0) {
      const historicalBatch: InputBatch = this.inputProvider.processEvent(
        batches.historical, false);
      this.strokeSession.addBatch(historicalBatch);
    }
    if (batches.real.length > 0) {
      const realBatch: InputBatch = this.inputProvider.processEvent(batches.real, false);
      this.strokeSession.addBatch(realBatch);
    }
  }

  private addPredictionPreview(event: TouchEvent, currentTouch: TouchObject): void {
    if (this.strokeSession === null || !this.strokeSession.isActive()) {
      return;
    }
    const predicted: PredictionCoordinates | null = this.predictor.predict(event);
    if (predicted === null) {
      this.strokeSession.addBatch({ kind: InputBatchKind.PREDICTED, points: [] });
      return;
    }
    const canvasPoint: Point2D = this.viewport.screenToCanvas(predicted.x, predicted.y);
    const raw: RawPointerEvent = this.toRawPointerEvent(
      currentTouch, false, event, event.timestamp);
    raw.x = Math.min(Math.max(canvasPoint.x, 0), this.getPaperWidth());
    raw.y = Math.min(Math.max(canvasPoint.y, 0), this.getPaperHeight());
    // PointPredictor only exposes coordinates. Preserve the current real sample's pen properties and
    // timestamp; InkInputProvider still rejects timestamp 0 exactly like the original predicted event path.
    const batch: InputBatch = this.inputProvider.processEvent([raw], true);
    this.strokeSession.addBatch(batch);
  }

  private resetPointerTracking(): void {
    this.activePointerId = -1;
    this.pointerStream.reset();
  }

  private getPaperWidth(): number {
    return this.currentPage.widthMm > 0 ? this.currentPage.widthMm * PAGE_UNITS_PER_MM : 800;
  }

  private getPaperHeight(): number {
    return this.currentPage.heightMm > 0 ? this.currentPage.heightMm * PAGE_UNITS_PER_MM : 1131;
  }

  private initializeLayerForPage(): void {
    const size: PagePixelSize = pagePixelSize(this.currentPage.widthMm, this.currentPage.heightMm);
    this.layerManager.initialize(size.width, size.height);
  }

  private centerPaperInViewport(): void {
    const canvasW: number = this.canvasCtx.width;
    const canvasH: number = this.canvasCtx.height;
    this.viewport.setScroll(
      (canvasW - this.getPaperWidth() * this.viewport.zoom) / 2,
      Math.max(16, (canvasH - this.getPaperHeight() * this.viewport.zoom) / 2));
    this.viewportInitialized = true;
  }

  build() {
    // T-040 修复：Stack alignContent BottomStart——控制条固定在左下角
    // （原实现 Row 上的 .align 是 Row 内容对齐，在 Stack 中无效 → 控制条居中显示）
    Stack({ alignContent: Alignment.BottomStart }) {
      Canvas(this.canvasCtx)
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
        .onReady(() => {
          this.onCanvasReady();
        })
        .onTouch((event: TouchEvent) => {
          this.onCanvasTouch(event);
        })
        // T-034：双指捏合缩放 + 双指平移（与单指书写互斥：onTouch 中 touches>1 时忽略）
        .gesture(
          GestureGroup(GestureMode.Exclusive,
            GestureGroup(GestureMode.Parallel,
              PinchGesture({ fingers: 2 })
                .onActionUpdate((event: GestureEvent) => {
                  const scale: number = event.scale !== undefined ? event.scale : 1.0;
                  const cx: number = event.fingerList !== undefined && event.fingerList.length > 0
                    ? (event.fingerList[0].localX + event.fingerList[event.fingerList.length - 1].localX) / 2
                    : this.canvasCtx.width / 2;
                  const cy: number = event.fingerList !== undefined && event.fingerList.length > 0
                    ? (event.fingerList[0].localY + event.fingerList[event.fingerList.length - 1].localY) / 2
                    : this.canvasCtx.height / 2;
                  // PinchGesture scale 为累计值；用相对上一帧的增量
                  const factor: number = this.gestureTracker.nextScaleFactor(scale);
                  this.viewport.zoomAt(cx, cy, factor);
                  this.onViewportChanged();
                })
                .onActionEnd(() => {
                  this.gestureTracker.resetScale();
                })
                .onActionCancel(() => {
                  this.gestureTracker.resetScale();
                }),
              PanGesture({ fingers: 2 })
                .onActionUpdate((event: GestureEvent) => {
                  if (event.offsetX !== undefined && event.offsetY !== undefined) {
                    const delta: Point2D = this.gestureTracker.nextPanDelta(event.offsetX, event.offsetY);
                    this.viewport.panBy(delta.x, delta.y);
                    this.onViewportChanged();
                  }
                })
                .onActionEnd(() => {
                  this.gestureTracker.resetPan();
                })
                .onActionCancel(() => {
                  this.gestureTracker.resetPan();
                }),
            ),
          ),
        )
      // 选区覆盖层（虚线边框 + 菜单）
      SelectionOverlay({
        selectionRect: this.selectionRect,
        visible: this.selectionVisible,
        canPaste: this.clipboardAvailable,
        containerWidth: this.overlayWidth,
        containerHeight: this.overlayHeight,
        onMenuAction: (action: SelectionMenuAction) => {
          this.onSelectionMenuAction(action);
        },
      })
      // 文本框编辑覆盖层
      TextBlockOverlay({
        editing: this.textEditing,
        element: this.editingTextBlock,
        screenOrigin: this.editingTextBlock !== null
          ? this.viewport.canvasToScreen(
            textBlockTransformComponents(this.editingTextBlock).origin.x,
            textBlockTransformComponents(this.editingTextBlock).origin.y)
          : { x: 0, y: 0 },
        screenBounds: this.textBlockScreenBounds(this.editingTextBlock),
        viewportZoom: this.viewport.zoom,
        layoutWidth: this.editingTextLayoutWidth,
        onDraftChange: (text: string) => {
          this.editingDraftText = text;
          if (this.editingTextBlock !== null &&
            this.editingTextBlock.resizesWidthToFitText === true) {
            const preview: TextBlockElement = this.textBlockTool.updateText(
              this.editingTextBlock, text);
            this.editingTextLayoutWidth = this.textRenderer.measureNaturalWidth(
              preview, this.renderCtx);
          }
        },
        onCommit: (text: string) => {
          this.onTextCommit(text);
        },
        onCancel: () => {
          this.onTextCancel();
        },
      })
      // T-034：缩放控制条（T-040 修复：Stack alignContent 定位左下角，避开底部 PageManagerBar）
      Row() {
        Button('-')
          .width(40)
          .height(36)
          .fontSize(18)
          .onClick(() => {
            this.zoomStep(-0.25);
          })
        Text(this.zoomPercent.toString() + '%')
          .fontSize(14)
          .width(64)
          .textAlign(TextAlign.Center)
        Button('+')
          .width(40)
          .height(36)
          .fontSize(18)
          .onClick(() => {
            this.zoomStep(0.25);
          })
        Button($r('app.string.fit_width'))
          .height(36)
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.zoomFitWidth();
          })
      }
      .margin({ left: 16, bottom: 68 })  // 避开底部 PageManagerBar（56vp）
      .backgroundColor(this.resolveTokens().surface)
      .borderRadius(8)
      .padding({ left: 4, right: 4 })
      if (this.dataLoading || this.dataLoadFailed) {
        Column() {
          Text(this.dataLoadFailed ? $r('app.string.page_unavailable') : $r('app.string.loading_page'))
            .fontSize(14)
            .fontColor(this.resolveTokens().textSecondary)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.resolveTokens().scrim)
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const width: number = newArea.width as number;
      const height: number = newArea.height as number;
      if (Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0) {
        this.overlayWidth = width;
        this.overlayHeight = height;
        if (this.selectionVisible) {
          this.updateSelectionOverlay();
        }
      }
    })
  }
}
