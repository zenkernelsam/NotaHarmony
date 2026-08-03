# T-034 画布缩放与平移（P0 核心交互）

## 目标

实现双指捏合缩放 + 双指平移 + 缩放坐标映射 + 缩放控制条。这是笔记应用的必备交互，当前完全缺失。

## 实现要求

### 修改/创建文件

1. `note/src/main/ets/rendering/CanvasViewport.ets`（新建：视口状态管理）
2. 修改 `note/src/main/ets/ui/editor/NoteCanvasView.ets`（手势绑定 + 渲染变换）

### CanvasViewport.ets

```typescript
export class CanvasViewport {
  zoom: number = 1.0;          // [0.25, 4.0]
  scrollX: number = 0;
  scrollY: number = 0;

  // 屏幕坐标 → 画布坐标（输入点需要此映射）
  screenToCanvas(sx: number, sy: number): Point2D {
    return { x: (sx - this.scrollX) / this.zoom, y: (sy - this.scrollY) / this.zoom };
  }
  // 画布坐标 → 屏幕坐标（渲染用）
  canvasToScreen(cx: number, cy: number): Point2D
  // 以某屏幕点为中心缩放（保持该点下的画布内容不动）
  zoomAt(sx: number, sy: number, factor: number): void
  // 平移（屏幕像素增量）
  panBy(dx: number, dy: number): void
  clamp(): void  // 限制 zoom 范围和滚动边界
}
```

### NoteCanvasView 手势绑定

- **PinchGesture** → `viewport.zoomAt(中心点, scale)` → 重绘
- **双指 PanGesture** → `viewport.panBy(dx, dy)` → 重绘
- **单指触摸** → 仍然是书写（先经 screenToCanvas 映射再进 StrokeSession）
- **渲染时**：`ctx.translate(scrollX, scrollY); ctx.scale(zoom, zoom)` 后再画纸张背景+笔画
- **缩放控制条**：右下角 Row { [-] [100%] [+] [适应宽度] }，按钮步进 0.25
- 缩放/滚动变化时持久化到 NoteViewState（防抖 500ms）

### 关键约束

- 所有输入点（书写/擦除/选区/双击）必须先过 screenToCanvas
- 已完成层 OffscreenCanvas 重绘时也要应用 viewport 变换
- 纸张背景平铺随 zoom 缩放（线宽按 zoom 比例，保持视觉 1px）
- 手势冲突：双指手势优先于单指书写（ArkUI GestureGroup 或手势判定）

## 验收标准

- [ ] 双指捏合可缩放（0.25~4.0），以两指中心为锚点
- [ ] 双指拖动可平移画布
- [ ] 缩放后书写位置准确（笔尖与笔迹对齐，无偏移）
- [ ] 缩放按钮可用，百分比显示正确
- [ ] 退出重进笔记，zoom/scroll 恢复
- [ ] `check_ets_files` + `build_project` 通过 + 模拟器不崩溃

## 完成报告

`docs/migration/reports/T-034-完成.md`
