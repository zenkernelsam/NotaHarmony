# ADR-0976 — cu9 manifest 索引写器

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `cu9` 迭代 `a00` 三分区（`b()`/`a(0,len)`/`c(len)`）
  逐条目 `boh.a` → `jqe.a` = **packed long
  `{offset<<32|length}`**。
- `yzVar.e/b/a/c(handler,name,off,len)` = 四类
  manifest 条目（dir/asset tg7/sg7/命名键值）。
- `zz` = 条目 `{a=handler,b,c,d=name}`；
  `ug7`/`tg7`/`sg7`/`gnd` = handler 类型。

## Harmony 决策

manifest 索引结构保留；zip 段布局对齐。

## Parity 状态

等价。

## 验证

- `d02-manifest-index.mjs`：10/10 通过。
