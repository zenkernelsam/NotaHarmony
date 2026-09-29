# ADR-0952 — 查询构造器（e6c/mlc/m2a）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `mlc` = {SUBSTRING, WHOLE_WORD, EXACT, PREFIX,
  TOKEN_PREFIX}。
- `e6c.a` = LIKE 模式：折叠→空判→`\ % _` 转义→`%%`。
- `e6c.b` = FTS MATCH：`[^\p{L}\p{N}]+` 分词；
  SUBSTRING→null；WHOLE_WORD→`t1 t2`；EXACT→
  `"t1 t2"`；PREFIX/TOKEN_PREFIX→`t1* t2*`
  （`m2a` case23 = `+"*"`）。

## Harmony 决策

LIKE 路径逐字保留；FTS 模式串语义保留但需
应用层词边界判定（无 MATCH）——待实现项。

## Parity 状态

部分等价（LIKE 等价；FTS 模式需模拟）。

## 验证

- `d02-query-builder.mjs`：14/14 通过。
