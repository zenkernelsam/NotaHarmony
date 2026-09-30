# Phase 1151 报告 — cz8 表访问器

## 完成内容

- `sg5` = 12 `cz8` holder 注册表（`fl6` 描述符映
  `core.flatbuffers.*` 真名）。
- `cz8 extends ThreadLocal`：工厂懒建 + `get` 绑槽——
  零分配热读；`bh4` 槽 lambda；`pg5/og5` 生成类工厂。

## 产出

- evidence `phase-1151-cz8-holders.md`
- fixture `d02-cz8-holders.mjs`（10/10）
- ADR-1095
