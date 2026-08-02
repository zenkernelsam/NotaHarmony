# T-013 层管理与脏矩形

## 目标

实现低延迟分层渲染架构：已完成笔画缓存层（OffscreenCanvas）+ 当前笔画实时层 + 脏矩形追踪，避免每帧全屏重绘。

## 参考

- 知识库：REVERSE_ANALYSIS.md §19（V33 架构：双缓冲、增量渲染区域 = bounds±3px、CLEAR 清屏后重绘）、§37（Canvas 2D OffscreenCanvas 路线）
- 契约：`note/src/main/ets/core/adaptation/StrokeRenderer.ets`（RenderContext 接口）
- 契约：`note/src/main/ets/core/model/GeometryTypes.ets`（Rect2D）
- 依赖：T-012 Canvas2DStrokeRenderer

## 实现要求

### 创建文件

1. `note/src/main/ets/rendering/DirtyRectTracker.ets`
2. `note/src/main/ets/rendering/StrokeLayerManager.ets`

### DirtyRectTracker.ets

```typescript
import { Rect2D } from '../core/model/GeometryTypes';

export class DirtyRectTracker {
  private dirtyRect: Rect2D | null = null;
  private padding: number;  // 默认 3px

  constructor(padding?: number)

  // 标记脏区（笔画 bounds 膨胀 padding）
  markDirty(bounds: Rect2D): void {
    // 如果 dirtyRect == null → 新建
    // 否则 → 合并（union）
  }

  // 获取并重置脏区
  consume(): Rect2D | null {
    const rect = this.dirtyRect;
    this.dirtyRect = null;
    return rect;
  }

  // 全屏脏（初始化/resize 时）
  markFullDirty(width: number, height: number): void

  isDirty(): boolean
}
```

### StrokeLayerManager.ets

```typescript
import { Rect2D } from '../core/model/GeometryTypes';
import { StrokeElementData } from '../core/model/StrokeTypes';
import { StrokeRenderer, RenderContext } from '../core/adaptation/StrokeRenderer';
import { DirtyRectTracker } from './DirtyRectTracker';

export class StrokeLayerManager {
  private completedLayer: OffscreenCanvas | null;   // 已完成笔画缓存
  private completedCtx: CanvasRenderingContext2D | null;
  private renderer: StrokeRenderer;
  private dirtyTracker: DirtyRectTracker;
  private canvasWidth: number;
  private canvasHeight: number;

  constructor(renderer: StrokeRenderer)

  // 初始化/重建 OffscreenCanvas（页面 onReady 或 resize 时调用）
  initialize(width: number, height: number): void

  // 将完成笔画渲染到已完成层
  commitStroke(stroke: StrokeElementData, renderCtx: RenderContext): void {
    // 1. 在 completedCtx 上渲染该笔画
    // 2. dirtyTracker.markDirty(stroke.bounds)
  }

  // 每帧合成：已完成层 + 当前笔画 → 主画布
  composite(mainCtx: CanvasRenderingContext2D, currentStroke: StrokeElementData | null, currentRenderCtx: RenderContext): void {
    // 1. 获取脏区 dirtyTracker.consume()
    // 2. 如果无脏区且无 currentStroke → 跳过
    // 3. mainCtx.save()
    // 4. 如果有脏区 → clipRect(dirtyRect) 限制重绘范围
    // 5. mainCtx.clearRect(脏区或全屏)
    // 6. mainCtx.drawImage(completedLayer, 0, 0)  // 已完成层
    // 7. 如果有 currentStroke → renderer 渲染当前笔画
    // 8. mainCtx.restore()
  }

  // 清空全部（新建笔记/撤销全部）
  clearAll(): void

  // 撤销最后一笔（需要外部提供笔画列表重绘）
  rebuildFromStrokes(strokes: StrokeElementData[], renderCtx: RenderContext): void {
    // 清空 completedLayer → 逐笔重新渲染
  }

  isInitialized(): boolean
}
```

### 鸿蒙特有约束

- 此文件**可以** import `OffscreenCanvas`、`CanvasRenderingContext2D`（渲染层实现）。
- **不 import** UI 组件（@Component 等）。
- OffscreenCanvas 尺寸 = 画布尺寸（全页），不做分块（MVP 阶段）。
- 脏矩形合并用 union（取两个 rect 的外接矩形）。
- composite() 中如果没有脏区也没有当前笔画，直接 return（省性能）。
- padding 默认 3（对应原版 ±3px）。

## 验收标准

- [ ] 两个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] DirtyRectTracker.markDirty 正确合并多个 rect
- [ ] StrokeLayerManager.initialize 创建 OffscreenCanvas
- [ ] composite 方法包含 clipRect 限制重绘
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-013-完成.md`
