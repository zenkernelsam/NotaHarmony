# ADR-0925 — SQLite/Room 持久层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `z7c` = Room statement binder（h0/l/o/q/r）。
- `zp1` = ClientOp 实体：`op` 列 = `ree.b(uq9)` 整信封
  字节——**本地库与线型同一格式**；opId 列 =
  `gk4.v` 打包 `(ts<<32)|site`；noteId = `ttf.a()` 16B。
- 7 表 schema 实证（ClientOp/ClientNoteUpdate/
  NoteAsset/PermanentlyDeletedNote/SyncedFolderMetadata/
  SyncedNoteMetadata-18列/SyncedOpMetadata-17列含
  checksum 指纹列）。

## Harmony 决策

Harmony RDB 持久层语义等价：op 字节原样存 blob 列、
qo5→long 打包键、uuid 16B。

## Parity 状态

等价。

## 验证

- `d02-sqlite-persistence.mjs`：21/21 通过。
