# Phase 1448 报告 — deselectMode 点除成员 0.2 灰显

## 目标

补齐 P1445 遗留疑点：`deselectedIds` 无渲染消费——原版 deselectMode
下点除成员应有"淡出待删"视觉。

## 原版取证

- `kgi:101-116`：`isf.h`（deselectMode）时 `isf.i` 点除集 → `hak.o0`
  注入页渲染协程（否则 ∅）。
- `hak:572/629/666`：`o0` 经 `y2g.f0` 并集装配为 `linkedHashSetF0` →
  `oo7.c` 笔画渲染工 / `oo7.d` 形状渲染工。
- `ho7:93/179`：x1h/u1h 描述符布尔位 = `set.contains(getId())`。
- `oo7:201`：`x1h.o() ? 0.2f : 1.0f` 透明度乘子；`oo7.x:632-638`
  `z` 分支 `paint.alpha *= 0.2`（乘法语义）。
- `jo7:110/128/164/179`：形状 `zContains*` → v1h 灰显标志同构；
  `hak:1073` 图片 `l97` 分支同款 contains 过滤。
- 语义：点除成员**元素层渲染透明度 ×0.2**；`isf.i` 清空（确认/取消）
  → 灰显解除。

## 缺口与修复

| 缺口 | 修复 |
|---|---|
| `deselectedIds` 零渲染消费 | `renderOrderedElements` 命中 `elementId` 的元素换用 `AlphaScaledDrawingContext(renderContext, 0.2)` |

`AlphaScaledDrawingContext`（Canvas2DStrokeRenderer.ets）：
`Canvas2DDrawingContext` 委托——全部方法直通内层，仅 `setGlobalAlpha`
按系数缩放。内部绝对覆写（笔画 `s.opacity`、音频 `playback.alpha`）
也被乘上——严格等效原版 paint-alpha 乘法；优于外层包装（会被内部
覆写抵消）。五类元素分支（stroke/text/shape/image/math）全经 `rc`
分发；缩放上下文每趟惰性分配一次。

## 适配登记

`n0`（f0 并集另一集）语义未完全解码（kgi 协程体反编译失败）——其并入
灰显集不影响"点除 → 0.2"映射；若属其它灰显类别，Harmony 无对应需求。

## 验证

- fixture `d02-original-deselect-member-dim.mjs` 19/19。
- 全量基线与双 HAP 构建见提交注记。

## ADR

ADR-1383。
