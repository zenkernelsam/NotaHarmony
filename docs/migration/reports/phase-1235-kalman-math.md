# Phase 1235 报告 — Kalman 数学

## 完成内容

- `x18`=稠密矩阵类（`a`=乘/`b`=加/`c`=get/`g`=reset）；
- `sl6`=13 矩阵全 Kalman 状态；`gra`=三轴引擎
  （`sl6 a,b,c`=x/y/pressure+`ps2`）—— 匀速 Kalman
  触控预测栈 `gdd→gra→sl6→x18`。

## 产出

- evidence `phase-1235-kalman-math.md`
- fixture `d02-kalman-math.mjs`（10/10）
- ADR-1179
