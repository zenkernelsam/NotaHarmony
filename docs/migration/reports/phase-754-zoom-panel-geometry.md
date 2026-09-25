# Phase 754：Zoom 面板原版几何——画布卡 272dp + 控制条内沿序交换

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-754-zoom-panel-geometry.md`
> ADR：`docs/migration/adr/ADR-0702-zoom-panel-geometry.md`（纠正
> ADR-0700 翻转机制结论）
> Replay：`d02-original-zoom-view.mjs`（123 pins，全绿）

## 背景

复核 `fgg.b` 面板组合时发现两处偏差：

1. 原版 `njj.d` Surface 卡高 **272dp**（内包 `dgg` = 放大表面 +
   前进区覆盖层 Box），`wfg` 控制条为兄弟节点——Phase 747 的
   160vp 无证据依据，缩水 41%。
2. `panelInTopHalf` 的实际机制是 `cgg` Column 内按
   `dockEdge==qeg.I` 条件交换控制条/画布卡顺序（条恒贴面板内沿：
   底停靠条在上、顶停靠条在下）——Phase 752 依 `svf` "toolboxFlip"
   实现的 `scaleY=±1` 图标镜像作用域判错（该翻转属主工具条），
   且会倒置按钮字形。

## 实现

- `ZOOM_SURFACE_HEIGHT_VP`/`surfaceHeightVp`：160 → **272**。
- `NoteZoomView` 控制条/画布区抽为 `@Builder ControlBar()` /
  `SurfaceArea()`，`build()` 按 `dockBottom` 交换 Column 顺序。
- 删除 `scale({x:1,y:-1})` 镜像。
- 源窗口高度同步变为 272/5=54.4 文档单位（原 32）。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=123`
  （h160→h272、chromeflip.scale 钉撤除、+6 p754 钉）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@default` / `note@ohosTest` HAP 构建：BUILD SUCCESSFUL
