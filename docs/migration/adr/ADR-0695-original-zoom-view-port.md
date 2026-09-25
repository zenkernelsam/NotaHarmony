# ADR-0695：原版 Zoom View 放大书写面板移植

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0690（ZOOM_VIEW 旗标更正：默认开）、ADR-0644（被更正的旧注册）、
  ADR-0692（音频联动笔触——与 Zoom 笔画共用 StrokeSession 管线）

## 背景

Android 1.0.3 编辑器内置 Zoom View：选中 ZOOM 工具（`a6f.U`，副托盘 index 2）
后弹出放大书写面板——以 5× 显示文档局部矩形，在其内落笔生成与主画布同一
笔迹管线产出的笔画；面板控制条含拖拽柄、Back/Forward/Return/Close；trailing
自动前进区支持连续书写自动滑窗。

Phase 742 证据更正（ADR-0690）：`ac4.F ZOOM_VIEW → "androidZoomView"` 打包默认
`true`（PRODUCTION 档 → `trb.e` 远端配置求值）——1.0.3 默认可见，必须移植。

## 决定

完整移植 Zoom View（非 fail-closed）。Harmony 侧实现拆解：

1. **工具模型**：`ToolType.ZOOM=9`；`createDefaultStates` 副托盘 index 2 播种
   `'zoom'`（笔型参数沿用 PEN 默认）；存量安装经 `initialize` 缺省回填获得。
2. **状态源**（宿主持有，对应 `ggg`）：`zoomSourceX/Y`（sourceRectDocPx 左上）、
   `zoomDockBottom`（qeg.J 默认底停靠）、`zoomMagnification=5`、`zoomAdvanceWidthVp=180`。
3. **面板组件** `NoteZoomView`：
   - 控制条按 `ww2` 顺序：拖拽柄（垂直 PanGesture 落点换停靠，
     a11y=zoom_view_move）+ Divider + `‹›↩✕` 四枚 48vp 按钮
     （a11y=zoom_view_back/forward/return/close）。
   - 放大画布：`ctx.transform(mag, −src)` + `StrokeCanvasPainter.renderStroke`
     复用正式墨迹渲染（铅笔 splat 纹理、胶带图案同径）。
   - 自动前进区：`g0j` advance_tab 语义——trailing 阴影带 + 中央拖钮，
     横向 PanGesture 调区宽（60..320vp 夹取）。
4. **书写管线**：面板触摸透传宿主 → `zoomDocPoint`（vp→px→doc + 页界夹取）→
   `inputProvider.processEvent` → `StrokeSession.addBatch` → `finishStroke`
   → 与主画布同一 commit/persist/undo 路径。
5. **重定位**：`ufg.Advance` → 末笔入区自动右滑 `rectW−advanceDoc`；
   Back/Forward 同步长步进；Return 跳回末笔续写位。
6. **主画布门**：ZOOM 激活时主画布不产生笔画（手势回落 Scroll 平移）；
   关闭 → 取消进行中的放大笔画 → 回落 DEFAULT 工具。

## 差异登记

- ~~放大面当前渲染**笔画层**；形状/图片/文本块未接入放大渲染~~
  **已于 Phase 748 / ADR-0696 修正**：vgg 注入整页渲染栈，放大面现复用
  renderOrderedElements 呈现全部元素。
- `advanceRegionWidth` 180dp → 180vp（设备密度归一化单位近似）。
- 拖拽柄停靠改为垂直拖动落点判定（档位语义一致，非逐像素跟随）。
- 未复制主画布 Prediction 预览分支（historical+real 批次已走同径平滑）。

## 后果

- `androidZoomView` 默认开对应的用户可见功能落地；工具箱副托盘出现 Zoom。
- `ui_tools__zoom`/`zoom_view_*` 字符串按原文注册（zh_CN 译配）。
- Replay：`d02-original-zoom-view.mjs` 钉住上述全部证据点与实现接点。
