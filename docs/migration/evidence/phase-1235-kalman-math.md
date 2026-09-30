# Phase 1235 证据 — Kalman 矩阵/滤波器内部（x18/sl6/gra）

来源：`defpackage/{x18,sl6,gra,ps2}.java`。

## `x18` = 稠密矩阵类

```java
final class x18 {
    int a,b; double[] c;      // rows, cols, data
    static void g(x18);        // reset
    void a(x18, x18);          // 矩阵乘 "dot matrix operation"
    void b(x18, x18);          // 矩阵加
    double c(i,j);             // get
}
```

## `sl6` = 13-矩阵 Kalman 滤波状态

```java
x18 a..m;   // 13 个矩阵 = state/covariance/transition/
            // measurement/Q/R/gain 全 Kalman 结构
```

## `gra` = 三轴 Kalman 引擎

```java
ps2 d,e,f,g;                  // 状态对象
double h,i; int j;
x18 k,l,m = new x18(1,1);     // scratch
sl6 a,b,c = a();              // x/y/pressure 三滤波器
```

`gra` 持有 3 个 `sl6` Kalman（x/y/pressure）+ `ps2`
状态 + scratch 矩阵 —— **匀速 Kalman 触控预测**。

## 语义

- `x18` = 通用稠密矩阵（`a`=乘/`b`=加/`c`=get/`g`=reset）；
- `sl6` = 单轴 Kalman（13 矩阵全结构：x, P, F, H,
  Q, R, K 等）;
- `gra` = 三轴引擎（`sl6 a,b,c` = x/y/pressure）;
- `gdd`→`gra`→`sl6`→`x18` —— 完整 Kalman 栈。

## Harmony 决策

Kalman 滤波 → Harmony 自研矩阵（`x18` 语义）+ 三轴
匀速 Kalman —— 笔迹预测数学保真。

## 产出

- fixture `d02-kalman-math.mjs`（10 断言）。
- ADR-1179；中文报告。
