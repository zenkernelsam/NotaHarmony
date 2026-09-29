# ADR-0927 — Client-Ops WAL 文件格式

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- 写（`ky` case1/`nr1`）：ops 按 10 万分块 →
  `<noteId>-<nano>-<seq>-<i>.wal` + `.tmp` 暂存 +
  `fag.m0` 原子改名；帧 = 16B noteId + BE 计数 +
  逐 op（BE 长度 + `ree.b` LE 信封）。
- 读（`fr1` case0）：16B noteId→`m18.X`；三道
  fail-closed 上限（计数<100001、单 op<10MiB、
  总≤500MiB）；LE uoffset 根读入 `uq9`。
- 混合端序：BE 框架包裹 LE FlatBuffer。
- `hr1` FilenameFilter：`.tmp`/`.wal`/`aqs.`/`.ae`/`event`。
- `nr1`：AtomicLong 序号、30s 提交超时告警、Room
  invalidation 监听 ClientOp/DraftNote、消费后删文件。

## Harmony 决策

等价实现：长度前缀+暂存改名+三档上限+消费即删；
WAL 与 ClientOp 表双轨（队列文件+索引表）。

## Parity 状态

等价。

## 验证

- `d02-wal-format.mjs`：23/23 通过。
