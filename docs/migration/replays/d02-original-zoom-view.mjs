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
const evidence749 = read('docs/migration/evidence/phase-749-original-zoom-advance-width-persist.md');
const evidence750 = read('docs/migration/evidence/phase-750-zoom-source-window-overlay.md');
const adr = read('docs/migration/adr/ADR-0695-original-zoom-view-port.md');
const adr748 = read('docs/migration/adr/ADR-0696-original-zoom-view-full-render.md');
const adr749 = read('docs/migration/adr/ADR-0697-original-zoom-advance-width-persist.md');
const adr750 = read('docs/migration/adr/ADR-0698-original-zoom-source-window-overlay.md');
const evidence751 = read('docs/migration/evidence/phase-751-zoom-window-edge-autoscroll.md');
const adr751 = read('docs/migration/adr/ADR-0699-original-zoom-window-edge-autoscroll.md');
const evidence752 = read('docs/migration/evidence/phase-752-zoom-advance-clamp-chromeflip.md');
const adr752 = read('docs/migration/adr/ADR-0700-original-zoom-advance-clamp-chromeflip.md');
const evidence754 = read('docs/migration/evidence/phase-754-zoom-panel-geometry.md');
const adr754 = read('docs/migration/adr/ADR-0702-zoom-panel-geometry.md');
const evidence755 = read('docs/migration/evidence/phase-755-zoom-panel-slide-transition.md');
const adr755 = read('docs/migration/adr/ADR-0703-zoom-panel-slide-transition.md');
const settingsStore = read('note/src/main/ets/data/EditorSettingsStore.ets');
const settingsTest = read('note/src/test/EditorViewModel.test.ets');

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
pin(/ZOOM_SURFACE_HEIGHT_VP: number = 272/.test(canvas), 'host.surface.h272');

// ---- 触摸管线（与主画布同径）----
pin(/onZoomTouchEvent\(event: TouchEvent\)/.test(canvas), 'host.touch.dispatch');
// Phase 750 修复：ctx 为 vp 绘制空间——doc = source + vp/mag，不得 vp2px
pin(/zoomDocPoint[\s\S]{0,400}touch\.x \/ this\.zoomMagnification/
  .test(canvas), 'host.coordmap.vp-per-doc');
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

// ---- Phase 749：o59.r 前进区宽持久化 ----
pin(/ZOOM_ADVANCE_WIDTH_KEY: string = 'zoomViewAdvanceRegionWidthDp'/
  .test(settingsStore), 'persist.key.original-name');
pin(/DEFAULT_ZOOM_ADVANCE_WIDTH_DP: number = 180/.test(settingsStore),
  'persist.default.180');
pin(/getZoomAdvanceWidthDp\(\): Promise<number>/.test(settingsStore) &&
  /saveZoomAdvanceWidthDp\(widthDp: number\): Promise<void>/.test(settingsStore),
  'persist.store.api');
pin(/zoomAdvanceWidthDp: number = 180/.test(editorVm), 'vm.field');
pin(/getZoomAdvanceWidthDp\(\)/.test(editorVm), 'vm.load');
pin(/setZoomAdvanceWidthDp\(widthDp: number\)/.test(editorVm) &&
  /enqueueSave[\s\S]{0,120}saveZoomAdvanceWidthDp/.test(editorVm), 'vm.save.enqueue');
// 挂载同步 + 拖拽提交点持久化
pin(/initZoomSourceRect[\s\S]{0,300}this\.zoomAdvanceWidthVp = this\.viewModel\.zoomAdvanceWidthDp/
  .test(canvas), 'host.mount.sync');
pin(/onAdvanceRegionCommit[\s\S]{0,300}setZoomAdvanceWidthDp/.test(canvas),
  'host.commit.persist');
