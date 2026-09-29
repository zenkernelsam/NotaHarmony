# ADR-1011：变换几何 = y18 矩阵 + k11 包围 + v09 类别

## 状态

已接受（Phase 1067）。

## 决策

- `y18` = 4×4 列主序浮点矩阵（identity/multiply/translate/
  rotate/scale）；`be5.P` 建矩阵，`y()` 用它变换 `k11` 包围。
- `v09` = 实体类别 {ANIMATION,INK,SHAPE,BLOCK}；
  `J` = 可变换子集（排除 ANIMATION）。

## 依据

`be5` 接口 `f()→v09`/`G()→k11`/`h()→fqa` 与 y18 的矩阵运算
共同构成变换管线。

## 后果

Harmony 用等价 4×4 矩阵；`v09` 类别 + 可变换集保留。
