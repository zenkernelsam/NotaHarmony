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
import {
  Canvas2DOffscreenRenderContext, Canvas2DStrokeRenderer, Canvas2DRenderContext,
} from '../../core/adaptation/Canvas2DStrokeRenderer';
import { Canvas2DTextRenderer } from '../../core/adaptation/Canvas2DTextRenderer';
import { LoadedPencilTexture, loadOriginalPencilTexture } from '../../core/adaptation/PencilTextureLoader';
import { ImageAssetLoader, ImageAssetLoadState, LoadedImageAsset } from
  '../../core/adaptation/ImageAssetLoader';
import {
  LoadedPdfBackground, PdfBackgroundLoader, PdfBackgroundLoadState,
} from '../../core/adaptation/PdfBackgroundLoader';
import {
  LoadedOriginalPaperTexture, OriginalPaperTextureLoader,
} from '../../core/adaptation/OriginalPaperTextureLoader';
import { StrokeLayerManager } from '../../rendering/StrokeLayerManager';
import { StrokeCanvasPainter } from '../../rendering/StrokeCanvasPainter';
import { ShapeCanvasRenderer } from '../../rendering/ShapeCanvasRenderer';
import { ImageCanvasRenderer } from '../../rendering/ImageCanvasRenderer';
import { MathCanvasRenderer, originalMathRasterScale } from '../../rendering/MathCanvasRenderer';
import { originalMathEngine, OriginalMathBitmap } from '../../rendering/OriginalMathEngine';
import {
  BitmapTransferKind, BitmapTransferMetrics, BitmapTransferTracker,
} from '../../core/adaptation/BitmapTransferTracker';
import { CanvasViewport, CumulativeGestureTracker } from '../../rendering/CanvasViewport';
import {
  PDF_RASTER_OVERSCAN_RATIO, pdfRasterPlanCovers, PdfRasterRequest,
} from '../../rendering/PdfRasterPlan';
import { pagePixelSize, PAGE_UNITS_PER_MM, PagePixelSize } from '../../core/model/PageCoordinateSpace';
import { StrokeSession } from '../../rendering/StrokeSession';
import { EraserEngine, EraserMode } from '../../rendering/EraserEngine';
import { OriginalInkPartialEraser } from '../../rendering/OriginalInkPartialEraser';
import {
  OriginalPartialEraserPreviewPhase, OriginalPartialEraserTransientPreview,
} from '../../rendering/OriginalPartialEraserTransientPreview';
import {
  OriginalShapePartialEraser, ShapePartialEraseReplacement,
} from '../../rendering/OriginalShapePartialEraser';
import { PaperRenderer } from '../../rendering/PaperRenderer';
import {
  buildPartialEraseElementReplacementMap, EditorHistoryBridge, GroupElementsAction, HistoryMove,
  OriginalClipboardPasteAction, OriginalPartialEraseAction, PageContentSnapshot,
  PartialEraseElementReplacement, partialEraseMixedElementOrder, UndoRedoManager,
  UndoableAction, UndoableActionType, validatePartialEraseElementHistoryState,
} from '../../rendering/UndoRedoManager';
import { HistoryMetadata, Op, OpType } from '../../core/model/OpTypes';
import { SelectionTool, SelectionMode } from '../../rendering/SelectionTool';
import {
  ClipboardCopyPreparation, ClipboardOriginalGroupPastePreview, ClipboardPasteResult,
  ClipboardSingleOriginalSource, StrokeClipboard,
} from '../../rendering/StrokeClipboard';
import { TextBlockTool } from '../../rendering/TextBlockTool';
import { ShapeDetector } from '../../core/algorithm/ShapeDetector';
import {
  decodePersistedElement, encodePersistedElement, HistoryPageSnapshot, OriginalZOrderCommand,
  OriginalClipboardPasteHistoryResult, OriginalClipboardPastePersistenceResult,
  OriginalClipboardPastePlan, OriginalGroupMutationResult, OriginalMathInsertResult,
  OriginalPartialEraseHistoryResult, OriginalPartialErasePersistenceResult,
  OriginalPartialErasePlan, OriginalPartialEraseReplacementPlan, OriginalTextEditPreview,
  OriginalZOrderHint, PersistedElement, StrokePersistence, validateOriginalClipboardPastePlan,
  validateOriginalPartialErasePlan, validatePartialEraseMaterializationPlan,
} from '../../data/StrokePersistence';
import { OriginalGroupMutationOpPayload } from '../../data/OriginalGroupMutationOpCodec';
import {
  decodeOriginalClipboardPasteMutation, OriginalClipboardPasteMutation,
} from '../../data/OriginalClipboardPasteMutationCodec';
import {
  decodeOriginalPartialEraseMutation, OriginalPartialEraseMutation,
} from '../../data/OriginalPartialEraseMutationCodec';
import {
  OriginalPartialEraseGroupPlan, OriginalPartialEraseGroupReplacement,
  planLocalPartialEraseGroups, replayOriginalPartialEraseGroups,
} from '../../data/OriginalPartialEraseGroupPlanner';
import {
  rebuildOriginalPencilWidth, RebuiltOriginalPencilWidth,
} from '../../core/adaptation/OriginalPencilWidthGeometry';
import { SearchSourceElement } from '../../data/SearchIndexPolicy';
import { DatabaseManager } from '../../data/DatabaseManager';
import {
  OriginalAppliedOperationTime, OriginalOperationAudioTimeStore,
} from '../../data/OriginalOperationAudioTimeStore';
import { decodeOperationId, encodeOperationId } from '../../data/OperationIdentity';
import { encodeOriginalLocalCreateInk } from '../../data/OriginalCreateInkPayloadEncoder';
import { encodeOriginalLocalCreateShape } from '../../data/OriginalCreateShapePayloadEncoder';
import { encodeOriginalLocalCreateTextBlock } from '../../data/OriginalCreateBlockPayloadEncoder';
import { encodeOriginalInitialInsertString } from '../../data/OriginalInsertTextPayloadEncoder';
import { toggleOriginalCheckboxAt } from '../../data/OriginalLocalCheckboxMutation';
import {
  AssetAvailabilityChange, assetAvailabilityHub,
} from '../../data/AssetAvailabilityHub';
import { OpStoreImpl, PersistentHistoryReplay } from '../../data/OpStoreImpl';
import {
  materializePersistentHistory, replayPersistentPageMutations, RestoredHistoryState,
} from '../../data/PersistentHistory';
import { replayPageMutation } from '../../data/PageMutationOpCodec';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { PageRepositoryImpl } from '../../data/PageRepositoryImpl';
import {
  InkPathCommand, InkStyle, InkStyleMapEntry, OriginalInkCreateMetadata, RenderSpec,
  StrokeElementData, StrokePathPoint,
  InputBatch, InputBatchKind,
  PencilSplatPoint,
} from '../../core/model/StrokeTypes';
import { ToolType } from '../../core/model/BrushTypes';
import {
  ImageElement, MathElement, ShapeElement, TextBlockElement,
} from '../../core/model/ElementTypes';
import {
  cloneImageElement, eraserPathHitsImageBlock, imageBlockWorldBounds, originalAssetStorageHash,
  reflectImageCropRect, transformImageElements,
} from '../../core/model/ImageBlockGeometry';
import {
  applyOriginalImageCropDraft, beginOriginalImageCrop, imageCropDraftCanvasCorners,
  OriginalImageCropSession, originalImageCropLocalDelta, resetOriginalImageCropDraft,
} from '../../core/model/OriginalImageCropGeometry';
import {
  cloneShapeElement, eraserPathHitsShape, recomputeShapeBounds, transformShapeElements,
} from '../../core/model/ShapeGeometry';
import { prepareRecognizedShapes } from '../../core/model/ShapeRecognition';
import {
  cloneTextBlockElement, eraserPathHitsTextBlock, pointHitsTextBlock, textBlockTransformComponents,
  textBlockWorldBounds, transformTextBlockElements,
} from '../../core/model/TextBlockGeometry';
import { Point2D, Rect2D, CubicSegment } from '../../core/model/GeometryTypes';
import {
  OriginalSelectionGroup, resolveOriginalGroupAuthoringMembers, resolveOriginalSelectedGroupLeaves,
} from '../../core/model/OriginalGroupSelection';
import { cloneMathElement, eraserPathHitsMathBlock, mathBlockWorldBounds,
  transformMathElements } from '../../core/model/MathBlockGeometry';
import { createOriginalMathInsertDraft, ORIGINAL_MATH_INSERT_MAX_HEIGHT,
  ORIGINAL_MATH_INSERT_MAX_WIDTH } from '../../core/model/OriginalMathInsertPlan';
import {
  CURRENT_VIEW_COORDINATE_MODEL_VERSION, isCurrentViewCoordinateModel, ORIGINAL_VIEWPORT_MAX_ZOOM,
  ORIGINAL_VIEWPORT_MIN_ZOOM, PageBackground, PageInfo,
} from '../../core/model/NoteTypes';
import { effectivePageBackground } from '../../core/model/PageBackgroundModel';
import {
  appendPageElementRefs, clonePageElementOrder, materializePageElements, movePageElementRefsOneStep,
  normalizePageElementOrder, OrderedPageElement, PageElementKind, PageElementRef,
  removePageElementRefs, requiresUnifiedElementRender, samePageElementMembers, samePageElementOrder,
} from '../../core/model/PageElementOrder';
import { EditorViewModel } from './EditorViewModel';
import { SelectionOverlay, SelectionMenuAction } from '../components/SelectionOverlay';
import { ImageCropHandle, ImageCropOverlay } from '../components/ImageCropOverlay';
import {
  initialOriginalMathEditorDraftState, isOriginalMathLatexDraftValid, MathEditorOverlay,
  OriginalMathEditorDraftState,
} from '../components/MathEditorOverlay';
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
import {
  OriginalAudioLinkedPlayback, OriginalAudioSegmentRange, resolveOriginalAudioLinkedPlayback,
} from '../../core/adaptation/OriginalAudioLinkedInkPlayback';

