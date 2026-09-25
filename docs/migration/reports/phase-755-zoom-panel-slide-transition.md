# Phase 755：Zoom 面板 AnimatedVisibility 靠缘 slide+fade 过渡

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-755-zoom-panel-slide-transition.md`
> ADR：`docs/migration/adr/ADR-0703-zoom-panel-slide-transition.md`
> Replay：`d02-original-zoom-view.mjs`（128 pins，全绿）

## 背景

`fgg.b` 复核显示原版 Zoom 面板经 `l96.J`（AnimatedVisibility）
显隐：`ey3.c/j` slide+fade 组合、`s01.Y(500,0,cs3.a)` 500ms
ease(0.25,0.1,0.25,1) tween、滑入缘随 `qeg` 停靠侧（Top/Bottom）。
Phase 747 的 `if` 挂载为瞬时显隐。

## 实现

`NoteCanvasView` zoom 挂载 Column 追加
`TransitionEffect.move(dock缘).combine(OPACITY)
.animation({500, Curve.Ease})`——`Curve.Ease` 贝塞尔与 `cs3.a`
逐值一致，方向映射停靠缘，进出皆走该过渡（激活/Close/换工具）。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=128`（+5 p755 钉）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@default` / `note@ohosTest` HAP 构建：BUILD SUCCESSFUL
- 注意：过渡属视觉动效，无设备运行验证（按规未启动模拟器）。
