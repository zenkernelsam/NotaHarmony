# Phase 989 报告 — `.ops`/`.offsets` 完整性校验链

## 范围

nce 校验块/z5c.i/uw7/o76。纯审计。

## 原版发现

- **五重校验**：ops size、offsets 长度=count×4、
  ops CRC32==pae.p、offsets 原文 CRC32、逐偏移
  （负值/越界/首项=0/严格单调）。
- `z5c.i` = 文件级 64K 分块 CRC32。
- `uw7` = 账簿物化器（末偏移守卫+mmap 逐 offset 读）。
- 违例 → o76/n76 → CorruptedSyncedOpException →
  ebe.J 重下载（与 Phase 985 形成闭环）。

## 产出

- 证据：`phase-989-ops-ledger-verify.md`
- Fixture：`d02-ops-ledger-verify.mjs`（18/18）
- ADR-0933；全量 Replay 见本提交。
