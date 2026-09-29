# ADR-0928 — Deferred-Ops 文件校验读

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `u63` = 文件引用 `{rowId,noteId,schemaVersion?short,
  format:x63,fileSize,crc32}` ↔ SyncedOpMetadata 列。
- `nce.A`：READ_ONLY mmap + 三重校验（empty→IOException、
  size≠→IOException、CRC32≠→log+null fail-soft、
  missing→IOException）。
- `x63` = 3 序数格式枚举；`jwh.a` 多态根读：
  0→r29 NoteBundle、1→vt9 OpsBundle、2→zgb
  ReceiveOpsEvent，均 LE uoffset 标准根读。
- `fsi.r` = 分块 CRC32 复算。

## Harmony 决策

等价：size+CRC32 双校验；checksum 失败保持原版的
fail-soft（log+null），size/empty/missing fail-hard。

## Parity 状态

等价。

## 验证

- `d02-deferred-ops-file.mjs`：20/20 通过。
