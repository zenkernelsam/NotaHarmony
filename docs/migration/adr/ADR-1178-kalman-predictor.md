# ADR-1178：bi8 多指针 Kalman 预测器

## 状态

已接受（Phase 1234）。

## 决策

`bi8` SparseArray 每指针 `gdd`+`gra` 三轴 Kalman（x/y/
pressure）+`tl6`/`uta` → Harmony 自研 Kalman 预测器
+ onTouch 事件。

## 理由

`bi8`=MultiPointerPredictor（DOWN→gdd，UP→remove，
`b(tool)`→预测 ev）；`gdd`=x/y/pressure 三轴 Kalman
（`sl6`+`x18.g`）—— 预测延迟遮蔽低延迟笔迹。

## 后果

Harmony 笔迹预测 = 自研 Kalman+onTouch —— 预测
低延迟语义保真。
