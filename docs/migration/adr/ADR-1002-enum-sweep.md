# ADR-1002 — 枚举清扫（11 个剩余枚举）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 11 个 byte 枚举：im 锚点 5、iq0 纸色**稀疏码**
  （1/2/6/7/13/15）、n3a 纸纹 3、oz9 书签、xw9 PDF 盒
  模式 3、y01 位置 4、z4d 形状定义 4、z90、zsa 位宽、
  ww9 值类型、t8a 路径元素 8（attributed×4+非×4）。

## Harmony 决策

- 枚举 wire 码全部保留；**iq0 稀疏码禁止重排**；
  t8a attributed 语义保留。

## Parity 状态

等价。

## 验证

- `d02-enum-sweep.mjs`：12/12 通过。
