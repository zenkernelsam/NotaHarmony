// T-015 画布页面集成（任务卡 T-015，Phase 2 手感闭环）
// ArkUI 页面：Canvas + TouchEvent 绑定 + 全部前序模块串联
// 页面层允许 import 所有平台 API；TouchType 为全局枚举无需 import
import { RawPointerEvent } from '../../core/adaptation/InkInputProvider';
import { InkInputProviderImpl } from '../../core/adaptation/InkInputProviderImpl';
import { NullPredictor } from '../../core/adaptation/NullPredictor';
import { Canvas2DStrokeRenderer, Canvas2DRenderContext } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { StrokeLayerManager } from '../../rendering/StrokeLayerManager';
import { StrokeSession } from '../../rendering/StrokeSession';
import { EraserEngine, EraserMode } from '../../rendering/EraserEngine';
import { RenderSpec, StrokeElementData, InputBatch } from '../../core/model/StrokeTypes';
import { BrushStyle, ToolType, brushStyleToInkStyle } from '../../core/model/BrushTypes';
import { Point2D } from '../../core/model/GeometryTypes';

@Entry
@Component
struct NoteCanvasPage {
  // === 状态 ===
  @State currentTool: ToolType = ToolType.PEN;
  @State brushColor: number = -16777216;  // 黑色 ARGB
  @State brushWidth: number = 36.0;
  @State brushStyle: BrushStyle = BrushStyle.MONO;

  // === 内部模块（非 @State）===
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private renderCtx: Canvas2DRenderContext = new Canvas2DRenderContext(this.canvasCtx);
  private inputProvider: InkInputProviderImpl = new InkInputProviderImpl(true, false, false);
  private predictor: NullPredictor = new NullPredictor();
  private renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
  private layerManager: StrokeLayerManager = new StrokeLayerManager(this.renderer);
  private strokeSession: StrokeSession | null = null;
  private eraserEngine: EraserEngine = new EraserEngine(EraserMode.WHOLE, 20);
  private completedStrokes: StrokeElementData[] = [];
  private eraserPath: Point2D[] = [];
  private isDrawing: boolean = false;
  private eraserActive: boolean = false;

  build() {
    Column() {
      // 顶部简易工具栏（切换工具用）
      Row() {
        Button('Pen')
          .onClick(() => {
            this.currentTool = ToolType.PEN;
            this.brushStyle = BrushStyle.MONO;
          })
        Button('Taper')
          .onClick(() => {
            this.currentTool = ToolType.PEN;
            this.brushStyle = BrushStyle.TAPER;
          })
        Button('Pencil')
          .onClick(() => {
            this.currentTool = ToolType.PENCIL;
          })
        Button('Eraser')
          .onClick(() => {
            this.currentTool = ToolType.WHOLE_ERASER;
            this.eraserEngine.setMode(EraserMode.WHOLE);
          })
        Button('Partial')
          .onClick(() => {
            this.currentTool = ToolType.PARTIAL_ERASER;
            this.eraserEngine.setMode(EraserMode.PARTIAL);
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)

      // 画布
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
    }
    .width('100%')
    .height('100%')
  }

  // === 画布初始化 ===
  private onCanvasReady(): void {
    const w: number = this.canvasCtx.width;
    const h: number = this.canvasCtx.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    this.layerManager.initialize(w, h);
    // MVP：splat 纹理用圆形 fallback，不加载外部图片
    this.renderer.setEraserMaskWidth(20);
    this.predictor.reset();  // 预测器预留（NullPredictor 无状态）
    this.renderFrame();
  }

  // === 触摸事件处理 ===
  private onCanvasTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.startStroke(event);
    } else if (event.type === TouchType.Move) {
      this.continueStroke(event);
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.endStroke();
    }
  }

  private startStroke(event: TouchEvent): void {
    if (event.touches.length === 0) {
      return;
    }
    if (this.currentTool === ToolType.WHOLE_ERASER || this.currentTool === ToolType.PARTIAL_ERASER) {
      // 橡皮擦模式
      this.eraserActive = true;
      this.eraserPath = [];
      this.isDrawing = true;
      this.collectEraserPoint(event.touches[0]);
      return;
    }
    const spec: RenderSpec = this.makeRenderSpec();
    if (this.strokeSession === null) {
      this.strokeSession = new StrokeSession(spec);
    }
    const startTime: number = Date.now();
    this.strokeSession.beginStroke(spec, startTime);
    this.inputProvider.beginStroke(startTime);
    const batch: InputBatch = this.inputProvider.processEvent(
      [this.toRawPointerEvent(event.touches[0], false)], false);
    this.strokeSession.addBatch(batch);
    this.isDrawing = true;
    this.renderFrame();
  }

  private continueStroke(event: TouchEvent): void {
    if (!this.isDrawing) {
      return;
    }
    if (this.eraserActive) {
      for (const t of event.touches) {
        this.collectEraserPoint(t);
      }
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
    // 预测点预留：PenKitPredictor 接入后在此追加渲染（NullPredictor 返回空数组）
    this.renderFrame();
  }

  private endStroke(): void {
    if (!this.isDrawing) {
      return;
    }
    if (this.eraserActive) {
      this.applyEraser();
      this.eraserActive = false;
      this.eraserPath = [];
    } else if (this.strokeSession !== null && this.strokeSession.isActive()) {
      const stroke: StrokeElementData = this.strokeSession.finishStroke();
      this.completedStrokes.push(stroke);
      this.layerManager.commitStroke(stroke, this.renderCtx);
    }
    this.isDrawing = false;
    this.renderFrame();
  }

  // === 橡皮擦执行 ===
  private applyEraser(): void {
    if (this.eraserPath.length === 0) {
      return;
    }
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
    // 重建已完成层
    this.layerManager.rebuildFromStrokes(this.completedStrokes, this.renderCtx);
  }

  private collectEraserPoint(touch: TouchObject): void {
    const p: RawPointerEvent = this.toRawPointerEvent(touch, false);
    this.eraserPath.push({ x: p.x, y: p.y });
  }

  // === 每帧渲染 ===
  private renderFrame(): void {
    if (!this.layerManager.isInitialized()) {
      return;
    }
    const current: StrokeElementData | null = this.strokeSession !== null && this.strokeSession.isActive()
      ? this.strokeSession.getCurrentStroke() : null;
    this.layerManager.composite(this.canvasCtx, current, this.renderCtx);
  }

  // === RenderSpec 构建 ===
  private makeRenderSpec(): RenderSpec {
    return {
      color: this.brushColor,
      brushWidth: this.brushWidth,
      inkStyle: brushStyleToInkStyle(this.brushStyle),
      isHighlighter: false,
      isPencil: this.currentTool === ToolType.PENCIL,
    };
  }

  // === TouchPoint → RawPointerEvent 转换 ===
  private toRawPointerEvent(touch: TouchObject, isHistorical: boolean): RawPointerEvent {
    // pressure 归一化：HarmonyOS TouchPoint.pressure 范围 [0, 65535)
    const rawPressure: number = touch.pressure !== undefined ? touch.pressure : 0;
    const pressure: number = rawPressure > 0 ? rawPressure / 65535 : 0;
    return {
      x: touch.x,
      y: touch.y,
      pressure: pressure,
      tiltRadians: 0,          // 模拟器可能无倾斜
      orientationRadians: 0,   // 模拟器可能无方位角
      toolType: 0,             // 默认 stylus
      timestamp: Date.now(),
      isHistorical: isHistorical,
    };
  }
}
