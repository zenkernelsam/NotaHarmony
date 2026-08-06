// T-020/T-025 画布视图组件（Phase 2 NoteCanvasPage 重构为可嵌入 @Component）
// 集成：纸张背景 / 笔迹渲染 / UndoRedo / 形状识别 / 选区变换 / 文本框 / 持久化
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RawPointerEvent } from '../../core/adaptation/InkInputProvider';
import { InkInputProviderImpl } from '../../core/adaptation/InkInputProviderImpl';
import { NullPredictor } from '../../core/adaptation/NullPredictor';
import { Canvas2DStrokeRenderer, Canvas2DRenderContext } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { StrokeLayerManager } from '../../rendering/StrokeLayerManager';
import { CanvasViewport } from '../../rendering/CanvasViewport';
import { StrokeSession } from '../../rendering/StrokeSession';
import { EraserEngine, EraserMode } from '../../rendering/EraserEngine';
import { PaperRenderer } from '../../rendering/PaperRenderer';
import { UndoRedoManager, UndoableAction, UndoableActionType } from '../../rendering/UndoRedoManager';
import { SelectionTool, SelectionMode } from '../../rendering/SelectionTool';
import { TextBlockTool } from '../../rendering/TextBlockTool';
import { ShapeDetector } from '../../core/algorithm/ShapeDetector';
import { StrokePersistence } from '../../data/StrokePersistence';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { RenderSpec, StrokeElementData, StrokePathPoint, InputBatch } from '../../core/model/StrokeTypes';
import { ToolType } from '../../core/model/BrushTypes';
import {
  EllipseElement, PolygonElement, TextBlockElement, NoteElement,
} from '../../core/model/ElementTypes';
import { Point2D, Rect2D } from '../../core/model/GeometryTypes';
import { PageInfo, PaperTemplate } from '../../core/model/NoteTypes';
import { EditorViewModel } from './EditorViewModel';
import { SelectionOverlay, SelectionMenuAction } from '../components/SelectionOverlay';
import { TextBlockOverlay } from '../components/TextBlockOverlay';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Component
export struct NoteCanvasView {
  // === 外部输入 ===
  @ObjectLink viewModel: EditorViewModel;
  @Prop noteId: string = '';
  // T-040 修复：页面设置（模板/尺寸/方向）变化时重绘画布
  @Prop @Watch('onPageChange') currentPage: PageInfo = {
    pageId: '', size: 1, template: 0, orientation: 0, widthMm: 210, heightMm: 297,
  };
  @Prop @Watch('onUndoSignalChange') undoSignal: number = 0;
  @Prop @Watch('onRedoSignalChange') redoSignal: number = 0;
  onUndoRedoChanged: (canUndo: boolean, canRedo: boolean) => void = () => {
  };

  // === 内部模块 ===
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderCtx: Canvas2DRenderContext = new Canvas2DRenderContext(this.canvasCtx);
  private inputProvider: InkInputProviderImpl = new InkInputProviderImpl(true, false, false);
  private predictor: NullPredictor = new NullPredictor();
  private renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
  private layerManager: StrokeLayerManager = new StrokeLayerManager(this.renderer);
  private strokeSession: StrokeSession | null = null;
  private eraserEngine: EraserEngine = new EraserEngine(EraserMode.WHOLE, 20);
  private paperRenderer: PaperRenderer = new PaperRenderer();
  private undoRedo: UndoRedoManager = new UndoRedoManager();
  private shapeDetector: ShapeDetector = new ShapeDetector();
  private persistence: StrokePersistence = new StrokePersistence();
  private selectionTool: SelectionTool = new SelectionTool();
  private textBlockTool: TextBlockTool = new TextBlockTool();
  // T-034：画布视口（缩放/平移）
  private viewport: CanvasViewport = new CanvasViewport();
  private viewportSaveTimer: number = -1;   // 防抖定时器
  private pinchLastScale: number = -1;      // 捏合累计缩放（手势增量换算）
  @State zoomPercent: number = 100;         // 控制条显示（100 = 100%）
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // === 画布状态 ===
  private completedStrokes: StrokeElementData[] = [];
  private textBlocks: TextBlockElement[] = [];
  private eraserPath: Point2D[] = [];
  private isDrawing: boolean = false;
  private eraserActive: boolean = false;
  private selectionDrawing: boolean = false;
  private selectionDrag: boolean = false;
  private dragBeforeStrokes: StrokeElementData[] = [];
  private lastDragPoint: Point2D = { x: 0, y: 0 };
  private lastTapTime: number = 0;
  private lastTapPos: Point2D = { x: 0, y: 0 };
  private loaded: boolean = false;
  @State textEditing: boolean = false;
  @State editingTextBlock: TextBlockElement | null = null;
  @State selectionRect: Rect2D = { left: 0, top: 0, right: 0, bottom: 0 };
  @State selectionVisible: boolean = false;

