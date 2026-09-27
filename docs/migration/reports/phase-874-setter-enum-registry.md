# Phase 874 报告 — setter 包装族 + op 枚举登记

## 范围

登记 MODIFY_* 统一单字段 setter 包装（k2d/y2d/z2d/g2d/p2d/
n2d）与九枚 op 枚举；核对 Harmony 解码与写手。纯审计阶段。

## 原版发现

- setter 表统一形态 `{f0: T}`：存在=改、缺省=不改。
- u16 线层工具枚举 8 值（PEN…LASER）；t16/ife/z4d/ty0/ive/
  im 全部复原；`a6f` 是另一套 UI 笔刷枚举（BrushTypes 引用）。

## Harmony 核对

u16 线值解码逐值一致、可创建门限正确排除不可创建工具；
setter null-gate 语义对应。

## 产出

- 证据：`phase-874-setter-enum-registry.md`
- Fixture：`d02-setter-enum-registry.mjs`（53/53）
- ADR-0818；全量 Replay 与双 HAP 结果记录于提交。