const HISTORY_CHECKPOINT_TAIL_OPERATIONS: number = 256;
const HISTORY_CHECKPOINT_MAX_ACTIONS: number = 128;
const HISTORY_REPLAY_ATTEMPTS: number = 4;
const ORIGINAL_CREATE_INK_PAYLOAD_TYPE: number = 15;
const ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH_VP: number = 280;
const ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT_VP: number = 96;
const ORIGINAL_MATH_EDITOR_PREVIEW_PIXEL_SCALE: number = 1;
const PDF_RASTER_REFRESH_DELAY_MS: number = 120;
const CLIPBOARD_PASTE_SUPPRESSION_MS: number = 200;

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
  @Prop @Watch('onMathInsertSignalChange') mathInsertSignal: number = 0;
  @Prop @Watch('onSelectionStyleSignalChange') selectionStyleSignal: number = 0;
  @Prop selectionInkStyle: InkStyle = InkStyle.FIXED_WIDTH;
  @Prop @Watch('onSelectionColorSignalChange') selectionColorSignal: number = 0;
  @Prop selectionInkColor: number = -16777216;
  @Prop @Watch('onSelectionWidthSignalChange') selectionWidthSignal: number = 0;
  @Prop selectionInkWidth: number = 5;
  @Prop @Watch('onAudioPlaybackChange') playbackAudioTime: string | null = null;
  @Prop @Watch('onAudioPlaybackChange') playbackAudioSegments: OriginalAudioSegmentRange[] = [];
  readRecordingAudioTime: () => string | null = (): string | null => null;
  // MyScript 的精确 hold 时长未出现在反编译配置中；保留注入点供设备对照后收敛。
  @Prop shapeHoldDelayMs: number = 500;
  onUndoRedoChanged: (canUndo: boolean, canRedo: boolean) => void = () => {
  };
  onRequestPage: (pageId: string) => void = () => {
  };
  onHistoryBridgeReady: (bridge: EditorHistoryBridge) => void = () => {
  };
  onSelectionInkControlsChanged: (color: number, width: number,
    minimum: number, maximum: number, variableStyleEnabled: boolean) => void =
    (_color: number, _width: number, _minimum: number, _maximum: number,
      _variableStyleEnabled: boolean): void => {
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
  private originalInkReservation: OriginalInkCreateMetadata | null = null;
  private originalInkReservationEpoch: number = 0;
  private originalInkReservationPromise: Promise<OriginalInkCreateMetadata | null> | null = null;
  private originalInkReservationGeneration: number = -1;
  private originalInkReservationPageId: string = '';
  private originalInkIneligiblePages: Set<string> = new Set<string>();
  private database: DatabaseManager | null = null;
  private imageAssetLoader: ImageAssetLoader | null = null;
  private imageAssets: Map<string, LoadedImageAsset> = new Map<string, LoadedImageAsset>();
  private imageAssetGeneration: number = 0;
  private pdfBackgroundLoader: PdfBackgroundLoader | null = null;
  private pdfBackground: LoadedPdfBackground | null = null;
  private pdfBackgroundGeneration: number = 0;
  private pdfRasterRefreshTimer: number = -1;
  private paperTextureLoader: OriginalPaperTextureLoader = new OriginalPaperTextureLoader();
  private paperTexture: LoadedOriginalPaperTexture | null = null;
  private paperTextureGeneration: number = 0;
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
  @StorageLink(THEME_MODE_KEY) @Watch('onMathEditorThemeChange') themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) @Watch('onMathEditorThemeChange') systemDark: boolean = false;

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
  private selectionGroups: OriginalSelectionGroup[] = [];
  private eraserPath: Point2D[] = [];
  private partialEraserPreview: OriginalPartialEraserTransientPreview =
    new OriginalPartialEraserTransientPreview();
  private isDrawing: boolean = false;
  private eraserActive: boolean = false;
  private selectionDrawing: boolean = false;
  private selectionDrag: boolean = false;
  private dragBeforeStrokes: StrokeElementData[] = [];
  private dragBeforeShapes: ShapeElement[] = [];
  private dragBeforeTextBlocks: TextBlockElement[] = [];
  private dragBeforeImages: ImageElement[] = [];
  private dragBeforeMathBlocks: MathElement[] = [];
  private lastDragPoint: Point2D = { x: 0, y: 0 };
  private lastTapTime: number = 0;
  private lastTapPos: Point2D = { x: 0, y: 0 };
  @State loaded: boolean = false;
  @State loadedPageId: string = '';
  @State dataLoading: boolean = true;
  @State dataLoadFailed: boolean = false;
  private pageLoadPromise: Promise<void> = Promise.resolve();
  private viewportInitialized: boolean = false;
  private shapeHoldTimer: number = -1;
  private heldShapes: ShapeElement[] = [];
  // -1: undo, 1: redo, 0: none. Cross-page history resumes after page data finishes loading.
  private pendingHistoryDirection: number = 0;
  @State historyBusy: boolean = false;
  private skipSavePageId: string = '';
  private pageLoadGeneration: number = 0;
  private originalInkAudioStarts: Map<string, string> = new Map<string, string>();
  private originalInkAudioStartsLoaded: boolean = false;
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
  @State selectionCanFlip: boolean = false;
  @State selectionCanCrop: boolean = false;
  @State selectionCanLock: boolean = false;
  @State selectionCanGroup: boolean = false;
  @State selectionCanUngroup: boolean = false;
  @State selectionCanEditMath: boolean = false;
  @State selectionPositionLocked: boolean = false;
  private imageCropSession: OriginalImageCropSession | null = null;
  @State imageCropVisible: boolean = false;
  @State imageCropDraft: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @State mathEditorVisible: boolean = false;
  @State mathEditorDraft: string = '';
  @State mathEditorDraftState: OriginalMathEditorDraftState = OriginalMathEditorDraftState.EMPTY;
  @State mathEditorBusy: boolean = false;
  @State mathEditorFailed: boolean = false;
  private mathEditorOriginal: MathElement | null = null;
  private mathEditorInsert: boolean = false;
  private mathEditorPreview: OriginalMathBitmap | null = null;
  private mathEditorValidationTimer: number = -1;
  private mathEditorValidationGeneration: number = 0;
  private mathEngineInitializationComplete: boolean = false;
  @State clipboardAvailable: boolean = false;
  @State overlayWidth: number = 0;
  @State overlayHeight: number = 0;
  private clipboardPasteTarget: Point2D | null = null;
  private lastPasteRequestTime: number = 0;

  aboutToAppear(): void {
    this.lifecycleActive = true;
    this.mathEngineInitializationComplete = originalMathEngine.isReady();
    originalMathEngine.initialize(getContext(this) as common.UIAbilityContext).then((ready: boolean): void => {
      this.mathEngineInitializationComplete = true;
      if (this.lifecycleActive && this.mathEditorVisible) {
        this.requestMathEditorDraftValidation();
      }
      if (ready && this.lifecycleActive && this.loaded) {
        this.renderFrame(true);
      }
    });
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
    this.partialEraserPreview.cancel();
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
      this.pdfBackgroundLoader = new PdfBackgroundLoader(db);
      this.persistence.initialize(db);
      const loaded = await this.persistence.loadElements(this.noteId, targetPageId);
      await this.loadOriginalInkAudioStarts(db);
      await this.refreshOriginalInkReservation(generation, targetPageId);
      if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== targetPageId) {
        return;
      }
      this.hydrateOriginalStrokeAudioStarts(loaded.strokes);
      this.completedStrokes = loaded.strokes;
      this.textBlocks = loaded.textBlocks;
      this.shapes = loaded.shapes;
      this.imageBlocks = loaded.images;
      this.mathBlocks = loaded.mathBlocks;
      this.elementOrder = loaded.elementOrder;
      this.selectionGroups = loaded.groups;
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
        this.layerManager.rebuildFromStrokes(
          this.completedStrokes, this.renderCtx, this.viewport.zoom);
        this.renderFrame(true);
      }
      this.refreshImageAssets(generation, targetPageId);
      this.refreshPdfBackground(generation, targetPageId);
      this.refreshPaperTexture(generation, targetPageId);
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

  private persist(rearmOriginalInk: boolean = false,
    originalZOrderHint?: OriginalZOrderHint): void {
    if (this.loaded && !this.dataLoading && !this.dataLoadFailed && this.persistence.isReady() &&
      this.noteId.length > 0 && this.loadedPageId.length > 0 &&
      this.loadedPageId !== this.skipSavePageId) {
      const pageId: string = this.loadedPageId;
      this.invalidateOriginalInkReservation();
      if (rearmOriginalInk) {
        this.originalInkIneligiblePages.delete(pageId);
      } else {
        this.originalInkIneligiblePages.add(pageId);
      }
      try {
        const historyRevision: number = this.undoRedo.getHistoryRevision();
        const preserveActionBoundary: boolean = historyRevision !== this.lastQueuedHistoryRevision;
        const history = preserveActionBoundary ? this.undoRedo.getLatestHistoryMetadata() : undefined;
        this.persistence.queueSaveElements(this.noteId, pageId, this.completedStrokes, this.textBlocks,
          this.elementOrder, this.shapes, preserveActionBoundary, history === null ? undefined : history,
          this.imageBlocks, this.mathBlocks, originalZOrderHint);
        this.lastQueuedHistoryRevision = historyRevision;
        this.persistence.flush(this.noteId, pageId).then(() => {
          if (!this.persistence.hasDirtySave(this.noteId, pageId)) {
            this.saveFailed = false;
          }
          if (rearmOriginalInk) {
            this.refreshOriginalInkReservation(this.pageLoadGeneration, pageId);
          }
        }).catch((e: Object) => this.reportSaveFailure(e));
      } catch (e) {
        this.reportSaveFailure(e as Object);
      }
    }
  }

  private async refreshOriginalInkReservation(generation: number,
    pageId: string): Promise<OriginalInkCreateMetadata | null> {
    if (!this.persistence.isReady() || pageId.length === 0 ||
      generation !== this.pageLoadGeneration || this.currentPage.pageId !== pageId ||
      this.originalInkIneligiblePages.has(pageId)) {
      return null;
    }
    if (this.originalInkReservation !== null) {
      return this.originalInkReservation;
    }
    if (this.originalInkReservationPromise !== null) {
      const inFlight: Promise<OriginalInkCreateMetadata | null> = this.originalInkReservationPromise;
      if (this.originalInkReservationGeneration === generation &&
        this.originalInkReservationPageId === pageId) {
        try {
          return await inFlight;
        } catch (_error) {
          return null;
        }
      }
      try {
        await inFlight;
      } catch (_error) {
        // The owning request reports its own failure. A current page may still be eligible.
      }
      if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== pageId) {
        return null;
      }
      return this.refreshOriginalInkReservation(generation, pageId);
    }
    const pending: Promise<OriginalInkCreateMetadata | null> =
      this.persistence.reserveOriginalInkCreate(this.noteId, pageId);
    const reservationEpoch: number = this.originalInkReservationEpoch;
    this.originalInkReservationPromise = pending;
    this.originalInkReservationGeneration = generation;
    this.originalInkReservationPageId = pageId;
    try {
      const reserved: OriginalInkCreateMetadata | null = await pending;
      if (reservationEpoch === this.originalInkReservationEpoch &&
        generation === this.pageLoadGeneration && this.currentPage.pageId === pageId) {
        this.originalInkReservation = reserved;
        return reserved;
      }
      return null;
    } catch (e) {
      hilog.error(0x0001, 'NoteCanvasView',
        'original CREATE_INK reservation skipped: %{public}s', JSON.stringify(e));
      return null;
    } finally {
      if (this.originalInkReservationPromise === pending) {
        this.originalInkReservationPromise = null;
        this.originalInkReservationGeneration = -1;
        this.originalInkReservationPageId = '';
      }
    }
  }

  private invalidateOriginalInkReservation(): void {
    this.originalInkReservationEpoch++;
    this.originalInkReservation = null;
    this.originalInkReservationPromise = null;
    this.originalInkReservationGeneration = -1;
    this.originalInkReservationPageId = '';
  }

  private async flushCurrentPage(): Promise<boolean> {
    await this.pageLoadPromise;
    if (!this.loaded || this.dataLoadFailed) {
      return true;
    }
    if (!this.persistence.isReady() || this.noteId.length === 0 || this.loadedPageId.length === 0) {
      return true;
    }
    if (this.mathEditorVisible) {
      return false;
    }
    if (this.textEditing && this.editingTextBlock !== null) {
      if (!await this.onTextCommit(this.editingDraftText)) {
        return false;
      }
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
    this.cancelImageCrop();
    this.cancelMathEditing();
    this.pageLoadPromise = this.switchPageData();
  }

  onAudioPlaybackChange(_propName: string): void {
    if (this.loaded) {
      this.renderFrame(true);
    }
  }

  aboutToDisappear(): void {
    this.lifecycleActive = false;
    this.partialEraserPreview.cancel();
    this.cancelImageCrop();
    this.cancelMathEditorDraftValidation();
    this.releaseMathEditorPreview();
    this.mathEditorDraftState = this.mathEditorVisible ?
      initialOriginalMathEditorDraftState(this.mathEditorDraft) : OriginalMathEditorDraftState.EMPTY;
    if (this.assetAvailabilitySubscription >= 0) {
      assetAvailabilityHub.unsubscribe(this.assetAvailabilitySubscription);
      this.assetAvailabilitySubscription = -1;
    }
    this.cancelPdfRasterRefresh();
    this.releaseImageAssets();
    this.releasePdfBackground();
    this.releasePaperTexture();
    this.strokeClipboard.clear();
    this.clipboardAvailable = false;
    this.cancelShapeDetectionTimer();
    if (this.viewportSaveTimer >= 0) {
      clearTimeout(this.viewportSaveTimer);
      this.viewportSaveTimer = -1;
    }
    this.saveViewportState();
    if (this.textEditing && this.editingTextBlock !== null) {
      this.onTextCommit(this.editingDraftText).catch((e: Object): void => {
        hilog.error(0x0001, 'NoteCanvasView',
          'final Text commit failed: %{public}s', JSON.stringify(e));
      }).finally((): void => {
        this.disposeRenderingResources();
      });
    } else {
      this.persist();
      this.disposeRenderingResources();
    }
  }

  private disposeRenderingResources(): void {
    const renderMetrics: BitmapTransferMetrics = this.layerManager.getRenderMetrics();
    hilog.info(0x0001, 'NoteCanvasView',
      'render metrics frames=%{public}d full=%{public}d transfers=%{public}d completed=%{public}d ' +
      'isolated=%{public}d pencilTint=%{public}d pencilTexture=%{public}d ' +
      'maxPerFrame=%{public}d maxDirtyRegions=%{public}d',
      renderMetrics.frameCount, renderMetrics.fullFrameCount, renderMetrics.totalTransfers,
      renderMetrics.completedLayerTransfers, renderMetrics.isolatedMaskTransfers,
      renderMetrics.pencilTintTransfers, renderMetrics.pencilTextureTransfers,
      renderMetrics.maxFrameTransfers, renderMetrics.maxDirtyRegionCount);
    this.mathRenderer.clear();
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
    this.cancelActiveInteraction();
    if (!this.loaded) {
      await this.loadNoteData();
      return;
    }
    if (this.currentPage.pageId === this.loadedPageId) {
      this.initializeLayerForPage();
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
      this.renderFrame(true);
      this.refreshPdfBackground(this.pageLoadGeneration, this.loadedPageId);
      this.refreshPaperTexture(this.pageLoadGeneration, this.loadedPageId);
      return;
    }
    const generation: number = ++this.pageLoadGeneration;
    this.invalidateOriginalInkReservation();
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
      const db: DatabaseManager | null = this.database;
      if (db !== null) {
        await this.loadOriginalInkAudioStarts(db);
      }
      await this.refreshOriginalInkReservation(generation, targetPageId);
      if (generation !== this.pageLoadGeneration || this.currentPage.pageId !== targetPageId) {
        return;
      }
      this.hydrateOriginalStrokeAudioStarts(loaded.strokes);
      this.completedStrokes = loaded.strokes;
      this.textBlocks = loaded.textBlocks;
      this.shapes = loaded.shapes;
      this.imageBlocks = loaded.images;
      this.mathBlocks = loaded.mathBlocks;
      this.elementOrder = loaded.elementOrder;
      this.selectionGroups = loaded.groups;
      this.loadedPageId = targetPageId;
      this.loaded = true;
      this.dataLoadFailed = false;
      this.selectionTool.deselect();
      this.selectionVisible = false;
      this.initializeLayerForPage();
      this.centerPaperInViewport();
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
      this.notifyUndoRedo();
      this.renderFrame(true);
      this.refreshImageAssets(generation, targetPageId);
      this.refreshPdfBackground(generation, targetPageId);
      this.refreshPaperTexture(generation, targetPageId);
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
          this.refreshPdfBackground(generation, fromPageId);
          this.refreshPaperTexture(generation, fromPageId);
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
    this.releasePdfBackground();
    this.releasePaperTexture();
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
      this.layerManager.rebuildFromStrokes([], this.renderCtx, this.viewport.zoom);
      this.renderFrame(true);
    }
  }

  onRedoSignalChange(_propName: string): void {
    hilog.info(0x0001, 'NoteCanvasView', 'redo signal received, canRedo=%{public}s',
      this.undoRedo.canRedo().toString());
    this.redoStroke();
  }

  onMathInsertSignalChange(_propName: string): void {
    this.startMathInsert();
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
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
    }
    this.renderFrame(true);
    this.schedulePdfRasterRefresh(0);
  }

  onSelectionStyleSignalChange(_propName: string): void {
    this.modifySelectedInkStyle(this.selectionInkStyle);
  }

  onSelectionColorSignalChange(_propName: string): void {
    this.modifySelectedInkColor(this.selectionInkColor);
  }

  onSelectionWidthSignalChange(_propName: string): void {
    this.modifySelectedInkWidth(this.selectionInkWidth);
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
        this.layerManager.rebuildFromStrokes(
          this.completedStrokes, this.renderCtx, this.viewport.zoom);
        this.renderFrame(true);
      }
    } catch (e) {
      console.error(`Original pencil texture load failed: ${JSON.stringify(e)}`);
      if (this.lifecycleActive) {
        this.renderer.setSplatTexture(Canvas2DStrokeRenderer.generatePencilTexture(this.bitmapTransferTracker));
        if (this.layerManager.isInitialized()) {
          this.layerManager.rebuildFromStrokes(
            this.completedStrokes, this.renderCtx, this.viewport.zoom);
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
    const partialEraserPreviewStroke: StrokeElementData | null = this.partialEraserPreview.getStroke();
    const orderedRender: boolean = this.requiresOrderedElementRender() || this.heldShapes.length > 0 ||
      (this.playbackAudioTime !== null && this.playbackAudioSegments.length > 0);
    const fullRedraw: boolean = forceFull || (partialEraserPreviewStroke === null && orderedRender);
    if (fullRedraw) {
      this.canvasCtx.clearRect(0, 0, w, h);
      this.canvasCtx.fillStyle = theme.background;
      this.canvasCtx.fillRect(0, 0, w, h);
    }
    this.canvasCtx.save();
    try {
      this.canvasCtx.translate(this.viewport.scrollX, this.viewport.scrollY);
      this.canvasCtx.scale(this.viewport.zoom, this.viewport.zoom);
      if (partialEraserPreviewStroke !== null) {
        this.layerManager.compositeWithOrderedPartialEraser(this.canvasCtx, partialEraserPreviewStroke, () => {
          const visibleLeft: number = -this.viewport.scrollX / this.viewport.zoom;
          const visibleTop: number = -this.viewport.scrollY / this.viewport.zoom;
          this.canvasCtx.fillStyle = theme.background;
          this.canvasCtx.fillRect(visibleLeft, visibleTop, w / this.viewport.zoom, h / this.viewport.zoom);
          this.renderPaper(theme);
        }, (renderContext: Canvas2DOffscreenRenderContext): void => {
          this.renderOrderedElements(renderContext, partialEraserPreviewStroke);
        }, this.viewport.zoom, forceFull);
      } else if (orderedRender) {
        this.renderPaper(theme);
        if (this.hasOriginalPartialEraser()) {
          this.renderOrderedContentLayer();
        } else {
          this.renderOrderedElements(this.renderCtx);
        }
        for (const heldShape of this.heldShapes) {
          this.shapeRenderer.renderShape(heldShape, this.renderCtx);
        }
        if (current !== null) {
          this.strokePainter.renderStroke(current, this.renderCtx, this.getPaperWidth(),
            this.getPaperHeight(), this.viewport.zoom);
        }
      } else if (forceFull) {
        this.renderPaper(theme);
        this.layerManager.compositeFull(this.canvasCtx, current, this.renderCtx, this.viewport.zoom);
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
    } finally {
      this.canvasCtx.restore();
    }
  }

  private renderPaper(theme: ThemeTokens): void {
    const loaded: LoadedPdfBackground | null = this.pdfBackground !== null &&
      this.pdfBackground.state === PdfBackgroundLoadState.READY ? this.pdfBackground : null;
    const bitmap: ImageBitmap | null = loaded === null ? null : loaded.bitmap;
    this.paperRenderer.renderBackground(this.canvasCtx, this.getPaperWidth(), this.getPaperHeight(),
      this.currentPage, this.viewport.zoom, theme, bitmap, this.paperTexture,
      loaded === null ? null : loaded.renderRect);
  }

  private renderTextBlocks(): void {
    for (const textBlock of this.textBlocks) {
      this.textRenderer.renderText(textBlock, this.renderCtx);
    }
  }

  private requiresOrderedElementRender(): boolean {
    return requiresUnifiedElementRender(this.elementOrder);
  }

  private hasOriginalPartialEraser(): boolean {
    return this.completedStrokes.some((stroke: StrokeElementData): boolean =>
      stroke.renderSpec.isPartialEraser === true);
  }

  private renderOrderedContentLayer(): void {
    const width: number = this.getPaperWidth();
    const height: number = this.getPaperHeight();
    if (width <= 0 || height <= 0) {
      return;
    }
    const layer: OffscreenCanvas = new OffscreenCanvas(width, height);
    const context: OffscreenCanvasRenderingContext2D =
      layer.getContext('2d', new RenderingContextSettings(true));
    const renderContext: Canvas2DOffscreenRenderContext = new Canvas2DOffscreenRenderContext(context);
    this.renderOrderedElements(renderContext);
    const bitmap: ImageBitmap = layer.transferToImageBitmap();
    this.bitmapTransferTracker.recordTransfer(BitmapTransferKind.COMPLETED_LAYER);
    try {
      this.canvasCtx.drawImage(bitmap, 0, 0, width, height);
    } finally {
      bitmap.close();
    }
  }

  private renderOrderedElements(renderContext: Canvas2DRenderContext | Canvas2DOffscreenRenderContext,
    transientTopStroke: StrokeElementData | null = null): void {
    const elements: OrderedPageElement[] = materializePageElements(
      this.elementOrder, this.completedStrokes, this.textBlocks, this.shapes, this.imageBlocks,
      this.mathBlocks, transientTopStroke);
    const mathRasterScale: number = originalMathRasterScale(this.viewport.zoom, vp2px(1));
    for (const element of elements) {
      if (element.kind === PageElementKind.STROKE) {
        if (transientTopStroke !== null && element.data === transientTopStroke) {
          this.strokePainter.renderStroke(
            element.data, renderContext, this.getPaperWidth(), this.getPaperHeight(),
            this.viewport.zoom);
          continue;
        }
        this.hydrateOriginalStrokeAudioStart(element.data);
        const playback: OriginalAudioLinkedPlayback = resolveOriginalAudioLinkedPlayback(
          element.data, this.playbackAudioTime, this.playbackAudioSegments);
        this.strokePainter.renderAudioLinkedStroke(element.data, playback,
          renderContext, this.getPaperWidth(), this.getPaperHeight(), this.viewport.zoom);
      } else if (element.kind === PageElementKind.TEXT) {
        this.textRenderer.renderText(element.data, renderContext);
      } else if (element.kind === PageElementKind.SHAPE) {
        this.shapeRenderer.renderShape(element.data, renderContext);
      } else if (element.kind === PageElementKind.IMAGE) {
        const loaded: LoadedImageAsset | undefined = this.imageAssets.get(
          originalAssetStorageHash(element.data.assetHashBits));
        if (loaded !== undefined && loaded.state === ImageAssetLoadState.READY && loaded.bitmap !== null) {
          this.imageRenderer.renderImage(element.data, loaded.bitmap, renderContext);
        }
      } else if (element.kind === PageElementKind.MATH) {
        this.mathRenderer.renderMath(element.data, renderContext, mathRasterScale);
      }
    }
  }

  private async loadOriginalInkAudioStarts(db: DatabaseManager): Promise<void> {
    if (this.originalInkAudioStartsLoaded) {
      return;
    }
    const timings: OriginalAppliedOperationTime[] =
      await new OriginalOperationAudioTimeStore(db).listForNote(this.noteId);
    const starts: Map<string, string> = new Map<string, string>();
    for (const timing of timings) {
      if (timing.payloadType === ORIGINAL_CREATE_INK_PAYLOAD_TYPE) {
        starts.set(encodeOperationId({ timestamp: timing.timestamp, siteId: timing.siteId }),
          timing.effectiveAudioTime);
      }
    }
    this.originalInkAudioStarts = starts;
    this.originalInkAudioStartsLoaded = true;
  }

  private hydrateOriginalStrokeAudioStarts(strokes: StrokeElementData[]): void {
    for (const stroke of strokes) {
      this.hydrateOriginalStrokeAudioStart(stroke);
    }
  }

  private hydrateOriginalStrokeAudioStart(stroke: StrokeElementData): void {
    if (stroke.audioStartTime !== undefined) {
      return;
    }
    const start: string | undefined = this.originalInkAudioStarts.get(stroke.id);
    if (start !== undefined) {
      stroke.audioStartTime = start;
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
    const effective = effectivePageBackground(this.currentPage);
    if (effective !== null && effective.pdf !== undefined && effective.pdf !== null &&
      originalAssetStorageHash(effective.pdf.metadata.assetHashBits) === change.storageHash) {
      this.refreshPdfBackground(this.pageLoadGeneration, this.loadedPageId);
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

  private refreshPdfBackground(pageGeneration: number, pageId: string,
    preserveCurrent: boolean = false): void {
    const loader: PdfBackgroundLoader | null = this.pdfBackgroundLoader;
    const effective: PageBackground | null = effectivePageBackground(this.currentPage);
    if (loader === null || effective === null || effective.pdf === undefined || effective.pdf === null) {
      this.releasePdfBackground();
      return;
    }
    if (preserveCurrent) {
      this.pdfBackgroundGeneration++;
    } else {
      this.releasePdfBackground();
    }
    const generation: number = this.pdfBackgroundGeneration;
    const rasterRequest: PdfRasterRequest | null = this.currentPdfRasterRequest(effective);
    loader.load(effective.pdf, rasterRequest).then((loaded: LoadedPdfBackground): void => {
      if (!this.lifecycleActive || pageGeneration !== this.pageLoadGeneration ||
        generation !== this.pdfBackgroundGeneration || this.loadedPageId !== pageId) {
        loader.release(loaded);
        return;
      }
      const previous: LoadedPdfBackground | null = this.pdfBackground;
      if (preserveCurrent && previous !== null && previous.state === PdfBackgroundLoadState.READY &&
        loaded.state !== PdfBackgroundLoadState.READY) {
        loader.release(loaded);
        hilog.warn(0x0001, 'NoteCanvasView',
          'PDF reraster kept previous bitmap state=%{public}d reason=%{public}s',
          loaded.state, loaded.error === null ? '' : loaded.error);
        return;
      }
      this.pdfBackground = loaded;
      if (previous !== null && previous !== loaded) {
        loader.release(previous);
      }
      if (loaded.state !== PdfBackgroundLoadState.READY) {
        hilog.warn(0x0001, 'NoteCanvasView',
          'PDF background unavailable state=%{public}d reason=%{public}s',
          loaded.state, loaded.error === null ? '' : loaded.error);
      }
      if (this.layerManager.isInitialized()) {
        this.renderFrame(true);
      }
      this.schedulePdfRasterRefresh(0);
    }).catch((error: Object): void => {
      hilog.error(0x0001, 'NoteCanvasView',
        'PDF background load failed: %{public}s', JSON.stringify(error));
    });
  }

  private currentPdfRasterRequest(background: PageBackground): PdfRasterRequest | null {
    const visiblePageRect: Rect2D | null = this.viewport.visibleCanvasRect(
      this.canvasCtx.width, this.canvasCtx.height);
    if (visiblePageRect === null) {
      return null;
    }
    const density: number = vp2px(1);
    const outputScale: number = this.viewport.zoom *
      (Number.isFinite(density) && density > 0 ? density : 1);
    return {
      paperWidth: this.getPaperWidth(),
      paperHeight: this.getPaperHeight(),
      visiblePageRect: visiblePageRect,
      outputScale: outputScale,
      rotationRadians: background.rotationRadians,
      margins: background.margins,
      overscanRatio: PDF_RASTER_OVERSCAN_RATIO,
    };
  }

  private schedulePdfRasterRefresh(delayMs: number = PDF_RASTER_REFRESH_DELAY_MS): void {
    this.cancelPdfRasterRefresh();
    if (!this.lifecycleActive || !this.loaded || this.loadedPageId.length === 0) {
      return;
    }
    this.pdfRasterRefreshTimer = setTimeout((): void => {
      this.pdfRasterRefreshTimer = -1;
      const effective: PageBackground | null = effectivePageBackground(this.currentPage);
      const loaded: LoadedPdfBackground | null = this.pdfBackground;
      if (effective === null || effective.pdf === undefined || effective.pdf === null ||
        loaded === null || loaded.state !== PdfBackgroundLoadState.READY) {
        return;
      }
      const request: PdfRasterRequest | null = this.currentPdfRasterRequest(effective);
      if (request === null || pdfRasterPlanCovers(loaded.rasterPlan, request)) {
        return;
      }
      this.refreshPdfBackground(this.pageLoadGeneration, this.loadedPageId, true);
    }, Math.max(0, delayMs));
  }

  private cancelPdfRasterRefresh(): void {
    if (this.pdfRasterRefreshTimer >= 0) {
      clearTimeout(this.pdfRasterRefreshTimer);
      this.pdfRasterRefreshTimer = -1;
    }
  }

  private releasePdfBackground(): void {
    this.cancelPdfRasterRefresh();
    this.pdfBackgroundGeneration++;
    if (this.pdfBackground !== null && this.pdfBackgroundLoader !== null) {
      this.pdfBackgroundLoader.release(this.pdfBackground);
    }
    this.pdfBackground = null;
  }

  private refreshPaperTexture(pageGeneration: number, pageId: string): void {
    const effective = effectivePageBackground(this.currentPage);
    const legacyPaperIndex: number | null = effective === null || effective.paper === null
      ? null : effective.paper.legacyPaperIndex;
    if (legacyPaperIndex !== null && this.paperTexture !== null &&
      this.paperTexture.legacyPaperIndex === legacyPaperIndex) {
      return;
    }
    this.releasePaperTexture();
    if (legacyPaperIndex === null) {
      return;
    }
    const generation: number = this.paperTextureGeneration;
    const context = getContext(this) as common.UIAbilityContext;
    this.paperTextureLoader.load(context, legacyPaperIndex).then(
      (loaded: LoadedOriginalPaperTexture): void => {
        if (!this.lifecycleActive || pageGeneration !== this.pageLoadGeneration ||
          generation !== this.paperTextureGeneration || this.loadedPageId !== pageId) {
          this.paperTextureLoader.release(loaded);
          return;
        }
        this.paperTexture = loaded;
        if (this.layerManager.isInitialized()) {
          this.renderFrame(true);
        }
      }).catch((error: Object): void => {
        if (generation === this.paperTextureGeneration &&
          pageGeneration === this.pageLoadGeneration && this.loadedPageId === pageId) {
          hilog.warn(0x0001, 'NoteCanvasView',
            'legacy paper texture unavailable index=%{public}d reason=%{public}s',
            legacyPaperIndex, JSON.stringify(error));
        }
      });
  }

  private releasePaperTexture(): void {
    this.paperTextureGeneration++;
    if (this.paperTexture !== null) {
      this.paperTextureLoader.release(this.paperTexture);
      this.paperTexture = null;
    }
  }

  // === T-034：视口操作 ===
  private onViewportChanged(): void {
    this.zoomPercent = Math.round(this.viewport.zoom * 100);
    if (this.selectionVisible) {
      this.updateSelectionOverlay();
    }
    this.renderFrame(true);
    this.schedulePdfRasterRefresh();
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
    this.viewport.stepZoomAt(w / 2, h / 2, delta);
    this.onViewportChanged();
  }

  private zoomFitWidth(): void {
    // T-040 修复：适配宽度以当前纸张实际宽度为基准（mm×3.78），铺满 85% 宽度
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    const paperW: number = this.getPaperWidth();
    const paperH: number = this.getPaperHeight();
    const fit: number = (w * 0.85) / paperW;
    const clamped: number = fit < ORIGINAL_VIEWPORT_MIN_ZOOM ? ORIGINAL_VIEWPORT_MIN_ZOOM :
      (fit > ORIGINAL_VIEWPORT_MAX_ZOOM ? ORIGINAL_VIEWPORT_MAX_ZOOM : fit);
    this.viewport.setZoomRaw(clamped);
    const scrollX: number = (w - paperW * clamped) / 2;
    const scrollY: number = Math.max(16, (h - paperH * clamped) / 2);
    this.viewport.setScroll(scrollX, scrollY);
    this.onViewportChanged();
  }

  // === 触摸事件 ===
  private onCanvasTouch(event: TouchEvent): void {
    if (!this.loaded || this.dataLoading || this.dataLoadFailed || this.historyBusy ||
      this.imageCropVisible || this.mathEditorVisible) {
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
    const canvasP: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
    if (Number.isFinite(canvasP.x) && Number.isFinite(canvasP.y)) {
      // The original Paste command uses the user long-press position as the
      // center of the copied bounds.  Keep the last canvas anchor even when a
      // later context-menu callback runs outside the touch handler.
      this.clipboardPasteTarget = { x: canvasP.x, y: canvasP.y };
    }
    // 原版工具枚举没有 TEXT；移植侧用 DEFAULT 表示临时文本输入模式。
    // 只有该模式响应标准双击，避免橡皮、选区和书写快速点按误建文本框。
    if (this.viewModel.currentTool === ToolType.DEFAULT) {
      if (this.toggleCheckboxMarkerAt(canvasP)) {
        this.lastTapTime = 0;
        return;
      }
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
    // 选区菜单区域：交给 SelectionOverlay 按钮处理，不进入画布逻辑
    // （避免 Canvas onTouch 触发 rebuild 导致按钮 click 识别失效；菜单按钮为屏幕坐标）
    if (this.selectionVisible && this.isInSelectionMenu(touch.x, touch.y)) {
      return;
    }

    this.activePointerId = touch.id;

    if (this.viewModel.isEraserActive()) {
      this.eraserEngine.setMode(this.viewModel.eraserIsPartial ? EraserMode.PARTIAL : EraserMode.WHOLE);
      this.partialEraserPreview.cancel();
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
        this.dragBeforeMathBlocks = this.mathBlocks.slice();
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
    const originalCreate: OriginalInkCreateMetadata | null = this.originalInkReservation;
    this.originalInkReservation = null;
    if (originalCreate !== null) {
      originalCreate.clientTime = Math.max(originalCreate.clientTime, Date.now());
      originalCreate.pencilSeed = startTime | 0;
    }
    // T-040 审核修复：传入当前 zoom（拟合容差按屏幕空间计算）
    this.strokeSession.beginStroke(
      spec, startTime, this.viewport.zoom, this.readRecordingAudioTime(), originalCreate);
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
        this.completedStrokes, this.shapes, this.textBlocks, this.imageBlocks,
        this.selectionGroups, this.mathBlocks);
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
      const selectedMathIds: string[] = this.selectionTool.getState().selectedMathIds.slice();
      const selectedGroupIds: string[] = this.selectionTool.getState().selectedGroupIds.slice();
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
          beforeMathBlocks: this.filterMathBlocksByIds(this.dragBeforeMathBlocks, selectedMathIds),
          afterMathBlocks: this.filterMathBlocksByIds(this.mathBlocks, selectedMathIds),
        });
        this.persist(this.areCanonicalOriginalPositionSelection(
          selectedStrokeIds, selectedShapeIds, selectedTextBlockIds,
          selectedImageIds, selectedMathIds));
        this.notifyUndoRedo();
      }
      this.selectionTool.selectElementIds(
        selectedStrokeIds, selectedShapeIds, selectedTextBlockIds, selectedImageIds,
        selectedGroupIds, selectedMathIds);
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
      this.persist((finalShapes.length === 0 && stroke.originalCreate !== undefined) ||
        (finalShapes.length === 1 && finalShapes[0].originalCreate !== undefined));
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
      const previewCleared: boolean = this.partialEraserPreview.cancel();
      this.resetPointerTracking();
      if (previewCleared && this.layerManager.isInitialized() && this.lifecycleActive) {
        this.renderFrame(true);
      }
      return;
    }
    this.cancelShapeDetectionTimer();
    this.heldShapes = [];
    if (this.strokeSession !== null && this.strokeSession.isActive()) {
      this.strokeSession.cancelStroke();
      this.refreshOriginalInkReservation(this.pageLoadGeneration, this.loadedPageId);
    }
    if (this.selectionDrag) {
      this.completedStrokes = this.dragBeforeStrokes.slice();
      this.shapes = this.dragBeforeShapes.slice();
      this.textBlocks = this.dragBeforeTextBlocks.slice();
      this.imageBlocks = this.dragBeforeImages.slice();
      this.mathBlocks = this.dragBeforeMathBlocks.slice();
      if (this.layerManager.isInitialized()) {
        this.layerManager.rebuildFromStrokes(
          this.completedStrokes, this.renderCtx, this.viewport.zoom);
      }
    }
    if (this.selectionDrawing || this.selectionDrag) {
      this.selectionTool.deselect();
      this.selectionVisible = false;
    }
    this.eraserActive = false;
    this.eraserPath = [];
    this.partialEraserPreview.cancel();
    this.selectionDrawing = false;
    this.selectionDrag = false;
    this.dragBeforeStrokes = [];
    this.dragBeforeShapes = [];
    this.dragBeforeTextBlocks = [];
    this.dragBeforeImages = [];
    this.dragBeforeMathBlocks = [];
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
      result.elements, stroke.id, stroke.renderSpec.color, stroke.renderSpec.brushWidth,
      this.originalToolForStroke(stroke), this.originalStyleForStroke(stroke),
      stroke.originalCreate === undefined ? undefined : {
        timestamp: stroke.originalCreate.timestamp, siteId: stroke.originalCreate.siteId,
        clientTime: stroke.originalCreate.clientTime,
        pageTimestamp: stroke.originalCreate.pageTimestamp,
        pageSiteId: stroke.originalCreate.pageSiteId, pageIndex: stroke.originalCreate.pageIndex,
        pencilSeed: stroke.originalCreate.pencilSeed,
        averageForce: this.averageStrokeForce(stroke),
      });
    return { shapes: shapes, replaced: shapes.length > 0 };
  }

  // 识别元素 → 形状笔画（采样点序列，保持渲染链不变）
  // === 橡皮擦 ===
  private applyEraser(): void {
    if (this.eraserEngine.getMode() === EraserMode.PARTIAL) {
      const eraserPath: Point2D[] = this.partialEraserPreview.getPath();
      const previewToken: number | null = this.partialEraserPreview.finish();
      if (previewToken === null || eraserPath.length === 0) {
        this.partialEraserPreview.cancel();
        this.renderFrame(true);
        return;
      }
      const strokeReplacements =
        new OriginalInkPartialEraser(this.eraserEngine.getWidth()).erase(
          eraserPath, this.partialEraserCandidateStrokes());
      const shapeReplacements: ShapePartialEraseReplacement[] =
        new OriginalShapePartialEraser(this.eraserEngine.getWidth()).erase(
          eraserPath, this.shapes);
      const replacements: OriginalPartialEraseReplacementPlan[] = [];
      for (const replacement of strokeReplacements) {
        replacements.push({
          sourceKind: PageElementKind.STROKE,
          source: replacement.sourceStroke,
          remnants: replacement.remnants,
        });
      }
      for (const replacement of shapeReplacements) {
        replacements.push({
          sourceKind: PageElementKind.SHAPE,
          source: replacement.sourceShape,
          remnants: replacement.remnants,
        });
      }
      if (replacements.length === 0) {
        this.partialEraserPreview.complete(previewToken);
        this.renderFrame(true);
        return;
      }
      const orderRanks: Map<string, number> = new Map<string, number>();
      for (let index: number = 0; index < this.elementOrder.length; index++) {
        const ref: PageElementRef = this.elementOrder[index];
        orderRanks.set(`${ref.kind}:${ref.elementId}`, index);
      }
      replacements.sort((left: OriginalPartialEraseReplacementPlan,
        right: OriginalPartialEraseReplacementPlan): number =>
        (orderRanks.get(`${left.sourceKind}:${left.source.id}`) ?? Number.MAX_SAFE_INTEGER) -
        (orderRanks.get(`${right.sourceKind}:${right.source.id}`) ?? Number.MAX_SAFE_INTEGER));
      const plan: OriginalPartialErasePlan = {
        replacements: replacements,
      };
      if (this.canCommitOriginalPartialErase(plan)) {
        this.commitOriginalPartialErase(plan, previewToken);
      } else {
        this.partialEraserPreview.complete(previewToken);
        this.applyPartialEraseLocally(plan);
        this.renderFrame(true);
      }
      return;
    }
    if (this.eraserPath.length === 0) {
      return;
    }
    const before: StrokeElementData[] = this.completedStrokes.slice();
    const beforeShapes: ShapeElement[] = this.shapes.slice();
    const beforeTextBlocks: TextBlockElement[] = this.textBlocks.slice();
    const beforeImages: ImageElement[] = this.imageBlocks.slice();
    const beforeMathBlocks: MathElement[] = this.mathBlocks.slice();
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
    const eraseObjects: boolean = true;
    const removedShapes: ShapeElement[] = [];
    const removedShapeIndices: number[] = [];
    for (let shapeIndex: number = 0; shapeIndex < beforeShapes.length; shapeIndex++) {
      const shape: ShapeElement = beforeShapes[shapeIndex];
      if (eraseObjects && eraserPathHitsShape(this.eraserPath, shape, this.eraserEngine.getWidth())) {
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
      if (eraseObjects && eraserPathHitsTextBlock(this.eraserPath, textBlock, this.eraserEngine.getWidth())) {
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
      if (eraseObjects && eraserPathHitsImageBlock(this.eraserPath, image, this.eraserEngine.getWidth())) {
        removedImages.push(image);
        removedImageIndices.push(imageIndex);
        this.removeImageById(image.id);
      }
    }
    const removedImageIds: string[] = removedImages.map((image: ImageElement): string => image.id);
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.IMAGE, removedImageIds);
    const removedMathBlocks: MathElement[] = [];
    const removedMathBlockIndices: number[] = [];
    for (let mathIndex: number = 0; mathIndex < beforeMathBlocks.length; mathIndex++) {
      const math: MathElement = beforeMathBlocks[mathIndex];
      if (eraseObjects && eraserPathHitsMathBlock(this.eraserPath, math, this.eraserEngine.getWidth())) {
        removedMathBlocks.push(math);
        removedMathBlockIndices.push(mathIndex);
        this.removeMathBlockById(math.id);
      }
    }
    const removedMathIds: string[] = removedMathBlocks.map((math: MathElement): string => math.id);
    this.elementOrder = removePageElementRefs(
      this.elementOrder, PageElementKind.MATH, removedMathIds);
    const changed: boolean = removed.length > 0 || removedShapes.length > 0 ||
      removedTextBlocks.length > 0 || removedImages.length > 0 || removedMathBlocks.length > 0;
    if (changed) {
      this.undoRedo.push({
        type: UndoableActionType.ERASE_ELEMENTS,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        removedStrokes: removed,
        removedStrokeIndices: removedIndices,
        addedStrokes: [],
        beforeModifiedStrokes: [],
        afterModifiedStrokes: [],
        removedShapes: removedShapes,
        removedShapeIndices: removedShapeIndices,
        removedTextBlocks: removedTextBlocks,
        removedTextBlockIndices: removedTextBlockIndices,
        removedImages: removedImages,
        removedImageIndices: removedImageIndices,
        removedMathBlocks: removedMathBlocks,
        removedMathBlockIndices: removedMathBlockIndices,
        elementOrderBefore: elementOrderBefore,
        elementOrderAfter: clonePageElementOrder(this.elementOrder),
      });
    }
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    const originalEntityOnly: boolean =
      (removed.length > 0 || removedShapes.length > 0 || removedTextBlocks.length > 0 ||
        removedImages.length > 0 || removedMathBlocks.length > 0) &&
      this.areCanonicalOriginalPositionSelection(
        removed.map((stroke: StrokeElementData): string => stroke.id),
        removedShapes.map((shape: ShapeElement): string => shape.id),
        removedTextBlocks.map((text: TextBlockElement): string => text.id),
        removedImages.map((image: ImageElement): string => image.id),
        removedMathBlocks.map((math: MathElement): string => math.id));
    if (changed) {
      this.persist(originalEntityOnly);
    }
    this.notifyUndoRedo();
    if (removedImages.length > 0) {
      this.refreshImageAssets(this.pageLoadGeneration, this.loadedPageId);
    }
  }

  private partialEraserCandidateStrokes(): StrokeElementData[] {
    return this.completedStrokes.slice();
  }

  private canCommitOriginalPartialErase(plan: OriginalPartialErasePlan): boolean {
    if (this.originalInkIneligiblePages.has(this.loadedPageId)) {
      return false;
    }
    const strokeIds: string[] = [];
    const shapeIds: string[] = [];
    for (const replacement of plan.replacements) {
      if (replacement.sourceKind === PageElementKind.STROKE) {
        strokeIds.push(replacement.source.id);
      } else if (replacement.sourceKind === PageElementKind.SHAPE) {
        shapeIds.push(replacement.source.id);
      } else {
        return false;
      }
    }
    if (!this.areCanonicalOriginalPositionSelection(strokeIds, shapeIds, [], [], [])) {
      return false;
    }
    try {
      validateOriginalPartialErasePlan(plan);
      return true;
    } catch (_error) {
      return false;
    }
  }

  private commitOriginalPartialErase(plan: OriginalPartialErasePlan,
    previewToken: number): void {
    const generation: number = this.pageLoadGeneration;
    const pageId: string = this.loadedPageId;
    const draftOperation: Op = {
      opId: 'pending-original-partial-erase', noteId: this.noteId,
      opType: OpType.ORIGINAL_PARTIAL_ERASE, payload: new Uint8Array(0), clientTime: 0,
    };
    const draft: OriginalPartialEraseAction = {
      type: UndoableActionType.ORIGINAL_PARTIAL_ERASE,
      noteId: this.noteId, pageId: pageId, operation: draftOperation,
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(draft);
    this.historyBusy = true;
    this.invalidateOriginalInkReservation();
    this.persistence.commitOriginalPartialErase(this.noteId, pageId, plan, prepared).then(
      (result: OriginalPartialErasePersistenceResult): void => {
        this.partialEraserPreview.complete(previewToken);
        try {
          const action: OriginalPartialEraseAction = {
            type: UndoableActionType.ORIGINAL_PARTIAL_ERASE,
            noteId: this.noteId, pageId: pageId, operation: result.operation,
          };
          this.undoRedo.push(action, prepared);
          this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
          if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
            pageId === this.currentPage.pageId && this.loaded && !this.dataLoading &&
            !this.dataLoadFailed) {
            this.installMutationElements(result.elements);
            this.selectionGroups = result.groups;
            this.selectionTool.deselect();
            this.selectionVisible = false;
            this.originalInkIneligiblePages.delete(pageId);
            this.layerManager.rebuildFromStrokes(
              this.completedStrokes, this.renderCtx, this.viewport.zoom);
            this.renderFrame();
          }
          this.notifyUndoRedo();
        } catch (e) {
          // The durable transaction has already committed. Never reinterpret a
          // local UI/history installation failure as permission to apply the
          // replacement a second time through the snapshot fallback.
          hilog.error(0x0001, 'NoteCanvasView',
            'original partial erase committed but UI install failed: %{public}s', JSON.stringify(e));
          if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
            pageId === this.currentPage.pageId && this.lifecycleActive) {
            this.pageLoadPromise = this.loadNoteData();
          }
        }
      }, (e: Object): void => {
        this.partialEraserPreview.complete(previewToken);
        this.reportSaveFailure(e);
        hilog.error(0x0001, 'NoteCanvasView',
          'original partial erase transaction failed: %{public}s', JSON.stringify(e));
        if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
          pageId === this.currentPage.pageId && this.loaded && !this.dataLoading &&
          !this.dataLoadFailed) {
          this.applyPartialEraseLocally(plan, prepared);
          this.renderFrame(true);
        }
      }).finally((): void => {
        const previewCleared: boolean = this.partialEraserPreview.complete(previewToken);
        this.historyBusy = false;
        if (previewCleared && generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
          this.layerManager.isInitialized() && this.lifecycleActive) {
          this.renderFrame(true);
        }
        if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
          !this.originalInkIneligiblePages.has(pageId)) {
          this.refreshOriginalInkReservation(generation, pageId);
        }
      });
  }

  private applyPartialEraseLocally(plan: OriginalPartialErasePlan,
    history?: HistoryMetadata): void {
    if (plan.replacements.length === 0) {
      return;
    }
    try {
      // A failed original preflight is not permission to delete the source in
      // the snapshot fallback.  Match wc/u5j's all-or-nothing materialization:
      // every remnant must be representable as CREATE_INK before local state
      // or history is touched, even when the source itself has a local ID.
      validatePartialEraseMaterializationPlan(plan);
    } catch (_error) {
      return;
    }
    const planByKey: Map<string, OriginalPartialEraseReplacementPlan> =
      new Map<string, OriginalPartialEraseReplacementPlan>();
    const sourceIds: Set<string> = new Set<string>();
    for (const replacement of plan.replacements) {
      if ((replacement.sourceKind !== PageElementKind.STROKE &&
        replacement.sourceKind !== PageElementKind.SHAPE) || replacement.source.id.length === 0 ||
        sourceIds.has(replacement.source.id)) {
        return;
      }
      sourceIds.add(replacement.source.id);
      planByKey.set(`${replacement.sourceKind}:${replacement.source.id}`, replacement);
    }
    const existingElementIds: Set<string> = new Set<string>();
    for (const ref of this.elementOrder) {
      existingElementIds.add(ref.elementId);
    }
    const remnantIds: Set<string> = new Set<string>();
    for (const replacement of plan.replacements) {
      for (const remnant of replacement.remnants) {
        if (remnant.id.length === 0 || sourceIds.has(remnant.id) ||
          existingElementIds.has(remnant.id) || remnantIds.has(remnant.id)) {
          return;
        }
        remnantIds.add(remnant.id);
      }
    }
    const sourceRefs: PageElementRef[] = [];
    for (const ref of this.elementOrder) {
      if (planByKey.has(`${ref.kind}:${ref.elementId}`)) {
        sourceRefs.push({ kind: ref.kind, elementId: ref.elementId, zIndex: ref.zIndex });
      }
    }
    if (sourceRefs.length !== plan.replacements.length) {
      return;
    }
    const added: StrokeElementData[] = [];
    const addedCounts: number[] = [];
    const groupReplacements: OriginalPartialEraseGroupReplacement[] = [];
    for (const ref of sourceRefs) {
      const replacement: OriginalPartialEraseReplacementPlan | undefined =
        planByKey.get(`${ref.kind}:${ref.elementId}`);
      if (replacement === undefined) {
        return;
      }
      addedCounts.push(replacement.remnants.length);
      for (const remnant of replacement.remnants) {
        added.push(remnant);
      }
      groupReplacements.push({
        sourceId: ref.elementId,
        remnantIds: replacement.remnants.map(
          (remnant: StrokeElementData): string => remnant.id),
      });
    }
    const replacementByKey: Map<string, PartialEraseElementReplacement> | null =
      buildPartialEraseElementReplacementMap(sourceRefs, added, addedCounts);
    if (replacementByKey === null) {
      return;
    }
    let groupPlan: OriginalPartialEraseGroupPlan;
    try {
      groupPlan = planLocalPartialEraseGroups(this.selectionGroups, groupReplacements);
    } catch (_error) {
      return;
    }
    const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const elementOrderAfter: PageElementRef[] | null = partialEraseMixedElementOrder(
      this.elementOrder, replacementByKey);
    if (elementOrderAfter === null) {
      return;
    }
    const sourceStrokeIds: Set<string> = new Set<string>();
    const sourceShapeIds: Set<string> = new Set<string>();
    for (const ref of sourceRefs) {
      if (ref.kind === PageElementKind.STROKE) {
        sourceStrokeIds.add(ref.elementId);
      } else {
        sourceShapeIds.add(ref.elementId);
      }
    }
    const removed: StrokeElementData[] = [];
    const removedIndices: number[] = [];
    const retainedStrokesById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
    for (let index: number = 0; index < this.completedStrokes.length; index++) {
      const stroke: StrokeElementData = this.completedStrokes[index];
      if (sourceStrokeIds.has(stroke.id)) {
        removed.push(stroke);
        removedIndices.push(index);
      } else if (retainedStrokesById.has(stroke.id)) {
        return;
      } else {
        retainedStrokesById.set(stroke.id, stroke);
      }
    }
    const removedShapes: ShapeElement[] = [];
    const removedShapeIndices: number[] = [];
    const nextShapes: ShapeElement[] = [];
    for (let index: number = 0; index < this.shapes.length; index++) {
      const shape: ShapeElement = this.shapes[index];
      if (sourceShapeIds.has(shape.id)) {
        removedShapes.push(shape);
        removedShapeIndices.push(index);
      } else {
        nextShapes.push(shape);
      }
    }
    if (removed.length !== sourceStrokeIds.size || removedShapes.length !== sourceShapeIds.size) {
      return;
    }
    const addedById: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
    for (const remnant of added) {
      addedById.set(remnant.id, remnant);
    }
    const next: StrokeElementData[] = [];
    const nextIds: Set<string> = new Set<string>();
    for (const ref of elementOrderAfter) {
      if (ref.kind !== PageElementKind.STROKE) {
        continue;
      }
      const stroke: StrokeElementData | undefined =
        retainedStrokesById.get(ref.elementId) ?? addedById.get(ref.elementId);
      if (stroke === undefined || nextIds.has(stroke.id)) {
        return;
      }
      nextIds.add(stroke.id);
      next.push(stroke);
    }
    if (next.length !== retainedStrokesById.size + added.length) {
      return;
    }
    const nextStrokeIndexById: Map<string, number> = new Map<string, number>();
    for (let index: number = 0; index < next.length; index++) {
      nextStrokeIndexById.set(next[index].id, index);
    }
    const addedIndices: number[] = [];
    for (const remnant of added) {
      const index: number | undefined = nextStrokeIndexById.get(remnant.id);
      if (index === undefined || (addedIndices.length > 0 &&
        index <= addedIndices[addedIndices.length - 1])) {
        return;
      }
      addedIndices.push(index);
    }
    if (!validatePartialEraseElementHistoryState(
      this.completedStrokes, this.shapes, sourceRefs, removed, removedIndices,
      removedShapes, removedShapeIndices, added, addedIndices, addedCounts, false)) {
      return;
    }
    this.completedStrokes = next;
    this.shapes = nextShapes;
    this.elementOrder = elementOrderAfter;
    this.undoRedo.push({
      type: UndoableActionType.ERASE_ELEMENTS,
      noteId: this.noteId,
      pageId: this.currentPage.pageId,
      removedStrokes: removed,
      removedStrokeIndices: removedIndices,
      addedStrokes: added,
      addedStrokeIndices: addedIndices,
      addedStrokeCounts: addedCounts,
      partialEraseSourceRefs: sourceRefs,
      partialEraseBeforeGroups: groupPlan.beforeGroups,
      partialEraseAfterGroups: groupPlan.afterGroups,
      beforeModifiedStrokes: [],
      afterModifiedStrokes: [],
      removedShapes: removedShapes,
      removedShapeIndices: removedShapeIndices,
      removedTextBlocks: [],
      removedTextBlockIndices: [],
      removedImages: [],
      removedImageIndices: [],
      removedMathBlocks: [],
      removedMathBlockIndices: [],
      elementOrderBefore: elementOrderBefore,
      elementOrderAfter: clonePageElementOrder(elementOrderAfter),
    }, history);
    this.selectionGroups = groupPlan.groups;
    this.originalInkIneligiblePages.add(this.loadedPageId);
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    this.persist(false);
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private collectEraserPoint(touch: TouchObject): void {
    const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
    const point: Point2D = {
      x: Math.min(Math.max(p.x, 0), this.getPaperWidth()),
      y: Math.min(Math.max(p.y, 0), this.getPaperHeight()),
    };
    if (this.eraserEngine.getMode() === EraserMode.PARTIAL) {
      let changed: boolean = false;
      try {
        if (this.partialEraserPreview.getPhase() !== OriginalPartialEraserPreviewPhase.TRACKING) {
          this.partialEraserPreview.begin(point, this.eraserEngine.getWidth());
          changed = true;
        } else {
          changed = this.partialEraserPreview.append(point);
        }
      } catch (e) {
        this.partialEraserPreview.cancel();
        hilog.error(0x0001, 'NoteCanvasView',
          'partial eraser preview rejected input: %{public}s', JSON.stringify(e));
      }
      if (changed) {
        this.renderFrame();
      } else if (this.partialEraserPreview.isFailed()) {
        this.renderFrame(true);
      }
      return;
    }
    this.eraserPath.push(point);
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
    if (this.imageCropVisible) {
      this.cancelImageCrop();
    }
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
    if (group.length > 1) {
      if (!this.isSinglePageElementGroup(group)) {
        hilog.error(0x0001, 'NoteCanvasView',
          'history group crossed its note/page/type domain; refusing a partial move');
        return;
      }
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
    if (action.type === UndoableActionType.GROUP_ELEMENTS) {
      if (group.length !== 1) {
        hilog.error(0x0001, 'NoteCanvasView', 'Group history cannot be coalesced');
        return;
      }
      if (action.pageId !== this.loadedPageId) {
        this.pendingHistoryDirection = isUndo ? -1 : 1;
        this.onRequestPage(action.pageId);
        return;
      }
      if (!this.validateActionState(action, isUndo)) {
        hilog.error(0x0001, 'NoteCanvasView', 'Group history source state is stale');
        return;
      }
      const history: HistoryMetadata | null = this.undoRedo.getHistoryMetadataForMove(action, isUndo);
      if (history === null) {
        hilog.error(0x0001, 'NoteCanvasView', 'Group history metadata is stale');
        return;
      }
      this.historyBusy = true;
      this.applyOriginalGroupHistoryMove(action, isUndo, history).finally((): void => {
        this.historyBusy = false;
      });
      return;
    }
    if (action.type === UndoableActionType.ORIGINAL_CLIPBOARD_PASTE) {
      if (group.length !== 1) {
        hilog.error(0x0001, 'NoteCanvasView', 'original clipboard Paste history cannot be coalesced');
        return;
      }
      if (action.pageId !== this.loadedPageId) {
        this.pendingHistoryDirection = isUndo ? -1 : 1;
        this.onRequestPage(action.pageId);
        return;
      }
      if (!this.validateOriginalClipboardPasteActionState(action, isUndo)) {
        hilog.error(0x0001, 'NoteCanvasView',
          'original clipboard Paste history source state is stale');
        return;
      }
      const history: HistoryMetadata | null =
        this.undoRedo.getHistoryMetadataForMove(action, isUndo);
      if (history === null) {
        hilog.error(0x0001, 'NoteCanvasView',
          'original clipboard Paste history metadata is stale');
        return;
      }
      this.historyBusy = true;
      this.applyOriginalClipboardPasteHistoryMove(action, isUndo, history).finally((): void => {
        this.historyBusy = false;
      });
      return;
    }
    if (action.type === UndoableActionType.ORIGINAL_PARTIAL_ERASE) {
      if (group.length !== 1) {
        hilog.error(0x0001, 'NoteCanvasView',
          'original partial erase history cannot be coalesced');
        return;
      }
      if (action.pageId !== this.loadedPageId) {
        this.pendingHistoryDirection = isUndo ? -1 : 1;
        this.onRequestPage(action.pageId);
        return;
      }
      if (!this.validateOriginalPartialEraseActionState(action, isUndo)) {
        hilog.error(0x0001, 'NoteCanvasView',
          'original partial erase history source state is stale');
        return;
      }
      const history: HistoryMetadata | null =
        this.undoRedo.getHistoryMetadataForMove(action, isUndo);
      if (history === null) {
        hilog.error(0x0001, 'NoteCanvasView',
          'original partial erase history metadata is stale');
        return;
      }
      this.historyBusy = true;
      this.applyOriginalPartialEraseHistoryMove(action, isUndo, history).finally((): void => {
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

  private async applyOriginalGroupHistoryMove(action: GroupElementsAction, isUndo: boolean,
    history: HistoryMetadata): Promise<void> {
    const mutation: OriginalGroupMutationOpPayload = {
      pageId: action.pageId,
      beforeGroups: action.beforeGroups,
      afterGroups: action.afterGroups,
      elementOrderBefore: action.elementOrderBefore,
      elementOrderAfter: action.elementOrderAfter,
    };
    try {
      const result: OriginalGroupMutationResult = await this.persistence.applyOriginalGroupHistory(
        this.noteId, mutation, !isUndo, history);
      const committed: boolean = isUndo ?
        this.undoRedo.commitUndo(action) : this.undoRedo.commitRedo(action);
      if (!committed) {
        throw new Error('Group history stack changed after durable apply');
      }
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.selectionGroups = result.groups;
      this.elementOrder = clonePageElementOrder(
        isUndo ? action.elementOrderBefore : action.elementOrderAfter);
      this.synchronizeElementArraysByOrder();
      this.selectionTool.deselect();
      this.selectionVisible = false;
      this.originalInkIneligiblePages.delete(action.pageId);
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
      this.renderFrame();
      this.notifyUndoRedo();
    } catch (e) {
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'Group history apply failed: %{public}s', JSON.stringify(e));
    }
  }

  private async applyOriginalClipboardPasteHistoryMove(
    action: OriginalClipboardPasteAction, isUndo: boolean,
    history: HistoryMetadata): Promise<void> {
    try {
      const mutation: OriginalClipboardPasteMutation =
        decodeOriginalClipboardPasteMutation(action.operation.payload);
      const result: OriginalClipboardPasteHistoryResult =
        await this.persistence.applyOriginalClipboardPasteHistory(
          this.noteId, mutation, !isUndo, history);
      const committed: boolean = isUndo ?
        this.undoRedo.commitUndo(action) : this.undoRedo.commitRedo(action);
      if (!committed) {
        throw new Error('original clipboard Paste history stack changed after durable apply');
      }
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.installMutationElements(result.elements);
      this.selectionGroups = result.groups;
      this.selectionTool.deselect();
      this.selectionVisible = false;
      this.originalInkIneligiblePages.delete(action.pageId);
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
      this.renderFrame();
      this.notifyUndoRedo();
    } catch (e) {
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'original clipboard Paste history apply failed: %{public}s', JSON.stringify(e));
    }
  }

  private async applyOriginalPartialEraseHistoryMove(
    action: OriginalPartialEraseAction, isUndo: boolean,
    history: HistoryMetadata): Promise<void> {
    try {
      const mutation: OriginalPartialEraseMutation =
        decodeOriginalPartialEraseMutation(action.operation.payload);
      const result: OriginalPartialEraseHistoryResult =
        await this.persistence.applyOriginalPartialEraseHistory(
          this.noteId, mutation, !isUndo, history);
      const committed: boolean = isUndo ?
        this.undoRedo.commitUndo(action) : this.undoRedo.commitRedo(action);
      if (!committed) {
        throw new Error('original partial erase history stack changed after durable apply');
      }
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.installMutationElements(result.elements);
      this.selectionGroups = result.groups;
      this.selectionTool.deselect();
      this.selectionVisible = false;
      this.originalInkIneligiblePages.delete(action.pageId);
      this.invalidateOriginalInkReservation();
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
      this.renderFrame();
      this.notifyUndoRedo();
      this.refreshOriginalInkReservation(this.pageLoadGeneration, action.pageId);
    } catch (e) {
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'original partial erase history apply failed: %{public}s', JSON.stringify(e));
    }
  }

  private isSinglePageElementGroup(group: HistoryMove[]): boolean {
    if (group.length === 0 || this.isPageAction(group[0].action.type) ||
      group[0].action.type === UndoableActionType.GROUP_ELEMENTS ||
      group[0].action.type === UndoableActionType.ORIGINAL_CLIPBOARD_PASTE ||
      group[0].action.type === UndoableActionType.ORIGINAL_PARTIAL_ERASE) {
      return false;
    }
    const pageId: string = group[0].action.pageId;
    for (const move of group) {
      if (move.action.noteId !== this.noteId || move.action.pageId !== pageId ||
        this.isPageAction(move.action.type) || move.action.type === UndoableActionType.GROUP_ELEMENTS ||
        move.action.type === UndoableActionType.ORIGINAL_CLIPBOARD_PASTE ||
        move.action.type === UndoableActionType.ORIGINAL_PARTIAL_ERASE) {
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
      this.invalidateOriginalInkReservation();
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
      const originalInkOnly: boolean = group.every((move: HistoryMove): boolean =>
        this.isOriginalInkAction(move.action));
      if (originalInkOnly) {
        this.originalInkIneligiblePages.delete(this.loadedPageId);
        this.refreshOriginalInkReservation(this.pageLoadGeneration, this.loadedPageId);
      } else {
        this.originalInkIneligiblePages.add(this.loadedPageId);
      }
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
      mathBlocks: this.mathBlocks.map((math: MathElement): MathElement => cloneMathElement(math)),
      history: history,
    };
  }

  private restoreHistoryPage(elements: SearchSourceElement[]): void {
    this.installMutationElements(elements);
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    this.renderFrame();
  }

  private commitHistory(action: UndoableAction, isUndo: boolean): void {
    const committed: boolean = isUndo
      ? this.undoRedo.commitUndo(action) : this.undoRedo.commitRedo(action);
    if (!committed) {
      hilog.error(0x0001, 'NoteCanvasView', 'history commit rejected after apply, type=%{public}d', action.type);
    } else if (!this.isPageAction(action.type)) {
      this.persist(this.isOriginalInkAction(action));
    }
    this.notifyUndoRedo();
  }

  private isOriginalInkAction(action: UndoableAction): boolean {
    if (action.type === UndoableActionType.ADD_ELEMENTS) {
      if (action.addedImages.length > 0 || (action.addedMathBlocks ?? []).length > 0 ||
        action.addedStrokes.length + action.addedShapes.length + action.addedTextBlocks.length !== 1) {
        return false;
      }
      if (action.addedStrokes.length === 1) {
        return action.addedStrokes[0].originalCreate !== undefined &&
          this.areCanonicalOriginalStrokes(action.addedStrokes);
      }
      if (action.addedShapes.length === 1) {
        return action.addedShapes[0].originalCreate !== undefined &&
          this.areCanonicalOriginalPositionSelection([], [action.addedShapes[0].id], [], [], []);
      }
      return action.addedTextBlocks[0].originalCreate !== undefined &&
        this.areCanonicalOriginalPositionSelection([], [], [action.addedTextBlocks[0].id], [], []);
    }
    if (action.type === UndoableActionType.ADD_STROKE) {
      return action.addedStrokes.length === 1 && action.addedStrokes[0].originalCreate !== undefined &&
        this.areCanonicalOriginalStrokes(action.addedStrokes);
    }
    if (action.type === UndoableActionType.ADD_ELEMENT) {
      return action.addedElement.originalCreate !== undefined &&
        this.areCanonicalOriginalPositionSelection([], [], [action.addedElement.id], [], []);
    }
    if (action.type === UndoableActionType.DELETE_ELEMENT) {
      return this.areCanonicalOriginalPositionSelection([], [], action.removedElements.map(
        (text: TextBlockElement): string => text.id), [], []);
    }
    if (action.type === UndoableActionType.DELETE_STROKE) {
      return action.beforeModifiedStrokes.length === 0 && action.afterModifiedStrokes.length === 0 &&
        this.areCanonicalOriginalStrokes(action.removedStrokes);
    }
    if (action.type === UndoableActionType.ERASE_ELEMENTS) {
      if ((action.partialEraseSourceRefs ?? []).length > 0 ||
        (action.addedStrokeCounts ?? []).length > 0) {
        return false;
      }
      return (action.addedStrokes ?? []).length === 0 &&
        action.beforeModifiedStrokes.length === 0 && action.afterModifiedStrokes.length === 0 &&
        this.areCanonicalOriginalPositionSelection(
        action.removedStrokes.map((stroke: StrokeElementData): string => stroke.id),
        action.removedShapes.map((shape: ShapeElement): string => shape.id),
        action.removedTextBlocks.map((text: TextBlockElement): string => text.id),
        action.removedImages.map((image: ImageElement): string => image.id),
        (action.removedMathBlocks ?? []).map((math: MathElement): string => math.id));
    }
    if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      return this.areCanonicalOriginalPositionSelection(
        action.removedStrokes.map((stroke: StrokeElementData): string => stroke.id),
        action.removedShapes.map((shape: ShapeElement): string => shape.id),
        action.removedTextBlocks.map((text: TextBlockElement): string => text.id),
        action.removedImages.map((image: ImageElement): string => image.id),
        (action.removedMathBlocks ?? []).map((math: MathElement): string => math.id));
    }
    if (action.type === UndoableActionType.TRANSFORM_STROKES) {
      return this.areCanonicalOriginalStrokes(action.beforeStrokes) &&
        this.areCanonicalOriginalStrokes(action.afterStrokes) &&
        this.sameStrokeIds(action.beforeStrokes, action.afterStrokes);
    }
    if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
      return this.areCanonicalOriginalPositionSelection(
        action.beforeStrokes.map((stroke: StrokeElementData): string => stroke.id),
        action.beforeShapes.map((shape: ShapeElement): string => shape.id),
        action.beforeTextBlocks.map((text: TextBlockElement): string => text.id),
        action.beforeImages.map((image: ImageElement): string => image.id),
        (action.beforeMathBlocks ?? []).map((math: MathElement): string => math.id));
    }
    if (action.type === UndoableActionType.REORDER_ELEMENTS) {
      const ids: string[] = action.elementOrderBefore.map(
        (ref: PageElementRef): string => ref.elementId);
      return samePageElementMembers(action.elementOrderBefore, action.elementOrderAfter) &&
        this.areCanonicalOriginalPositionSelection(ids, [], [], [], []);
    }
    return false;
  }

  private areCanonicalOriginalStrokes(strokes: StrokeElementData[]): boolean {
    if (strokes.length === 0) {
      return false;
    }
    for (const stroke of strokes) {
      if (decodeOperationId(stroke.id) === null) {
        return false;
      }
    }
    return true;
  }

  private areCanonicalOriginalPositionSelection(strokeIds: string[], shapeIds: string[],
    textIds: string[], imageIds: string[], mathIds: string[]): boolean {
    const ids: string[] = strokeIds.concat(shapeIds).concat(textIds).concat(imageIds).concat(mathIds);
    if (ids.length === 0) {
      return false;
    }
    for (const id of ids) {
      if (decodeOperationId(id) === null) {
        return false;
      }
    }
    return true;
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
      type === UndoableActionType.REORDER_PAGES || type === UndoableActionType.PAGE_SETTINGS ||
      type === UndoableActionType.NOTE_BACKGROUND || type === UndoableActionType.NOTE_TITLE;
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
      const removedMathBlocks: MathElement[] = action.removedMathBlocks ?? [];
      const removedMathBlockIndices: number[] = action.removedMathBlockIndices ?? [];
      const addedStrokes: StrokeElementData[] = action.addedStrokes ?? [];
      const addedStrokeIndices: number[] = action.addedStrokeIndices ?? [];
      const addedStrokeCounts: number[] = action.addedStrokeCounts ?? [];
      const hasPartialReplacement: boolean = (action.partialEraseSourceRefs ?? []).length > 0 ||
        addedStrokes.length > 0 ||
        addedStrokeIndices.length > 0 || addedStrokeCounts.length > 0;
      const partialTargetGroups: OriginalSelectionGroup[] | null = hasPartialReplacement ?
        replayOriginalPartialEraseGroups(
          this.selectionGroups, action.partialEraseBeforeGroups ?? [],
          action.partialEraseAfterGroups ?? [], !isUndo) : [];
      if (partialTargetGroups === null) {
        return false;
      }
      if (isUndo) {
        for (const stroke of addedStrokes) {
          this.removeStrokeById(stroke.id);
        }
        this.restoreRemovedStrokes(action.removedStrokes, action.removedStrokeIndices);
        this.restoreRemovedShapes(action.removedShapes, action.removedShapeIndices);
        this.restoreRemovedTextBlocks(action.removedTextBlocks, action.removedTextBlockIndices);
        this.restoreRemovedImages(action.removedImages, action.removedImageIndices);
        this.restoreRemovedMathBlocks(removedMathBlocks, removedMathBlockIndices);
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
        for (const math of removedMathBlocks) {
          this.removeMathBlockById(math.id);
        }
        this.restoreRemovedStrokes(addedStrokes, addedStrokeIndices);
        this.replaceStrokesById(action.afterModifiedStrokes);
      }
      if (hasPartialReplacement) {
        this.selectionGroups = partialTargetGroups;
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
      const addedMathBlocks: MathElement[] = action.addedMathBlocks ?? [];
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
        for (const math of addedMathBlocks) {
          this.removeMathBlockById(math.id);
        }
      } else {
        this.completedStrokes = this.completedStrokes.concat(action.addedStrokes);
        this.shapes = this.shapes.concat(action.addedShapes);
        this.textBlocks = this.textBlocks.concat(action.addedTextBlocks);
        this.imageBlocks = this.imageBlocks.concat(action.addedImages);
        this.mathBlocks = this.mathBlocks.concat(addedMathBlocks);
      }
    } else if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      const removedMathBlocks: MathElement[] = action.removedMathBlocks ?? [];
      const removedMathBlockIndices: number[] = action.removedMathBlockIndices ?? [];
      if (isUndo) {
        this.restoreRemovedStrokes(action.removedStrokes, action.removedStrokeIndices);
        this.restoreRemovedShapes(action.removedShapes, action.removedShapeIndices);
        this.restoreRemovedTextBlocks(action.removedTextBlocks, action.removedTextBlockIndices);
        this.restoreRemovedImages(action.removedImages, action.removedImageIndices);
        this.restoreRemovedMathBlocks(removedMathBlocks, removedMathBlockIndices);
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
        for (const math of removedMathBlocks) {
          this.removeMathBlockById(math.id);
        }
      }
    } else if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
      this.replaceStrokesById(isUndo ? action.beforeStrokes : action.afterStrokes);
      this.replaceShapesById(isUndo ? action.beforeShapes : action.afterShapes);
      this.replaceTextBlocksById(isUndo ? action.beforeTextBlocks : action.afterTextBlocks);
      this.replaceImagesById(isUndo ? action.beforeImages : action.afterImages);
      this.replaceMathBlocksById(isUndo ? (action.beforeMathBlocks ?? []) : (action.afterMathBlocks ?? []));
    } else if (action.type === UndoableActionType.PERSISTED_PAGE_MUTATIONS) {
      if (!this.applyPersistedPageMutations(action.operations, isUndo)) {
        return false;
      }
    } else if (action.type === UndoableActionType.GROUP_ELEMENTS) {
      this.applyGroupActionState(action, isUndo);
    } else {
      hilog.error(0x0001, 'NoteCanvasView', 'unsupported history action type=%{public}d', action.type);
      return false;
    }
    const targetOrder: PageElementRef[] | null = this.getActionTargetOrder(action, isUndo);
    if (targetOrder !== null) {
      this.elementOrder = clonePageElementOrder(targetOrder);
      this.synchronizeElementArraysByOrder();
    }
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
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
    if (action.type === UndoableActionType.GROUP_ELEMENTS) {
      return this.validateGroupActionState(action, isUndo);
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
      const removedMathBlocks: MathElement[] = action.removedMathBlocks ?? [];
      const removedMathBlockIndices: number[] = action.removedMathBlockIndices ?? [];
      const addedStrokes: StrokeElementData[] = action.addedStrokes ?? [];
      const addedStrokeIndices: number[] = action.addedStrokeIndices ?? [];
      const addedStrokeCounts: number[] = action.addedStrokeCounts ?? [];
      const partialEraseSourceRefs: PageElementRef[] = action.partialEraseSourceRefs ??
        action.removedStrokes.map((stroke: StrokeElementData, index: number): PageElementRef => ({
          kind: PageElementKind.STROKE, elementId: stroke.id, zIndex: index,
        }));
      const hasPartialReplacement: boolean = (action.partialEraseSourceRefs ?? []).length > 0 ||
        addedStrokes.length > 0 ||
        addedStrokeIndices.length > 0 || addedStrokeCounts.length > 0;
      const partialEraseBeforeGroups: OriginalSelectionGroup[] =
        action.partialEraseBeforeGroups ?? [];
      const partialEraseAfterGroups: OriginalSelectionGroup[] =
        action.partialEraseAfterGroups ?? [];
      const hasChange: boolean = action.removedStrokes.length > 0 ||
        addedStrokes.length > 0 || action.beforeModifiedStrokes.length > 0 ||
        action.removedShapes.length > 0 ||
        action.removedTextBlocks.length > 0 || action.removedImages.length > 0 ||
        removedMathBlocks.length > 0;
      const sourceModified: StrokeElementData[] = isUndo
        ? action.afterModifiedStrokes : action.beforeModifiedStrokes;
      if (!hasChange || !this.hasUniqueStrokeIds(action.removedStrokes) ||
        !this.hasUniqueStrokeIds(addedStrokes) ||
        !this.strokeIdsDisjoint(action.removedStrokes, addedStrokes) ||
        !this.sameStrokeIds(action.beforeModifiedStrokes, action.afterModifiedStrokes) ||
        !this.hasUniqueShapeIds(action.removedShapes) ||
        !this.hasUniqueTextBlockIds(action.removedTextBlocks) ||
        !this.hasUniqueImageIds(action.removedImages) ||
        !this.hasUniqueMathBlockIds(removedMathBlocks) || !this.allStrokeIdsPresent(sourceModified) ||
        (!hasPartialReplacement &&
          (partialEraseBeforeGroups.length > 0 || partialEraseAfterGroups.length > 0)) ||
        (hasPartialReplacement && replayOriginalPartialEraseGroups(
          this.selectionGroups, partialEraseBeforeGroups, partialEraseAfterGroups, !isUndo) === null)) {
        return false;
      }
      if (hasPartialReplacement && !validatePartialEraseElementHistoryState(
        this.completedStrokes, this.shapes, partialEraseSourceRefs,
        action.removedStrokes, action.removedStrokeIndices,
        action.removedShapes, action.removedShapeIndices,
        addedStrokes, addedStrokeIndices, addedStrokeCounts, isUndo)) {
        return false;
      }
      if (!isUndo) {
        const validStrokeState: boolean = hasPartialReplacement ||
          (this.allStrokeIdsPresent(action.removedStrokes) && this.allStrokeIdsAbsent(addedStrokes));
        return validStrokeState &&
          this.allShapeIdsPresent(action.removedShapes) &&
          this.allTextBlockIdsPresent(action.removedTextBlocks) &&
          this.allImageIdsPresent(action.removedImages) &&
          this.allMathBlockIdsPresent(removedMathBlocks);
      }
      const validStrokeState: boolean = hasPartialReplacement ||
        (this.allStrokeIdsPresent(addedStrokes) &&
          this.validateRemovedStrokeIndices(action.removedStrokes, action.removedStrokeIndices));
      return validStrokeState &&
        this.validateRemovedShapeIndices(action.removedShapes, action.removedShapeIndices) &&
        this.validateRemovedTextBlockIndices(action.removedTextBlocks, action.removedTextBlockIndices) &&
        this.validateRemovedImageIndices(action.removedImages, action.removedImageIndices) &&
        this.validateRemovedMathBlockIndices(removedMathBlocks, removedMathBlockIndices);
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
      const addedMathBlocks: MathElement[] = action.addedMathBlocks ?? [];
      const hasAdded: boolean = action.addedStrokes.length > 0 || action.addedShapes.length > 0 ||
        action.addedTextBlocks.length > 0 || action.addedImages.length > 0 || addedMathBlocks.length > 0;
      if (!hasAdded || !this.hasUniqueStrokeIds(action.addedStrokes) ||
        !this.hasUniqueShapeIds(action.addedShapes) || !this.hasUniqueTextBlockIds(action.addedTextBlocks) ||
        !this.hasUniqueImageIds(action.addedImages) || !this.hasUniqueMathBlockIds(addedMathBlocks) ||
        !this.sameAddedElementRefs(
          action.addedStrokes, action.addedShapes, action.addedTextBlocks, action.addedImages,
          addedMathBlocks,
          action.addedElementOrder)) {
        return false;
      }
      return isUndo
        ? this.allStrokeIdsPresent(action.addedStrokes) && this.allShapeIdsPresent(action.addedShapes) &&
          this.allTextBlockIdsPresent(action.addedTextBlocks)
          && this.allImageIdsPresent(action.addedImages) && this.allMathBlockIdsPresent(addedMathBlocks)
        : this.allPageElementIdsAbsent(
          action.addedStrokes, action.addedShapes, action.addedTextBlocks, action.addedImages,
          addedMathBlocks);
    }
    if (action.type === UndoableActionType.DELETE_ELEMENTS) {
      const removedMathBlocks: MathElement[] = action.removedMathBlocks ?? [];
      const removedMathBlockIndices: number[] = action.removedMathBlockIndices ?? [];
      const hasRemoved: boolean = action.removedStrokes.length > 0 || action.removedShapes.length > 0 ||
        action.removedTextBlocks.length > 0 || action.removedImages.length > 0 ||
        removedMathBlocks.length > 0;
      if (!hasRemoved || !this.hasUniqueStrokeIds(action.removedStrokes) ||
        !this.hasUniqueShapeIds(action.removedShapes) ||
        !this.hasUniqueTextBlockIds(action.removedTextBlocks) ||
        !this.hasUniqueImageIds(action.removedImages) ||
        !this.hasUniqueMathBlockIds(removedMathBlocks)) {
        return false;
      }
      if (!isUndo) {
        return this.allStrokeIdsPresent(action.removedStrokes) &&
          this.allShapeIdsPresent(action.removedShapes) &&
          this.allTextBlockIdsPresent(action.removedTextBlocks) &&
          this.allImageIdsPresent(action.removedImages) &&
          this.allMathBlockIdsPresent(removedMathBlocks);
      }
      return this.validateRemovedStrokeIndices(action.removedStrokes, action.removedStrokeIndices) &&
        this.validateRemovedShapeIndices(action.removedShapes, action.removedShapeIndices) &&
        this.validateRemovedTextBlockIndices(action.removedTextBlocks, action.removedTextBlockIndices) &&
        this.validateRemovedImageIndices(action.removedImages, action.removedImageIndices) &&
        this.validateRemovedMathBlockIndices(removedMathBlocks, removedMathBlockIndices);
    }
    if (action.type === UndoableActionType.TRANSFORM_ELEMENTS) {
      const sourceStrokes: StrokeElementData[] = isUndo ? action.afterStrokes : action.beforeStrokes;
      const sourceShapes: ShapeElement[] = isUndo ? action.afterShapes : action.beforeShapes;
      const sourceTextBlocks: TextBlockElement[] = isUndo ? action.afterTextBlocks : action.beforeTextBlocks;
      const sourceImages: ImageElement[] = isUndo ? action.afterImages : action.beforeImages;
      const beforeMathBlocks: MathElement[] = action.beforeMathBlocks ?? [];
      const afterMathBlocks: MathElement[] = action.afterMathBlocks ?? [];
      const sourceMathBlocks: MathElement[] = isUndo ? afterMathBlocks : beforeMathBlocks;
      const hasTransform: boolean = sourceStrokes.length > 0 || sourceShapes.length > 0 ||
        sourceTextBlocks.length > 0 || sourceImages.length > 0 || sourceMathBlocks.length > 0;
      return hasTransform && this.sameStrokeIds(action.beforeStrokes, action.afterStrokes) &&
        this.sameShapeIds(action.beforeShapes, action.afterShapes) &&
        this.sameTextBlockIds(action.beforeTextBlocks, action.afterTextBlocks) &&
        this.sameImageIds(action.beforeImages, action.afterImages) &&
        this.sameMathBlockIds(beforeMathBlocks, afterMathBlocks) &&
        this.allStrokeIdsPresent(sourceStrokes) && this.allShapeIdsPresent(sourceShapes) &&
        this.allTextBlockIdsPresent(sourceTextBlocks) && this.allImageIdsPresent(sourceImages) &&
        this.allMathBlockIdsPresent(sourceMathBlocks);
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

  private validateGroupActionState(action: GroupElementsAction, isUndo: boolean): boolean {
    if (action.beforeGroups.length > 1 || action.afterGroups.length > 1 ||
      action.beforeGroups.length + action.afterGroups.length !== 1) {
      return false;
    }
    const source: OriginalSelectionGroup[] = isUndo ? action.afterGroups : action.beforeGroups;
    const other: OriginalSelectionGroup[] = isUndo ? action.beforeGroups : action.afterGroups;
    const group: OriginalSelectionGroup = source.length === 1 ? source[0] : other[0];
    if (decodeOperationId(group.id) === null || !this.allCanonicalOperationIds(group.members)) {
      return false;
    }
    const active: OriginalSelectionGroup | null = this.findSelectionGroup(group.id);
    return source.length === 0 ? active === null :
      active !== null && this.sameSelectionGroup(active, group);
  }

  private validateOriginalClipboardPasteActionState(
    action: OriginalClipboardPasteAction, isUndo: boolean): boolean {
    if (action.operation.noteId !== action.noteId ||
      action.operation.opType !== OpType.ORIGINAL_CLIPBOARD_PASTE) {
      return false;
    }
    try {
      const mutation: OriginalClipboardPasteMutation =
        decodeOriginalClipboardPasteMutation(action.operation.payload);
      if (mutation.pageMutation.pageId !== action.pageId) {
        return false;
      }
      const current: SearchSourceElement[] = this.currentMutationElements();
      replayPageMutation(current, mutation.pageMutation, !isUndo);
      for (const group of mutation.groups) {
        const active: OriginalSelectionGroup | null = this.findSelectionGroup(group.id);
        if (isUndo ? active === null || !this.sameSelectionGroup(active, group) : active !== null) {
          return false;
        }
      }
      return true;
    } catch (_error) {
      return false;
    }
  }

  private validateOriginalPartialEraseActionState(
    action: OriginalPartialEraseAction, isUndo: boolean): boolean {
    if (action.operation.noteId !== action.noteId ||
      action.operation.opType !== OpType.ORIGINAL_PARTIAL_ERASE) {
      return false;
    }
    try {
      const mutation: OriginalPartialEraseMutation =
        decodeOriginalPartialEraseMutation(action.operation.payload);
      if (mutation.pageMutation.pageId !== action.pageId) {
        return false;
      }
      replayPageMutation(this.currentMutationElements(), mutation.pageMutation, !isUndo);
      return replayOriginalPartialEraseGroups(
        this.selectionGroups, mutation.beforeGroups, mutation.afterGroups, !isUndo) !== null;
    } catch (_error) {
      return false;
    }
  }

  private applyGroupActionState(action: GroupElementsAction, isUndo: boolean): void {
    const target: OriginalSelectionGroup[] = isUndo ? action.beforeGroups : action.afterGroups;
    const source: OriginalSelectionGroup[] = isUndo ? action.afterGroups : action.beforeGroups;
    const affected: OriginalSelectionGroup = target.length === 1 ? target[0] : source[0];
    const groups: OriginalSelectionGroup[] = this.selectionGroups.filter(
      (group: OriginalSelectionGroup): boolean => group.id !== affected.id);
    if (target.length === 1) {
      groups.push({ id: target[0].id, timestamp: target[0].timestamp,
        siteId: target[0].siteId, members: target[0].members.slice() });
    }
    this.selectionGroups = groups;
  }

  private sameSelectionGroup(left: OriginalSelectionGroup,
    right: OriginalSelectionGroup): boolean {
    if (left.id !== right.id || left.timestamp !== right.timestamp ||
      left.siteId !== right.siteId || left.members.length !== right.members.length) {
      return false;
    }
    for (let index: number = 0; index < left.members.length; index++) {
      if (left.members[index] !== right.members[index]) {
        return false;
      }
    }
    return true;
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
      const mathIds: string[] = (action.removedMathBlocks ?? []).map(
        (math: MathElement): string => math.id);
      const addedStrokes: StrokeElementData[] = action.addedStrokes ?? [];
      const addedStrokeIndices: number[] = action.addedStrokeIndices ?? [];
      const addedStrokeCounts: number[] = action.addedStrokeCounts ?? [];
      const partialEraseSourceRefs: PageElementRef[] = action.partialEraseSourceRefs ??
        action.removedStrokes.map((stroke: StrokeElementData, index: number): PageElementRef => ({
          kind: PageElementKind.STROKE, elementId: stroke.id, zIndex: index,
        }));
      const hasPartialReplacement: boolean = (action.partialEraseSourceRefs ?? []).length > 0 ||
        addedStrokes.length > 0 ||
        addedStrokeIndices.length > 0 || addedStrokeCounts.length > 0;
      let withoutStrokes: PageElementRef[];
      if (hasPartialReplacement) {
        const replacementByKey: Map<string, PartialEraseElementReplacement> | null =
          buildPartialEraseElementReplacementMap(
            partialEraseSourceRefs, addedStrokes, addedStrokeCounts);
        if (replacementByKey === null) {
          return false;
        }
        const replaced: PageElementRef[] | null = partialEraseMixedElementOrder(
          action.elementOrderBefore, replacementByKey);
        if (replaced === null) {
          return false;
        }
        withoutStrokes = replaced;
      } else {
        withoutStrokes = removePageElementRefs(
          action.elementOrderBefore, PageElementKind.STROKE, strokeIds);
      }
      const withoutShapes: PageElementRef[] = hasPartialReplacement ? withoutStrokes :
        removePageElementRefs(withoutStrokes, PageElementKind.SHAPE, shapeIds);
      const withoutTexts: PageElementRef[] = removePageElementRefs(
        withoutShapes, PageElementKind.TEXT, textIds);
      const withoutImages: PageElementRef[] = removePageElementRefs(
        withoutTexts, PageElementKind.IMAGE, imageIds);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(withoutImages, PageElementKind.MATH, mathIds));
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
      const mathIds: string[] = (action.removedMathBlocks ?? []).map(
        (math: MathElement): string => math.id);
      const withoutStrokes: PageElementRef[] = removePageElementRefs(
        action.elementOrderBefore, PageElementKind.STROKE, strokeIds);
      const withoutShapes: PageElementRef[] = removePageElementRefs(
        withoutStrokes, PageElementKind.SHAPE, shapeIds);
      const withoutTexts: PageElementRef[] = removePageElementRefs(
        withoutShapes, PageElementKind.TEXT, textIds);
      const withoutImages: PageElementRef[] = removePageElementRefs(
        withoutTexts, PageElementKind.IMAGE, imageIds);
      return samePageElementOrder(action.elementOrderAfter,
        removePageElementRefs(withoutImages, PageElementKind.MATH, mathIds));
    }
    if (action.type === UndoableActionType.GROUP_ELEMENTS) {
      return samePageElementMembers(action.elementOrderBefore, action.elementOrderAfter);
    }
    return action.type === UndoableActionType.REORDER_ELEMENTS &&
      samePageElementMembers(action.elementOrderBefore, action.elementOrderAfter);
  }

  private getActionSourceOrder(action: UndoableAction, isUndo: boolean): PageElementRef[] | null {
    if (action.type === UndoableActionType.ADD_STROKE || action.type === UndoableActionType.DELETE_STROKE ||
      action.type === UndoableActionType.ERASE_ELEMENTS || action.type === UndoableActionType.ADD_ELEMENT ||
      action.type === UndoableActionType.DELETE_ELEMENT || action.type === UndoableActionType.REORDER_ELEMENTS ||
      action.type === UndoableActionType.ADD_SHAPE || action.type === UndoableActionType.ADD_ELEMENTS ||
      action.type === UndoableActionType.DELETE_ELEMENTS ||
      action.type === UndoableActionType.GROUP_ELEMENTS) {
      return isUndo ? action.elementOrderAfter : action.elementOrderBefore;
    }
    return null;
  }

  private getActionTargetOrder(action: UndoableAction, isUndo: boolean): PageElementRef[] | null {
    if (action.type === UndoableActionType.ADD_STROKE || action.type === UndoableActionType.DELETE_STROKE ||
      action.type === UndoableActionType.ERASE_ELEMENTS || action.type === UndoableActionType.ADD_ELEMENT ||
      action.type === UndoableActionType.DELETE_ELEMENT || action.type === UndoableActionType.REORDER_ELEMENTS ||
      action.type === UndoableActionType.ADD_SHAPE || action.type === UndoableActionType.ADD_ELEMENTS ||
      action.type === UndoableActionType.DELETE_ELEMENTS ||
      action.type === UndoableActionType.GROUP_ELEMENTS) {
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

  private countMathBlockId(id: string): number {
    let count: number = 0;
    for (const math of this.mathBlocks) {
      if (math.id === id) {
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

  private strokeIdsDisjoint(left: StrokeElementData[], right: StrokeElementData[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const stroke of left) {
      ids.add(stroke.id);
    }
    for (const stroke of right) {
      if (ids.has(stroke.id)) {
        return false;
      }
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

  private hasUniqueMathBlockIds(mathBlocks: MathElement[]): boolean {
    const ids: Set<string> = new Set<string>();
    for (const math of mathBlocks) {
      if (ids.has(math.id)) {
        return false;
      }
      ids.add(math.id);
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

  private sameMathBlockIds(a: MathElement[], b: MathElement[]): boolean {
    if (a.length !== b.length || !this.hasUniqueMathBlockIds(a) || !this.hasUniqueMathBlockIds(b)) {
      return false;
    }
    const ids: Set<string> = new Set<string>();
    for (const math of b) {
      ids.add(math.id);
    }
    for (const math of a) {
      if (!ids.has(math.id)) {
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

  private filterMathBlocksByIds(mathBlocks: MathElement[], ids: string[]): MathElement[] {
    const selected: Set<string> = new Set<string>(ids);
    const result: MathElement[] = [];
    for (const math of mathBlocks) {
      if (selected.has(math.id)) {
        result.push(math);
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
    textBlocks: TextBlockElement[], images: ImageElement[], mathBlocks: MathElement[],
    refs: PageElementRef[]): boolean {
    if (refs.length !== strokes.length + shapes.length + textBlocks.length + images.length +
      mathBlocks.length) {
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
    for (const math of mathBlocks) {
      expected.add(`${PageElementKind.MATH}:${math.id}`);
    }
    if (expected.size !== refs.length) {
      return false;
    }
    const actual: Set<string> = new Set<string>();
    for (const ref of refs) {
      if ((ref.kind !== PageElementKind.STROKE && ref.kind !== PageElementKind.SHAPE &&
        ref.kind !== PageElementKind.TEXT && ref.kind !== PageElementKind.IMAGE &&
        ref.kind !== PageElementKind.MATH) ||
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
    textBlocks: TextBlockElement[], images: ImageElement[], mathBlocks: MathElement[]): boolean {
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
    for (const math of this.mathBlocks) {
      existing.add(math.id);
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
    for (const math of mathBlocks) {
      if (existing.has(math.id) || added.has(math.id)) {
        return false;
      }
      added.add(math.id);
    }
    return true;
  }

  private appendMixedElementRefs(order: PageElementRef[], refs: PageElementRef[]): PageElementRef[] | null {
    const result: PageElementRef[] = clonePageElementOrder(order);
    const appended: Set<string> = new Set<string>();
    for (const ref of refs) {
      const key: string = `${ref.kind}:${ref.elementId}`;
      if ((ref.kind !== PageElementKind.STROKE && ref.kind !== PageElementKind.SHAPE &&
        ref.kind !== PageElementKind.TEXT && ref.kind !== PageElementKind.IMAGE &&
        ref.kind !== PageElementKind.MATH) ||
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

  private allMathBlockIdsPresent(mathBlocks: MathElement[]): boolean {
    for (const math of mathBlocks) {
      if (this.countMathBlockId(math.id) !== 1) {
        return false;
      }
    }
    return true;
  }

  private allMathBlockIdsAbsent(mathBlocks: MathElement[]): boolean {
    for (const math of mathBlocks) {
      if (this.countMathBlockId(math.id) !== 0) {
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

  private validateRemovedMathBlockIndices(mathBlocks: MathElement[], indices: number[]): boolean {
    if (!this.allMathBlockIdsAbsent(mathBlocks) || indices.length !== mathBlocks.length) {
      return false;
    }
    let previous: number = -1;
    for (let i: number = 0; i < indices.length; i++) {
      const index: number = indices[i];
      if (!Number.isInteger(index) || index < previous || index < 0 ||
        index > this.mathBlocks.length + i) {
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

  private restoreRemovedMathBlocks(mathBlocks: MathElement[], indices: number[]): void {
    for (let i: number = 0; i < mathBlocks.length; i++) {
      this.mathBlocks.splice(indices[i], 0, mathBlocks[i]);
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

  private replaceMathBlocksById(replacements: MathElement[]): void {
    for (const replacement of replacements) {
      for (let i: number = 0; i < this.mathBlocks.length; i++) {
        if (this.mathBlocks[i].id === replacement.id) {
          this.mathBlocks[i] = replacement;
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
    let selectedColor: number | null = null;
    let selectedWidth: number | null = null;
    let selectedMinimum: number = 0.5;
    let selectedMaximum: number = 30;
    const pageWidth: number = this.getPaperWidth();
    for (const stroke of this.completedStrokes) {
      if (state.selectedStrokeIds.indexOf(stroke.id) < 0 ||
        stroke.renderSpec.isPartialEraser === true) {
        continue;
      }
      if (selectedColor === null) {
        selectedColor = (0xFF000000 | (stroke.renderSpec.color & 0x00FFFFFF)) | 0;
      }
      if (selectedWidth === null) {
        const tape: boolean = stroke.renderSpec.tapePattern !== undefined &&
          stroke.renderSpec.tapePattern !== null;
        selectedMinimum = tape ? 2 : stroke.renderSpec.isPencil ? 1 : 0.5;
        selectedMaximum = tape ? 64 : stroke.renderSpec.isPencil ? 10 : 30;
        const controlWidth: number = stroke.renderSpec.brushWidth * 768 / pageWidth;
        selectedWidth = Math.round(Math.min(selectedMaximum,
          Math.max(selectedMinimum, controlWidth)) * 2) / 2;
      }
    }
    for (const shape of this.shapes) {
      if (state.selectedShapeIds.indexOf(shape.id) < 0) {
        continue;
      }
      if (selectedColor === null) {
        selectedColor = (0xFF000000 | (shape.color & 0x00FFFFFF)) | 0;
      }
      if (selectedWidth === null) {
        const tool: number = shape.originalTool === undefined ? 0 : shape.originalTool;
        selectedMinimum = tool === 3 ? 2 : tool === 1 ? 1 : 0.5;
        selectedMaximum = tool === 3 ? 64 : tool === 1 ? 10 : 30;
        selectedWidth = Math.round(Math.min(selectedMaximum,
          Math.max(selectedMinimum, shape.strokeWidth)) * 2) / 2;
      }
    }
    if (selectedColor !== null || selectedWidth !== null) {
      const selectedStrokeIds: Set<string> = new Set<string>(state.selectedStrokeIds);
      const variableStyleEnabled: boolean = state.selectedShapeIds.length === 0 &&
        !this.completedStrokes.some((stroke: StrokeElementData): boolean =>
          selectedStrokeIds.has(stroke.id) && stroke.renderSpec.isPencil);
      this.onSelectionInkControlsChanged(selectedColor ?? this.selectionInkColor,
        selectedWidth ?? this.selectionInkWidth, selectedMinimum, selectedMaximum,
        variableStyleEnabled);
    }
    this.selectionCanFlip = this.canFlipImageSelection(
      state.selectedStrokeIds, state.selectedShapeIds, state.selectedTextBlockIds,
      state.selectedImageIds, state.selectedGroupIds, state.selectedMathIds);
    this.selectionCanCrop = this.canCropImageSelection(
      state.selectedStrokeIds, state.selectedShapeIds, state.selectedTextBlockIds,
      state.selectedImageIds, state.selectedGroupIds, state.selectedMathIds);
    const selectedEntityIds: string[] = state.selectedStrokeIds.concat(state.selectedShapeIds)
      .concat(state.selectedTextBlockIds).concat(state.selectedImageIds).concat(state.selectedMathIds);
    const groupMembers: string[] | null = resolveOriginalGroupAuthoringMembers(
      selectedEntityIds, state.selectedGroupIds, this.selectionGroups);
    this.selectionCanGroup = groupMembers !== null && groupMembers.length >= 2 &&
      this.allCanonicalOperationIds(groupMembers);
    this.selectionCanUngroup = state.selectedGroupIds.length === 1 &&
      this.findSelectionGroup(state.selectedGroupIds[0]) !== null &&
      resolveOriginalSelectedGroupLeaves(
        state.selectedGroupIds, selectedEntityIds, this.selectionGroups) !== null;
    this.selectionCanEditMath = state.selectedMathIds.length === 1 &&
      state.selectedStrokeIds.length === 0 && state.selectedShapeIds.length === 0 &&
      state.selectedTextBlockIds.length === 0 && state.selectedImageIds.length === 0 &&
      state.selectedGroupIds.length === 0 &&
      this.mathBlocks.some((math: MathElement): boolean =>
        math.id === state.selectedMathIds[0] && decodeOperationId(math.id) !== null);
    let lockableCount: number = 0;
    let lockedCount: number = 0;
    for (const shape of this.shapes) {
      if (state.selectedShapeIds.indexOf(shape.id) >= 0) {
        lockableCount++;
        lockedCount += shape.positionLocked === true ? 1 : 0;
      }
    }
    for (const text of this.textBlocks) {
      if (state.selectedTextBlockIds.indexOf(text.id) >= 0) {
        lockableCount++;
        lockedCount += text.positionLocked === true ? 1 : 0;
      }
    }
    for (const image of this.imageBlocks) {
      if (state.selectedImageIds.indexOf(image.id) >= 0) {
        lockableCount++;
        lockedCount += image.positionLocked ? 1 : 0;
      }
    }
    for (const math of this.mathBlocks) {
      if (state.selectedMathIds.indexOf(math.id) >= 0) {
        lockableCount++;
        lockedCount += math.positionLocked ? 1 : 0;
      }
    }
    const selectedCount: number = state.selectedStrokeIds.length + lockableCount;
    const onlyShapesSelected: boolean = state.selectedShapeIds.length > 0 &&
      state.selectedShapeIds.length === selectedCount;
    // Original 1.0.3 dhb handles a tapped Block directly; drawn/group selections use xsc.k,
    // which accepts only Shapes. Harmony has no separate tap-selection state, so one selected
    // entity is the equivalent direct-selection path.
    this.selectionCanLock = onlyShapesSelected ||
      (selectedCount === 1 && state.selectedGroupIds.length === 0);
    this.selectionPositionLocked = lockableCount > 0 && lockedCount === lockableCount;
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
    for (const math of this.mathBlocks) {
      if (state.selectedMathIds.indexOf(math.id) >= 0) {
        if (rect === null) {
          rect = { left: math.bounds.left, top: math.bounds.top,
            right: math.bounds.right, bottom: math.bounds.bottom };
        } else {
          rect = { left: Math.min(rect.left, math.bounds.left),
            top: Math.min(rect.top, math.bounds.top),
            right: Math.max(rect.right, math.bounds.right),
            bottom: Math.max(rect.bottom, math.bounds.bottom) };
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
    const selectedMathIds: string[] = this.selectionTool.getState().selectedMathIds;
    const before: StrokeElementData[] = this.filterStrokesByIds(this.completedStrokes, selectedStrokeIds);
    const beforeShapes: ShapeElement[] = this.filterShapesByIds(this.shapes, selectedShapeIds);
    const beforeTextBlocks: TextBlockElement[] = this.filterTextBlocksByIds(
      this.textBlocks, selectedTextBlockIds);
    const beforeImages: ImageElement[] = this.filterImagesByIds(this.imageBlocks, selectedImageIds);
    const beforeMathBlocks: MathElement[] = this.filterMathBlocksByIds(this.mathBlocks, selectedMathIds);
    const source: StrokeElementData[] = this.selectionDrag ? this.dragBeforeStrokes : this.completedStrokes;
    const sourceShapes: ShapeElement[] = this.selectionDrag ? this.dragBeforeShapes : this.shapes;
    const sourceTextBlocks: TextBlockElement[] = this.selectionDrag ? this.dragBeforeTextBlocks : this.textBlocks;
    const sourceImages: ImageElement[] = this.selectionDrag ? this.dragBeforeImages : this.imageBlocks;
    const sourceMathBlocks: MathElement[] = this.selectionDrag ? this.dragBeforeMathBlocks : this.mathBlocks;
    this.completedStrokes = this.selectionTool.applyTransform(source);
    this.shapes = transformShapeElements(sourceShapes,
      this.selectionTool.getState().selectedShapeIds, this.selectionTool.getState().transform);
    this.textBlocks = transformTextBlockElements(
      sourceTextBlocks, selectedTextBlockIds, this.selectionTool.getState().transform);
    this.imageBlocks = transformImageElements(
      sourceImages, selectedImageIds, this.selectionTool.getState().transform);
    this.mathBlocks = transformMathElements(
      sourceMathBlocks, selectedMathIds, this.selectionTool.getState().transform);
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
        beforeMathBlocks: beforeMathBlocks,
        afterMathBlocks: this.filterMathBlocksByIds(this.mathBlocks, selectedMathIds),
      });
    }
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    this.updateSelectionOverlay();
    if (notifyPersist) {
      this.persist(this.areCanonicalOriginalPositionSelection(
        selectedStrokeIds, selectedShapeIds, selectedTextBlockIds,
        selectedImageIds, selectedMathIds));
      this.notifyUndoRedo();
    }
    this.renderFrame();
  }

  onSelectionMenuAction(action: SelectionMenuAction): void {
    if (this.historyBusy || !this.loaded || this.dataLoading || this.dataLoadFailed ||
      this.loadedPageId.length === 0 || this.loadedPageId !== this.currentPage.pageId) {
      return;
    }
    hilog.info(0x0001, 'NoteCanvasView', 'selection menu action=%{public}d', action);
    const state = this.selectionTool.getState();
    if (action === SelectionMenuAction.DELETE || action === SelectionMenuAction.CUT) {
      const ids: string[] = state.selectedStrokeIds.slice();
      const shapeIds: string[] = state.selectedShapeIds.slice();
      const textIds: string[] = state.selectedTextBlockIds.slice();
      const imageIds: string[] = state.selectedImageIds.slice();
      const mathIds: string[] = state.selectedMathIds.slice();
      let cutPreparation: ClipboardCopyPreparation | null = null;
      if (action === SelectionMenuAction.CUT) {
        cutPreparation = this.prepareSelectedClipboard(
          ids, shapeIds, textIds, imageIds, mathIds, state.selectedGroupIds);
      }
      if (action === SelectionMenuAction.CUT && cutPreparation === null) {
        return;
      }
      const removed: StrokeElementData[] = [];
      const removedIndices: number[] = [];
      const removedShapes: ShapeElement[] = [];
      const removedShapeIndices: number[] = [];
      const removedTextBlocks: TextBlockElement[] = [];
      const removedTextBlockIndices: number[] = [];
      const removedImages: ImageElement[] = [];
      const removedImageIndices: number[] = [];
      const removedMathBlocks: MathElement[] = [];
      const removedMathBlockIndices: number[] = [];
      const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
      for (let strokeIndex: number = 0; strokeIndex < this.completedStrokes.length; strokeIndex++) {
        const s: StrokeElementData = this.completedStrokes[strokeIndex];
        if (ids.indexOf(s.id) >= 0) {
          removed.push(s);
          removedIndices.push(strokeIndex);
        }
      }
      for (let shapeIndex: number = 0; shapeIndex < this.shapes.length; shapeIndex++) {
        if (shapeIds.indexOf(this.shapes[shapeIndex].id) >= 0) {
          removedShapes.push(this.shapes[shapeIndex]);
          removedShapeIndices.push(shapeIndex);
        }
      }
      for (let textIndex: number = 0; textIndex < this.textBlocks.length; textIndex++) {
        if (textIds.indexOf(this.textBlocks[textIndex].id) >= 0) {
          removedTextBlocks.push(this.textBlocks[textIndex]);
          removedTextBlockIndices.push(textIndex);
        }
      }
      for (let imageIndex: number = 0; imageIndex < this.imageBlocks.length; imageIndex++) {
        if (imageIds.indexOf(this.imageBlocks[imageIndex].id) >= 0) {
          removedImages.push(this.imageBlocks[imageIndex]);
          removedImageIndices.push(imageIndex);
        }
      }
      for (let mathIndex: number = 0; mathIndex < this.mathBlocks.length; mathIndex++) {
        if (mathIds.indexOf(this.mathBlocks[mathIndex].id) >= 0) {
          removedMathBlocks.push(this.mathBlocks[mathIndex]);
          removedMathBlockIndices.push(mathIndex);
        }
      }
      if (removed.length === 0 && removedShapes.length === 0 && removedTextBlocks.length === 0 &&
        removedImages.length === 0 && removedMathBlocks.length === 0) {
        if (cutPreparation !== null) {
          this.strokeClipboard.cancelPreparedCopy(cutPreparation);
        }
        return;
      }
      const removedStrokeIds: string[] = removed.map(
        (stroke: StrokeElementData): string => stroke.id);
      const removedShapeIds: string[] = removedShapes.map(
        (shape: ShapeElement): string => shape.id);
      const removedTextIds: string[] = removedTextBlocks.map(
        (textBlock: TextBlockElement): string => textBlock.id);
      const removedImageIds: string[] = removedImages.map(
        (image: ImageElement): string => image.id);
      const removedMathIds: string[] = removedMathBlocks.map(
        (math: MathElement): string => math.id);
      let elementOrderAfter: PageElementRef[] = removePageElementRefs(
        this.elementOrder, PageElementKind.STROKE, removedStrokeIds);
      elementOrderAfter = removePageElementRefs(
        elementOrderAfter, PageElementKind.SHAPE, removedShapeIds);
      elementOrderAfter = removePageElementRefs(
        elementOrderAfter, PageElementKind.TEXT, removedTextIds);
      elementOrderAfter = removePageElementRefs(
        elementOrderAfter, PageElementKind.IMAGE, removedImageIds);
      elementOrderAfter = removePageElementRefs(
        elementOrderAfter, PageElementKind.MATH, removedMathIds);
      let deleteAction: UndoableAction;
      if (removedShapes.length > 0 || removedTextBlocks.length > 0 || removedImages.length > 0 ||
        removedMathBlocks.length > 0) {
        deleteAction = {
          type: UndoableActionType.DELETE_ELEMENTS,
          noteId: this.noteId,
          pageId: this.loadedPageId,
          removedStrokes: removed,
          removedStrokeIndices: removedIndices,
          removedShapes: removedShapes,
          removedShapeIndices: removedShapeIndices,
          removedTextBlocks: removedTextBlocks,
          removedTextBlockIndices: removedTextBlockIndices,
          removedImages: removedImages,
          removedImageIndices: removedImageIndices,
          removedMathBlocks: removedMathBlocks,
          removedMathBlockIndices: removedMathBlockIndices,
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(elementOrderAfter),
        };
      } else if (removed.length > 0) {
        deleteAction = {
          type: UndoableActionType.DELETE_STROKE,
          noteId: this.noteId,
          pageId: this.loadedPageId,
          removedStrokes: removed,
          removedStrokeIndices: removedIndices,
          beforeModifiedStrokes: [],
          afterModifiedStrokes: [],
          elementOrderBefore: elementOrderBefore,
          elementOrderAfter: clonePageElementOrder(elementOrderAfter),
        };
      } else {
        if (cutPreparation !== null) {
          this.strokeClipboard.cancelPreparedCopy(cutPreparation);
        }
        return;
      }
      const removedStrokeSet: Set<string> = new Set<string>(removedStrokeIds);
      const removedShapeSet: Set<string> = new Set<string>(removedShapeIds);
      const removedTextSet: Set<string> = new Set<string>(removedTextIds);
      const removedImageSet: Set<string> = new Set<string>(removedImageIds);
      const removedMathSet: Set<string> = new Set<string>(removedMathIds);
      const nextStrokes: StrokeElementData[] = this.completedStrokes.filter(
        (stroke: StrokeElementData): boolean => !removedStrokeSet.has(stroke.id));
      const nextShapes: ShapeElement[] = this.shapes.filter(
        (shape: ShapeElement): boolean => !removedShapeSet.has(shape.id));
      const nextTextBlocks: TextBlockElement[] = this.textBlocks.filter(
        (textBlock: TextBlockElement): boolean => !removedTextSet.has(textBlock.id));
      const nextImages: ImageElement[] = this.imageBlocks.filter(
        (image: ImageElement): boolean => !removedImageSet.has(image.id));
      const nextMathBlocks: MathElement[] = this.mathBlocks.filter(
        (math: MathElement): boolean => !removedMathSet.has(math.id));
      const originalEntityOnly: boolean = this.areCanonicalOriginalPositionSelection(
        removedStrokeIds, removedShapeIds, removedTextIds, removedImageIds, removedMathIds);
      let preparedHistory: HistoryMetadata;
      try {
        preparedHistory = this.undoRedo.prepareHistoryMetadata(deleteAction);
        this.persistence.queueSaveElements(this.noteId, this.loadedPageId,
          nextStrokes, nextTextBlocks, elementOrderAfter, nextShapes, true, preparedHistory,
          nextImages, nextMathBlocks);
      } catch (e) {
        if (cutPreparation !== null) {
          this.strokeClipboard.cancelPreparedCopy(cutPreparation);
        }
        this.reportSaveFailure(e as Object);
        return;
      }
      const persistedPageId: string = this.loadedPageId;
      this.invalidateOriginalInkReservation();
      if (originalEntityOnly) {
        this.originalInkIneligiblePages.delete(persistedPageId);
      } else {
        this.originalInkIneligiblePages.add(persistedPageId);
      }
      this.persistence.flush(this.noteId, persistedPageId).then((): void => {
        if (!this.persistence.hasDirtySave(this.noteId, persistedPageId)) {
          this.saveFailed = false;
        }
        if (originalEntityOnly) {
          this.refreshOriginalInkReservation(this.pageLoadGeneration, persistedPageId);
        }
      }).catch((e: Object): void => this.reportSaveFailure(e));
      if (cutPreparation !== null) {
        if (this.strokeClipboard.commitPreparedCopy(cutPreparation)) {
          this.clipboardAvailable = true;
        } else {
          // The document deletion has already been accepted, but a second
          // concurrent copy must never silently publish the wrong snapshot.
          // Keep the previous clipboard and surface the invariant violation.
          hilog.error(0x0001, 'NoteCanvasView',
            'Cut completed but its prepared clipboard token was superseded');
        }
      }
      this.completedStrokes = nextStrokes;
      this.shapes = nextShapes;
      this.textBlocks = nextTextBlocks;
      this.imageBlocks = nextImages;
      this.mathBlocks = nextMathBlocks;
      this.elementOrder = elementOrderAfter;
      this.selectionTool.deleteSelected();
      this.undoRedo.push(deleteAction, preparedHistory);
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.selectionVisible = false;
      this.layerManager.rebuildFromStrokes(
        this.completedStrokes, this.renderCtx, this.viewport.zoom);
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
        state.selectedTextBlockIds, state.selectedImageIds, state.selectedMathIds,
        state.selectedGroupIds, action === SelectionMenuAction.SEND_FORWARD);
    } else if (action === SelectionMenuAction.FLIP_H || action === SelectionMenuAction.FLIP_V) {
      this.flipSelected(state.selectedStrokeIds, state.selectedShapeIds,
        state.selectedTextBlockIds, state.selectedImageIds, state.selectedGroupIds,
        state.selectedMathIds,
        action === SelectionMenuAction.FLIP_H);
    } else if (action === SelectionMenuAction.CROP) {
      this.startImageCrop();
    } else if (action === SelectionMenuAction.LOCK) {
      this.setSelectedPositionLocked(!this.selectionPositionLocked);
    } else if (action === SelectionMenuAction.GROUP) {
      this.groupSelectedElements();
    } else if (action === SelectionMenuAction.UNGROUP) {
      this.ungroupSelectedElements();
    } else if (action === SelectionMenuAction.EDIT_MATH) {
      this.startMathEditing();
    } else if (action === SelectionMenuAction.COPY) {
      this.copySelectedToClipboard(
        state.selectedStrokeIds, state.selectedShapeIds, state.selectedTextBlockIds,
        state.selectedImageIds, state.selectedMathIds, state.selectedGroupIds);
    } else if (action === SelectionMenuAction.PASTE) {
      const target: Point2D | null = this.selectionPasteTarget();
      if (target !== null) {
        this.pasteClipboard(target);
      }
    }
  }

  private onMathEditorThemeChange(): void {
    if (this.lifecycleActive && this.mathEditorVisible) {
      this.requestMathEditorDraftValidation();
    }
  }

  private requestMathEditorDraftValidation(): void {
    this.cancelMathEditorDraftValidation();
    this.releaseMathEditorPreview();
    if (!this.mathEditorVisible) {
      this.mathEditorDraftState = OriginalMathEditorDraftState.EMPTY;
      return;
    }
    const draft: string = this.mathEditorDraft;
    const initialState: OriginalMathEditorDraftState = initialOriginalMathEditorDraftState(draft);
    this.mathEditorDraftState = initialState;
    if (initialState !== OriginalMathEditorDraftState.LOADING) {
      return;
    }
    if (!originalMathEngine.isReady()) {
      if (this.mathEngineInitializationComplete) {
        this.mathEditorDraftState = OriginalMathEditorDraftState.INVALID;
      }
      return;
    }
    const generation: number = this.mathEditorValidationGeneration;
    const color: number = this.mathEditorPreviewArgb();
    const previewWidthPixels: number = vp2px(ORIGINAL_MATH_EDITOR_PREVIEW_WIDTH_VP);
    const previewHeightPixels: number = vp2px(ORIGINAL_MATH_EDITOR_PREVIEW_HEIGHT_VP);
    if (!Number.isFinite(previewWidthPixels) || !Number.isFinite(previewHeightPixels) ||
      previewWidthPixels <= 0 || previewHeightPixels <= 0) {
      this.mathEditorDraftState = OriginalMathEditorDraftState.INVALID;
      return;
    }
    this.mathEditorValidationTimer = setTimeout((): void => {
      this.mathEditorValidationTimer = -1;
      if (generation !== this.mathEditorValidationGeneration || !this.lifecycleActive ||
        !this.mathEditorVisible || draft !== this.mathEditorDraft) {
        return;
      }
      let preview: OriginalMathBitmap | null = null;
      try {
        preview = originalMathEngine.render(draft,
          previewWidthPixels, previewHeightPixels,
          color, ORIGINAL_MATH_EDITOR_PREVIEW_PIXEL_SCALE);
      } catch (error) {
        console.warn(`Math editor preview render failed: ${JSON.stringify(error)}`);
      }
      if (generation !== this.mathEditorValidationGeneration || !this.lifecycleActive ||
        !this.mathEditorVisible || draft !== this.mathEditorDraft) {
        if (preview !== null) {
          this.releaseOriginalMathBitmap(preview);
        }
        return;
      }
      if (preview === null) {
        this.mathEditorDraftState = OriginalMathEditorDraftState.INVALID;
        return;
      }
      this.mathEditorPreview = preview;
      this.mathEditorDraftState = OriginalMathEditorDraftState.OK;
    }, 0);
  }

  private cancelMathEditorDraftValidation(): void {
    this.mathEditorValidationGeneration++;
    if (this.mathEditorValidationTimer >= 0) {
      clearTimeout(this.mathEditorValidationTimer);
      this.mathEditorValidationTimer = -1;
    }
  }

  private releaseMathEditorPreview(): void {
    const preview: OriginalMathBitmap | null = this.mathEditorPreview;
    this.mathEditorPreview = null;
    if (preview !== null) {
      this.releaseOriginalMathBitmap(preview);
    }
  }

  private releaseOriginalMathBitmap(preview: OriginalMathBitmap): void {
    try {
      preview.bitmap.close();
    } catch (_error) {
    }
    try {
      preview.pixelMap.release().catch((error: Object): void => {
        console.warn(`Math editor preview PixelMap release failed: ${JSON.stringify(error)}`);
      });
    } catch (error) {
      console.warn(`Math editor preview cleanup failed: ${JSON.stringify(error)}`);
    }
  }

  private mathEditorPreviewArgb(): number {
    const token: string = this.resolveTokens().textPrimary;
    if (token.startsWith('#') && token.length === 7) {
      const rgb: number = parseInt(token.substring(1), 16);
      if (Number.isFinite(rgb)) {
        return (0xFF000000 | rgb) | 0;
      }
    } else if (token.startsWith('#') && token.length === 9) {
      const argb: number = parseInt(token.substring(1), 16);
      if (Number.isFinite(argb)) {
        return argb | 0;
      }
    }
    return -16777216;
  }

  private startMathEditing(): void {
    if (this.mathEditorVisible || this.historyBusy || !this.selectionCanEditMath) {
      return;
    }
    const selected: string[] = this.selectionTool.getState().selectedMathIds;
    const math: MathElement | undefined = this.mathBlocks.find(
      (candidate: MathElement): boolean => selected.length === 1 && candidate.id === selected[0]);
    if (math === undefined || decodeOperationId(math.id) === null) {
      return;
    }
    this.mathEditorOriginal = cloneMathElement(math);
    this.mathEditorInsert = false;
    this.mathEditorDraft = math.latex;
    this.mathEditorFailed = false;
    this.mathEditorBusy = false;
    this.mathEditorVisible = true;
    this.requestMathEditorDraftValidation();
    this.selectionVisible = false;
  }

  private startMathInsert(): void {
    if (this.mathEditorVisible || this.historyBusy || !this.loaded || this.dataLoading ||
      this.dataLoadFailed || !this.persistence.isReady() || this.loadedPageId.length === 0) {
      return;
    }
    this.selectionTool.deselect();
    this.selectionVisible = false;
    this.mathEditorOriginal = null;
    this.mathEditorInsert = true;
    this.mathEditorDraft = '';
    this.mathEditorFailed = false;
    this.mathEditorBusy = false;
    this.mathEditorVisible = true;
    this.requestMathEditorDraftValidation();
  }

  private cancelMathEditing(): void {
    if (this.mathEditorBusy) {
      return;
    }
    this.mathEditorVisible = false;
    this.cancelMathEditorDraftValidation();
    this.releaseMathEditorPreview();
    this.mathEditorDraftState = OriginalMathEditorDraftState.EMPTY;
    this.mathEditorDraft = '';
    this.mathEditorFailed = false;
    this.mathEditorOriginal = null;
    this.mathEditorInsert = false;
    this.updateSelectionOverlay();
  }

  private async confirmMathEditing(): Promise<void> {
    const before: MathElement | null = this.mathEditorOriginal;
    if (this.mathEditorBusy || this.historyBusy ||
      this.mathEditorDraftState !== OriginalMathEditorDraftState.OK ||
      this.mathEditorPreview === null || !isOriginalMathLatexDraftValid(this.mathEditorDraft)) {
      return;
    }
    if (this.mathEditorInsert) {
      await this.confirmMathInsert();
      return;
    }
    if (before === null) {
      return;
    }
    const draft: string = this.mathEditorDraft;
    if (before.latex === draft) {
      this.cancelMathEditing();
      return;
    }
    const pageId: string = this.loadedPageId;
    const generation: number = this.pageLoadGeneration;
    const after: MathElement = cloneMathElement(before);
    if (originalMathEngine.fit(draft, before.blockWidth, before.blockHeight) === null) {
      this.mathEditorFailed = true;
      return;
    }
    after.latex = draft;
    const action: UndoableAction = {
      type: UndoableActionType.TRANSFORM_ELEMENTS,
      noteId: this.noteId,
      pageId: pageId,
      beforeStrokes: [], afterStrokes: [], beforeShapes: [], afterShapes: [],
      beforeTextBlocks: [], afterTextBlocks: [], beforeImages: [], afterImages: [],
      beforeMathBlocks: [before], afterMathBlocks: [after],
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(action);
    const proposedMath: MathElement[] = this.mathBlocks.map(
      (math: MathElement): MathElement => math.id === before.id ? after : math);
    this.mathEditorBusy = true;
    this.mathEditorFailed = false;
    this.historyBusy = true;
    try {
      await this.persistence.commitOriginalMathLatex(
        this.noteId, pageId, this.completedStrokes, this.textBlocks, this.elementOrder,
        this.shapes, this.imageBlocks, proposedMath, prepared);
      this.undoRedo.push(action, prepared);
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.mathEditorVisible = false;
      this.cancelMathEditorDraftValidation();
      this.releaseMathEditorPreview();
      this.mathEditorDraftState = OriginalMathEditorDraftState.EMPTY;
      this.mathEditorDraft = '';
      this.mathEditorOriginal = null;
      this.mathEditorInsert = false;
      this.originalInkIneligiblePages.delete(pageId);
      this.saveFailed = false;
      if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
        pageId === this.currentPage.pageId) {
        this.mathBlocks = proposedMath;
        this.updateSelectionOverlay();
        this.renderFrame();
      }
      this.notifyUndoRedo();
    } catch (e) {
      this.mathEditorFailed = true;
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'original Math latex commit failed: %{public}s', JSON.stringify(e));
    } finally {
      this.mathEditorBusy = false;
      this.historyBusy = false;
    }
  }

  private async confirmMathInsert(): Promise<void> {
    const pageId: string = this.loadedPageId;
    const generation: number = this.pageLoadGeneration;
    const center: Point2D = this.viewport.screenToCanvas(
      this.canvasCtx.width / 2, this.canvasCtx.height / 2);
    const fitted = originalMathEngine.fit(this.mathEditorDraft,
      ORIGINAL_MATH_INSERT_MAX_WIDTH, ORIGINAL_MATH_INSERT_MAX_HEIGHT);
    const draft: MathElement | null = fitted === null ? null : createOriginalMathInsertDraft(
      this.mathEditorDraft, center, this.getPaperWidth(), this.getPaperHeight(),
      fitted.width, fitted.height);
    if (draft === null) {
      this.mathEditorFailed = true;
      return;
    }
    const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const pending: MathElement = cloneMathElement(draft);
    pending.id = 'pending-original-math-insert';
    const pendingRef: PageElementRef = {
      kind: PageElementKind.MATH, elementId: pending.id, zIndex: elementOrderBefore.length,
    };
    const draftAction: UndoableAction = {
      type: UndoableActionType.ADD_ELEMENTS,
      noteId: this.noteId, pageId: pageId,
      addedStrokes: [], addedShapes: [], addedTextBlocks: [], addedImages: [],
      addedMathBlocks: [pending], addedElementOrder: [pendingRef],
      elementOrderBefore: elementOrderBefore,
      elementOrderAfter: elementOrderBefore.concat([pendingRef]),
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(draftAction);
    this.mathEditorBusy = true;
    this.mathEditorFailed = false;
    this.historyBusy = true;
    try {
      const result: OriginalMathInsertResult = await this.persistence.commitOriginalMathInsert(
        this.noteId, pageId, draft, prepared);
      const addedRef: PageElementRef = {
        kind: PageElementKind.MATH, elementId: result.math.id,
        zIndex: result.elementOrder.findIndex(
          (ref: PageElementRef): boolean => ref.kind === PageElementKind.MATH &&
            ref.elementId === result.math.id),
      };
      if (addedRef.zIndex < 0) {
        throw new Error('durable Math insert omitted its element order');
      }
      const action: UndoableAction = {
        type: UndoableActionType.ADD_ELEMENTS,
        noteId: this.noteId, pageId: pageId,
        addedStrokes: [], addedShapes: [], addedTextBlocks: [], addedImages: [],
        addedMathBlocks: [result.math], addedElementOrder: [addedRef],
        elementOrderBefore: elementOrderBefore,
        elementOrderAfter: clonePageElementOrder(result.elementOrder),
      };
      this.undoRedo.push(action, prepared);
      this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
      this.mathEditorVisible = false;
      this.cancelMathEditorDraftValidation();
      this.releaseMathEditorPreview();
      this.mathEditorDraftState = OriginalMathEditorDraftState.EMPTY;
      this.mathEditorDraft = '';
      this.mathEditorOriginal = null;
      this.mathEditorInsert = false;
      this.originalInkIneligiblePages.delete(pageId);
      this.saveFailed = false;
      if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
        pageId === this.currentPage.pageId) {
        this.mathBlocks = this.mathBlocks.concat([result.math]);
        this.elementOrder = clonePageElementOrder(result.elementOrder);
        this.synchronizeElementArraysByOrder();
        this.selectionTool.selectElementIds([], [], [], [], [], [result.math.id]);
        this.updateSelectionOverlay();
        this.renderFrame();
      }
      this.notifyUndoRedo();
    } catch (e) {
      this.mathEditorFailed = true;
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'original Math insert failed: %{public}s', JSON.stringify(e));
    } finally {
      this.mathEditorBusy = false;
      this.historyBusy = false;
    }
  }

  private groupSelectedElements(): void {
    const state = this.selectionTool.getState();
    const strokeIds: string[] = state.selectedStrokeIds.slice();
    const shapeIds: string[] = state.selectedShapeIds.slice();
    const textIds: string[] = state.selectedTextBlockIds.slice();
    const imageIds: string[] = state.selectedImageIds.slice();
    const mathIds: string[] = state.selectedMathIds.slice();
    const groupIds: string[] = state.selectedGroupIds.slice();
    const selected: Set<string> = new Set<string>(strokeIds.concat(shapeIds).concat(textIds)
      .concat(imageIds).concat(mathIds));
    const orderedIds: string[] = this.elementOrder
      .filter((ref: PageElementRef): boolean => selected.has(ref.elementId))
      .map((ref: PageElementRef): string => ref.elementId);
    const members: string[] | null = resolveOriginalGroupAuthoringMembers(
      orderedIds, groupIds, this.selectionGroups);
    if (members === null || members.length < 2 || !this.allCanonicalOperationIds(members)) {
      return;
    }
    const pageId: string = this.loadedPageId;
    const beforeOrder: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const draft: GroupElementsAction = {
      type: UndoableActionType.GROUP_ELEMENTS, noteId: this.noteId, pageId: pageId,
      beforeGroups: [], afterGroups: [], elementOrderBefore: beforeOrder,
      elementOrderAfter: beforeOrder,
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(draft);
    this.historyBusy = true;
    this.persistence.createOriginalGroup(
      this.noteId, pageId, members, beforeOrder, prepared).then(
      (result: OriginalGroupMutationResult): void => {
        const action: GroupElementsAction = this.groupActionFromMutation(result.mutation);
        this.undoRedo.push(action, prepared);
        this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
        this.selectionGroups = result.groups;
        this.elementOrder = clonePageElementOrder(result.mutation.elementOrderAfter);
        this.synchronizeElementArraysByOrder();
        const created: OriginalSelectionGroup = result.mutation.afterGroups[0];
        this.selectionTool.selectElementIds(
          strokeIds, shapeIds, textIds, imageIds, [created.id], mathIds);
        this.originalInkIneligiblePages.delete(pageId);
        this.layerManager.rebuildFromStrokes(
          this.completedStrokes, this.renderCtx, this.viewport.zoom);
        this.updateSelectionOverlay();
        this.renderFrame();
        this.notifyUndoRedo();
      }).catch((e: Object): void => {
        this.reportSaveFailure(e);
        hilog.error(0x0001, 'NoteCanvasView', 'Group failed: %{public}s', JSON.stringify(e));
      }).finally((): void => {
        this.historyBusy = false;
      });
  }

  private ungroupSelectedElements(): void {
    const state = this.selectionTool.getState();
    if (state.selectedGroupIds.length !== 1) {
      return;
    }
    const group: OriginalSelectionGroup | null = this.findSelectionGroup(state.selectedGroupIds[0]);
    if (group === null) {
      return;
    }
    const strokeIds: string[] = state.selectedStrokeIds.slice();
    const shapeIds: string[] = state.selectedShapeIds.slice();
    const textIds: string[] = state.selectedTextBlockIds.slice();
    const imageIds: string[] = state.selectedImageIds.slice();
    const mathIds: string[] = state.selectedMathIds.slice();
    const pageId: string = this.loadedPageId;
    const beforeOrder: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const draft: GroupElementsAction = {
      type: UndoableActionType.GROUP_ELEMENTS, noteId: this.noteId, pageId: pageId,
      beforeGroups: [], afterGroups: [], elementOrderBefore: beforeOrder,
      elementOrderAfter: beforeOrder,
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(draft);
    this.historyBusy = true;
    this.persistence.ungroupOriginalGroup(
      this.noteId, pageId, group, beforeOrder, prepared).then(
      (result: OriginalGroupMutationResult): void => {
        const action: GroupElementsAction = this.groupActionFromMutation(result.mutation);
        this.undoRedo.push(action, prepared);
        this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
        this.selectionGroups = result.groups;
        this.elementOrder = clonePageElementOrder(result.mutation.elementOrderAfter);
        this.synchronizeElementArraysByOrder();
        this.selectionTool.selectElementIds(
          strokeIds, shapeIds, textIds, imageIds, [], mathIds);
        this.originalInkIneligiblePages.delete(pageId);
        this.layerManager.rebuildFromStrokes(
          this.completedStrokes, this.renderCtx, this.viewport.zoom);
        this.updateSelectionOverlay();
        this.renderFrame();
        this.notifyUndoRedo();
      }).catch((e: Object): void => {
        this.reportSaveFailure(e);
        hilog.error(0x0001, 'NoteCanvasView', 'Ungroup failed: %{public}s', JSON.stringify(e));
      }).finally((): void => {
        this.historyBusy = false;
      });
  }

  private groupActionFromMutation(mutation: OriginalGroupMutationOpPayload): GroupElementsAction {
    return {
      type: UndoableActionType.GROUP_ELEMENTS, noteId: this.noteId, pageId: mutation.pageId,
      beforeGroups: mutation.beforeGroups, afterGroups: mutation.afterGroups,
      elementOrderBefore: mutation.elementOrderBefore,
      elementOrderAfter: mutation.elementOrderAfter,
    };
  }

  private allCanonicalOperationIds(ids: string[]): boolean {
    if (ids.length === 0) {
      return false;
    }
    for (const id of ids) {
      if (decodeOperationId(id) === null) {
        return false;
      }
    }
    return true;
  }

  private findSelectionGroup(id: string): OriginalSelectionGroup | null {
    for (const group of this.selectionGroups) {
      if (group.id === id) {
        return group;
      }
    }
    return null;
  }

  private reorderSelected(ids: string[], shapeIds: string[], textIds: string[], imageIds: string[],
    mathIds: string[], groupIds: string[], forward: boolean): void {
    const allSelectedIds: string[] = ids.concat(shapeIds).concat(textIds).concat(imageIds)
      .concat(mathIds);
    const groupedLeaves: string[] | null = resolveOriginalSelectedGroupLeaves(
      groupIds, allSelectedIds, this.selectionGroups);
    if (groupedLeaves === null) {
      return;
    }
    const grouped: Set<string> = new Set<string>(groupedLeaves);
    const directStrokeIds: string[] = ids.filter((id: string): boolean => !grouped.has(id));
    const directShapeIds: string[] = shapeIds.filter((id: string): boolean => !grouped.has(id));
    const directTextIds: string[] = textIds.filter((id: string): boolean => !grouped.has(id));
    const directImageIds: string[] = imageIds.filter((id: string): boolean => !grouped.has(id));
    const directMathIds: string[] = mathIds.filter((id: string): boolean => !grouped.has(id));
    const selectedIds: string[] = directStrokeIds.concat(directShapeIds).concat(directTextIds)
      .concat(directImageIds).concat(directMathIds);
    if (selectedIds.length === 0) {
      return;
    }
    const before: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const after: PageElementRef[] = movePageElementRefsOneStep(
      before, selectedIds, groupIds, this.selectionGroups, forward);
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
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    const originalEligible: boolean = this.areCanonicalOriginalPositionSelection(
      directStrokeIds, directShapeIds, directTextIds, directImageIds, directMathIds);
    const hint: OriginalZOrderHint | undefined = originalEligible ? {
      command: forward ? OriginalZOrderCommand.BRING_FORWARD : OriginalZOrderCommand.SEND_BACKWARD,
      selectedElementIds: selectedIds,
      selectedGroupIds: groupIds.slice(),
    } : undefined;
    this.persist(originalEligible, hint);
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private flipSelected(ids: string[], shapeIds: string[], textIds: string[], imageIds: string[],
    groupIds: string[], mathIds: string[], horizontal: boolean): void {
    if (!this.canFlipImageSelection(ids, shapeIds, textIds, imageIds, groupIds, mathIds)) {
      return;
    }
    const beforeImages: ImageElement[] = this.filterImagesByIds(this.imageBlocks, imageIds)
      .map((image: ImageElement): ImageElement => cloneImageElement(image));
    const afterImages: ImageElement[] = beforeImages.map((image: ImageElement): ImageElement => {
      const replacement: ImageElement = cloneImageElement(image);
      if (horizontal) {
        replacement.imageFlippedHorizontally = !replacement.imageFlippedHorizontally;
      } else {
        replacement.imageFlippedVertically = !replacement.imageFlippedVertically;
      }
      if (replacement.cropRect !== null) {
        replacement.cropRect = reflectImageCropRect(replacement.cropRect,
          replacement.intrinsicWidth, replacement.intrinsicHeight, horizontal);
      }
      return replacement;
    });
    this.replaceImagesById(afterImages);
    this.undoRedo.push({
      type: UndoableActionType.TRANSFORM_ELEMENTS,
      noteId: this.noteId,
      pageId: this.currentPage.pageId,
      beforeStrokes: [], afterStrokes: [], beforeShapes: [], afterShapes: [],
      beforeTextBlocks: [], afterTextBlocks: [], beforeImages: beforeImages,
      afterImages: afterImages, beforeMathBlocks: [], afterMathBlocks: [],
    });
    this.updateSelectionOverlay();
    this.persist(this.areCanonicalOriginalPositionSelection([], [], [], imageIds, []));
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private setSelectedPositionLocked(locked: boolean): void {
    const state = this.selectionTool.getState();
    const beforeShapes: ShapeElement[] = [];
    const afterShapes: ShapeElement[] = [];
    const beforeTextBlocks: TextBlockElement[] = [];
    const afterTextBlocks: TextBlockElement[] = [];
    const beforeImages: ImageElement[] = [];
    const afterImages: ImageElement[] = [];
    const beforeMathBlocks: MathElement[] = [];
    const afterMathBlocks: MathElement[] = [];
    for (const shape of this.shapes) {
      if (state.selectedShapeIds.indexOf(shape.id) < 0 || (shape.positionLocked === true) === locked) {
        continue;
      }
      const before: ShapeElement = cloneShapeElement(shape);
      const after: ShapeElement = cloneShapeElement(shape);
      after.positionLocked = locked;
      beforeShapes.push(before);
      afterShapes.push(after);
    }
    for (const text of this.textBlocks) {
      if (state.selectedTextBlockIds.indexOf(text.id) < 0 || (text.positionLocked === true) === locked) {
        continue;
      }
      const before: TextBlockElement = cloneTextBlockElement(text);
      const after: TextBlockElement = cloneTextBlockElement(text);
      after.positionLocked = locked;
      beforeTextBlocks.push(before);
      afterTextBlocks.push(after);
    }
    for (const image of this.imageBlocks) {
      if (state.selectedImageIds.indexOf(image.id) < 0 || image.positionLocked === locked) {
        continue;
      }
      const before: ImageElement = cloneImageElement(image);
      const after: ImageElement = cloneImageElement(image);
      after.positionLocked = locked;
      beforeImages.push(before);
      afterImages.push(after);
    }
    for (const math of this.mathBlocks) {
      if (state.selectedMathIds.indexOf(math.id) < 0 || math.positionLocked === locked) {
        continue;
      }
      const before: MathElement = cloneMathElement(math);
      const after: MathElement = cloneMathElement(math);
      after.positionLocked = locked;
      beforeMathBlocks.push(before);
      afterMathBlocks.push(after);
    }
    if (afterShapes.length === 0 && afterTextBlocks.length === 0 &&
      afterImages.length === 0 && afterMathBlocks.length === 0) {
      return;
    }
    this.replaceShapesById(afterShapes);
    this.replaceTextBlocksById(afterTextBlocks);
    this.replaceImagesById(afterImages);
    this.replaceMathBlocksById(afterMathBlocks);
    this.undoRedo.push({
      type: UndoableActionType.TRANSFORM_ELEMENTS,
      noteId: this.noteId, pageId: this.currentPage.pageId,
      beforeStrokes: [], afterStrokes: [], beforeShapes: beforeShapes, afterShapes: afterShapes,
      beforeTextBlocks: beforeTextBlocks, afterTextBlocks: afterTextBlocks,
      beforeImages: beforeImages, afterImages: afterImages,
      beforeMathBlocks: beforeMathBlocks, afterMathBlocks: afterMathBlocks,
    });
    this.updateSelectionOverlay();
    this.persist(this.areCanonicalOriginalPositionSelection([],
      beforeShapes.map((shape: ShapeElement): string => shape.id),
      beforeTextBlocks.map((text: TextBlockElement): string => text.id),
      beforeImages.map((image: ImageElement): string => image.id),
      beforeMathBlocks.map((math: MathElement): string => math.id)));
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private canFlipImageSelection(ids: string[], shapeIds: string[], textIds: string[],
    imageIds: string[], groupIds: string[], mathIds: string[]): boolean {
    if (ids.length > 0 || shapeIds.length > 0 || textIds.length > 0 ||
      groupIds.length > 0 || mathIds.length > 0 || imageIds.length === 0 ||
      new Set<string>(imageIds).size !== imageIds.length) {
      return false;
    }
    const images: ImageElement[] = this.filterImagesByIds(this.imageBlocks, imageIds);
    if (images.length !== imageIds.length) {
      return false;
    }
    for (const image of images) {
      if (image.positionLocked || (image.cropRect !== null &&
        (!Number.isFinite(image.intrinsicWidth) || !Number.isFinite(image.intrinsicHeight) ||
          !Number.isFinite(image.cropRect.left) || !Number.isFinite(image.cropRect.top) ||
          !Number.isFinite(image.cropRect.right) || !Number.isFinite(image.cropRect.bottom) ||
          image.cropRect.right < image.cropRect.left ||
          image.cropRect.bottom < image.cropRect.top))) {
        return false;
      }
    }
    return true;
  }

  private copySelectedToClipboard(ids: string[], shapeIds: string[] = [],
    textIds: string[] = [], imageIds: string[] = [], mathIds: string[] = [],
    groupIds: string[] = []): boolean {
    const preparation: ClipboardCopyPreparation | null = this.prepareSelectedClipboard(
      ids, shapeIds, textIds, imageIds, mathIds, groupIds);
    if (preparation === null || !this.strokeClipboard.commitPreparedCopy(preparation)) {
      return false;
    }
    this.clipboardAvailable = true;
    return true;
  }

  private prepareSelectedClipboard(ids: string[], shapeIds: string[] = [],
    textIds: string[] = [], imageIds: string[] = [], mathIds: string[] = [],
    groupIds: string[] = []): ClipboardCopyPreparation | null {
    if (!this.validRequestedIds(ids) || !this.validRequestedIds(shapeIds) ||
      !this.validRequestedIds(textIds) || !this.validRequestedIds(imageIds) ||
      !this.validRequestedIds(mathIds) || !this.validRequestedIds(groupIds)) {
      return null;
    }
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
    const selectedMathBlocks: MathElement[] = [];
    for (const math of this.mathBlocks) {
      if (mathIds.indexOf(math.id) >= 0) {
        selectedMathBlocks.push(math);
      }
    }
    if (selected.length !== ids.length || selectedShapes.length !== shapeIds.length ||
      selectedTextBlocks.length !== textIds.length || selectedImages.length !== imageIds.length ||
      selectedMathBlocks.length !== mathIds.length) {
      return null;
    }
    const selectedOrder: PageElementRef[] = [];
    const selectedOrderIds: Set<string> = new Set<string>();
    for (const ref of this.elementOrder) {
      if ((ref.kind === PageElementKind.STROKE && ids.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.SHAPE && shapeIds.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.TEXT && textIds.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.IMAGE && imageIds.indexOf(ref.elementId) >= 0) ||
        (ref.kind === PageElementKind.MATH && mathIds.indexOf(ref.elementId) >= 0)) {
        if (selectedOrderIds.has(ref.elementId)) {
          return null;
        }
        selectedOrderIds.add(ref.elementId);
        selectedOrder.push({ kind: ref.kind, elementId: ref.elementId, zIndex: selectedOrder.length });
      }
    }
    const selectedCount: number = ids.length + shapeIds.length + textIds.length +
      imageIds.length + mathIds.length;
    if (selectedCount === 0 || selectedOrder.length !== selectedCount) {
      return null;
    }
    return this.strokeClipboard.prepareCopy(
      selected, this.loadedPageId, selectedShapes, selectedOrder, selectedTextBlocks,
      selectedImages, selectedMathBlocks, this.selectionGroups, groupIds);
  }

  private validRequestedIds(ids: string[]): boolean {
    const unique: Set<string> = new Set<string>();
    for (const id of ids) {
      if (id.length === 0 || unique.has(id)) {
        return false;
      }
      unique.add(id);
    }
    return true;
  }

  private canPasteClipboardNow(): boolean {
    return this.clipboardAvailable && this.strokeClipboard.hasContent() && this.loaded &&
      !this.dataLoading && !this.dataLoadFailed && !this.historyBusy &&
      this.loadedPageId.length > 0 && this.loadedPageId === this.currentPage.pageId;
  }

  private selectionPasteTarget(): Point2D | null {
    if (!this.selectionVisible || !Number.isFinite(this.selectionRect.left) ||
      !Number.isFinite(this.selectionRect.right) || !Number.isFinite(this.selectionRect.top) ||
      !Number.isFinite(this.selectionRect.bottom)) {
      return this.clipboardPasteTarget === null ? null : {
        x: this.clipboardPasteTarget.x, y: this.clipboardPasteTarget.y,
      };
    }
    const centerScreen: Point2D = {
      x: (this.selectionRect.left + this.selectionRect.right) / 2,
      y: (this.selectionRect.top + this.selectionRect.bottom) / 2,
    };
    const centerCanvas: Point2D = this.viewport.screenToCanvas(centerScreen.x, centerScreen.y);
    return Number.isFinite(centerCanvas.x) && Number.isFinite(centerCanvas.y) ? centerCanvas : null;
  }

  private canCropImageSelection(ids: string[], shapeIds: string[], textIds: string[],
    imageIds: string[], groupIds: string[], mathIds: string[]): boolean {
    if (ids.length > 0 || shapeIds.length > 0 || textIds.length > 0 || groupIds.length > 0 ||
      mathIds.length > 0 || imageIds.length !== 1) {
      return false;
    }
    const images: ImageElement[] = this.filterImagesByIds(this.imageBlocks, imageIds);
    return images.length === 1 && beginOriginalImageCrop(images[0]) !== null;
  }

  private startImageCrop(): void {
    if (this.historyBusy || this.imageCropVisible) {
      return;
    }
    const state = this.selectionTool.getState();
    if (!this.canCropImageSelection(state.selectedStrokeIds, state.selectedShapeIds,
      state.selectedTextBlockIds, state.selectedImageIds, state.selectedGroupIds,
      state.selectedMathIds)) {
      return;
    }
    const images: ImageElement[] = this.filterImagesByIds(this.imageBlocks, state.selectedImageIds);
    const session: OriginalImageCropSession | null = beginOriginalImageCrop(images[0]);
    if (session === null) {
      return;
    }
    this.imageCropSession = session;
    this.imageCropDraft = {
      left: session.draft.left, top: session.draft.top,
      right: session.draft.right, bottom: session.draft.bottom,
    };
    this.selectionVisible = false;
    this.imageCropVisible = true;
  }

  private imageCropScreenCorners(): Point2D[] {
    if (!this.imageCropVisible || this.imageCropSession === null) {
      return [];
    }
    const canvasCorners: Point2D[] = imageCropDraftCanvasCorners(
      this.imageCropSession, this.imageCropDraft);
    return canvasCorners.map((point: Point2D): Point2D =>
      this.viewport.canvasToScreen(point.x, point.y));
  }

  private moveImageCropHandle(handle: ImageCropHandle,
    screenDeltaX: number, screenDeltaY: number): void {
    const session: OriginalImageCropSession | null = this.imageCropSession;
    if (!this.imageCropVisible || session === null || this.viewport.zoom <= 0) {
      return;
    }
    const localDelta: Point2D | null = originalImageCropLocalDelta(session.original,
      screenDeltaX / this.viewport.zoom, screenDeltaY / this.viewport.zoom);
    if (localDelta === null) {
      return;
    }
    const scaleX: number = Math.hypot(session.original.transform[0], session.original.transform[3]);
    const scaleY: number = Math.hypot(session.original.transform[1], session.original.transform[4]);
    const minimumWidth: number = Math.min(session.domain.right - session.domain.left,
      32 / Math.max(0.0001, this.viewport.zoom * scaleX));
    const minimumHeight: number = Math.min(session.domain.bottom - session.domain.top,
      32 / Math.max(0.0001, this.viewport.zoom * scaleY));
    const draft: Rect2D = {
      left: this.imageCropDraft.left, top: this.imageCropDraft.top,
      right: this.imageCropDraft.right, bottom: this.imageCropDraft.bottom,
    };
    if (handle === ImageCropHandle.TOP_LEFT || handle === ImageCropHandle.BOTTOM_LEFT ||
      handle === ImageCropHandle.LEFT) {
      draft.left = Math.max(session.domain.left,
        Math.min(draft.left + localDelta.x, draft.right - minimumWidth));
    }
    if (handle === ImageCropHandle.TOP_RIGHT || handle === ImageCropHandle.RIGHT ||
      handle === ImageCropHandle.BOTTOM_RIGHT) {
      draft.right = Math.min(session.domain.right,
        Math.max(draft.right + localDelta.x, draft.left + minimumWidth));
    }
    if (handle === ImageCropHandle.TOP_LEFT || handle === ImageCropHandle.TOP ||
      handle === ImageCropHandle.TOP_RIGHT) {
      draft.top = Math.max(session.domain.top,
        Math.min(draft.top + localDelta.y, draft.bottom - minimumHeight));
    }
    if (handle === ImageCropHandle.BOTTOM_LEFT || handle === ImageCropHandle.BOTTOM ||
      handle === ImageCropHandle.BOTTOM_RIGHT) {
      draft.bottom = Math.min(session.domain.bottom,
        Math.max(draft.bottom + localDelta.y, draft.top + minimumHeight));
    }
    this.imageCropDraft = draft;
  }

  private resetImageCrop(): void {
    if (this.imageCropSession !== null) {
      this.imageCropDraft = resetOriginalImageCropDraft(this.imageCropSession);
    }
  }

  private cancelImageCrop(): void {
    const imageId: string = this.imageCropSession === null ? '' : this.imageCropSession.original.id;
    this.imageCropSession = null;
    this.imageCropVisible = false;
    this.imageCropDraft = { left: 0, top: 0, right: 0, bottom: 0 };
    if (imageId.length > 0 && this.loadedPageId === this.currentPage.pageId &&
      this.imageBlocks.some((image: ImageElement): boolean => image.id === imageId)) {
      this.selectionTool.selectElementIds([], [], [], [imageId]);
      this.updateSelectionOverlay();
    }
  }

  private confirmImageCrop(): void {
    const session: OriginalImageCropSession | null = this.imageCropSession;
    if (!this.imageCropVisible || session === null || this.historyBusy) {
      return;
    }
    const after: ImageElement | null = applyOriginalImageCropDraft(session, this.imageCropDraft);
    if (after === null) {
      return;
    }
    const before: ImageElement = cloneImageElement(session.original);
    const beforeBytes: Uint8Array = encodePersistedElement({ kind: 'image', data: before });
    const afterBytes: Uint8Array = encodePersistedElement({ kind: 'image', data: after });
    this.imageCropSession = null;
    this.imageCropVisible = false;
    this.imageCropDraft = { left: 0, top: 0, right: 0, bottom: 0 };
    this.selectionTool.selectElementIds([], [], [], [after.id]);
    if (this.sameBytes(beforeBytes, afterBytes)) {
      this.updateSelectionOverlay();
      return;
    }
    this.replaceImagesById([after]);
    this.undoRedo.push({
      type: UndoableActionType.TRANSFORM_ELEMENTS,
      noteId: this.noteId,
      pageId: this.currentPage.pageId,
      beforeStrokes: [], afterStrokes: [], beforeShapes: [], afterShapes: [],
      beforeTextBlocks: [], afterTextBlocks: [], beforeImages: [before], afterImages: [after],
      beforeMathBlocks: [], afterMathBlocks: [],
    });
    this.updateSelectionOverlay();
    this.persist(true);
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private sameBytes(left: Uint8Array, right: Uint8Array): boolean {
    if (left.length !== right.length) {
      return false;
    }
    for (let index: number = 0; index < left.length; index++) {
      if (left[index] !== right[index]) {
        return false;
      }
    }
    return true;
  }

  private modifySelectedInkStyle(style: InkStyle): void {
    this.modifySelectedInkRegisters(style, null, null);
  }

  private modifySelectedInkColor(color: number): void {
    this.modifySelectedInkRegisters(null, color, null);
  }

  private modifySelectedInkWidth(controlWidth: number): void {
    this.modifySelectedInkRegisters(null, null, controlWidth);
  }

  private modifySelectedInkRegisters(style: InkStyle | null, color: number | null,
    controlWidth: number | null): void {
    if (this.historyBusy || !this.loaded || !this.viewModel.isSelectionActive()) {
      return;
    }
    const selected: Set<string> = new Set<string>(
      this.selectionTool.getState().selectedStrokeIds);
    const selectedShapes: Set<string> = new Set<string>(
      this.selectionTool.getState().selectedShapeIds);
    const before: StrokeElementData[] = [];
    const after: StrokeElementData[] = [];
    const beforeShapes: ShapeElement[] = [];
    const afterShapes: ShapeElement[] = [];
    const replacements: Map<string, StrokeElementData> = new Map<string, StrokeElementData>();
    const shapeReplacements: Map<string, ShapeElement> = new Map<string, ShapeElement>();
    for (const stroke of this.completedStrokes) {
      if (!selected.has(stroke.id) || stroke.renderSpec.isPartialEraser === true ||
        (style !== null && stroke.renderSpec.isPencil)) {
        continue;
      }
      const source: StrokeElementData = this.cloneStrokeSnapshot(stroke);
      const replacement: StrokeElementData = this.cloneStrokeSnapshot(stroke);
      if (style !== null) {
        replacement.renderSpec.inkStyle = style;
        replacement.styleMap = [];
      }
      if (color !== null) {
        const alpha: number = stroke.renderSpec.isHighlighter ? 107 : 255;
        replacement.renderSpec.color = ((alpha << 24) | (color & 0x00FFFFFF)) | 0;
      }
      if (controlWidth !== null) {
        const tape: boolean = stroke.renderSpec.tapePattern !== undefined &&
          stroke.renderSpec.tapePattern !== null;
        const minimum: number = tape ? 2 : stroke.renderSpec.isPencil ? 1 : 0.5;
        const maximum: number = tape ? 64 : stroke.renderSpec.isPencil ? 10 : 30;
        const bounded: number = Math.min(maximum, Math.max(minimum, controlWidth));
        const persistedWidth: number = bounded * this.getPaperWidth() / 768;
        if (stroke.renderSpec.isPencil) {
          try {
            const rebuilt: RebuiltOriginalPencilWidth = rebuildOriginalPencilWidth(
              stroke, persistedWidth);
            replacement.splatPoints = rebuilt.splatPoints;
            replacement.bounds = rebuilt.bounds;
          } catch (_error) {
            continue;
          }
        }
        replacement.renderSpec.brushWidth = persistedWidth;
      }
      const sourceBytes: Uint8Array = encodePersistedElement({ kind: 'stroke', data: source });
      const replacementBytes: Uint8Array = encodePersistedElement({ kind: 'stroke', data: replacement });
      if (this.sameBytes(sourceBytes, replacementBytes)) {
        continue;
      }
      before.push(source);
      after.push(replacement);
      replacements.set(stroke.id, replacement);
    }
    for (const shape of this.shapes) {
      if (style === InkStyle.VARIABLE_WIDTH) {
        continue;
      }
      if (!selectedShapes.has(shape.id)) {
        continue;
      }
      const source: ShapeElement = cloneShapeElement(shape);
      const replacement: ShapeElement = cloneShapeElement(shape);
      const tool: number = shape.originalTool === undefined ? 0 : shape.originalTool;
      if (style !== null) {
        replacement.originalStyle = style === InkStyle.FIXED_WIDTH ? 1 :
          style === InkStyle.DASH ? 2 : 3;
      }
      if (color !== null) {
        const alpha: number = tool === 2 ? 107 : 255;
        replacement.color = ((alpha << 24) | (color & 0x00FFFFFF)) | 0;
        if (tool === 2) {
          replacement.fillColor = replacement.color;
        }
      }
      if (controlWidth !== null) {
        const minimum: number = tool === 3 ? 2 : tool === 1 ? 1 : 0.5;
        const maximum: number = tool === 3 ? 64 : tool === 1 ? 10 : 30;
        replacement.strokeWidth = Math.min(maximum, Math.max(minimum, controlWidth));
      }
      const sourceBytes: Uint8Array = encodePersistedElement({ kind: 'shape', data: source });
      const replacementBytes: Uint8Array = encodePersistedElement({ kind: 'shape', data: replacement });
      if (this.sameBytes(sourceBytes, replacementBytes)) {
        continue;
      }
      beforeShapes.push(source);
      afterShapes.push(replacement);
      shapeReplacements.set(shape.id, replacement);
    }
    if (after.length === 0 && afterShapes.length === 0) {
      return;
    }
    this.completedStrokes = this.completedStrokes.map((stroke: StrokeElementData): StrokeElementData =>
      replacements.get(stroke.id) ?? stroke);
    this.shapes = this.shapes.map((shape: ShapeElement): ShapeElement =>
      shapeReplacements.get(shape.id) ?? shape);
    if (afterShapes.length === 0) {
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_STROKES,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        beforeStrokes: before,
        afterStrokes: after,
      });
    } else {
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_ELEMENTS,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        beforeStrokes: before, afterStrokes: after,
        beforeShapes: beforeShapes, afterShapes: afterShapes,
        beforeTextBlocks: [], afterTextBlocks: [], beforeImages: [], afterImages: [],
        beforeMathBlocks: [], afterMathBlocks: [],
      });
    }
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    this.persist(this.areCanonicalOriginalPositionSelection(
      before.map((stroke: StrokeElementData): string => stroke.id),
      beforeShapes.map((shape: ShapeElement): string => shape.id), [], [], []));
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private originalToolForStroke(stroke: StrokeElementData): number {
    if (stroke.renderSpec.tapePattern !== undefined && stroke.renderSpec.tapePattern !== null) {
      return 3;
    }
    return stroke.renderSpec.isPencil ? 1 : stroke.renderSpec.isHighlighter ? 2 : 0;
  }

  private originalStyleForStroke(stroke: StrokeElementData): number {
    return stroke.renderSpec.inkStyle === InkStyle.VARIABLE_WIDTH ? 0 :
      stroke.renderSpec.inkStyle === InkStyle.FIXED_WIDTH ? 1 :
        stroke.renderSpec.inkStyle === InkStyle.DASH ? 2 : 3;
  }

  private averageStrokeForce(stroke: StrokeElementData): number | null {
    let total: number = 0;
    let count: number = 0;
    for (const point of stroke.pathPoints) {
      if (Number.isFinite(point.pressure) && point.pressure >= 0) {
        total += point.pressure;
        count++;
      }
    }
    return count === 0 ? null : total / count;
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

  private removeMathBlockById(id: string): void {
    const remaining: MathElement[] = [];
    for (const math of this.mathBlocks) {
      if (math.id !== id) {
        remaining.push(math);
      }
    }
    this.mathBlocks = remaining;
  }

  private pasteClipboard(targetCenter: Point2D): void {
    if (!this.canPasteClipboardNow() || !Number.isFinite(targetCenter.x) ||
      !Number.isFinite(targetCenter.y)) {
      return;
    }
    const now: number = Date.now();
    if (now - this.lastPasteRequestTime < CLIPBOARD_PASTE_SUPPRESSION_MS) {
      return;
    }
    this.lastPasteRequestTime = now;
    if (this.strokeClipboard.hasOriginalGroupGraph()) {
      let preview: ClipboardOriginalGroupPastePreview | null = null;
      try {
        preview = this.strokeClipboard.prepareOriginalGroupPaste(
          this.getPaperWidth(), this.getPaperHeight(), targetCenter);
      } catch (e) {
        this.reportSaveFailure(e as Object);
        hilog.error(0x0001, 'NoteCanvasView',
          'original Group Paste geometry failed: %{public}s', JSON.stringify(e));
        return;
      }
      if (preview === null) {
        return;
      }
      this.applyOriginalGroupClipboardPaste(preview);
      return;
    }
    const source: ClipboardSingleOriginalSource | null =
      this.strokeClipboard.singleOriginalCreateSource();
    if (source !== null && decodeOperationId(source.elementId) !== null &&
      this.canEncodeOriginalClipboardSource(source)) {
      const generation: number = this.pageLoadGeneration;
      const pageId: string = this.loadedPageId;
      this.historyBusy = true;
      this.persistence.reserveOriginalInkCreate(this.noteId, pageId).then(
        (metadata: OriginalInkCreateMetadata | null): void => {
          if (generation !== this.pageLoadGeneration || pageId !== this.loadedPageId ||
            pageId !== this.currentPage.pageId || !this.loaded || this.dataLoading ||
            this.dataLoadFailed) {
            return;
          }
          this.applyClipboardPaste(metadata, source.kind, targetCenter);
        }).catch((e: Object): void => {
          this.reportSaveFailure(e);
          hilog.error(0x0001, 'NoteCanvasView',
            'Paste identity reservation failed: %{public}s', JSON.stringify(e));
        }).finally((): void => {
          this.historyBusy = false;
        });
      return;
    }
    this.applyClipboardPaste(null, null, targetCenter);
  }

  private applyOriginalGroupClipboardPaste(preview: ClipboardOriginalGroupPastePreview): void {
    const paste: ClipboardPasteResult = preview.paste;
    const plan: OriginalClipboardPastePlan = {
      strokes: paste.strokes, shapes: paste.shapes, textBlocks: paste.textBlocks,
      images: paste.images, mathBlocks: paste.mathBlocks,
      elementOrder: paste.elementOrder, groups: preview.groups,
      topGroupIds: preview.topGroupIds,
    };
    try {
      validateOriginalClipboardPastePlan(plan);
    } catch (e) {
      this.reportSaveFailure(e as Object);
      hilog.error(0x0001, 'NoteCanvasView',
        'original Group Paste preflight failed: %{public}s', JSON.stringify(e));
      return;
    }
    const generation: number = this.pageLoadGeneration;
    const pageId: string = this.loadedPageId;
    const draftOperation: Op = {
      opId: 'pending-original-clipboard-paste', noteId: this.noteId,
      opType: OpType.ORIGINAL_CLIPBOARD_PASTE, payload: new Uint8Array(0), clientTime: 0,
    };
    const draft: OriginalClipboardPasteAction = {
      type: UndoableActionType.ORIGINAL_CLIPBOARD_PASTE,
      noteId: this.noteId, pageId: pageId, operation: draftOperation,
    };
    const prepared: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(draft);
    this.historyBusy = true;
    this.persistence.commitOriginalClipboardPaste(
      this.noteId, pageId, plan, prepared).then(
      (result: OriginalClipboardPastePersistenceResult): void => {
        if (!this.strokeClipboard.commitPreparedPaste(
          paste.pasteSequence, paste.clipboardRevision)) {
          hilog.error(0x0001, 'NoteCanvasView',
            'original Group Paste sequence changed after durable apply');
        }
        const action: OriginalClipboardPasteAction = {
          type: UndoableActionType.ORIGINAL_CLIPBOARD_PASTE,
          noteId: this.noteId, pageId: pageId, operation: result.operation,
        };
        this.undoRedo.push(action, prepared);
        this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
        if (generation === this.pageLoadGeneration && pageId === this.loadedPageId &&
          pageId === this.currentPage.pageId && this.loaded && !this.dataLoading &&
          !this.dataLoadFailed) {
          this.completedStrokes = this.completedStrokes.concat(result.strokes);
          this.shapes = this.shapes.concat(result.shapes);
          this.textBlocks = this.textBlocks.concat(result.textBlocks);
          this.imageBlocks = this.imageBlocks.concat(result.images);
          this.mathBlocks = this.mathBlocks.concat(result.mathBlocks);
          this.elementOrder = clonePageElementOrder(result.elementOrder);
          this.selectionGroups = result.groups;
          this.synchronizeElementArraysByOrder();
          if (result.images.length > 0) {
            this.refreshImageAssets(this.pageLoadGeneration, pageId);
          }
          this.selectionTool.selectElementIds(
            result.strokes.map((stroke: StrokeElementData): string => stroke.id),
            result.shapes.map((shape: ShapeElement): string => shape.id),
            result.textBlocks.map((text: TextBlockElement): string => text.id),
            result.images.map((image: ImageElement): string => image.id),
            result.topGroupIds,
            result.mathBlocks.map((math: MathElement): string => math.id));
          this.originalInkIneligiblePages.delete(pageId);
          this.layerManager.rebuildFromStrokes(
            this.completedStrokes, this.renderCtx, this.viewport.zoom);
          this.updateSelectionOverlay();
          this.renderFrame();
        }
        this.notifyUndoRedo();
      }).catch((e: Object): void => {
        this.reportSaveFailure(e);
        hilog.error(0x0001, 'NoteCanvasView',
          'original Group Paste transaction failed: %{public}s', JSON.stringify(e));
      }).finally((): void => {
        this.historyBusy = false;
      });
  }

  private canEncodeOriginalClipboardSource(source: ClipboardSingleOriginalSource): boolean {
    try {
      if (source.kind === PageElementKind.STROKE && source.stroke !== undefined) {
        encodeOriginalLocalCreateInk({ timestamp: 1, siteId: 1, index: 0 }, source.stroke);
        return true;
      }
      if (source.kind === PageElementKind.SHAPE && source.shape !== undefined) {
        encodeOriginalLocalCreateShape({ timestamp: 1, siteId: 1, index: 0 }, source.shape, null);
        return true;
      }
      if (source.kind === PageElementKind.TEXT && source.textBlock !== undefined) {
        encodeOriginalLocalCreateTextBlock({ timestamp: 1, siteId: 1, index: 0 }, source.textBlock);
        encodeOriginalInitialInsertString({ timestamp: 1, siteId: 1 }, source.textBlock.richText);
        return true;
      }
    } catch (_error) {
      return false;
    }
    return false;
  }

  private applyClipboardPaste(originalCreate: OriginalInkCreateMetadata | null,
    originalCreateKind: PageElementKind | null, targetCenter: Point2D): void {
    const result: ClipboardPasteResult | null = this.strokeClipboard.preparePaste(
      this.getPaperWidth(), this.getPaperHeight(), targetCenter,
      (sourceId: string, sequence: number, index: number): string =>
        originalCreate === null ? this.createClipboardElementId(sourceId, sequence, index) :
          encodeOperationId({ timestamp: originalCreate.timestamp, siteId: originalCreate.siteId }),
      originalCreate === null ? null : originalCreateKind);
    if (result === null || (result.strokes.length === 0 && result.shapes.length === 0 &&
      result.textBlocks.length === 0 && result.images.length === 0 && result.mathBlocks.length === 0)) {
      return;
    }
    if (originalCreate !== null) {
      if (result.strokes.length === 1) {
        result.strokes[0].originalCreate = originalCreate;
      } else if (result.shapes.length === 1) {
        result.shapes[0].originalCreate = {
          timestamp: originalCreate.timestamp, siteId: originalCreate.siteId,
          clientTime: originalCreate.clientTime,
          pageTimestamp: originalCreate.pageTimestamp, pageSiteId: originalCreate.pageSiteId,
          pageIndex: originalCreate.pageIndex, pencilSeed: originalCreate.pencilSeed,
          averageForce: null,
        };
      } else if (result.textBlocks.length === 1) {
        result.textBlocks[0].originalCreate = originalCreate;
      } else {
        return;
      }
    }
    const elementOrderBefore: PageElementRef[] = clonePageElementOrder(this.elementOrder);
    const pastedIds: string[] = result.strokes.map((stroke: StrokeElementData): string => stroke.id);
    const pastedShapeIds: string[] = result.shapes.map((shape: ShapeElement): string => shape.id);
    const pastedTextIds: string[] = result.textBlocks.map(
      (textBlock: TextBlockElement): string => textBlock.id);
    const pastedImageIds: string[] = result.images.map((image: ImageElement): string => image.id);
    const pastedMathIds: string[] = result.mathBlocks.map((math: MathElement): string => math.id);
    const elementOrderAfter: PageElementRef[] | null = this.appendMixedElementRefs(
      this.elementOrder, result.elementOrder);
    if (elementOrderAfter === null) {
      return;
    }
    const action: UndoableAction = {
      type: UndoableActionType.ADD_ELEMENTS,
      noteId: this.noteId,
      pageId: this.loadedPageId,
      addedStrokes: result.strokes,
      addedShapes: result.shapes,
      addedTextBlocks: result.textBlocks,
      addedImages: result.images,
      addedMathBlocks: result.mathBlocks,
      addedElementOrder: clonePageElementOrder(result.elementOrder),
      elementOrderBefore: elementOrderBefore,
      elementOrderAfter: clonePageElementOrder(elementOrderAfter),
    };
    const preparedHistory: HistoryMetadata = this.undoRedo.prepareHistoryMetadata(action);
    const nextStrokes: StrokeElementData[] = this.completedStrokes.concat(result.strokes);
    const nextShapes: ShapeElement[] = this.shapes.concat(result.shapes);
    const nextTextBlocks: TextBlockElement[] = this.textBlocks.concat(result.textBlocks);
    const nextImages: ImageElement[] = this.imageBlocks.concat(result.images);
    const nextMathBlocks: MathElement[] = this.mathBlocks.concat(result.mathBlocks);
    const rearmOriginalInk: boolean = originalCreate !== null;
    try {
      this.persistence.queueSaveElements(this.noteId, this.loadedPageId,
        nextStrokes, nextTextBlocks, elementOrderAfter, nextShapes, true, preparedHistory,
        nextImages, nextMathBlocks);
    } catch (e) {
      this.reportSaveFailure(e as Object);
      return;
    }
    if (!this.strokeClipboard.commitPreparedPaste(
      result.pasteSequence, result.clipboardRevision)) {
      // preparePaste() and queueSaveElements() are synchronous on the ArkUI
      // thread, so no published clipboard can replace this revision between
      // them. Continue applying the already-enqueued document if that
      // invariant is ever violated, rather than diverging UI from storage.
      hilog.error(0x0001, 'NoteCanvasView',
        'ordinary Paste preparation changed after save enqueue');
    }
    const persistedPageId: string = this.loadedPageId;
    this.invalidateOriginalInkReservation();
    if (rearmOriginalInk) {
      this.originalInkIneligiblePages.delete(persistedPageId);
    } else {
      this.originalInkIneligiblePages.add(persistedPageId);
    }
    this.persistence.flush(this.noteId, persistedPageId).then((): void => {
      if (!this.persistence.hasDirtySave(this.noteId, persistedPageId)) {
        this.saveFailed = false;
      }
      if (rearmOriginalInk) {
        this.refreshOriginalInkReservation(this.pageLoadGeneration, persistedPageId);
      }
    }).catch((e: Object): void => this.reportSaveFailure(e));
    this.completedStrokes = nextStrokes;
    this.shapes = nextShapes;
    this.textBlocks = nextTextBlocks;
    this.imageBlocks = nextImages;
    this.mathBlocks = nextMathBlocks;
    this.elementOrder = elementOrderAfter;
    this.undoRedo.push(action, preparedHistory);
    this.lastQueuedHistoryRevision = this.undoRedo.getHistoryRevision();
    this.selectionTool.selectElementIds(
      pastedIds, pastedShapeIds, pastedTextIds, pastedImageIds, [], pastedMathIds);
    this.layerManager.rebuildFromStrokes(
      this.completedStrokes, this.renderCtx, this.viewport.zoom);
    this.updateSelectionOverlay();
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
        for (const math of this.mathBlocks) {
          if (math.id === id) {
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
        isPartialEraser: s.renderSpec.isPartialEraser,
        inkEffects: s.renderSpec.inkEffects,
        inkEffectsTinted: s.renderSpec.inkEffectsTinted,
        inkEffectPhase: s.renderSpec.inkEffectPhase,
        tapePattern: s.renderSpec.tapePattern,
      },
      transform: s.transform.slice(),
      bounds: {
        left: s.bounds.left, top: s.bounds.top,
        right: s.bounds.right, bottom: s.bounds.bottom,
      },
      maskPath: s.maskPath.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
      customPath: s.customPath === undefined ? undefined : s.customPath === null ? null :
        s.customPath.map((command: InkPathCommand): InkPathCommand => ({
          type: command.type,
          points: command.points.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
        })),
      fillPath: s.fillPath === undefined ? undefined : s.fillPath === null ? null :
        s.fillPath.map((command: InkPathCommand): InkPathCommand => ({
          type: command.type,
          points: command.points.map((point: Point2D): Point2D => ({ x: point.x, y: point.y })),
        })),
      fillColor: s.fillColor,
      styleMap: s.styleMap === undefined ? undefined :
        s.styleMap.map((entry: InkStyleMapEntry): InkStyleMapEntry => ({
          backingPencilSeed: entry.backingPencilSeed,
          backingPencilReferencePoint: {
            x: entry.backingPencilReferencePoint.x, y: entry.backingPencilReferencePoint.y,
          },
          backingDashPhase: entry.backingDashPhase,
          backingDashPeriod: entry.backingDashPeriod,
        })),
      audioStartTime: s.audioStartTime,
      audioDuration: s.audioDuration,
      originalCreate: s.originalCreate === undefined ? undefined : {
        timestamp: s.originalCreate.timestamp, siteId: s.originalCreate.siteId,
        clientTime: s.originalCreate.clientTime,
        pageTimestamp: s.originalCreate.pageTimestamp,
        pageSiteId: s.originalCreate.pageSiteId, pageIndex: s.originalCreate.pageIndex,
        pencilSeed: s.originalCreate.pencilSeed,
      },
      isFinished: s.isFinished,
    };
  }

  private pointInRect(p: Point2D, r: Rect2D): boolean {
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
  }

  // selectionRect 与触点均为屏幕坐标；命中区域必须复用覆盖层的钳制布局。
  private isInSelectionMenu(x: number, y: number): boolean {
    const position: SelectionOverlayPosition = selectionOverlayPosition(
      this.selectionRect, this.overlayWidth, this.overlayHeight, false);
    return x >= position.x && x <= position.x + SELECTION_MENU_BUTTON_WIDTH &&
      y >= position.actionY && y <= position.actionY + SELECTION_MENU_BUTTON_HEIGHT;
  }

  @Builder
  private ClipboardPasteContextMenu() {
    Menu() {
      if (this.canPasteClipboardNow()) {
        MenuItem({ content: $r('app.string.paste') })
          .onClick(() => {
            const target: Point2D | null = this.clipboardPasteTarget;
            if (target !== null) {
              hilog.info(0x0001, 'NoteCanvasView', 'canvas context Paste clicked');
              this.pasteClipboard(target);
            }
          });
      }
    }
  }

  // === 文本框 ===
  private createTextBlockAt(position: Point2D): void {
    const element: TextBlockElement = this.textBlockTool.createTextBlock(position,
      -16777216, 17);
    element.contentLeftInset = 5;
    element.contentTopInset = 3;
    element.contentRightInset = 5;
    element.contentBottomInset = 10;
    element.corner = 0;
    element.textWrap = 0;
    element.enableCaption = false;
    element.paper = null;
    element.resizesWidthToFitText = false;
    const originalCreate: OriginalInkCreateMetadata | null = this.originalInkReservation;
    this.originalInkReservation = null;
    if (originalCreate !== null) {
      originalCreate.clientTime = Math.max(originalCreate.clientTime, Date.now());
      element.id = encodeOperationId({
        timestamp: originalCreate.timestamp, siteId: originalCreate.siteId,
      });
      element.originalCreate = {
        timestamp: originalCreate.timestamp, siteId: originalCreate.siteId,
        clientTime: originalCreate.clientTime,
        pageTimestamp: originalCreate.pageTimestamp,
        pageSiteId: originalCreate.pageSiteId, pageIndex: originalCreate.pageIndex,
        pencilSeed: 0,
      };
      element.textOrigin = { x: 0, y: 0 };
      element.transform = [1, 0, position.x, 0, 1, position.y, 0, 0, 1];
      element.bounds = textBlockWorldBounds(element);
    }
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

  private toggleCheckboxMarkerAt(position: Point2D): boolean {
    for (let index: number = this.textBlocks.length - 1; index >= 0; index--) {
      const before: TextBlockElement = this.textBlocks[index];
      if (!pointHitsTextBlock(position, before)) {
        continue;
      }
      const codePointIndex: number | null = this.textRenderer.hitCheckboxMarker(
        before, this.renderCtx, position);
      if (codePointIndex === null) {
        continue;
      }
      const after: TextBlockElement | null = toggleOriginalCheckboxAt(before, codePointIndex);
      if (after === null) {
        return false;
      }
      this.replaceTextBlock(after);
      this.undoRedo.push({
        type: UndoableActionType.REPLACE_ELEMENT,
        noteId: this.noteId,
        pageId: this.currentPage.pageId,
        beforeStrokes: [],
        afterStrokes: [],
        beforeElements: [before],
        afterElements: [after],
      });
      this.notifyUndoRedo();
      this.persist();
      this.renderFrame(true);
      return true;
    }
    return false;
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

  async onTextCommit(text: string): Promise<boolean> {
    if (this.historyBusy) {
      return false;
    }
    let changed: boolean = false;
    let rearmOriginalCreate: boolean = false;
    if (this.editingTextBlock !== null) {
      if (this.editingOriginalTextBlock === null && text.length === 0) {
        this.onTextCancel();
        return true;
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
        rearmOriginalCreate = updated.originalCreate !== undefined;
      } else if (this.editingOriginalTextBlock.richText !== text &&
        decodeOperationId(this.editingOriginalTextBlock.id) === null) {
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
      } else if (this.editingOriginalTextBlock.richText !== text) {
        const editing: TextBlockElement = this.editingTextBlock;
        const original: TextBlockElement = this.editingOriginalTextBlock;
        const pageId: string = this.currentPage.pageId;
        const loadedPageId: string = this.loadedPageId;
        this.historyBusy = true;
        let preview: OriginalTextEditPreview | null = null;
        try {
          preview = await this.persistence.previewOriginalTextEdit(
            this.noteId, pageId, original, text);
        } catch (e) {
          hilog.error(0x0001, 'NoteCanvasView',
            'original Text edit preview failed: %{public}s', JSON.stringify(e));
        } finally {
          this.historyBusy = false;
        }
        if (preview === null) {
          hilog.error(0x0001, 'NoteCanvasView',
            'original Text edit rejected because CRDT style preview diverged');
          return false;
        }
        if (this.editingTextBlock !== editing || this.editingOriginalTextBlock !== original ||
          this.currentPage.pageId !== pageId || this.loadedPageId !== loadedPageId) {
          return false;
        }
        let updated: TextBlockElement = this.textBlockTool.updateText(
          editing, text, preview.characterStyleRuns, preview.paragraphStyleRuns);
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
      this.persist(rearmOriginalCreate);
    }
    if (this.lifecycleActive) {
      this.renderFrame(true);
    }
    return true;
  }

  onTextCancel(): void {
    if (this.historyBusy) {
      return;
    }
    let cancelledOriginalCreate: boolean = false;
    if (this.editingTextBlock !== null && this.editingOriginalTextBlock === null) {
      const id: string = this.editingTextBlock.id;
      cancelledOriginalCreate = this.editingTextBlock.originalCreate !== undefined;
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
    if (cancelledOriginalCreate) {
      this.refreshOriginalInkReservation(this.pageLoadGeneration, this.loadedPageId);
    } else {
      this.persist();
    }
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
        // Original w43/v49 expose Paste from the long-press position, not from
        // a fixed viewport button.  ArkUI's context menu keeps that native
        // anchor and performs the same edge adjustment as the platform menu.
        .bindContextMenu(() => {
          this.ClipboardPasteContextMenu();
        }, ResponseType.LongPress)
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
                  this.schedulePdfRasterRefresh(0);
                })
                .onActionCancel(() => {
                  this.gestureTracker.resetScale();
                  this.schedulePdfRasterRefresh(0);
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
                  this.schedulePdfRasterRefresh(0);
                })
                .onActionCancel(() => {
                  this.gestureTracker.resetPan();
                  this.schedulePdfRasterRefresh(0);
                }),
            ),
          ),
        )
      // 选区覆盖层（虚线边框 + 菜单）
      SelectionOverlay({
        selectionRect: this.selectionRect,
        visible: this.selectionVisible,
        canPaste: this.canPasteClipboardNow(),
        canFlip: this.selectionCanFlip,
        canCrop: this.selectionCanCrop,
        canLock: this.selectionCanLock,
        canGroup: this.selectionCanGroup,
        canUngroup: this.selectionCanUngroup,
        canEditMath: this.selectionCanEditMath,
        positionLocked: this.selectionPositionLocked,
        containerWidth: this.overlayWidth,
        containerHeight: this.overlayHeight,
        onMenuAction: (action: SelectionMenuAction) => {
          this.onSelectionMenuAction(action);
        },
      })
      ImageCropOverlay({
        visible: this.imageCropVisible,
        corners: this.imageCropScreenCorners(),
        containerWidth: this.overlayWidth,
        containerHeight: this.overlayHeight,
        onMove: (handle: ImageCropHandle, deltaX: number, deltaY: number) => {
          this.moveImageCropHandle(handle, deltaX, deltaY);
        },
        onClose: () => this.cancelImageCrop(),
        onReset: () => this.resetImageCrop(),
        onConfirm: () => this.confirmImageCrop(),
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
        onCommit: async (text: string): Promise<boolean> => {
          try {
            return await this.onTextCommit(text);
          } catch (e) {
            hilog.error(0x0001, 'NoteCanvasView',
              'Text commit failed: %{public}s', JSON.stringify(e));
            return false;
          }
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
      MathEditorOverlay({
        visible: this.mathEditorVisible,
        draft: this.mathEditorDraft,
        draftState: this.mathEditorDraftState,
        preview: this.mathEditorPreview === null ? null : this.mathEditorPreview.pixelMap,
        busy: this.mathEditorBusy,
        failed: this.mathEditorFailed,
        containerWidth: this.overlayWidth,
        onDraftChange: (value: string): void => {
          this.mathEditorDraft = value;
          this.mathEditorFailed = false;
          this.requestMathEditorDraftValidation();
        },
        onCancel: (): void => this.cancelMathEditing(),
        onConfirm: (): void => {
          this.confirmMathEditing().catch((e: Object): void => {
            this.mathEditorFailed = true;
            hilog.error(0x0001, 'NoteCanvasView',
              'Math editor confirmation failed: %{public}s', JSON.stringify(e));
          });
        },
      })
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
        this.schedulePdfRasterRefresh(0);
      }
    })
  }
}
