# Phase 981 报告 — SQLite/Room 持久层

## 范围

z7c/wp1/iq1/zp1/gk4。纯审计。

## 原版发现

- `z7c` = Room binder 接口；`zp1` = ClientOp 实体——
  **op 字节经 ree.b 原样入 `op` blob 列**（本地库=
  线型同字节）。
- `gk4.v` = qo5→long 打包（ts<<32|site）。
- 7 表 INSERT schema 实证（SyncedNoteMetadata 18 列、
  SyncedOpMetadata 17 列含三 checksum 指纹列）。

## 产出

- 证据：`phase-981-sqlite-persistence.md`
- Fixture：`d02-sqlite-persistence.mjs`（21/21）
- ADR-0925；全量 Replay 见本提交。
