# ADR-1031：因果集合 = 只读物化视图

## 状态

已接受（Phase 1087）。

## 决策

Harmony 因果 map = `ija` 模式：底层 `gja` 因果存储 +
`e()` 物化 + `J` LinkedHashMap 缓存；`put`/`merge` 抛
"read-only" —— 应用层禁直写，变更必须经 op→register。

## 依据

`ija.get` 缓存-then-物化 + 4 写操作抛异常 + `f(hja)` 子视图。

## 后果

Harmony 集合对 UI 只读；写路径单一走 CRDT op（保因果序）。
