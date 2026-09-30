# Phase 1147 证据 — ly3/s06/m4d 实体存贮值 + 4 表分类

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ly3 extends qg2` = 实体基接口

`qg2` = 带 id 实体；`ba6.y` 的 `r()→qja`/`i()→uia` 存贮
值类型。

## `s06 implements yy3,be5,ly3,bf0` = 实体快照

```java
s06 { uq9 b;      // create-op
      dm2 c;      // payload 部
      d16 d;      // payload 部
      z4 e;       // payload 部
      pp7 f;      // payload 部
      int g;      // 参
      k11 h, i;   // 双界!（local+world 或 bounds+crop）
      int j;
      u16 k;
      Integer l;  // 可变子索引?
      v09 m }     // 实体 kind（ANIMATION/INK/SHAPE/BLOCK）
static k11 n = new k11()  // EMPTY_BOUNDS
```

不可变全解实体快照 —— `l()→bja` 存贮值；`be5` 变换 +
`yy3` 子索引 + `bf0` 额外。

## `m4d extends ly3` = 实体变体接口

`p()→bja` 存贮值（另一实体族）。

## 4 存贮分类（ba6.y 链）

`r()→qja`(ly3) / `l()→bja`(s06 形状快照) / `p()→bja`
(m4d 变体) / `i()→uia`(ly3) —— 按实体 kind 分表的
索引。

## 语义

实体存贮按 kind 分 4 表；`s06` = 形状/实体的全解快照
（create-op + 5 payload 部 + 双界 + kind + 子索引），
`EMPTY_BOUNDS` 常量兜底。

## Harmony 决策

- 实体存贮 = kind 分表 Map；`s06` 快照 = `{createOp,
  payload×5, bounds×2, kind, subIdx}`。
- Harmony：同构分表 + Record 快照。

## 产出

- fixture `d02-entity-stores.mjs`（10 断言）。
- ADR-1091；中文报告。
