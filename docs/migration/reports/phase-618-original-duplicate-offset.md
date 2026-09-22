# Phase 618 — DUPLICATE 粘贴位置偏移（cg2.a()）

## 原版证据

- `lg2.java:171-191` `b()`：DUPLICATE 粘贴位置 =
  `ei3.a(fE2+fE, f(jC)+f2)` = `cg2.c() + cg2.a()` 分量相加。
- `cg2.java:21-26`：`a()` = `min((cmb.c-cmb.a)*0.1f, 30f)`
  打包为等量 x/y 偏移向量；`c()` = `fi3.b(cmb)`。
- `fi3.java:34-38`：`b(cmb)` = 矩形中心。
- 结论：副本中心 = 原选区中心 + min(选区宽×0.1, 30) 页面
  单位（x/y 同值）——副本向右下错开。常规 PASTE 无此偏移。

## 排查结论

Harmony `duplicateSelected` 与 PASTE 共用
`selectionPasteTarget()`（纯选区中心）——副本与原选区
完全重合，原版则带可见错位。

## 修复

`duplicateSelected` 内：
`rectWidthCanvas = (selectionRect.right - left) / zoom`
（屏幕像素还原页面单位）；`nudge = min(width×0.1, 30)`
（异常时取 30 兜底）；粘贴目标 `target + nudge`。
PASTE/`selectionPasteTarget` 不动。

## 验证

- 新增 replay `d02-original-duplicate-offset.mjs`：12/12 绿。
- 全量 desktop replay 套件：508/508 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

`Phase 618: DUPLICATE pastes at selection center + min(10% width, 30) (cg2.a)`
