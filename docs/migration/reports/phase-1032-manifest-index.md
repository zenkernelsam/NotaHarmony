# Phase 1032 报告 — cu9 manifest 索引写器

## 范围

`cu9`/`yz`/`a00`/`zz`/`jqe` + handler 类型。纯审计。

## 原版发现

- `cu9` 迭代 `a00` 三分区（dir/asset/kv 段），
  每条目 `boh.a` → `jqe.a` = packed long
  `{offset<<32|length}`。
- `yzVar` = manifest 写器：e(dir)/b(tg7)/a(sg7)/
  c(name) 四类条目。
- `zz` = 条目 `{handler,b,c,name}`；`ug7`/`tg7`/
  `sg7`/`gnd` handler 类型。

## Harmony 决策

manifest 索引结构保留；zip 段对齐。

## 产出

- 证据：`phase-1032-manifest-index.md`
- Fixture：`d02-manifest-index.mjs`（10/10）
- ADR-0976；全量 Replay 见本提交。
