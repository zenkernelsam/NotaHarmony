// T-006 笔画渲染适配接口（契约 phase-1-data-model.md §3.8，照搬，禁止修改签名）
// 适配层接口：渲染上下文抽象，隔离 Canvas/OpenGL 差异
// 接口定义不 import 任何 @ohos.* / @kit.* 平台模块
import { StrokeElementData, PencilSplatPoint, RenderSpec } from '../model/StrokeTypes';
import { Rect2D } from '../model/GeometryTypes';

// 渲染上下文抽象（隔离 Canvas/OpenGL 差异）
export interface RenderContext {
  save(): void;
  restore(): void;
  clipRect(rect: Rect2D): void;
  clear(rect: Rect2D): void;
}

export interface StrokeRenderer {
  // 渲染中心线笔画（Mono/Dash/Dot）
  renderCenterPath(stroke: StrokeElementData, ctx: RenderContext): void;
  // 渲染可变宽度填充轮廓（Taper）
  renderVariableWidthOutline(stroke: StrokeElementData, ctx: RenderContext): void;
  // 渲染铅笔飞溅
  renderPencilSplats(splats: PencilSplatPoint[], spec: RenderSpec, ctx: RenderContext): void;
  // 渲染擦除遮罩
  renderEraserMask(stroke: StrokeElementData, ctx: RenderContext): void;
}
