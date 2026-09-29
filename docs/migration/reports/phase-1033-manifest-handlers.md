# Phase 1033 报告 — manifest 条目 handler 分类

## 范围

`yz`/`a00`/`zz`/`wz`/`ug7`/`gnd`/`tg7`/`sg7` 类型图。
纯审计。

## 原版发现

- `yz implements Appendable`{StringBuilder,List} =
  manifest 写器；`a00 implements CharSequence`{List}。
- `wz` → `gnd`{xoe,long} 目录 / `ug7` abstract
  {cye,cqe} → `tg7`/`sg7`{String,cqe} 资产。
- `yz.e/b/a/c` = dir/tg7/sg7/命名四类条目写入。

## Harmony 决策

handler 分类保留；Appendable→StringBuilder 等价。

## 产出

- 证据：`phase-1033-manifest-handlers.md`
- Fixture：`d02-manifest-handlers.mjs`（10/10）
- ADR-0977；全量 Replay 见本提交。
