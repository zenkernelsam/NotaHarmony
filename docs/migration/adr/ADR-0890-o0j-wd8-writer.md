# ADR-0890 — o0j.f ModifyInk 写器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `o0j.f` = wd8 19 槽写器：f0 inks 向量
  **required**（`z(iN,4)`）；f1-f18 逐项镜像读端。
- `aVar.l=true` = 枚举强制写开关（byte 枚举
  =0 也写出，避免缺省歧义）。
- `xd8` 路径 provider、`apb.Y` 点写器、
  `z5c.P` 色写器、`rz1.h0/g0` 位集编码。

## Harmony 决策

写端字段序对齐；f0 required 语义保留；
枚举 0 值强制写出。

## Parity 状态

等价。

## 验证

- `d02-o0j-wd8-writer.mjs`：11/11 通过。
- 全量 Replay 819 文件绿，见 Phase 946 提交。
