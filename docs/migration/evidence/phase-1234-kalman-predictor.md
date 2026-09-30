# Phase 1234 证据 — bi8 多指针 Kalman 预测器

来源：`defpackage/{bi8,tl6,mf8,gdd,gra,sl6,x18,uta}.java`。

## `bi8` = MultiPointerPredictor

```java
static boolean c = Log.isLoggable("MultiPointerPredictor", 3);
SparseArray a;               // pointerId → gdd
void a(MotionEvent ev) {
    pointerId = ev.getPointerId(actionIndex);
    // DOWN/POINTER_DOWN → new gdd(b, pointerId, getToolType)
    // UP → remove
}
MotionEvent b(int i);         // 预测 MotionEvent
```

## `gdd` = 单指针 Kalman 预测器

```java
// gra = 3 个 sl6 Kalman 滤波器（x/y/pressure-size）
sl6 a,b,c;                    // x, y, pressure
Arrays.fill(sl6.a.c, 0);      // 状态清零
x18.g(sl6.b);                 // 滤波器重置
motionEvent.findPointerIndex / toolType → 采样
```

`sl6` = **Kalman 滤波器**（`a.c`=状态向量、`x18.g`=预测/
更新）—— 低延迟笔迹：预测下一 MotionEvent 位置提前
绘制（预测笔触渲染）。

## `mf8{a(ev),b()→ev}` = 预测器接口；`tl6` = 消费器

`tl6{bi8 a, uta b}` —— `a()` 喂事件、`b()` 取预测；
`uta` = 事件时刻跟踪（`a=eventTime`）。

## 语义

- 每 pointerId 一个 `gdd`（工具类型感知）；
- `gra`=x/y/pressure 三轴 Kalman；
- `bi8.b(tool)` → 合成预测 MotionEvent；
- **预测延迟遮蔽** —— 笔迹低延迟关键。

## Harmony 决策

MotionEvent+Kalman → Harmony `onTouch` 事件 + 自研
Kalman 预测器（x/y/pressure 三轴）；`toolType` →
`TouchObject.type`（触控笔/手指）。

## 产出

- fixture `d02-kalman-predictor.mjs`（10 断言）。
- ADR-1178；中文报告。
