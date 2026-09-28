# ADR-0895 — op 写器解剖

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`vej.q` 标准写器解剖：wj9 元素提供器 +
sg5.o 空哨兵 + D(bytes,len,align) 结构向量 +
sg5.f 草稿写 + 负长日志 + z(iN,4) required。
全表写器同构。

## Harmony 决策

写器同构语义对齐。

## Parity 状态

等价。

## 验证

- `d02-vej-writer-anatomy.mjs`：8/8 通过。
- 全量 Replay 824 文件绿，见 Phase 951 提交。
