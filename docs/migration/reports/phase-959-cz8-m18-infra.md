# Phase 959 报告 — cz8/x82.x/m18 基础设施

## 范围

cz8.java + x82.x + m18.S/E/y0 + th7.java。纯审计。

## 原版发现

- `cz8` = ThreadLocal+复位池（sg5/dk4 池基底）。
- `x82.x` = 委托 acquire（raw get + reset）。
- `m18.S/E` = ListBuilder 建/封对；`y0`=round+NaN。
- `x82.y` = UTF-8 4B→UTF-16 代理对公式实证。

## 产出

- 证据：`phase-959-cz8-m18-infra.md`
- Fixture：`d02-cz8-m18-infra.mjs`（14/14）
- ADR-0903；全量 Replay 832 文件绿。
