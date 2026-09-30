# ADR-1161：文本值层（ele/dle/jqe/k1a）

## 状态

已接受（Phase 1217）。

## 决策

`ele` TextFieldCharSequence + `dle` TextEditBuffer +
`jqe` packed TextRange + `k1a` 区域载荷 → ArkTS
`TextEditState` + builder + `{hi<<32|lo}` 区间；
`rh8.A` 构造钳位保留。

## 理由

`ele` 委托 CharSequence + 构造钳位选区/组合/区域；
`jqe` packed long（`d`=坍缩）；`dle` Appendable
编辑构建 + `a46.i` sink 对齐。

## 后果

Harmony 文本值 = 不可变态+可变 builder+packed 区间
—— 语义对齐，钳位保真。
