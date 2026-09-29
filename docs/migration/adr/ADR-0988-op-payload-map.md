# ADR-0988 — 操作载荷类全集与 ka4 校验语义

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z5c` op 分派：`uq9.m().ordinal()` switch 0–31 → 31 个
  `cee+ka4` 载荷类（NONE→throw null；default→null）。
- `ka4.a()` = **校验接口**：返回错误字符串，null=通过
  （修正"String 访问器"旧解读）。
- `l2d` SET_METADATA 校验：title 非空≤256；模板 PDF 单页；
  字号>0；字体族≤30；`nz9` 子校验经 `ddg.g`。

## Harmony 决策

32 载荷逐一映射；`ka4.a()` → `validate(): string|null`；
SET_METADATA 五条校验规则逐条保留。

## Parity 状态

等价（校验文案后续需逐类核对）。

## 验证

- `d02-op-payload-map.mjs`：12/12 通过。
