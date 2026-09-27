# Phase 933 报告 — lv2 物化器全量登记

## 范围

`lv2` 线型物化器方法完整登记。纯审计。

## 原版发现

- 29 物化器覆盖全部表的向量字段（ink 路径字节、
  qo5 引用、 cxc 位置、 ie8 子表、 uq9 ops、
  fqa 点、 ukb 段）；统一 S→逐元素→E→hw3.I。
- `th7` 返回=可变热路径表；`List`=冻结表。
- 非线型成员：±INF 浮点哨兵元组、Compose
  大函数、杂项 helper 登记备查。

## 产出

- 证据：`phase-933-lv2-materializers.md`
- Fixture：`d02-lv2-materializer-registry.mjs`（32/32）
- ADR-0877；全量 Replay 806 文件绿。
