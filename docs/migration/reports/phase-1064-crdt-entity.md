# Phase 1064 报告 — m5d CRDT 实体 + materialize

## 完成内容

- `m5d implements be5,k5d,fi0` = **14-寄存器活实体**；
  `n5d` spec 持 `yc6` 默认快照，`do6.g` 初始化。
- `fi0` 访问器映射钉死：o→c / n→d / w→e / J→f。
- `be5` 读器 materialize：读 `reg.b` 值（如 `G()` 包围盒
  读边界+参数寄存器）。
- `ei0` = `v1b` 绑定属性引用，`get()` switch 寻址寄存器。
- `A()` = `r++` 版本戳；`fl6[] w` = KProperty 委托数组。

## 意义

实体 = spec + 寄存器数组的工厂化模式；所有属性经 CRDT
寄存器（无裸字段），合并语义统一走 LWW。

## 产出

- evidence `phase-1064-crdt-entity.md`
- fixture `d02-crdt-entity.mjs`（10/10）
- ADR-1008
