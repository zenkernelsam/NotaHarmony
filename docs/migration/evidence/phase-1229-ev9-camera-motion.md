# Phase 1229 证据 — ev9 相机运动传感器（旋转矢量→视差矩阵）

来源：`defpackage/{ev9,dv9,m40,s5c}.java`。

## `ev9 implements SensorEventListener`

```java
float[] a,b,c = [16];   // 旋转/重映射/基线矩阵
float[] d = [3];        // azimuth/pitch/roll
Display e;              // 屏幕旋转
dv9[] f;                // 2 监听器（bpd 实现 dv9!）
```

## `onSensorChanged` = 旋转矢量→相对矩阵

```java
getRotationMatrixFromVector(a, values);          // TYPE_ROTATION_VECTOR
int rot = display.getRotation();
remapCoordinateSystem(b, axis129/130/2/1, a);    // 按屏幕旋转重映射
remapCoordinateSystem(a, 1, 131, b);              // X→Z' 相机系
getOrientation(b, d);
float f = d[2];                                   // roll
Matrix.rotateM(a, 0, 90f, 1,0,0);                 // X 轴 90°
if (!g) { m40.d(c, a); g=true; }                  // 首次=基线
multiplyMM(a, b, c);                              // a = 当前×基线 → 相对旋转
f[i].a(f, a);                                     // 通知 dv9
```

## 语义

- 用 **TYPE_ROTATION_VECTOR**（四元数→矩阵）；
- 按屏幕旋转重映射坐标系（rot 0/1/2/3→AXIS 映射）;
- 首帧存基线 `c`，后续 `a = current×baseline` = **相对旋转**
- `f[i].a(roll, 相对矩阵)` 通知 2 个 `dv9`（`bpd` SceneRenderer!）
- `bpd` 用它做 **笔记内容视差**（倾斜设备 → 内容偏移 ——
  Notability 标志性相机视差效果）。

## Harmony 决策

`SensorManager`/TYPE_ROTATION_VECTOR → Harmony
`sensor` 框架 `ROTATION_VECTOR` + `matrix` API；`dv9`
监听器 → XComponent 视差回调 —— 视差语义保真。

## 产出

- fixture `d02-ev9-camera-motion.mjs`（10 断言）。
- ADR-1173；中文报告。
