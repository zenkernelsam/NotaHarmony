# Phase 983 报告 — Client-Ops WAL 文件格式

## 范围

ky/nr1/fr1/hr1。纯审计。

## 原版发现

- **WAL 写**（ky case1）：10 万 op/批分块，
  `<id>-<ns>-<seq>-<i>.wal`+`.tmp` 暂存+原子改名；
  帧 = 16B noteId + BE 计数 + 逐 op（BE len + ree.b
  LE 信封）——**BE 框架包 LE 负载**。
- **WAL 读**（fr1 case0）：三道 fail-closed 上限
  （<100001 / <10MiB / ≤500MiB）+ LE 根读。
- `nr1` = WAL store：AtomicLong 序号、30s 提交告警、
  ClientOp/DraftNote invalidation、消费后删除。
- `hr1` = 5 路 FilenameFilter。

## 产出

- 证据：`phase-983-wal-format.md`
- Fixture：`d02-wal-format.mjs`（23/23）
- ADR-0927；全量 Replay 见本提交。
