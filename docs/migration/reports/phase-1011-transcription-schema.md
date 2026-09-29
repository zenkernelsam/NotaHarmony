# Phase 1011 报告 — 转写子系统 schema

## 范围

transcriptions/transcription_segments 表、ncf 段
模型、独立数据库。纯审计。

## 原版发现

- `transcriptions`：`sha512Hash` UNIQUE 音频指纹
  幂等 + status/language/fullText/processorVersion/
  serverCompletedAt + 5 索引。
- `transcription_segments`：FK CASCADE +
  startTime/endTime/confidence。
- `ncf{start,end,ucf,int}`；独立
  TranscriptionDatabase。
- 服务端转写（serverCompletedAt）。

## Harmony 决策

表等价平移；转写 fail-closed。

## 产出

- 证据：`phase-1011-transcription-schema.md`
- Fixture：`d02-transcription-schema.mjs`（12/12）
- ADR-0955；全量 Replay 见本提交。
