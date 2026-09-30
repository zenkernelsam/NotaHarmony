# Phase 1309 报告 — CRDT 线格式保真

## 完成内容

- Harmony `data/` 保真原版 FlatBuffer 线格式 + 排序：
  `OriginalSyncedOperationFlatBuffer`/`EnvelopeEncoder`
  （读写原版 op 信封，`ORIGINAL_*`=解码 haa op）；
  `OperationIdentity`（timestamp+siteId 64-bit pack+
  `compareOriginalSequenceIdentity`=原版 `exc.A0` 比较器
  signed-int-timestamp/unsigned-site 逐位复刻）；`Incoming
  OperationSyncCoordinator`（AsyncMutex+receiveOpsEvent/
  replayOpsBundle/replayDeferredBundle+site-ID CRDT 同步）
  —— 与原版同步互操作（修正 1308：线格式保真，仅
  本地 op 分类法有超集差异）。

## 产出

- evidence `phase-1309-crdt-wire-fidelity.md`
- fixture `d02-crdt-wire-fidelity.mjs`（10/10）
- ADR-1253
