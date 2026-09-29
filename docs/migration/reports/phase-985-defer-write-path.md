# Phase 985 报告 — Defer 写路径

## 范围

nce.g/u、crb-17/18、w63.a、ebe、fsi.z。纯审计。

## 原版发现

- **前向兼容核心**：blob schema > 本端 rgc.a → 不物化，
  走 defer（文件+元数据行，size+CRC32 入库）；
  ≤ 本端 → 物化 ops + Room 事务。
- `nce.u` = 原子 defer 提交（pv2.c 事务内文件写+行插）。
- `crb` case17 = CREATE_NEW 排他 blob 写；case18 =
  qud 下载原子改名。
- `w63.a` = x63 枚举名转换器（NOTE_BUNDLE/OPS_BUNDLE/
  RECEIVE_OPS_EVENT）。
- `ebe` = SUCCESS/CORRUPT_NEEDS_REDOWNLOAD 结果枚举。

## 产出

- 证据：`phase-985-defer-write-path.md`
- Fixture：`d02-defer-write-path.mjs`（19/19）
- ADR-0929；全量 Replay 见本提交。
