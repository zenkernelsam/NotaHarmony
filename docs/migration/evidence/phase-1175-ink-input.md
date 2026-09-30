# Phase 1175 证据 — 墨迹输入层（手势分类 + 预测 + 触摸）

来源：`defpackage`（obf）墨迹输入类。

## `bi8` = `MultiPointerPredictor`（实名 Log tag）

```java
Log.isLoggable("MultiPointerPredictor",3)
SparseArray a     // per-pointer
a(MotionEvent)    // 喂事件
b(int)→MotionEvent // 预测某指针下一事件
```

**多点指针预测器** —— 按 pointer-id 预测下一触控位置，
降墨迹渲染延迟（predict-then-draw）。

## `mf8` = 预测器 iface `{a(ev), b()→ev}`；`tl6 implements mf8`

## `iqa` = 触控/手写笔分类归一器

```java
iqa(List, hc0):
  a()→MotionEvent
  getClassification()          // Android 触控分类
  getButtonState/getMetaState
  getActionMasked() → i 枚举
    3 = TWO_FINGER_SWIPE → 10
    5 = PINCH            → 8
    …→1
```

`getClassification` 3/5（双指扫/捏合）+ button/meta →
内部动作枚举 —— 把手写笔/手势事件归一为编辑动作。

## `cj7 implements View.OnTouchListener`

`aq3` 处理 + `ViewConfiguration.getTapTimeout()` + 坐标
数学 `a/b/c` —— 触摸监听（长按/点击判定）。

## Harmony 决策

- `MotionEvent` → Harmony `TouchEvent`/`Input`（手写笔
  `toolType`）。
- `getClassification`（手掌/双指/捏合）→ Harmony 手势
  识别器映射。
- `mf8`/`bi8` 预测 → Harmony **predictor**（Harmony 有
  `touchPredictor`？）或自研外推 —— 降墨迹延迟必需。

## 产出

- fixture `d02-ink-input.mjs`（10 断言）。
- ADR-1119；中文报告。
