# Phase 1181 证据 — 选择态模型（ktc sealed + 4 impl + cmb bounds）

来源：`defpackage/{ktc,ftc,htc,etc,itc,cmb,pda}.java`。

## `ktc` = **选择态密封 iface**

```java
interface ktc:
  b()→cmb      // dispatch 4 impl → bounds|null
  c()→Set; f()→Set; h()→Set   // 选中 id 集
  getId()→ttf  // 选择 id
  i()→bool
```

`ContentInputs.selectionState`（Phase 1180）的类型。

## 4 impl 子型

```java
itc implements ktc: {qo5 a, ttf b}    // op-锚定选择（文本选
                                    // 中落在 CRDT opId）
ftc implements htc: {cmb a, cmb b}   // 双 bounds 选择
etc implements ktc: {List a, cmb b}  // 项集选择（多元素）
htc extends ktc                       // 子 iface（文本选？）
```

## `cmb` = 选择 bounds `{float a,b,c,d}` + `e=(0,0,0,0)`

`pda` = 空 marker iface（`pdfTextSelectionState`）。

## 判定

**选择模型**：`ktc` 密封态 4 子型 ——
- `itc` = op-锚定文本选择（`qo5` CRDT opId + `ttf` id）
- `ftc` = 双 bounds（起止锚框）
- `etc` = 项集选择（列表+bounds）
- `pda` = PDF 文本选择 marker

每子型 `b()→cmb` 给 bounds，`ttf` 全局选择 id。

## Harmony 决策

- `cmb` bounds → Harmony `Rect`。
- `ktc` 密封选择态 → Harmony sealed/`type` union 选择
  状态（op-锚定/双 bounds/项集/PDF 文本）。
- `ttf` 选择 id → Harmony 选择 id。

## 产出

- fixture `d02-selection.mjs`（10 断言）。
- ADR-1125；中文报告。
