# Phase 988 报告 — 落盘 op 账簿三层结构

## 范围

dbe/pr1/lv2.s0·q·o0·p·t/kl1/hg4。纯审计。

## 原版发现

- `dbe` = 同步文件路径族（.ops/.offsets/.deferred/
  fingerprints/）；`pr1` = 三目录提供者（含
  client_ops_wal——Phase 983 WAL 目录同源）。
- `lv2.s0` = **指纹账簿重建**：`.offsets` int32 索引→
  `.ops` mmap 逐 op 提 site+serverTime → 按站点分组写
  `<site>.fingerprints`（LE 12B {ts,serverTime} 记录）
  → hg4{site,len,crc} 入库。
- `kl1` = CRC32 计数输出流；`hg4` = 指纹行实体。
- `lv2.t` = q89 OpAck 物化器。

## 产出

- 证据：`phase-988-ops-ledger-files.md`
- Fixture：`d02-ops-ledger-files.mjs`（25/25）
- ADR-0932；全量 Replay 见本提交。
