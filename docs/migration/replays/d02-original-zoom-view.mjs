import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const brushTypes = read('note/src/main/ets/core/model/BrushTypes.ets');
const editorVm = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const toolboxDialog = read('note/src/main/ets/ui/editor/ToolboxSettingsDialog.ets');
const zoomView = read('note/src/main/ets/ui/editor/NoteZoomView.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const baseStrings = read('note/src/main/resources/base/element/string.json');
const zhStrings = read('note/src/main/resources/zh_CN/element/string.json');
const evidence = read('docs/migration/evidence/phase-747-original-zoom-view.md');
const evidence748 = read('docs/migration/evidence/phase-748-original-zoom-view-full-render.md');
const adr = read('docs/migration/adr/ADR-0695-original-zoom-view-port.md');
const adr748 = read('docs/migration/adr/ADR-0696-original-zoom-view-full-render.md');

// Phase 747 — 原版 Zoom View（ggg 状态机 + ww2/wfg 控制条 + g0j 前进区）
// 背景：ADR-0690 更正——"androidZoomView" 打包默认 true（PRODUCTION 档），
// 1.0.3 默认可见；旧 ADR-0644"旗标未开"系误读。lgg 默认：
// isShown=false / dockEdge=qeg.J(Bottom) / mag=5.0f / advanceWidth=180dp。

let pass = 0;
const pin = (ok, name) => { assert.ok(ok, name); pass++; };

// ---- 工具模型 ----
pin(/ZOOM = 9/.test(brushTypes), 'tooltype.zoom');
pin(/a6f\.U = ZOOM/.test(brushTypes), 'tooltype.zoom.comment');
// rz1 副托盘序：POINTER(0)/LASER(1)/ZOOM(2)/REVIEW(3)/RULER(4)
pin(/'zoom', ownerId, ToolType\.ZOOM, 2,/.test(editorVm), 'vm.zoom.seed.index2');
pin(/TRAY_TYPE_SECONDARY\),\s*\n\s*\/\/ 原版 rz1:1075/.test(editorVm) ||
  /ToolType\.ZOOM, 2,[\s\S]*?TRAY_TYPE_SECONDARY/.test(editorVm), 'vm.zoom.secondary');
pin(/case ToolType\.ZOOM: return \$r\('app\.string\.tool_zoom'\)/
  .test(toolboxDialog), 'label.zoom');

// ---- ggg 状态源（宿主持有）----
pin(/zoomSourceX: number = 0/.test(canvas), 'host.sourceX');
pin(/zoomDockBottom: boolean = true/.test(canvas), 'host.dockEdge.bottom.default');
pin(/zoomAdvanceWidthVp: number = 180/.test(canvas), 'host.advanceWidth.180');
pin(/zoomMagnification: number = 5/.test(canvas), 'host.mag.5x');
pin(/ZOOM_SURFACE_HEIGHT_VP: number = 160/.test(canvas), 'host.surface.h160');

// ---- 触摸管线（与主画布同径）----
pin(/onZoomTouchEvent\(event: TouchEvent\)/.test(canvas), 'host.touch.dispatch');
pin(/zoomDocPoint[\s\S]{0,400}vp2px\(touch\.x\) \/ this\.zoomMagnification/
  .test(canvas), 'host.coordmap.px-per-doc');
pin(/ArkUIStylusAdapter\.fromTouch\(touch, event\)/.test(canvas), 'host.stylus.attrs');
pin(/inputProvider\.processEvent/.test(canvas), 'host.provider.pipeline');
pin(/new StrokeSession\(spec\)/.test(canvas), 'host.session.reuse');
pin(/strokeSession\.finishStroke\(\)/.test(canvas), 'host.finish');
pin(/UndoableActionType\.ADD_STROKE/.test(canvas), 'host.undo.addstroke');
pin(/layerManager\.commitStroke\(stroke, this\.renderCtx, this\.viewport\.zoom\)/
  .test(canvas), 'host.commit.layer');
// 主画布门：ZOOM 激活不产生笔画（回落 Scroll 平移/点按检查照常）
pin(/currentTool === ToolType\.ZOOM\) \{\s*return;/.test(canvas), 'host.main.gate');
// 取消并入 cancelActiveInteraction
pin((() => {
  const i = canvas.indexOf('private cancelActiveInteraction(): void');
  const j = canvas.indexOf('resetPointerTracking();', i);
  return i >= 0 && j > i && canvas.slice(i, j).includes('this.onZoomTouchCancel();');
})(), 'host.cancel.wired');

