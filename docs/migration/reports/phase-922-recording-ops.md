# Phase 922 报告 — `yn2`/`ke8` 录音 op 实名

## 范围

录音创建/修改 op 载荷实名。纯审计。

## 原版发现

- yn2=CreateRecording 6 字段：akb 资产 + ULong
  startTime/endTime + name + ukb[] 16B 分段向量 +
  tmf zIndex。
- ke8=ModifyRecording 4 字段（qo5 目标 + setter）。
- zq9 全部 op 载荷读侧闭合（26+ 类）。

## Harmony 核对

编码对齐。

## 产出

- 证据：`phase-922-recording-ops.md`
- Fixture：`d02-recording-ops.mjs`（14/14）
- ADR-0866；全量 Replay 795 文件绿。
