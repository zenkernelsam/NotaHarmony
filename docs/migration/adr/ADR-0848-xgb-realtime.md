# ADR-0848 — `xgb` = `Realtime` 音频时间值类

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `xgb` = `Realtime`：ULong 语义领域值类
  （`Long.compareUnsigned` + 无符号十进制格式化）——
  录音/回放实时位置。
- 使用点：`wq9.d`（OpCreationMetadata.audioTime，掩码
  bit16 默认 null）、`w0j.a` 等工厂参数、`uq9` 字段3、
  `f8d.c` rawAudioTime。
- **创建侧=Realtime，线上=裸 ULong**：uq9 读侧暴露
  `tmf`/`long`——Realtime 不持久化类型，仅语义标注。
- 无符号家族终态：mmf=UInt、ymf=UShort、tmf=ULong、
  xgb=Realtime。

## Harmony 决策

audioTime 按 ULong 读；Realtime 语义仅创建侧标注。

## Parity 状态

等价（值类实名 + 线上类型边界澄清）。

## 验证

- `d02-xgb-realtime.mjs`：11/11 通过。
- 全量 Replay 777 文件绿，见 Phase 904 提交。
