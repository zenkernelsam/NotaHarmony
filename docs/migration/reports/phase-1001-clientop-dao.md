# Phase 1001 报告 — `kq1` ClientOp DAO

## 范围

kq1 DAO 解剖、nr1 查询面（d/e/f/g）、Room 运行时
组件映射。纯审计。

## 原版发现

- `kq1` = ClientOp DAO：`x5c a` = RoomDatabase；
  `q36 d` = EntityInsertionAdapter（`wp1` INSERT +
  `iq1` 行工厂）；`sh8`/`iq1 b` = 语句持有+删除适配。
- `c(ttf)` 按笔记读 ops；`a(ttf,kr1)` 按笔记写/删。
- `nr1.d/e` = lazy DAO/数据库；`f` = 只读 tx→Set；
  `g` = `l96.J0` Flow 式查询。

## Harmony 决策

等价平移 relationalStore。

## 产出

- 证据：`phase-1001-clientop-dao.md`
- Fixture：`d02-clientop-dao.mjs`（12/12）
- ADR-0945；全量 Replay 见本提交。
