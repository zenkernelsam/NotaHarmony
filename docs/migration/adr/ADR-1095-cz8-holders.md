# ADR-1095：cz8 线程局部表访问器

## 状态

已接受（Phase 1151）。

## 决策

- `sg5` = 12 `cz8` holder 注册表（`cz8(factory,bh4(idx))`
  ↔ `core.flatbuffers.*` 经 `fl6` 描述符）。
- `cz8 extends ThreadLocal`：`initialValue` 懒建生成表、
  `get` 取+`bh4(idx)` 绑槽 —— 零分配热读。
- `bh4` = 槽绑定合成 lambda；`pg5`/`og5` = 生成类工厂。

## 依据

`cz8 extends ThreadLocal` + `a.invoke()`/`b.invoke(obj)` +
`sg5.c..n` cz8 注册。

## 后果

Harmony：单线程下免分配表池 / AsyncLocal；混淆类↔
schema 名映射经 `sg5`。
