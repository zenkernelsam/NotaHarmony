# Phase 984 报告 — Deferred-Ops 文件校验读

## 范围

nce.A/u63/x63/jwh.a/fsi.r。纯审计。

## 原版发现

- `u63` = deferred-ops 文件引用实体（rowId/noteId/
  格式/期望 size/期望 CRC32）↔ SyncedOpMetadata 列。
- `nce.A` = 校验 mmap：empty/size-mismatch/missing→
  IOException；CRC32 mismatch→log+null（fail-soft）。
- `x63` = 3 格式枚举，同一文件槽可载三种 root：
  NoteBundle(0)/OpsBundle(1)/ReceiveOpsEvent(2)。
- `fsi.r` = 分块 CRC32。

## 产出

- 证据：`phase-984-deferred-ops-file.md`
- Fixture：`d02-deferred-ops-file.mjs`（20/20）
- ADR-0928；全量 Replay 见本提交。
