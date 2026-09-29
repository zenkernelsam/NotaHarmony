# ADR-0945 — `kq1` ClientOp DAO + nr1 查询面

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `kq1` = ClientOp DAO：`{x5c db, q36 d
  (wp1 insert+iq1 row-factory), sh8, iq1 b}`；
  `c(ttf)` 按笔记查询、`a(ttf,kr1)` 按笔记操作。
- `nr1`：`d()`=lazy kq1、`e()`=lazy
  NoteBundleMetadataDatabase、`f`=只读事务→Set、
  `g`=`l96.J0` createFlow 挂起查询。
- Room 运行时：`q36` EntityInsertionAdapter、
  `l96` tx/flow helper、`ys2.r` 失效→Flow。

## Harmony 决策

平移 relationalStore：ClientOp 表 + noteId 查询 +
事务批量插入 + dataChange 订阅。

## Parity 状态

等价（Room→relationalStore 映射已建立）。

## 验证

- `d02-clientop-dao.mjs`：12/12 通过。
