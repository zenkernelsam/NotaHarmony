# Phase 1195 证据 — 手势→渲染桥（aaf GestureDetector + jqa + ev9）

来源：`defpackage/{aaf,jqa,ev9}.java`。

## `aaf` = GestureDetector→renderer 桥

```java
aaf extends GestureDetector.SimpleOnGestureListener
      implements View.OnTouchListener, dv9:
  bpd K                    // SceneRenderer
  GestureDetector M
  PointF I,J,K,L,N         // 触控点
  onDown / onScroll / onSingleTapUp   // 手势回调
```

手势（点按/滚动/单触）→ `bpd` SceneRenderer 平移/选择。

## `jqa` = 3 值输入-模式 enum（`vle.A(iqa,jqa,long)` 参）

`{I,J,K}` 3 常量 —— 触控模式/工具态（手写笔/手指/橡皮
类输入模态）。

## `ev9 implements SensorEventListener` = 运动传感

```java
ev9: float[16] a,b   // 旋转矩阵
  SensorManager→onSensorChanged→rotation matrix→nc1 相机
```

## 判定

**输入→渲染桥**：触控 `aaf` GestureDetector（onDown/
Scroll/SingleTap→`bpd`）+ `jqa` 输入模态 enum + `ev9`
传感旋转矩阵（`nc1` 相机）—— 手势平移/选择 +
传感视差。

## Harmony 决策

- `GestureDetector` → Harmony `Gesture`/`PanGesture`/
  `TapGesture`/`PinchGesture`。
- `jqa` 输入模态 → Harmony 输入模式 enum。
- `ev9` 传感 → `@ohos.sensor` 旋转矩阵。

## 产出

- fixture `d02-gesture.mjs`（10 断言）。
- ADR-1139；中文报告。
