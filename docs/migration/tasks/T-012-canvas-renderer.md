# T-012 Canvas 2D 渲染器

## 目标

实现 StrokeRenderer 接口的 Canvas 2D 版本，支持中心线路径、可变宽度填充、PencilSplat 纹理着色和擦除遮罩四种渲染模式。

## 参考

- 知识库：REVERSE_ANALYSIS.md §4（pzf.g 固定中心线：Round cap/join、Dash `{2w,1w}`、Dots `{0.001w,2w}`、荧光笔 alpha）、§37（Canvas 2D splat 渲染：OffscreenCanvas + source-in 着色）、§5b（clipOutPath 擦除）
- 契约：`note/src/main/ets/core/adaptation/StrokeRenderer.ets`（接口，不得修改）
- 契约：`note/src/main/ets/core/model/StrokeTypes.ets`（StrokeElementData, RenderSpec, InkStyle, PencilSplatPoint）
- 依赖：T-010 WidthOutlineBuilder（可变宽度轮廓点）
- 依赖：T-011 PencilSplatGenerator（splat 点已生成，本卡只负责渲染）

## 实现要求

### 创建文件

`note/src/main/ets/core/adaptation/Canvas2DStrokeRenderer.ets`

### 类设计

```typescript
import { StrokeRenderer, RenderContext } from './StrokeRenderer';
import { StrokeElementData, PencilSplatPoint, RenderSpec, InkStyle } from '../model/StrokeTypes';
import { Rect2D, Point2D } from '../model/GeometryTypes';
// 此文件可以 import 平台 Canvas 类型（它是适配层实现）

export class Canvas2DStrokeRenderer implements StrokeRenderer {
  private splatTexture: ImageBitmap | null;  // 铅笔纹理（T-015 加载后注入）
  private colorCache: Map<number, OffscreenCanvas>;  // 颜色缓存

  constructor()

  setSplatTexture(texture: ImageBitmap): void

  // === 中心线路径（Mono/Dash/Dot）===
  renderCenterPath(stroke: StrokeElementData, ctx: RenderContext): void {
    // 1. ctx.save()
    // 2. 构建 Path: moveTo(p0) → 对每段 cubicSegment: bezierCurveTo(p1,p2,p3)
    // 3. 设置 lineWidth = stroke.renderSpec.brushWidth
    // 4. lineCap = 'round', lineJoin = 'round'
    // 5. 根据 inkStyle:
    //    - FIXED_WIDTH: 实线 stroke()
    //    - DASH: setLineDash([2*width, 1*width])
    //    - DOTS: setLineDash([0.001*width, 2*width])
    // 6. strokeStyle = colorToRgba(renderSpec.color)
    // 7. 荧光笔: globalAlpha = 107/255 ≈ 0.42
    // 8. ctx.restore()
  }

  // === 可变宽度填充轮廓（Taper）===
  renderVariableWidthOutline(stroke: StrokeElementData, ctx: RenderContext): void {
    // 1. 从 stroke 获取轮廓点（由 StrokeSession 预计算并存入）
    //    或调用 WidthOutlineBuilder.build(stroke.pathPoints, renderSpec.brushWidth)
    // 2. ctx.save()
    // 3. beginPath → moveTo(outline[0]) → lineTo(outline[1..n]) → closePath
    // 4. fillStyle = colorToRgba(renderSpec.color)
    // 5. fill()
    // 6. ctx.restore()
  }

  // === PencilSplat 渲染（OffscreenCanvas + source-in）===
  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, ctx: RenderContext): void {
    // 1. 获取/创建该颜色的缓存 OffscreenCanvas
    // 2. 对每个 splat:
    //    a. offCtx.save()
    //    b. offCtx.translate(splat.x, splat.y)
    //    c. offCtx.rotate(splat.rotation)
    //    d. offCtx.scale(splat.scale, splat.scale)
    //    e. offCtx.globalAlpha = splat.opacity
    //    f. offCtx.drawImage(splatTexture, -w/2, -h/2)
    //    g. offCtx.restore()
    // 3. 着色: offCtx.globalCompositeOperation = 'source-in'
    //    offCtx.fillStyle = color; offCtx.fillRect(全区域)
    // 4. 主画布: ctx.drawImage(offscreen)
    // 5. 重置 offscreen 供下次使用
  }

  // === 擦除遮罩 ===
  renderEraserMask(stroke: StrokeElementData, ctx: RenderContext): void {
    // 1. 如果 stroke.maskPath 为空 → return
    // 2. ctx.save()
    // 3. 构建擦除路径: moveTo → lineTo → (不 close，用 lineWidth 扩展)
    // 4. globalCompositeOperation = 'destination-out'
    // 5. lineWidth = 擦除宽度
    // 6. stroke() → 挖洞效果
    // 7. ctx.restore()
  }

  // 工具：ARGB int → rgba 字符串
  private colorToRgba(argb: number): string {
    // a = (argb >>> 24) & 0xFF, r = (argb >>> 16) & 0xFF ...
    // return `rgba(r,g,b,a/255)`
  }
}
```

### 鸿蒙特有约束

- 此文件**可以** import Canvas 相关类型（`CanvasRenderingContext2D`, `OffscreenCanvas`, `ImageBitmap`）——它是适配层实现。
- 但**不 import** TouchEvent / UI 组件等平台类型。
- `RenderContext` 接口是抽象的；本实现内部需要操作真实 Canvas，因此构造函数或方法需要接收真实 `CanvasRenderingContext2D`。设计：让 `RenderContext` 的实现类包装真实 Canvas（在 T-013/T-015 中实现），本文件通过 `RenderContext` 接口操作。
- 如果 `RenderContext` 接口不够用（需要 drawImage 等），在本文件内定义 `Canvas2DRenderContext extends RenderContext` 扩展类。
- PencilSplat 纹理未加载时（splatTexture=null），用 4px 圆形 fallback。
- 颜色缓存 Map 的 key 为 ARGB int。

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] Canvas2DStrokeRenderer implements StrokeRenderer（编译验证）
- [ ] 四个 render 方法均有实现（非空方法体）
- [ ] DASH 模式使用 setLineDash([2w, w])
- [ ] PencilSplat 使用 source-in 着色逻辑
- [ ] 擦除使用 destination-out
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-012-完成.md`
