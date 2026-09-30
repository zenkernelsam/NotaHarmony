# ADR-1091：实体存贮分类

## 状态

已接受（Phase 1147）。

## 决策

- 实体存贮按 kind 分 4 表：`r→qja`(ly3)、`l→bja`(s06)、
  `p→bja`(m4d)、`i→uia`(ly3)。
- `s06` = 全解实体快照 `{createOp, payload×5(dm2,d16,z4,
  pp7), 双界 k11×2, v09 kind, 子索引}` + EMPTY_BOUNDS。

## 依据

`s06 implements yy3,be5,ly3,bf0` 全字段 + `ly3`/`m4d`
接口链。

## 后果

Harmony：kind 分表 Map；`s06` Record 快照含双界+
kind+create-op。