  aboutToAppear(): void {
    this.loadNoteData();
  }

  // === 数据加载与持久化 ===
  private async loadNoteData(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const db: DatabaseManager = DatabaseManager.getInstance();
      await db.initialize(context);
      this.persistence.initialize(db);
      const loaded = await this.persistence.loadElements(this.noteId);
      this.completedStrokes = loaded.strokes;
      this.textBlocks = loaded.textBlocks;
      // T-034：恢复视口（zoom/scroll）
      const noteRepo = new NoteRepositoryImpl(db);
      const state = await noteRepo.getViewState(this.noteId);
      if (state !== null && state.zoom > 0) {
        this.viewport.setZoom(state.zoom);
        this.viewport.setScroll(state.scrollOffsetX, state.scrollOffsetY);
        this.zoomPercent = Math.round(state.zoom * 100);
      }
      this.loaded = true;
      if (this.layerManager.isInitialized()) {
        this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
        this.renderFrame();
      }
    } catch (e) {
      console.error(`NoteCanvasView load failed: ${JSON.stringify(e)}`);
    }
  }

  private persist(): void {
    if (this.persistence.isReady() && this.noteId.length > 0) {
      this.persistence.saveElements(this.noteId, this.completedStrokes, this.textBlocks);
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
    this.renderFrame();
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
    this.layerManager.initialize(w, h);
    this.renderer.setEraserMaskWidth(20);
    this.predictor.reset();
    if (this.loaded) {
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    }
    this.renderFrame();
  }

  // === 每帧渲染（背景 + 已完成层 + 当前笔画 + 文本框）===
  // T-034：视口变换（translate + scale）后以画布坐标绘制，背景铺满视口可见区
  private renderFrame(): void {
    if (!this.layerManager.isInitialized()) {
      return;
    }
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    this.canvasCtx.save();
    this.canvasCtx.clearRect(0, 0, w, h);
    this.canvasCtx.translate(this.viewport.scrollX, this.viewport.scrollY);
    this.canvasCtx.scale(this.viewport.zoom, this.viewport.zoom);
    // T-038：纸张底色/线色随主题；T-040：纸张按 mm 尺寸居中绘制
    const theme: ThemeTokens = ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
    this.paperRenderer.renderBackground(this.canvasCtx, w / this.viewport.zoom,
      h / this.viewport.zoom, this.currentPage.template as PaperTemplate, this.viewport.zoom, theme,
      this.currentPage.widthMm, this.currentPage.heightMm);
    const current: StrokeElementData | null = this.strokeSession !== null && this.strokeSession.isActive()
      ? this.strokeSession.getCurrentStroke() : null;
    this.layerManager.compositeFull(this.canvasCtx, current, this.renderCtx);
    // 文本框渲染（笔画层之上）
    for (const t of this.textBlocks) {
      this.textBlockTool.renderText(this.canvasCtx, t);
    }
    this.canvasCtx.restore();
  }

  // === T-034：视口操作 ===
  private onViewportChanged(): void {
    this.zoomPercent = Math.round(this.viewport.zoom * 100);
    this.renderFrame();
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
    const paperW: number = this.currentPage.widthMm > 0 ? this.currentPage.widthMm * 3.78 : 800;
    const fit: number = (w * 0.85) / paperW;
    const clamped: number = fit < 0.25 ? 0.25 : (fit > 4.0 ? 4.0 : fit);
    this.viewport.setZoom(clamped);
    this.onViewportChanged();
  }

  // === 触摸事件 ===
  private onCanvasTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.onTouchDown(event);
    } else if (event.type === TouchType.Move) {
      this.onTouchMove(event);
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.onTouchUp();
    }
  }

  private onTouchDown(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }
    // T-034：双指手势接管（捏合缩放/双指平移），单指书写
    if (event.touches.length > 1) {
      return;
    }
    const touch: TouchObject = event.touches[0];
    // 双击检测（创建文本框；屏幕坐标距离判断）
    const now: number = Date.now();
    const dx: number = touch.x - this.lastTapPos.x;
    const dy: number = touch.y - this.lastTapPos.y;
    const dist: number = Math.sqrt(dx * dx + dy * dy);
    if (now - this.lastTapTime < 800 && dist < 10) {  // MVP 放宽到 800ms 便于模拟器验证
      this.lastTapTime = 0;
      this.createTextBlockAt(this.viewport.screenToCanvas(touch.x, touch.y));
      return;
    }
    this.lastTapTime = now;
    this.lastTapPos = { x: touch.x, y: touch.y };

    // T-034：后续逻辑统一使用画布坐标（视口逆映射）
    const canvasP: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);

    // 选区菜单区域：交给 SelectionOverlay 按钮处理，不进入画布逻辑
    // （避免 Canvas onTouch 触发 rebuild 导致按钮 click 识别失效；菜单按钮为屏幕坐标）
    if (this.selectionVisible && this.isInSelectionMenu(touch.x, touch.y)) {
      return;
    }

    if (this.viewModel.isEraserActive()) {
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
      if (this.selectionVisible && this.pointInRect(canvasP, this.selectionRect)) {
        hilog.info(0x0001, 'NoteCanvasView', 'selection drag start at (%{public}f,%{public}f) rect=(%{public}f,%{public}f)-(%{public}f,%{public}f)',
          canvasP.x, canvasP.y, this.selectionRect.left, this.selectionRect.top,
          this.selectionRect.right, this.selectionRect.bottom);
        this.selectionDrag = true;
        this.dragBeforeStrokes = this.completedStrokes.slice();
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
    const startTime: number = Date.now();
    // T-040 审核修复：传入当前 zoom（拟合容差按屏幕空间计算）
    this.strokeSession.beginStroke(spec, startTime, this.viewport.zoom);
    this.inputProvider.beginStroke(startTime);
    const batch: InputBatch = this.inputProvider.processEvent(
      [this.toRawPointerEvent(touch, false)], false);
    this.strokeSession.addBatch(batch);
    this.isDrawing = true;
    this.renderFrame();
  }

  private onTouchMove(event: TouchEvent): void {
    if (!this.isDrawing) {
      return;
    }
    // T-034：双指手势接管
    if (event.touches.length > 1) {
      return;
    }
    if (this.eraserActive) {
      for (const t of event.touches) {
        this.collectEraserPoint(t);
      }
      return;
    }
    if (this.selectionDrawing) {
      const touch: TouchObject = event.touches[0];
      const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
      this.selectionTool.updateSelection(p);
      return;
    }
    if (this.selectionDrag) {
      const touch: TouchObject = event.touches[0];
      const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
      const dx: number = p.x - this.lastDragPoint.x;
      const dy: number = p.y - this.lastDragPoint.y;
      this.lastDragPoint = { x: p.x, y: p.y };
      this.selectionTool.moveSelected(dx, dy);
      this.applySelectionTransform(false, false);  // 移动中不 push undo（结束时统一 push）
      return;
    }
    const rawEvents: RawPointerEvent[] = [];
    for (const t of event.touches) {
      rawEvents.push(this.toRawPointerEvent(t, false));
    }
    const batch: InputBatch = this.inputProvider.processEvent(rawEvents, false);
    if (this.strokeSession !== null) {
      this.strokeSession.addBatch(batch);
    }
    this.renderFrame();
  }

  private onTouchUp(): void {
    if (!this.isDrawing) {
      return;
    }
    if (this.eraserActive) {
      this.applyEraser();
      this.eraserActive = false;
      this.eraserPath = [];
    } else if (this.selectionDrawing) {
      const ids: string[] = this.selectionTool.finalizeSelection(this.completedStrokes);
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
      // 移动完成：统一记录一次 undo
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_STROKES,
        addedStroke: null,
        removedStrokes: [],
        beforeStrokes: this.dragBeforeStrokes,
        afterStrokes: this.completedStrokes.slice(),
      });
      this.persist();
      this.notifyUndoRedo();
    } else if (this.strokeSession !== null && this.strokeSession.isActive()) {
      const stroke: StrokeElementData = this.strokeSession.finishStroke();
      hilog.info(0x0001, 'NoteCanvasView', 'stroke finished, pts=%{public}d', stroke.pathPoints.length);
      // 形状识别（Pen 工具，识别成功则替换为形状笔画；T-036：REPLACE_ELEMENT 入栈，undo 恢复原笔画）
      let finalStroke: StrokeElementData = stroke;
      let replaced: boolean = false;
      if (this.viewModel.currentTool === ToolType.PEN && this.viewModel.shapeDetectionEnabled) {
        const detected: StrokeElementData = this.tryShapeDetect(stroke);
        if (detected.id === stroke.id && detected.pathPoints.length !== stroke.pathPoints.length) {
          // 识别成功（形状点序列变化）
          finalStroke = detected;
          replaced = true;
        }
      }
      this.completedStrokes.push(finalStroke);
      if (replaced) {
        this.undoRedo.push({
          type: UndoableActionType.REPLACE_ELEMENT,
          addedStroke: finalStroke,
          removedStrokes: [],
          beforeStrokes: [stroke],
          afterStrokes: [finalStroke],
        });
      } else {
        this.undoRedo.push({
          type: UndoableActionType.ADD_STROKE,
          addedStroke: finalStroke,
          removedStrokes: [],
          beforeStrokes: [],
          afterStrokes: [],
        });
      }
      hilog.info(0x0001, 'NoteCanvasView', 'pushed ADD_STROKE, canUndo=%{public}s',
        this.undoRedo.canUndo().toString());
      this.layerManager.commitStroke(finalStroke, this.renderCtx);
      this.persist();
      this.notifyUndoRedo();
      hilog.info(0x0001, 'NoteCanvasView', 'after notify, canUndo=%{public}s',
        this.undoRedo.canUndo().toString());
    }
    this.isDrawing = false;
    this.renderFrame();
  }

  // === 形状识别 ===
  private tryShapeDetect(stroke: StrokeElementData): StrokeElementData {
    const pts: Point2D[] = [];
    for (const p of stroke.pathPoints) {
      pts.push(p.position);
    }
    const result = this.shapeDetector.recognizeShape(pts);
    if (result === null || result.elements.length === 0) {
      hilog.info(0x0001, 'NoteCanvasView', 'shape detect: no match, pts=%{public}d', pts.length);
      return stroke;
    }
    hilog.info(0x0001, 'NoteCanvasView', 'shape detect: match confidence=%{public}f', result.confidence);
    const element: NoteElement = result.elements[0];
    const probe: EllipseElement = element as EllipseElement;
    if (probe.radiusX === undefined || probe.center === undefined) {
      return stroke;  // 仅支持椭圆/多边形替换
    }
    return this.elementToStroke(element, stroke);
  }

  // 识别元素 → 形状笔画（采样点序列，保持渲染链不变）
  private elementToStroke(element: NoteElement, original: StrokeElementData): StrokeElementData {
    const points: Point2D[] = [];
    const ellipse: EllipseElement = element as EllipseElement;
    if (ellipse.radiusX !== undefined && ellipse.center !== undefined) {
      // 椭圆
      const steps: number = 32;
      for (let i = 0; i <= steps; i++) {
        const a: number = (i / steps) * Math.PI * 2;
        points.push({
          x: ellipse.center.x + Math.cos(a) * ellipse.radiusX,
          y: ellipse.center.y + Math.sin(a) * ellipse.radiusY,
        });
      }
    } else {
      // 多边形
      const poly: PolygonElement = element as PolygonElement;
      for (const v of poly.vertices) {
        points.push(v);
      }
      if (poly.isClosed && poly.vertices.length > 0) {
        points.push(poly.vertices[0]);  // 闭合
      }
    }
    const pathPoints: StrokePathPoint[] = [];
    for (const pt of points) {
      pathPoints.push({ position: pt, widthFactor: 1.0 });
    }
    return {
      id: original.id,
      pathPoints: pathPoints,
      cubicSegments: [],
      splatPoints: [],
      renderSpec: original.renderSpec,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: element.bounds,
      maskPath: [],
      isFinished: true,
    };
  }

  // === 橡皮擦 ===
  private applyEraser(): void {
    if (this.eraserPath.length === 0) {
      return;
    }
    const before: StrokeElementData[] = this.completedStrokes.slice();
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
    // 记录 undo（擦除）
    const removed: StrokeElementData[] = [];
    for (const s of before) {
      let stillThere: boolean = false;
      for (const cur of this.completedStrokes) {
        if (cur.id === s.id) {
          stillThere = true;
          break;
        }
      }
      if (!stillThere) {
        removed.push(s);
      }
    }
    if (removed.length > 0) {
      this.undoRedo.push({
        type: UndoableActionType.ERASE_STROKES,
        addedStroke: null,
        removedStrokes: removed,
        beforeStrokes: [],
        afterStrokes: [],
      });
    }
    // T-040 审核修复：PARTIAL 擦除（maskPath 挖洞）也需入栈可撤销
    // （before=受影响笔画擦除前快照，after=擦除后快照；undo 恢复原笔画，redo 重新挖洞）
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
    if (partialBefore.length > 0) {
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_STROKES,
        addedStroke: null,
        removedStrokes: [],
        beforeStrokes: partialBefore,
        afterStrokes: partialAfter,
      });
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.notifyUndoRedo();
  }

  private collectEraserPoint(touch: TouchObject): void {
    const p: RawPointerEvent = this.toRawPointerEvent(touch, false);
    this.eraserPath.push({ x: p.x, y: p.y });
  }

  // === Undo / Redo ===
  private undoStroke(): void {
    hilog.info(0x0001, 'NoteCanvasView', 'undoStroke called, canUndo=%{public}s',
      this.undoRedo.canUndo().toString());
    const action: UndoableAction | null = this.undoRedo.undo();
    if (action === null) {
      return;
    }
    this.applyAction(action, true);
  }

  private redoStroke(): void {
    const action: UndoableAction | null = this.undoRedo.redo();
    if (action === null) {
      hilog.info(0x0001, 'NoteCanvasView', 'redoStroke: no action');
      return;
    }
    hilog.info(0x0001, 'NoteCanvasView', 'redoStroke called, type=%{public}d added=%{public}s',
      action.type, action.addedStroke !== null ? action.addedStroke.id : 'null');
    this.applyAction(action, false);
  }

  // isUndo=true 执行反向；false 执行正向
  private applyAction(action: UndoableAction, isUndo: boolean): void {
    if (action.type === UndoableActionType.ADD_STROKE && action.addedStroke !== null) {
      if (isUndo) {
        this.removeStrokeById(action.addedStroke.id);
      } else {
        this.completedStrokes.push(action.addedStroke);
      }
    } else if (action.type === UndoableActionType.ERASE_STROKES) {
      if (isUndo) {
        for (const s of action.removedStrokes) {
          this.completedStrokes.push(s);
        }
      } else {
        for (const s of action.removedStrokes) {
          this.removeStrokeById(s.id);
        }
      }
    } else if (action.type === UndoableActionType.DELETE_STROKE) {
      if (isUndo) {
        for (const s of action.removedStrokes) {
          this.completedStrokes.push(s);
        }
      } else {
        for (const s of action.removedStrokes) {
          this.removeStrokeById(s.id);
        }
      }
    } else if (action.type === UndoableActionType.TRANSFORM_STROKES) {
      // T-040 审核修复：按 id 替换（before/after 可为选中笔画子集快照，避免整表替换丢失其他笔画）
      const target: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      for (const t of target) {
        let found: boolean = false;
        for (let i = 0; i < this.completedStrokes.length; i++) {
          if (this.completedStrokes[i].id === t.id) {
            this.completedStrokes[i] = t;
            found = true;
            break;
          }
        }
        if (!found) {
          this.completedStrokes.push(t);
        }
      }
    } else if (action.type === UndoableActionType.ADD_ELEMENT) {
      // T-036：文本框创建
      if (isUndo) {
        if (action.addedElement !== undefined && action.addedElement !== null) {
          this.removeTextBlockById(action.addedElement.id);
        }
      } else if (action.addedElement !== undefined && action.addedElement !== null) {
        this.textBlocks.push(action.addedElement);
      }
    } else if (action.type === UndoableActionType.DELETE_ELEMENT) {
      // T-036：文本框删除
      if (isUndo) {
        if (action.removedElements !== undefined) {
          for (const t of action.removedElements) {
            this.textBlocks.push(t);
          }
        }
      } else if (action.removedElements !== undefined) {
        for (const t of action.removedElements) {
          this.removeTextBlockById(t.id);
        }
      }
    } else if (action.type === UndoableActionType.REPLACE_ELEMENT) {
      // T-036：形状替换（撤销恢复原笔画，重做恢复形状）
      // T-040 审核修复：按 id 替换（原实现整表替换会丢失其他笔画）
      const target: StrokeElementData[] = isUndo ? action.beforeStrokes : action.afterStrokes;
      for (const t of target) {
        let found: boolean = false;
        for (let i = 0; i < this.completedStrokes.length; i++) {
          if (this.completedStrokes[i].id === t.id) {
            this.completedStrokes[i] = t;
            found = true;
            break;
          }
        }
        if (!found) {
          this.completedStrokes.push(t);
        }
      }
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.notifyUndoRedo();
    this.renderFrame();
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
    const before: StrokeElementData[] = this.completedStrokes.slice();
    this.completedStrokes = this.selectionTool.applyTransform(this.completedStrokes);
    if (pushUndo) {
      this.undoRedo.push({
        type: UndoableActionType.TRANSFORM_STROKES,
        addedStroke: null,
        removedStrokes: [],
        beforeStrokes: before,
        afterStrokes: this.completedStrokes.slice(),
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
    hilog.info(0x0001, 'NoteCanvasView', 'selection menu action=%{public}d', action);
    const state = this.selectionTool.getState();
    if (action === SelectionMenuAction.DELETE || action === SelectionMenuAction.CUT) {
      const ids: string[] = this.selectionTool.deleteSelected();
      const removed: StrokeElementData[] = [];
      for (const s of this.completedStrokes) {
        if (ids.indexOf(s.id) >= 0) {
          removed.push(s);
        }
      }
      for (const s of removed) {
        this.removeStrokeById(s.id);
      }
      if (removed.length > 0) {
        this.undoRedo.push({
          type: UndoableActionType.DELETE_STROKE,
          addedStroke: null,
          removedStrokes: removed,
          beforeStrokes: [],
          afterStrokes: [],
        });
      }
      this.selectionVisible = false;
      this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
      this.persist();
      this.notifyUndoRedo();
      this.renderFrame();
    } else if (action === SelectionMenuAction.DESELECT) {
      this.selectionTool.deselect();
      this.selectionVisible = false;
    } else if (action === SelectionMenuAction.SEND_FORWARD || action === SelectionMenuAction.SEND_BACKWARD) {
      this.reorderSelected(state.selectedStrokeIds, action === SelectionMenuAction.SEND_FORWARD);
    } else if (action === SelectionMenuAction.FLIP_H || action === SelectionMenuAction.FLIP_V) {
      this.flipSelected(state.selectedStrokeIds, action === SelectionMenuAction.FLIP_H);
    } else if (action === SelectionMenuAction.COPY) {
      this.copySelected(state.selectedStrokeIds);
    }
  }

  private reorderSelected(ids: string[], forward: boolean): void {
    const before: StrokeElementData[] = this.completedStrokes.slice();
    const order: StrokeElementData[] = [];
    const selected: StrokeElementData[] = [];
    for (const s of this.completedStrokes) {
      if (ids.indexOf(s.id) >= 0) {
        selected.push(s);
      } else {
        order.push(s);
      }
    }
    if (forward) {
      this.completedStrokes = order.concat(selected);
    } else {
      this.completedStrokes = selected.concat(order);
    }
    this.undoRedo.push({
      type: UndoableActionType.TRANSFORM_STROKES,
      addedStroke: null,
      removedStrokes: [],
      beforeStrokes: before,
      afterStrokes: this.completedStrokes.slice(),
    });
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.notifyUndoRedo();
    this.renderFrame();
  }

  private flipSelected(ids: string[], horizontal: boolean): void {
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
    const cx: number = (minX + maxX) / 2;
    const cy: number = (minY + maxY) / 2;
    const flip: number[] = horizontal ? [-1, 0, cx * 2, 0, 1, 0, 0, 0, 1] : [1, 0, 0, 0, -1, cy * 2, 0, 0, 1];
    this.selectionTool.getState().transform = flip;
    this.applySelectionTransform(true, true);
    this.selectionTool.getState().transform = [1, 0, 0, 0, 1, 0, 0, 0, 1];
  }

  private copySelected(ids: string[]): void {
    const copies: StrokeElementData[] = [];
    for (const s of this.completedStrokes) {
      if (ids.indexOf(s.id) >= 0) {
        copies.push(this.cloneStroke(s));
      }
    }
    for (const c of copies) {
      this.completedStrokes.push(c);
    }
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
    this.persist();
    this.renderFrame();
  }

  private cloneStroke(s: StrokeElementData): StrokeElementData {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return {
      id: timePart + randPart,
      pathPoints: s.pathPoints.slice(),
      cubicSegments: s.cubicSegments.slice(),
      splatPoints: s.splatPoints.slice(),
      renderSpec: s.renderSpec,
      transform: s.transform.slice(),
      bounds: {
        left: s.bounds.left + 20,
        top: s.bounds.top + 20,
        right: s.bounds.right + 20,
        bottom: s.bounds.bottom + 20,
      },
      maskPath: s.maskPath.slice(),
      isFinished: s.isFinished,
    };
  }

  private pointInRect(p: Point2D, r: Rect2D): boolean {
    return p.x >= r.left && p.x <= r.right && p.y >= r.top && p.y <= r.bottom;
  }

  // 判断点击位置是否在选区菜单按钮区域（菜单按钮在选区下方；T-033 单按钮 + bindMenu）
  // T-034：selectionRect 已转换为屏幕坐标，入参为屏幕坐标
  private isInSelectionMenu(x: number, y: number): boolean {
    const menuTop: number = this.selectionRect.bottom + 8;
    const menuBottom: number = menuTop + 48;
    const menuLeft: number = this.selectionRect.left;
    const menuRight: number = menuLeft + 130;
    return x >= menuLeft && x <= menuRight && y >= menuTop && y <= menuBottom;
  }

  // === 文本框 ===
  private createTextBlockAt(position: Point2D): void {
    const element: TextBlockElement = this.textBlockTool.createTextBlock(position,
      this.viewModel.brushColor, 24);
    this.textBlocks.push(element);
    this.editingTextBlock = element;
    this.textEditing = true;
    this.renderFrame();
  }

  onTextCommit(text: string): void {
    if (this.editingTextBlock !== null) {
      const updated: TextBlockElement = this.textBlockTool.updateText(this.editingTextBlock, text);
      for (let i = 0; i < this.textBlocks.length; i++) {
        if (this.textBlocks[i].id === updated.id) {
          this.textBlocks[i] = updated;
          break;
        }
      }
      // T-036：文本框创建入栈（undo 删除，redo 恢复）
      this.undoRedo.push({
        type: UndoableActionType.ADD_ELEMENT,
        addedStroke: null,
        removedStrokes: [],
        beforeStrokes: [],
        afterStrokes: [],
        addedElement: updated,
        removedElements: [],
      });
      this.notifyUndoRedo();
    }
    this.textEditing = false;
    this.editingTextBlock = null;
    this.persist();
    this.renderFrame();
  }

  onTextCancel(): void {
    if (this.editingTextBlock !== null) {
      const id: string = this.editingTextBlock.id;
      const remaining: TextBlockElement[] = [];
      for (const t of this.textBlocks) {
        if (t.id !== id) {
          remaining.push(t);
        }
      }
      this.textBlocks = remaining;
      // T-040 审核修复：取消编辑 = 放弃创建，不应入栈
      // （原实现 push DELETE_ELEMENT，undo 后会恢复一个空文本框）
    }
    this.textEditing = false;
    this.editingTextBlock = null;
    this.renderFrame();
  }

  // === RenderSpec 构建 ===
  private makeRenderSpec(): RenderSpec {
    return this.viewModel.getRenderSpec();
  }

  // === TouchPoint → RawPointerEvent 转换 ===
  // T-034：坐标经视口逆映射（屏幕 → 画布）
  // T-040 审核修复：TouchObject.pressure 已是 [0,1] 归一化值，不能再除以 65535
  // （原实现导致所有笔画 pressure≈0 → widthFactor 恒为下限 0.3）
  private toRawPointerEvent(touch: TouchObject, isHistorical: boolean): RawPointerEvent {
    const rawPressure: number = touch.pressure !== undefined ? touch.pressure : 0;
    const pressure: number = rawPressure > 0 ? Math.min(rawPressure, 1) : 0;
    const p: Point2D = this.viewport.screenToCanvas(touch.x, touch.y);
    return {
      x: p.x,
      y: p.y,
      pressure: pressure,
      tiltRadians: 0,
      orientationRadians: 0,
      toolType: 0,
      timestamp: Date.now(),
      isHistorical: isHistorical,
    };
  }

  build() {
    Stack() {
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
                  const last: number = this.pinchLastScale >= 0 ? this.pinchLastScale : 1.0;
                  const factor: number = last > 0 ? scale / last : 1.0;
                  this.pinchLastScale = scale;
                  this.viewport.zoomAt(cx, cy, factor);
                  this.onViewportChanged();
                })
                .onActionEnd(() => {
                  this.pinchLastScale = -1;
                }),
              PanGesture({ fingers: 2 })
                .onActionUpdate((event: GestureEvent) => {
                  if (event.offsetX !== undefined && event.offsetY !== undefined) {
                    this.viewport.panBy(event.offsetX, event.offsetY);
                    this.onViewportChanged();
                  }
                }),
            ),
          ),
        )
      // 选区覆盖层（虚线边框 + 菜单）
      SelectionOverlay({
        selectionRect: this.selectionRect,
        visible: this.selectionVisible,
        onMenuAction: (action: SelectionMenuAction) => {
          this.onSelectionMenuAction(action);
        },
      })
      // 文本框编辑覆盖层
      TextBlockOverlay({
        editing: this.textEditing,
        element: this.editingTextBlock,
        onCommit: (text: string) => {
          this.onTextCommit(text);
        },
        onCancel: () => {
          this.onTextCancel();
        },
      })
      // T-034：缩放控制条（右下角；left/bottom 定位不依赖 canvasCtx.height 初始化时机）
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
        Button('适应宽度')
          .height(36)
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => {
            this.zoomFitWidth();
          })
      }
      .align(Alignment.BottomStart)
      .margin({ left: 16, bottom: 68 })  // 避开底部 PageManagerBar（56vp）
      .backgroundColor('#F2F2F2')
      .borderRadius(8)
      .padding({ left: 4, right: 4 })
    }
    .width('100%')
    .height('100%')
  }
}
