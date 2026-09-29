# ADR-0955 — 转写子系统 schema

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `transcriptions`：11 列，`sha512Hash` UNIQUE 幂等键，
  status/language/fullText/processorVersion/
  serverCompletedAt + 4 辅索引。
- `transcription_segments`：6 列 + FK CASCADE +
  transcriptionId/startTime 索引。
- `ncf` = 段模型 `{start,end,content:ucf,d:int}`。
- 独立 `TranscriptionDatabase`。

## Harmony 决策

表平移 relationalStore；转写服务 fail-closed；
sha512Hash 幂等键保留。

## Parity 状态

存储等价；转写服务不可用。

## 验证

- `d02-transcription-schema.mjs`：12/12 通过。
