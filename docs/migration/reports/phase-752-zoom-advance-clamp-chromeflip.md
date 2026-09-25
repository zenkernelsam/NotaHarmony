# Phase 752：原版 Zoom 前进区宽夹取域修正 + panelInTopHalf chrome 翻转

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-752-zoom-advance-clamp-chromeflip.md`
> ADR：`docs/migration/adr/ADR-0700-original-zoom-advance-clamp-chromeflip.md`
> Replay：`docs/migration/replays/d02-original-zoom-view.mjs`（118 pins，全绿）

## 背景

Zoom 簇深挖（`ggg`/`egg`/`htd`/`svf`/`u49`/`b7f`）暴露两处对齐缺口：
Phase 749 的前进区宽夹取域为估值 [60,320]，原版实为 [48,336]；
`ggg` 第 6 字段 `panelInTopHalf` 此前漏登记——它驱动控制条镀铬的
垂直镜像动画。

## 原版证据（decompiled_1.0.3）

- `htd.java` case 18：`setAdvanceRegionWidth` →
  `rh8.u(f, 48.0f, 336.0f)`（coerceIn）——**夹取域 [48,336]dp**；
  读侧 `bc7` 无夹取（原版夹取仅存在于 setter）。
- `ggg.toString`：第 6 字段 `panelInTopHalf`；`egg` case 0 由布局
  位置流（`zt8`/`z04` 组合两个 l6a）派生写入。
- `ahg.S = ko4.f(ufb, svf(19))` = `isShown && panelInTopHalf` 派生流
  → `u49:1481` `mx.b(flag?1:-1, spec, "chromeFlip")` +
  `u49:1625` → `z5c.c`/`b7f.a` `jw0(0,flip)` —— 面板在上半区时
  zoom 控制条镀铬 scaleY 镜像（"toolboxFlip" 动画）。

## 移植内容

| 模块 | 变更 |
|------|------|
| `NoteZoomView.ets` | `ZOOM_ADVANCE_WIDTH_MIN/MAX_VP=48/336` 常量 + 拖拽夹取域更正；控制条 Row `.scale({x:1, y: dockBottom?1:-1})` —— `panelInTopHalf ≡ !dockBottom`（离散停靠覆盖全部可达态） |

## 近似登记

- 无 spring 过渡动画（`s01.Y` spec 细节不可见）——即时翻转；
- 仅控制条镜像，书写画布不翻转（画布变换独立于 chrome）。

## 验证

- 专项 Replay：`D02_ORIGINAL_ZOOM_VIEW_OK pins=118`（+6 pins）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@ohosTest` / `note@default` HAP 构建：BUILD SUCCESSFUL
- 警告：仅既有弃用告警，无新增错误
