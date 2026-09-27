# Phase 897 报告 — 叶子校验体 + vy7 序 + ymf 实名

## 范围

实名 ka4 叶子校验体与 vy7 字段序、ymf 值类。纯审计。

## 原版发现

- `k3a.a()`：纸色 alpha=0xFF 规则。
- `vy7.a()`：非负+逐边有限；**TBLR 序** top@0/bottom@4/
  left@8/right@12。
- `qed`/`fqa` 校验 = ddg.i/h 委托。
- `ymf` = UShort 值类（schemaVersion 类型）。

## Harmony 核对

alpha 门、TBLR 序、无符号读取对齐。

## 产出

- 证据：`phase-897-leaf-validators.md`
- Fixture：`d02-leaf-validators.mjs`（13/13）
- ADR-0841；全量 Replay 770 文件绿。
