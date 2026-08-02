# T-015 画布页面集成（手感闭环）

## 目标

创建 NoteCanvasPage：ArkUI Canvas 组件 + TouchEvent 绑定 + 全部前序模块串联，实现"触摸 → 笔迹上屏"的可运行闭环。这是 Phase 2 的最终集成卡。

## 参考

- 知识库：REVERSE_ANALYSIS.md §39.5（编辑器画布入口 zz8 → t09 → cxe）、§36（TouchEvent/TouchPoint 字段）
- 契约：Phase 1 全部适配层接口
- 依赖：T-008~T-014 全部产出

## 实现要求

### 创建文件

`note/src/main/ets/ui/editor/NoteCanvasPage.ets`

### 页面结构

```typescript
import { ... } from '../../core/adaptation/InkInputProvider';
import { InkInputProviderImpl } from '../../core/adaptation/InkInputProviderImpl';
import { NullPredictor } from '../../core/adaptation/NullPredictor';
import { Canvas2DStrokeRenderer } from '../../core/adaptation/Canvas2DStrokeRenderer';
import { StrokeLayerManager } from '../../rendering/StrokeLayerManager';
import { StrokeSession } from '../../rendering/StrokeSession';
import { EraserEngine, EraserMode } from '../../rendering/EraserEngine';
import { RenderSpec, InkStyle, StrokeElementData, InputBatch, InputBatchKind } from '../../core/model/StrokeTypes';
import { BrushStyle, ToolType, brushStyleToInkStyle } from '../../core/model/BrushTypes';
import { RawPointerEvent } from '../../core/adaptation/InkInputProvider';

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
  private inputProvider: InkInputProviderImpl = new InkInputProviderImpl(true, false, false);
  private predictor: NullPredictor = new NullPredictor();
  private renderer: Canvas2DStrokeRenderer = new Canvas2DStrokeRenderer();
  private layerManager: StrokeLayerManager = new StrokeLayerManager(this.renderer);
  private strokeSession: StrokeSession | null = null;
  private eraserEngine: EraserEngine = new EraserEngine(EraserMode.WHOLE, 20);
  private completedStrokes: StrokeElementData[] = [];
  private isDrawing: boolean = false;

  build() {
    Column() {
      // 顶部简易工具栏（切换工具用）
      Row() {
        Button('Pen').onClick(() => { this.currentTool = ToolType.PEN; })
        Button('Pencil').onClick(() => { this.currentTool = ToolType.PENCIL; })
        Button('Eraser').onClick(() => { this.currentTool = ToolType.WHOLE_ERASER; })
      }.width('100%').height(48)

      // 画布
      Canvas(this.canvasCtx)
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .onReady(() => { this.onCanvasReady(); })
        .onTouch((event: TouchEvent) => { this.onCanvasTouch(event); })
    }
    .width('100%')
    .height('100%')
  }

  // === 画布初始化 ===
  private onCanvasReady(): void {
    // 1. 获取画布宽高
    // 2. layerManager.initialize(width, height)
    // 3. 加载 splat 纹理（如果铅笔）→ renderer.setSplatTexture()
    //    MVP: 用 4px 圆形 fallback，不加载外部图片
    // 4. 首次全屏渲染
  }

  // === 触摸事件处理 ===
  private onCanvasTouch(event: TouchEvent): void {
    // 根据 event.type:
    // TouchType.Down → startStroke(event)
    // TouchType.Move → continueStroke(event)
    // TouchType.Up / TouchType.Cancel → endStroke()
  }

  private startStroke(event: TouchEvent): void {
    // 1. 如果当前工具是橡皮擦 → 进入擦除模式
    // 2. 否则 → 创建 RenderSpec，strokeSession.beginStroke()
    // 3. 将 event.touches[0] 转为 RawPointerEvent → inputProvider.processEvent()
    // 4. strokeSession.addBatch()
    // 5. isDrawing = true
    // 6. 请求重绘
  }

  private continueStroke(event: TouchEvent): void {
    // 1. 转换所有 touches → RawPointerEvent[]
    //    pressure 归一化: touchPoint.pressure / 65535（HarmonyOS 范围）
    // 2. inputProvider.processEvent(rawEvents, false)
    // 3. 如果是擦除 → 收集擦除路径点
    // 4. 否则 → strokeSession.addBatch()
    // 5. 预测点: predictor.predict() → 额外渲染（可选）
    // 6. 重绘当前帧
    // 7. requestAnimationFrame 或 Canvas invalidate
  }

  private endStroke(): void {
    // 1. 如果是擦除 → eraserEngine.erase() → 处理结果 → 重建层
    // 2. 否则 → strokeSession.finishStroke() → completedStrokes.push()
    //    → layerManager.commitStroke()
    // 3. isDrawing = false
    // 4. 重绘
  }

  // === 每帧渲染 ===
  private renderFrame(): void {
    // layerManager.composite(canvasCtx, currentStroke, renderCtx)
  }

  // === TouchPoint → RawPointerEvent 转换 ===
  private toRawPointerEvent(touch: TouchObject, isHistorical: boolean): RawPointerEvent {
    return {
      x: touch.x,
      y: touch.y,
      pressure: touch.pressure ?? 0,
      tiltRadians: 0,          // 模拟器可能无倾斜
      orientationRadians: 0,   // 模拟器可能无方位角
      toolType: 0,             // 默认 stylus
      timestamp: Date.now(),
      isHistorical: isHistorical,
    };
  }
}
```

### 页面路由注册

修改 `note/src/main/resources/base/profile/main_pages.json`，添加：
```json
{
  "src": [
    "pages/Index",
    "ui/editor/NoteCanvasPage"
  ]
}
```

同时修改 `note/src/main/ets/pages/Index.ets`，添加一个按钮跳转到 NoteCanvasPage：
```typescript
Button('Open Canvas').onClick(() => {
  router.pushUrl({ url: 'ui/editor/NoteCanvasPage' });
})
```

### 鸿蒙特有约束

- 使用 `@Entry @Component struct` 装饰器。
- Canvas 组件的 `onReady` 回调中才能获取真实宽高。
- TouchEvent 的 pressure 范围是 [0, 65535)（API 15+），需归一化。
- 模拟器可能不支持 pressure/tilt/orientation → 全部 fallback 到默认值。
- 使用 `import { router } from '@kit.ArkUI'` 做页面跳转。
- 不引入第三方状态管理库。
- 画布重绘：Canvas 组件没有 invalidate API，需要通过修改 @State 变量触发重绘，或使用 `canvasCtx` 直接操作。

### 关键：如何让 Canvas 每帧重绘

ArkUI Canvas 不像 Android View 有 invalidate()。方案：
1. 在 onTouch Move 中直接调用 `renderFrame()`（同步重绘）
2. 或使用 `@State frameCounter: number` 每帧 +1 触发 build 重执行（性能较差）
3. **推荐**：在 Move 事件中直接操作 canvasCtx 绘制，不依赖 build 循环

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] `start_app` 在模拟器运行成功（不崩溃）
- [ ] 从 Index 页面可跳转到 NoteCanvasPage
- [ ] 在画布上触摸滑动可见笔迹（PEN 模式：黑色线条）
- [ ] 切换 Pencil 模式可见不同渲染效果（splat 或 fallback 圆点）
- [ ] 切换 Eraser 模式触摸可擦除已有笔画
- [ ] hilog 无 ERROR 级别日志
- [ ] 不修改 Phase 1 契约文件

## 完成报告

`docs/migration/reports/T-015-完成.md`
