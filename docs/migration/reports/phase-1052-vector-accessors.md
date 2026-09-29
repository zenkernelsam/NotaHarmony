# Phase 1052 报告 — lv2 向量访问器与持久化集合

## 范围

`lv2` 向量访问范型、`m18`/`th7`/`hw3`/`u4` 持久化集合。
纯审计。

## 原版发现

- 规范范型：`c(slot)`→`i()` 长度→`m18.S()` builder→
  逐元素 `B/l` 读→`m18.E()` 冻结；空→`hw3.I`。
- 访问器全清单：M/N/O/P/Q/I/J/W/X/Y/u/e0/S/w/B/E/x/C/F/
  y/z/f0/g0/b0/c0/d0/T/U/V。
- `th7 extends u4` builder（`{I array,J size,K frozen}`，
  `L`=EMPTY）；`hw3.I` 空表单例；`m18.S/E` 构建/冻结。
- `lv2` 常量：±INF 边界对象、`zp9(7)`、`8f/24f`。

## Harmony 决策

向量读取统一范型；持久化集合两阶段构建。

## 产出

- 证据：`phase-1052-vector-accessors.md`
- Fixture：`d02-vector-accessors.mjs`（12/12）
- ADR-0996；全量 Replay 见本提交。
