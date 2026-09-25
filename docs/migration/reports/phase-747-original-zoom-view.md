# Phase 747：原版 Zoom View 放大书写面板移植

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-747-original-zoom-view.md`
> ADR：`docs/migration/adr/ADR-0695-original-zoom-view-port.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（58 pins，全绿）

## 背景

Phase 742（ADR-0690）已更正：原版 `ac4.F ZOOM_VIEW → "androidZoomView"` 打包
默认 `true`（PRODUCTION 档→远端配置求值），即 1.0.3 中 Zoom 工具默认可见，
属真实待移植项——旧 ADR-0644"旗标未开"为误读。本 Phase 完成移植。

## 原版实现要点（decompiled_1.0.3）

- `ggg.java` ZoomViewState：isShown / dockEdge / sourceRectDocPx /
  magnification / advanceRegionWidthDp / panelInTopHalf
- `lgg.java` 默认：隐藏、底停靠（`qeg.J=Bottom`）、5.0×、180dp、非上半屏
- `ww2.java`/`wfg.java` 控制条：`[拖拽柄][分隔][Back][Forward][Return][Close]`
  均为 48dp 按钮，附 `zoom_view_*` a11y 描述
- `g0j.java`：自动前进区 `zoom_advance_tab`（"Adjust auto-advance area"）
- `ufg.java`：重定位事件 `{Advance, Back, Return}`
- `a6f.U=ZOOM` → `rz1` 副托盘 index 2；工具标签 `ui_tools__zoom="Zoom"`

## 移植内容

| 模块 | 变更 |
|------|------|
| `core/model/BrushTypes.ets` | `ToolType.ZOOM = 9`；修正旧注释 |
| `ui/editor/EditorViewModel.ets` | `createDefaultStates` 副托盘 index 2 播种 `'zoom'`；存量安装自动回填 |
| `ui/editor/ToolboxSettingsDialog.ets` | ZOOM 工具标签 → `tool_zoom` |
| `ui/editor/NoteZoomView.ets` | **新增**：控制条（拖拽柄/Back/Forward/Return/Close）+ 放大画布（5× + advance_tab 区）|
| `ui/editor/NoteCanvasView.ets` | ggg 状态源 + 触摸管线 + ufg 重定位 + 主画布 ZOOM 门 + 取消并入 `cancelActiveInteraction` |
| `resources/base\|zh_CN/element/string.json` | `tool_zoom` + `zoom_view_*` ×7 键 ×2 语系 |

## 语义对齐

- 书写：面板触摸 → doc 映射（`source + vp2px(x)/5`）→ `inputProvider.processEvent`
  → `StrokeSession` → 提交路径与主画布 Up 逐项一致（undo/persist/commitStroke）。
- 重定位：`Advance`（末笔入区自动右滑 `rectW−advanceDoc`）、`Back`/`Forward`
  （同步长步进）、`Return`（跳回末笔续写位）。
- 停靠：拖拽柄垂直拖动落点判定 Top/Bottom；默认底停靠。
- 关闭：取消进行中笔画 → `selectTool(DEFAULT)`。
- 主画布：ZOOM 激活时不产生笔画；滚动平移/文本链接点按保持原语义。
- a11y：七枚控件描述全部按原版字符串注册。

## 差异登记（详见 ADR-0695 §差异）

1. 放大面渲染笔画层；形状/图片/文本块留待后续接线。
2. 180dp→180vp 密度归一近似。
3. 停靠改为拖落点判档（非逐像素跟随）。
4. Prediction 预览分支未复制（historical+real 批次同径平滑）。

## 验证

- Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=58`
- `note@default` 增量构建成功（仅既有 vp2px 等弃用告警，无新增错误）
