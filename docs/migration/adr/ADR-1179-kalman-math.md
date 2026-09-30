# ADR-1179：Kalman 矩阵/滤波器内部

## 状态

已接受（Phase 1235）。

## 决策

`x18` 稠密矩阵+`sl6` 13-矩阵 Kalman+`gra` 三轴引擎
→ Harmony 自研矩阵+三轴匀速 Kalman。

## 理由

`x18`=矩阵类（`a`=乘/`b`=加/`c`=get）；`sl6`=13 矩阵
全 Kalman 结构；`gra`=`sl6 a,b,c`=x/y/pressure 三轴
+`ps2` —— 匀速 Kalman 触控预测。

## 后果

Harmony 笔迹预测 = 自研矩阵+Kalman —— 预测数学
保真。
