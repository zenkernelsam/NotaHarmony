# ADR-0981 — x09 文档模型 + m09 默认常量

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `x09` = marker iface（218+ impl）；`m09` =
  companion 默认常量（qed size/vy7 margins/hu1
  color/vv7 复合/a79.P float）+ `c=qed.d()/768`
  基准缩放。
- `m09.a(r29,cl9)` = bundle→model 物化器
  （ze9 头部+lv2.T ops→cl9 文档）。

## Harmony 决策

`x09`→ArkTS base interface；`m09` 常量+`a()`物化器
保留；768 缩放对齐。

## Parity 状态

等价。

## 验证

- `d02-document-model.mjs`：10/10 通过。