// 拖拽基准宽钉在 onActionStart（offsetX 累计量不得逐帧重复相减）
pin(/onActionStart\(\(\) => \{[\s\S]{0,160}this\.advanceDragStartWidthVp = this\.advanceWidthVp/
  .test(zoomView), 'panel.drag.startpinned');
pin(/advanceDragStartWidthVp - event\.offsetX/.test(zoomView),
  'panel.drag.cumulative-fixed');
pin(/onActionEnd\(\(\) => \{[\s\S]{0,80}this\.onAdvanceRegionCommit/.test(zoomView),
  'panel.drag.endcommit');
// 测试 fake 同步接口扩展
pin(/getZoomAdvanceWidthDp/.test(settingsTest), 'test.fake.zoomwidth');

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
// Phase 749 文档钉：o59.r/n27 写链 + ADR-0697
pin(/o59\.r/.test(evidence749) && /zoomViewAdvanceRegionWidthDp/.test(evidence749) &&
  /n27/.test(evidence749), 'evidence749.o59r');
pin(/ADR-0697|o59\.r/.test(adr749) && /提交点/.test(adr749), 'adr749.approx');

// ---- Phase 750：gfg/dfg 源窗口覆盖层 + vp2px 坐标修复 ----
// vp2px 修复：面板触摸 → doc 不得再乘 density（ctx 为 vp 绘制空间）
pin(/zoomSourceX \+ touch\.x \/ this\.zoomMagnification/.test(canvas),
  'p750.docpoint.vp');
pin(!/vp2px\(touch\.[xy]\)/.test(canvas), 'p750.docpoint.nodensity');
pin(/overlayWidth : 360\) - 16/.test(canvas), 'p750.surfacewidth.margin');
pin(!/vp2px\(this\.zoomAdvanceWidthVp\)/.test(canvas), 'p750.advance.nodensity');
pin(!/vp2px\(this\.advanceWidthVp\)|vp2px\(10\)|vp2px\(28\)/.test(zoomView),
  'p750.panel.nodensity');
// 覆盖层绘制：遮罩 + 圆角描边 + 左下把手 chip
pin(/renderZoomWindowOverlay\(\): void/.test(canvas), 'p750.overlay.method');
pin(/#14000000/.test(canvas) && /ZOOM_WINDOW_SCRIM/.test(canvas),
  'p750.overlay.scrim8pct');
pin(/traceRoundRect[\s\S]{0,200}ctx\.arc/.test(canvas), 'p750.overlay.roundrect');
pin(/ZOOM_WINDOW_KNOB_VP: number = 24/.test(canvas), 'p750.overlay.knob24');
// 手势路由：ZOOM 激活时 onCanvasTouch 顶层路由 + 模式机
pin(/currentTool === ToolType\.ZOOM\) \{\s*this\.onZoomWindowTouch\(event\)/.test(canvas),
  'p750.touch.route');
pin(/ZOOM_WINDOW_DRAG_MOVE/.test(canvas) && /ZOOM_WINDOW_DRAG_RESIZE/.test(canvas),
  'p750.touch.modes');
pin(/ZOOM_WINDOW_KNOB_HIT_VP/.test(canvas) && /Math\.hypot/.test(canvas),
  'p750.knob.hittest');
// 移动=setSourceRect（screenDelta/zoom）；缩放=resizeSourceRect（rect+mag 联动）
pin(/\(touch\.x - this\.zoomWindowLastX\) \/ this\.viewport\.zoom/.test(canvas),
  'p750.move.delta');
pin(/zoomMagnification = Math\.min\(ZOOM_WINDOW_MAG_MAX/.test(canvas) &&
  /fixedRight/.test(canvas), 'p750.resize.maglink');
// 生命周期：初始化后重绘出覆盖层；卸载收尾清覆盖层；cancel 收尾手势
pin(/initZoomSourceRect[\s\S]{0,600}this\.renderFrame\(\);/.test(canvas),
  'p750.init.repaint');
pin(/onDisAppear\(\(\) => \{[\s\S]{0,120}endZoomWindowDrag/.test(canvas),
  'p750.unmount.cleanup');
pin(/cancelActiveInteraction[\s\S]{0,400}endZoomWindowDrag/.test(canvas),
  'p750.cancel.cleanup');
// 文档钉
pin(/gfg/.test(evidence750) && /resizeSourceRect/.test(evidence750) &&
  /iu1\.b\(0\.08f\)/.test(evidence750), 'p750.evidence.overlay');
pin(/zoom_overlay|zoom_outline/.test(evidence750) && /hhf/.test(evidence750),
  'p750.evidence.drawables');
pin(/vp2px/.test(evidence750) && /LengthMetricsUnit\.DEFAULT/.test(evidence750),
  'p750.evidence.vpbug');
pin(/resizeSourceRect/.test(adr750) && /1, ?10|1\.0, ?10|\[1,\s*10\]/.test(adr750),
  'p750.adr.resize');

// ---- Phase 751：bfg 边缘自动滚动（按压拖拽 + 指针近缘 → 视口平移+窗口跟随）----
pin(/ZOOM_EDGE_SCROLL_BAND_VP: number = 30/.test(canvas) &&
  /ZOOM_EDGE_SCROLL_SLOW_VPS: number = 100/.test(canvas) &&
  /ZOOM_EDGE_SCROLL_FAST_VPS: number = 500/.test(canvas), 'p751.constants');
pin(/updateZoomWindowEdgeScroll\(pointerX: number\)/.test(canvas) &&
  /w - ZOOM_EDGE_SCROLL_BAND_VP/.test(canvas) &&
  /pointerX < ZOOM_EDGE_SCROLL_BAND_VP/.test(canvas), 'p751.band.both');
pin(/setInterval[\s\S]{0,120}zoomWindowEdgeScrollTick/.test(canvas),
  'p751.frameloop');
pin(/viewport\.panBy\(-dxVp, 0\)/.test(canvas) &&
  /dxVp \/ this\.viewport\.zoom/.test(canvas), 'p751.scroll.follow');
pin(/zoomWindowDragMode === 0 \|\| this\.zoomEdgeScrollDir === 0/.test(canvas),
  'p751.tick.gate');
pin(/endZoomWindowDrag[\s\S]{0,120}stopZoomWindowEdgeScroll/.test(canvas) &&
  /clearInterval\(this\.zoomEdgeScrollTimer\)/.test(canvas), 'p751.cleanup');
pin(/updateZoomWindowEdgeScroll\(touch\.x\)/.test(canvas), 'p751.move.wired');
// 文档钉
pin(/bfg/.test(evidence751) && /withFrameNanos|30dp/.test(evidence751) &&
  /100dp/.test(evidence751) && /500dp/.test(evidence751), 'p751.evidence');
pin(/ADR-0699|bfg/.test(adr751) && /panBy/.test(adr751), 'p751.adr');

// ---- Phase 752：前进区夹取域 [48,336] 修正 + panelInTopHalf chromeFlip ----
pin(/ZOOM_ADVANCE_WIDTH_MIN_VP: number = 48/.test(zoomView) &&
  /ZOOM_ADVANCE_WIDTH_MAX_VP: number = 336/.test(zoomView), 'p752.clamp.consts');
pin(/Math\.max\(ZOOM_ADVANCE_WIDTH_MIN_VP,[\s\S]{0,60}ZOOM_ADVANCE_WIDTH_MAX_VP/
  .test(zoomView), 'p752.clamp.applied');
pin(!/Math\.max\(60, Math\.min\(320/.test(zoomView), 'p752.clamp.oldgone');
pin(/panelInTopHalf/.test(evidence752) && /rh8\.u\(fFloatValue, 48\.0f, 336\.0f\)|48\.0f, 336\.0f/
  .test(evidence752), 'p752.evidence');
pin(/panelInTopHalf|chromeFlip/.test(adr752) && /48/.test(adr752) && /336/.test(adr752),
  'p752.adr');

// ---- Phase 754：fgg.b 原版面板几何——画布卡 272dp + 控制条内沿序交换 ----
// 原版 njj.d(height 272dp) 仅包 dgg 画布卡（j0j 表面+g0j.c 前进区覆盖层），
// wfg 控制条是 Column 兄弟节点；旧 160vp 为未登记缩水。
pin(/surfaceHeightVp: number = 272/.test(zoomView), 'p754.surface.h272.prop');
// fgg.b Column：底停靠 [控制条][画布卡]、顶停靠 [画布卡][控制条]——
// 控制条恒贴面板内沿（条随停靠侧交换而非图标镜像）。
pin(/if \(this\.dockBottom\) \{[\s\S]{0,60}this\.ControlBar\(\)[\s\S]{0,60}this\.SurfaceArea\(\)/
  .test(zoomView), 'p754.dockorder.bottom');
pin(/\} else \{[\s\S]{0,60}this\.SurfaceArea\(\)[\s\S]{0,60}this\.ControlBar\(\)/
  .test(zoomView), 'p754.dockorder.top');
// Phase 752 的 scaleY 图标镜像机制证伪——原版是 Column 序交换。
pin(!/scale\(\{ x: 1, y: this\.dockBottom/.test(zoomView), 'p754.scalemirror.gone');
pin(/272\.0f|272dp|fgg/.test(evidence754) && /Column|内沿|兄弟/.test(evidence754),
  'p754.evidence');
pin(/272|fgg/.test(adr754) && /ADR-0700|supersed|纠正|取代/.test(adr754), 'p754.adr');

// ---- Phase 755：fgg.b l96.J AnimatedVisibility 500ms 靠缘 slide+fade ----
// s01.Y(500,0,cs3.a) + ey3.c/j slide∘fade 组合；iq2(0.25,0.1,0.25,1)≡Curve.Ease。
pin(/\.move\(this\.zoomDockBottom \? TransitionEdge\.BOTTOM : TransitionEdge\.TOP\)/.test(canvas), 'p755.edge.dock');
pin(/\.combine\(TransitionEffect\.OPACITY\)/.test(canvas), 'p755.slidefade');
pin(/duration: 500, curve: Curve\.Ease/.test(canvas), 'p755.timing');
pin(/l96\.J|AnimatedVisibility/.test(evidence755) && /iq2\(0\.25f, 0\.1f/.test(evidence755),
  'p755.evidence');
pin(/500|AnimatedVisibility|slide/.test(adr755), 'p755.adr');

console.log(`D02_ORIGINAL_ZOOM_VIEW_OK pins=${pass}`);
