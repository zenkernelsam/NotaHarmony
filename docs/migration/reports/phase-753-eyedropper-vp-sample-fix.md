# Phase 753：eyedropper 取样坐标 vp/px 单位修复

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-753-eyedropper-vp-sample-fix.md`
> ADR：`docs/migration/adr/ADR-0701-eyedropper-vp-sample-fix.md`
> Replay：`docs/migration/replays/d02-original-eyedropper.mjs`（30 pins，全绿）

## 背景

Phase 750 确认 `CanvasRenderingContext2D` 默认 vp 绘制空间并修复
Zoom 路径的同型 `vp2px` 缺陷时，登记了 `sampleEyedropper` 的同类
观察项。本 Phase 落地修复。

## 缺陷

`getImageData` 在 `LengthMetricsUnit.DEFAULT`（vp）模式下入参为
vp、返回 `ImageData.width/height` 为物理 px。旧实现：

- `xVp×density` 送入 vp 解释的 API → 取样区偏移约 2.75×；
- 请求 `24`（被解释为 24vp→66 物理 px）；
- 以 vp 值当 px 行距索引 `data` → 取到错误像素；
- `PixelMap` 声明 24×24 vs 缓冲 66×66×4 → 尺寸失配、放大镜畸形。

## 修复

`sampleEyedropper` 改 vp 直取 + 物理 px 行距：请求边长
`24/density` vp（保持原版 `nui` 24 物理 px 邻域）、`ImageData`
实际宽高作行距与 PixelMap 尺寸、触点偏移 `(xVp−sx)×density`。

## 验证

- 专项 Replay：`d02-original-eyedropper TOTAL=30`（+4 vp 空间钉，
  `canvas pixel sampling` 钉同步演进）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@ohosTest` / `note@default` HAP 构建：BUILD SUCCESSFUL
- 警告：仅既有弃用告警，无新增错误
