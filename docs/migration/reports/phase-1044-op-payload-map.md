# Phase 1044 报告 — 操作载荷类全集与 ka4 校验

## 范围

`z5c` 操作分派表 32 分支全图、`ka4` 语义修正、`l2d`
SET_METADATA 校验规则。纯审计。

## 原版发现

- `z5c` 按 `uq9.m().ordinal()` 分派 31 个载荷类，NONE→throw，
  default→null；全部 `extends cee implements ka4`。
- **`ka4.a()` = 校验失败原因**（null=通过）——修正此前
  "id 字符串访问器"解读：utf/cxc/id 类型的 `a()` 同属
  校验语义。
- `l2d`（SET_METADATA）校验：title 非空≤256、模板 PDF
  `sw9.o()==1`、字号>0、字体族≤30、`nz9`→`ddg.g` 子校验。

## Harmony 决策

`ka4` → `validate(): string|null`；SET_METADATA 规则逐条
保留（256/30/>0/单页模板）。

## 产出

- 证据：`phase-1044-op-payload-map.md`
- Fixture：`d02-op-payload-map.mjs`（12/12）
- ADR-0988；全量 Replay 见本提交。
