# Phase 1123 证据 — 物化快照/视图集合谱系

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `f1a` = 页/块快照聚合 `{int, rvb, cl2, kia, …}`

## `rvb implements svb` = 文本块快照

```java
rvb { bxc I;      // 文本序列 spec
      cl2 J, L;   // 惰性 map×2（tombstone/属性）
      xgb K }     // 时戳
```

`v69.b` 里 `new rvb(iwc.c(), al2.a(), xgb)` 构造。

## map 叉系（`ija`/`jja`）

- `kja extends ija` = 惰性 map（`b(obj)` 值变换）。
- `nja extends ija` = 惰性 map（`e(obj)` + `f(hja)→jja` fork）。
- `mja extends jja` = 只读（`a(gja)→ija` builder 派生）。
- `oja extends jja` = 只读快照。

## list/seq 系

- `ria implements List,ik6` = `{bka I, ArrayList J}` ——
  builder list + pending 槽。
- `q07` = List 只读包装（`add` 抛）。
- `lia extends w4 Collection` = 视图 `e()→kia`。
- `bka extends u4 Collection` = builder 集合 `f()→z4`。

## Harmony 决策

- 快照 = spec + tombstone map + 时戳（rvb）。
- map/list 视图 = 惰性变换 + 只读 + builder 派生三模式。

## 产出

- fixture `d02-snapshot-views.mjs`（10 断言）。
- ADR-1067；中文报告。
