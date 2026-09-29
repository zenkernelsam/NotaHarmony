# Phase 1062 报告 — CRDT 寄存器应用层

## 范围

`fi0.d` 应用模板、`rz1` 写助手、`fqb`/`v1b`/`ei0` 机制、
`be5` 变换 iface。纯审计。

## 原版发现

- 实体属性以**独立 CRDT 寄存器**存储：pageAndOrigin
  （k1a 复合值）、rotation、scale、zIndex——每个经
  `rz1.R/P/Q` 按 op 因果写入 `Register$Builder`。
- null 值跳过写入；任一寄存器变更触发 `A()` 失效。
- `ei0` = callable reference 拿 builder 方法；
  `v1b` = Provider<Register.Builder>。
- `be5` = 实体变换抽象（origin/rotation/scale/page +
  矩阵 P()/y()）；m5d/ry0 实现。

## Harmony 决策

寄存器-per-属性语义必须保留（不可简化为字段覆盖）。

## 产出

- 证据：`phase-1062-crdt-registers.md`
- Fixture：`d02-crdt-registers.mjs`（11/11）
- ADR-1006；全量 Replay 见本提交。