// ---- ufg 重定位 ----
pin(/private zoomAutoAdvance\(stroke/.test(canvas), 'host.ufg.advance');
pin(/rectW - this\.zoomAdvanceDoc\(\)|rectW - advanceDoc/.test(canvas),
  'host.ufg.step-minus-advance');
pin(/private zoomStepBack\(\)/.test(canvas), 'host.ufg.back');
pin(/private zoomReturnToInk\(\)/.test(canvas), 'host.ufg.return');
pin(/pathPoints\[stroke\.pathPoints\.length - 1\]/.test(canvas),
  'host.return.lastink');
// 面板显隐 = 工具激活；关闭回落 DEFAULT
pin(/currentTool === ToolType\.ZOOM && this\.loaded/.test(canvas), 'host.mount');
pin(/selectTool\(ToolType\.DEFAULT\)/.test(canvas), 'host.close.default');

// ---- 面板组件（ww2/wfg 控制条 + g0j 前进区）----
pin(/export struct NoteZoomView/.test(zoomView), 'panel.component');
// Phase 748：vgg 注入整页渲染栈——放大面经父组件 renderContent 回调绘制
// 纸面 + z-order 全元素，不再持有独立 StrokeCanvasPainter 笔画直绘路径。
pin(!/StrokeCanvasPainter/.test(zoomView), 'panel.no.strokeonly.painter');
pin(/renderContent: \(renderContext: Canvas2DRenderContext,?\s*\n?\s*rawCtx: CanvasRenderingContext2D, mag: number\)/
  .test(zoomView), 'panel.renderContent.prop');
pin(/this\.renderContent\(this\.renderCtx, ctx, this\.magnification\)/
  .test(zoomView), 'panel.renderContent.call');
// 父组件实现：纸面（含 PDF 底图）+ 有序全元素 + 活动 zoom 笔画置顶
pin(/renderZoomPanelContent\(renderContext: Canvas2DRenderContext/
  .test(canvas), 'host.renderZoomPanelContent');
pin(/paperRenderer\.renderBackground\(rawCtx, this\.getPaperWidth\(\), this\.getPaperHeight\(\),\s*\n\s*this\.currentPage, mag/
  .test(canvas), 'host.zoom.paper');
pin(/this\.renderOrderedElements\(renderContext, this\.zoomLiveStroke, mag\)/
  .test(canvas), 'host.zoom.ordered');
// renderOrderedElements 新增 renderZoom 形参（默认 viewport.zoom）
pin(/transientTopStroke: StrokeElementData \| null = null,\s*\n\s*renderZoom: number = this\.viewport\.zoom/
  .test(canvas), 'host.renderZoom.param');
pin(/originalMathRasterScale\(renderZoom, vp2px\(1\)\)/.test(canvas),
  'host.renderZoom.mathscale');
// 主画布内容变更镜像放大面
pin(/currentTool === ToolType\.ZOOM\) \{\s*this\.zoomPaintTick\+\+;/
  .test(canvas), 'host.zoom.mirror.tick');
pin(/ctx\.transform\(this\.magnification/.test(zoomView), 'panel.mag.transform');
pin(/zoom_view_move/.test(zoomView), 'panel.a11y.move');
pin(/zoom_view_back/.test(zoomView), 'panel.a11y.back');
pin(/zoom_view_forward/.test(zoomView), 'panel.a11y.forward');
pin(/zoom_view_return/.test(zoomView), 'panel.a11y.return');
pin(/zoom_view_close/.test(zoomView), 'panel.a11y.close');
pin(/zoom_view_advance/.test(zoomView), 'panel.a11y.advance');
pin(/width\(48\)\s*\n\s*\.height\(48\)/.test(zoomView), 'panel.buttons.48');
pin(/PanDirection\.Vertical/.test(zoomView), 'panel.drag.vertical');
pin(/PanDirection\.Horizontal/.test(zoomView), 'panel.advance.drag');

// ---- 字符串（原文 + zh_CN）----
for (const [key, val] of [
  ['tool_zoom', 'Zoom'],
  ['zoom_view_move', 'Move Zoom View'],
  ['zoom_view_back', 'Back'],
  ['zoom_view_forward', 'Forward'],
  ['zoom_view_return', 'Return'],
  ['zoom_view_close', 'Close Zoom View'],
  ['zoom_view_advance', 'Adjust auto-advance area'],
]) {
  pin(baseStrings.includes(`"name": "${key}"`) && baseStrings.includes(`"value": "${val}"`),
    `string.base.${key}`);
}
for (const key of [
  'tool_zoom', 'zoom_view_move', 'zoom_view_back', 'zoom_view_forward',
  'zoom_view_return', 'zoom_view_close', 'zoom_view_advance',
]) {
  pin(zhStrings.includes(`"name": "${key}"`), `string.zh.${key}`);
}

// ---- 文档钉 ----
pin(/qeg\.J/.test(evidence), 'evidence.qeg.bottom');
pin(/5\.0f/.test(evidence) && /180\.0f/.test(evidence), 'evidence.defaults');
pin(/ufg/.test(evidence) && /Advance/.test(evidence), 'evidence.ufg');
pin(/ADR-0690/.test(adr) && /默认开/.test(adr), 'adr.flag.correction');
pin(/ToolType\.ZOOM = 9|ToolType\.ZOOM=9/.test(adr), 'adr.tooltype');
// Phase 748 文档钉：vgg 整页渲染栈证据 + ADR-0696
pin(/vgg/.test(evidence748) && /oze.*fvb.*uke.*hnf.*gc9.*cga/s.test(evidence748),
  'evidence748.vgg.stack');
pin(/renderZoomPanelContent/.test(adr748) && /renderOrderedElements/.test(adr748),
  'adr748.wiring');

console.log(`D02_ORIGINAL_ZOOM_VIEW_OK pins=${pass}`);
