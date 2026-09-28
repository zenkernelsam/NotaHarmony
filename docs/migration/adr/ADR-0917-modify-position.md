# ADR-0917 — ie8 ModifyPosition 条目契约

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`ie8` = ModifyPosition：`{target:qo5@0 必需,
page:cxc@1, origin:fqa@2, rotation:k2d@3,
scale:y2d@4, zIndex:tmf@5}`。`w0j.e` 写器 C(6)+z(4)；
rotation/scale 为 setter 子表；**zIndex=long**
（tmf.I 经 `f(5,·)` 写入）。

`w0j.f` = 0..5→1..6 层序映射助手。

## Harmony 决策

- zIndex 位宽：原版 long，Harmony int——已登记的
  位宽差异再证一处（td8/le8 同）。
- setter 包装与 je8 向量联结已对齐。

## Parity 状态

等价（位宽差异记录在案）。

## 验证

- `d02-modify-position.mjs`：15/15 通过。
