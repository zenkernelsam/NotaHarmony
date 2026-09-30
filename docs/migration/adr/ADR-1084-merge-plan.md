# ADR-1084：e0a 合并计划

## 状态

已接受（Phase 1140）。

## 决策

- `e0a{ArrayList a, LinkedHashSet b}` = 合并计划：
  `a`=已解空间实体（`wnd.c`+`vnd`），`b`=未解 opId。
- `v69.g`：键并集逐 op→`ba6.y`→`wnd{vnd a, c list}`
  →已解入 `a`、未解入 `b`。
- `ba6.y` = per-op 实体解析器。

## 依据

`e0a(ArrayList,LinkedHashSet)` + `g` 的 resolved/unresolved
分支 + `wnd{vnd,c}`。

## 后果

Harmony：`{Array,Set}` 计划 + resolver；未解 op 留待
下轮调和（fail-safe）。
