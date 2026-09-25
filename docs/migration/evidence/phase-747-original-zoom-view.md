# Phase 747 证据：原版 Zoom View 放大书写视口（ggg/vgg/ww2/g0j/fgg/wfg/lgg/qeg/ufg）

> 证据基线：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources`（Android 1.0.3 JADX）。
> 本 Phase 移植原版 WetInk 编辑器中的 Zoom View（放大书写面板）——Phase 742（ADR-0690）
> 已更正：ZOOM_VIEW 旗标在 1.0.3 默认开（`"androidZoomView"` 打包默认 `true`，
> PRODUCTION 档→远端配置求值），ZOOM 工具默认可见，属真实待移植项而非"旗标未开"。

## 1. 原版类与字段

### 状态机（`defpackage/ggg.java` — ZoomViewState）

```text
ZoomViewState(
  isShown,               // a：面板显隐
  dockEdge,              // b：停靠边（qeg）
  sourceRectDocPx,       // c：放大窗口在文档坐标（doc px）下的源矩形
  magnification,         // d：放大倍率
  advanceRegionWidthDp,  // e：自动前进区宽（dp）
  panelInTopHalf         // f：面板是否位于上半屏
)
```

### 默认值（`defpackage/lgg.java`）

| 字段 | 默认 |
|------|------|
| isShown | `false`（选中 ZOOM 工具才显示） |
| dockEdge | `qeg.J`（Bottom） |
| sourceRectDocPx | 空矩形 |
| magnification | `5.0f` |
| advanceRegionWidthDp | `180.0f` |
| panelInTopHalf | `false` |

### 停靠枚举（`defpackage/qeg.java`）

`qeg { I="Top"(0), J="Bottom"(1), K=[I,J] }`——两档停靠（顶/底）；
`lgg:19` 确认默认 `qeg.J`（Bottom）。

### 重定位事件（`defpackage/ufg.java`）

```text
ufg { I=Advance, J=Back, K=Return }
```

面板的书写宿主按三类重定位原因调整 `sourceRectDocPx`：
- `Advance`：笔画落进自动前进区 → 窗口右滑；
- `Back`/`Return`：控制条按钮触发窗口回跳/跳回墨迹位。

### 控制条（`defpackage/wfg.java` + `ww2.java` default case）

`wfg.c`：48dp 拖拽柄（`ui_designsystem__drag_handle`），a11y 描述 =
`feature_note_wetink_ui__zoom_view_move_description`，`q8e.a(...)` pointer-input 拖动手势。

`ww2` default case 控制条行（48dp 高，`bfd.h(48.0f)`），顺序：

```text
[drag handle] [divider] [Back] [Forward] [Return] [Close]
```

- `wfg.b(ue4.r(...), zoom_view_back_description, fn, …)` — Back
- `wfg.b(ue4.r(...), zoom_view_forward_description, fn, …)` — Forward（`z=true` 变体）
- `wfg.b(vh2.h(zoom_return), zoom_view_return_description, fn, …)` — Return
- `wfg.b(ue4.u(...), zoom_view_close_description, fn, …)` — Close

`g0j.java:69`：`zoom_advance_tab` drawable + a11y `zoom_view_advance_region_description`
（"Adjust auto-advance area"）——自动前进区边缘的可拖调整钮。

### 原版字符串（`res/values/strings.xml`）

| key | value |
|-----|-------|
| `ui_tools__zoom` | Zoom |
| `…zoom_view_advance_region_description` | Adjust auto-advance area |
| `…zoom_view_back_description` | Back |
| `…zoom_view_forward_description` | Forward |
| `…zoom_view_move_description` | Move Zoom View |
| `…zoom_view_return_description` | Return |
| `…zoom_view_close_description` | Close Zoom View |

### 工具槽位（`a6f.java`/`rz1` 种子）

`a6f.U = ZOOM`；`rz1` 副托盘序 = POINTER(0)/LASER(1)/**ZOOM(2)**/REVIEW(3)/RULER(4)，
ZOOM 占据 index 2。

## 2. Harmony 实现映射（Phase 747）

### 新增/改动文件

| 文件 | 内容 |
|------|------|
| `core/model/BrushTypes.ets` | `ToolType.ZOOM = 9`；修正旧注释（ADR-0690 已更正旗标默认开） |
| `ui/editor/EditorViewModel.ets` | `createDefaultStates` 副托盘 index 2 播种 `'zoom'`（PEN 默认笔型参数）；存量安装经既有缺省回填机制获得 |
| `ui/editor/ToolboxSettingsDialog.ets` | `toolTypeLabel` ZOOM → `tool_zoom` |
| `ui/editor/NoteZoomView.ets` | **新增组件**：控制条 + 放大画布 |
| `ui/editor/NoteCanvasView.ets` | ggg 状态源（zoomSourceX/Y/dockBottom/advanceWidthVp/mag=5）、触摸管线、自动前进/步进/回跳、关闭回落 DEFAULT |
| `resources/base|zh_CN/element/string.json` | `tool_zoom` + `zoom_view_{move,back,forward,return,close,advance}` ×2 语系 |

### 语义映射

| 原版 | Harmony |
|------|---------|
| `ggg.a isShown` | `viewModel.currentTool === ToolType.ZOOM` 即挂载面板 |
| `ggg.b dockEdge` | `zoomDockBottom: boolean`（底=lgg 默认） |
| `ggg.c sourceRectDocPx` | `zoomSourceX/Y`（左上角）；窗口 doc 宽 = 屏 px ÷ 5 |
| `ggg.d magnification=5.0` | `zoomMagnification = 5`（screen px / doc px） |
| `ggg.e advanceRegionWidthDp=180` | `zoomAdvanceWidthVp = 180`（vp 近似；advance_tab 可拖调 60..320） |
| `ufg.Advance` | `zoomAutoAdvance(stroke)`：末笔末端入区 → `sourceX += rectW − advanceDoc` |
| `ufg.Back` | `zoomStepBack`：`sourceX −= rectW − advanceDoc` |
| `ufg.Return` | `zoomReturnToInk`：末笔末端锚定至前进区前沿 |
| `ww2` 控制条 | Row：`≡`(PanGesture 垂直拖→换停靠) + Divider + `‹ › ↩ ✕` 四枚 48vp 按钮，a11y 描述全部按原版键 |
| `g0j` advance_tab | 画布内 trailing 阴影带 + 区界线 + 中央拖钮（横向 PanGesture 调宽） |
| `zeg` Close | `onClose` → 取消进行中的放大笔画 → `selectTool(DEFAULT)` |

### 书写管线（与主画布同径）

- 面板触摸透传 `onZoomTouchEvent`：Down/Move/Up/Cancel 全生命周期；
- `zoomRawPointerEvent`：`ArkUIStylusAdapter.fromTouch` 取压感/倾角/方位/toolType，
  坐标 `doc = source + vp2px(touch.x) / mag`，夹取至页边界——与
  `toRawPointerEvent` 的页界夹取一致；
- `inputProvider.processEvent`（pressure/tilt/orientation 归一化 + elapsed 计时）
  → `StrokeSession.addBatch`（同主画布平滑/拟合管线）；
- Up：`finishStroke` → `completedStrokes.push` → `appendPageElementRefs` →
  `undoRedo.push(ADD_STROKE)` → `layerManager.commitStroke` → `persist(originalCreate)`
  → `notifyUndoRedo` → `zoomAutoAdvance` → `renderFrame`——与主画布笔画
  提交路径逐项对应；
- 进行中的笔画经 `strokeSession.getCurrentStroke()` → `zoomLiveStroke` @Prop
  → `paintTick` 触发 `NoteZoomView` 重绘；
- 取消：`onZoomTouchCancel`（含 `refreshOriginalInkReservation`），
  已并入 `cancelActiveInteraction` 顶部（工具切换/页面离开时兜底）。

### 主画布行为门

`onTouchDown` 在 LASER 分支之后、笔画工具分支之前加：
`currentTool === ZOOM → return`（不置 isDrawing）——放大书写期间主画布
不产生笔画；外层 Scroll 平移与上方的文本链接/元素点按检查保持原语义。

### 放大渲染

`NoteZoomView.draw()`：`paperBackground` 填充 → `ctx.transform(5×, −src)` →
`StrokeCanvasPainter.renderStroke`（复用正式墨迹渲染器，含 revealedTapeIds/
铅笔 splat/胶带图案的既有渲染路径）→ `liveStroke` → 自动前进区视觉标记。

## 3. 与原版差异登记（本 Phase 边界）

1. **原文形状/图片/文本块在放大面内不渲染**——原版 WetInk 放大面渲染全部
   元素层；本切片先覆盖笔画层（书写主场景）。形状/图片/文本的放大渲染
   留待后续 Phase（渲染器接口已就绪，仅未接线）。
2. **180dp→180vp 近似**：Harmony `advanceRegionWidth` 用 vp 承载
   （vp≈dp 设备密度归一化单位，语义等价）。
3. **拖拽柄重新停靠**：原版 pointer-input 拖动跟随手指；本实现以垂直
   PanGesture 落点判定 Top/Bottom（下拖→底，上拖→顶），停靠档位语义一致。
4. **Advance/Back/Return 步长**：原版由 wetink 宿主计算精确位移；本实现按
   `rectW − advanceDoc` 步进（保持前进区重叠，衔接语义一致）。
5. **`panelInTopHalf`**：原版记录面板屏幕半区（影响附加 UI 布局）；Harmony
   面板固定贴边停靠，不另需半区标记。
6. **预测/预测批**：面板 move 收集 historical + real 批次；主画布的
   Prediction 预览路径未在放大面内复制（笔迹仍实时绘制，延迟差异不可见）。

## 4. 可复验命令

```bash
# 原版证据
grep -n "zoom_view_" "/c/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml"
grep -n "advance\|magnification\|dockEdge" "/c/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/lgg.java"

# Harmony 实现
grep -n "ToolType.ZOOM" note/src/main/ets/core/model/BrushTypes.ets
grep -n "zoom" note/src/main/ets/ui/editor/NoteZoomView.ets
grep -n "zoomAutoAdvance\|initZoomSourceRect\|onZoomTouch" note/src/main/ets/ui/editor/NoteCanvasView.ets
```
