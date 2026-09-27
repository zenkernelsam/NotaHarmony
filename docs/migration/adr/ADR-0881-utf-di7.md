# ADR-0881 — Uuid 线型布局 + 路径迭代器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `utf`=Uuid 16B inline：bitsHigh@0 + bitsLow@8
  （MSB 在前，标准 UUID 大端）。
- `cee.g(int)` = ByteBuffer 切片访问器；
  `di7`/`ei7` = hmf 零拷贝字节迭代器覆盖
  dm2/wd8/gd 路径向量 g(6-26)。

## Harmony 决策

Uuid 线型 MSB-first；路径向量按原始字节切片读。

## Parity 状态

等价。

## 验证

- `d02-utf-di7.mjs`：10/10 通过。
- 全量 Replay 810 文件绿，见 Phase 937 提交。
