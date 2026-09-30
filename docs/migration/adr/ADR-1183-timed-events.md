# ADR-1183：hwa/fwa/gwa/ewa 计时手势事件

## 状态

已接受（Phase 1239）。

## 决策

`fwa(long)`=计时 start+`gwa`/`ewa`=fire/cancel 终态
→ Harmony `onLongPress`+计时器二分终态。

## 理由

`hwa`=计时事件分类；`fwa`=长按 start（时间戳）；
`gwa`/`ewa`=两种终态都包 `fwa`→`e71` 出栈 ——
press-hold 计时手势（fire-vs-release）。

## 后果

Harmony 长按手势 = onLongPress+计时 —— 计时事件
语义保真。
