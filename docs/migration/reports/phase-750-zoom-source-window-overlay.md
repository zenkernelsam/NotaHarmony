# Phase 750：原版 Zoom 源窗口覆盖层（gfg/dfg/bfg）+ vp2px 坐标修复

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-750-zoom-source-window-overlay.md`
> ADR：`docs/migration/adr/ADR-0698-original-zoom-source-window-overlay.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（103 pins，全绿）

## 背景

Phase 747–749 移植了 Zoom 放大书写面板，但原版 `gfg` 还有一层叠加在
**页面画布上**的可交互源窗口：窗外 8% 暗化遮罩、圆角描边框、左下角
圆形把手 chip——窗内拖动移动窗口、把手拖动缩放窗口并联动放大倍率。
本次补齐该层，并顺带修复 Phase 747 遗留的 vp2px 坐标系缺陷。

## 原版证据（decompiled_1.0.3）

- `gfg.java`：覆盖层组合函数，`efg`（PointerInputEventHandler）包裹整页；
  回调委托 `ahg.setSourceRect(Rect)` ×1 + `ahg.resizeSourceRect(Rect, F)` ×2；
  常量 `a = iu1.b(0.08f)`（遮罩 alpha），`b` = 把手握持多边形点表。
- `ahg.i(cmb, f)`（mask=51）：sourceRect 与 magnification **同帧同写**——
  窗口缩放与放大倍率耦合。
- `drawable/ui_designsystem__zoom_*`：`fill`（chip 黑底）、`overlay`（白片
  挖圆孔）、`outline`（描边框、左下缺口）、`highlight`（高光）、
  `shadow`（底缘投影）——把手定位于窗口左下角。
- `hhf`：双模式指针处理器——a=0 分支为速度 fling 检测（面板拖拽柄
  甩动停靠，**非**早前推测的旋转手势）；a=1 包装 `ffg` 二级拖拽状态机。
- `dfg`/`ffg` 的 `invokeSuspend` 均未反编译（JadxOverflow）——
  精确手势数学不可恢复，按文档化近似实现。

## 移植内容

| 模块 | 变更 |
|------|------|
| `NoteCanvasView.ets` | `renderZoomWindowOverlay`（遮罩+描边+chip 把手，renderFrame 尾部屏幕空间）；`onZoomWindowTouch`（onCanvasTouch 顶层路由：窗内拖动移动 / 把手缩放联动倍率 / 窗外点按移位）；`endZoomWindowDrag` 接入 cancelActiveInteraction 与面板 onDisAppear |
| `NoteZoomView.ets` | advancePx/tabW/tabH 去除 vp2px |

## 顺带修复：vp2px 坐标缺陷（Phase 747 移植 bug）

`CanvasRenderingContext2D` 默认 `LengthMetricsUnit.DEFAULT` = vp 绘制空间，
触摸/ctx/scroll 全 vp 自洽。747 版误乘 density：面板笔画落点、源窗尺寸、
前进区宽度在 density≈2.75 设备上全部放大约 2.75×。已统一改回 vp 直值；
源窗宽另修正为 `overlayWidth − 16`（面板 margin 8×2）。

## 近似登记

- 把手命中半径 36vp、倍率域 [1,10]、窗外点按窗口跳中——`dfg` 未反编译，
  按经典 zoom-box 交互近似。
- `hhf` fling 停靠未移植（沿用 Phase 747 落点判定）。
- chip 高光/投影细节简化。

## 观察项

- `sampleEyedropper` 的 `getImageData` 取样坐标乘 density——vp 模式下
  ImageData 坐标亦为 vp，存在同类偏移，登记留待后续 Phase。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=103`（+21 pins：覆盖层
  结构、手势路由、move/resize 语义、生命周期清理、vp2px 修复钉）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@ohosTest`：BUILD SUCCESSFUL（clean 后）
- `note@default`：BUILD SUCCESSFUL（clean 后）
- 警告：仅既有弃用告警（vp2px/getContext/showToast 等），无新增错误
