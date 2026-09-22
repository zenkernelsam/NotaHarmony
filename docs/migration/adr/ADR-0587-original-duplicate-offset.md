# ADR-0587 — DUPLICATE 粘贴位置偏移（cg2.a()）

- 状态：Accepted
- Phase 618；对齐 `lg2.b` + `cg2.a()/c()` + `fi3.b`
  （decompiled_1.0.3）。

## 背景

原版 DUPLICATE（`dhb` case3 → `vsc` → `lg2.b`）的粘贴位置 =
`cg2.c() + cg2.a()`：`c()` = 选区矩形中心（`fi3.b`），
`a()` = `(min(选区宽×0.1, 30), 同值)`——副本向右下错开，
避免与原选区完全重合（可见的「副本错位」行为）。

Harmony 旧实现：`duplicateSelected` 与 PASTE 共用
`selectionPasteTarget()` = 选区矩形中心——副本与原选区
完全重合，用户难以察觉复制已发生。

## 决策

1. `duplicateSelected` 内注入偏移：
   `rectWidthCanvas = (selectionRect.right - left) / zoom`
   （`selectionRect` 是屏幕像素，除缩放还原页面单位），
   `nudge = min(width×0.1, 30)`，粘贴目标 =
   `target + nudge`（x/y 同值）。
2. PASTE 与 `selectionPasteTarget` 不变——常规粘贴不带
   该偏移（原版 PASTE 不经 `cg2.a()`）。

## 边界

- `rectWidthCanvas` 非有限/非正（选区矩形退化）→
  `nudge = 30`（上限兜底，fail-safe 而非 fail-closed——
  DUPLICATE 已确认选区存在才走到这里，矩形异常时取原版
  最大偏移是更保守的用户可见反馈）。
- 偏移为页面单位（模型空间），与 `pasteClipboard` 的
  中心语义一致。
- 30 为原版 `Math.min` 硬上限，照抄不调整。
