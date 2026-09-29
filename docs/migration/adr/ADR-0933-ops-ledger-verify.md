# ADR-0933 — `.ops`/`.offsets` 完整性校验链

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 装载校验五重：`.ops` size==opFileSize、`.offsets`
  len==count×4、`z5c.i(.ops)` CRC32==opsChecksum、
  `.offsets` 原文 CRC32、逐偏移负值/越界/首项=0/
  严格单调。
- `z5c.i` = 64K 分块文件 CRC32（不存在/空→0）。
- `uw7` = `.ops`+`.offsets` 物化读：末偏移≥ops.len
  校验、mmap READ_ONLY、逐 offset LE 根读 uq9。
- 违例 → `o76`/`n76` → CorruptedSyncedOpException →
  ebe.J CORRUPT_NEEDS_REDOWNLOAD（Phase 985 闭环）。

## Harmony 决策

等价：五重校验 fail-closed→redownload；不尝试本地修复。

## Parity 状态

等价。

## 验证

- `d02-ops-ledger-verify.mjs`：18/18 通过。
