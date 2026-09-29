# Phase 991 报告 — `pae` SyncedOpMetadata 实体

## 范围

pae/ye9。纯审计。

## 原版发现

- `pae` 17 字段 ↔ SyncedOpMetadata 17 列顺序对应：
  id/legacyId/editorSiteId/editorId/createdAt/creatorId/
  updatedAt/maxServerTime(xgb)/title/titleOpId(qo5)/
  opCount/opFileSize/maxTimestamp/schemaVersion/
  fingerprintFileLengths(Set\<hg4\>)/opsChecksum/
  offsetsChecksum。
- `pae.g` = copy() 位掩码（defer/物化分支局部更新）。
- `ye9` = createdAt 审计接口。

## 产出

- 证据：`phase-991-synced-op-metadata-entity.md`
- Fixture：`d02-synced-op-metadata-entity.mjs`（9/9）
- ADR-0935；全量 Replay 见本提交。
