# Phase 1001 证据 — `kq1` ClientOp DAO + nr1 查询面

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `kq1` = ClientOp DAO

```java
final class kq1 {
    x5c a;              // RoomDatabase
    q36 d;              // EntityInsertionAdapter:
                        //   new q36(wp1 binder, iq1 row-factory)
    sh8 c = new sh8(22);  // 预编译语句持有者
    iq1 b;              // 删除/查询适配器
}
```

- `q36` = Room `EntityInsertionAdapter<T>`（
  `wp1` = INSERT SQL、`iq1` = 行→实体转换，Phase 981）。
- `kq1.c(ttf)` = 按 note 查询 ClientOp（`cq1` 状态机）。
- `kq1.a(ttf, kr1)` = 另一按 note 操作（删除/标记）。
- `kr1` = ClientOp 查询结果/参数类型。

## `nr1` 查询/访问面

- `d()` = lazy `kq1`（ClientOp DAO）。
- `e()` = lazy `NoteBundleMetadataDatabase`（主库）。
- `f(ff2)` = `l96.L0(db, true, false, fq1(1))` 只读事务
  → `au1.X1`（结果集→Set）。
- `g(ttf, ff2)` = `l96.J0` = Room `createFlow`/挂起查询
  （`jq1(kq1, ttf)` 查询体）。

## `x5c` = RoomDatabase 基（`a` 字段即 db）

`wp1`/`iq1`/`sh8`/`q36`/`l96` = Room 运行时全家桶：
- `wp1` = SupportSQLiteStatement 绑定器（INSERT）。
- `iq1` = 行工厂/删除适配。
- `q36` = EntityInsertionAdapter。
- `l96.L0/J0` = withTransaction / createFlow helper。
- `ys2.r` = InvalidationTracker→Flow 工厂。

## HarmonyOS 决策

- `kq1` DAO 语义平移 `relationalStore`：表 `ClientOp`
  + 按 noteId 查询 + 事务批量插入。
- `l96.L0` 等价 `relationalStore` 的 `beginTransaction`/
  `commit`/`rollBack`；`createFlow` 等价
  `on('dataChange')` 订阅。

## 产出

- fixture `d02-clientop-dao.mjs`（12 断言）。
- ADR-0945；中文报告。
