# ADR-1085：ba6.y per-op 实体解析器

## 状态

已接受（Phase 1141）。

## 决策

- `ba6.y`：墓碑 op→`h85` member-collection 子解→
  `wnd{null,set,list}`（未解）；活 op→4 存贮链
  （r→l→p→i）查 `ly3`；`be5`→界（自变换 `y(G())` 或
  `yy3.E()` 子索引 + `ny3` 缓存）→`do6.i` crop→`vnd`。
- `wnd{vnd,LinkedHashSet,ArrayList}` 3 字段。

## 依据

`K(op,j())` 墓碑分支 + 4 表链 + `be5`/`yy3.E`/`ny3.e/a`。

## 后果

Harmony：同构 resolver（tombstone→children、4-store 链、
bounds 缓存、unresolved set）；`e0a.a←list+vnd、
b←set`。
