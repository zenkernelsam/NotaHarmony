# ADR-1163：ype 布局几何持有

## 状态

已接受（Phase 1219）。

## 决策

`ype` 布局坐标持有（`wpe` 文本布局 + `mv6`×4 +
`d` 位置→偏移 + `q21` r21[16] 回调）→ Harmony
`componentUtils` 矩形 + 命中偏移 + `onAreaChange`。

## 理由

`ype{yme×2, p6a×4, q21}`；`c()→wpe`、
`d(long,bool)→wpe.b.j(zii.f)` 命中、`mv6.J` 裁剪、
`q21{r21[16]}` 监听器数组。

## 后果

Harmony 布局追踪 = 组件矩形+命中测试+面积回调 —
对齐 Compose TextFieldDelegate 几何层。
