# ADR-1006 — CRDT 寄存器应用层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `fi0.d(uq9, ie8)` = 实体寄存器应用模板：
  pageAndOrigin/rotation/scale/zIndex 四个寄存器经
  `rz1.R/P/Q` 写（null 跳过），任一写入→`A()` 失效。
- `rz1.R`：`((fqb)reg.get()).c(op, value)`——
  `Register$Builder.c(op,val)` 因果键写（真实类名
  `com.gingerlabs.notability.core.model.crdt`）。
- 值包装：k1a(page+origin)/tz9(cxc)/xgb(ULong)/
  y2d(scale)/k2d(SetFloat)。
- `be5` 实体变换 iface + `m5d`/`ry0` 实现 + y18 矩阵。

## Harmony 决策

**CRDT 收敛核心**：每属性独立寄存器+op 因果写——
实现须保留 LWW/寄存器语义，禁用最后写覆盖简化。

## Parity 状态

等价（寄存器合并序详见后续 Register 实现审计）。

## 验证

- `d02-crdt-registers.mjs`：11/11 通过。
