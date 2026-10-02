# Phase 1458 证据 — 原版 RTL 左锚旋转柄（yj8 布局方向）

证据来源：`decompiled_1.4.2/sources/defpackage/`。

## `yj8` 枚举

`yj8.java`：`{F=Ltr, G=Rtl}`——布局书写方向枚举，
`ms1` 从 `this.H`（容器布局方向）注入命中分发。

## 锚点 `gsf.i`（ms1.java:164-167 调用区 / gsf.java:164）

```java
public static long i(sbe sbeVar, yj8 yj8Var) {
    yj8Var.getClass();
    return s64.a(yj8Var == yj8.F ? sbeVar.c : sbeVar.a,
      (sbeVar.b + sbeVar.d) / 2.0f);
}
```

`F`(LTR) → `sbe.c`（右边 x）；`G`(RTL) → `sbe.a`（左边 x）；
y 恒为上下边中点。

## 茎长方向 `gsf.e`（gsf.java:87）

```java
float f3 = (56.0f / f2) * (qe4Var.getLayoutDirection() == yj8.F ? 1 : -1);
```

LTR 茎向右延 +56dp/zoom；RTL 向左延 −56dp/zoom。

## 命中域 `ms1:468-480`

`jI = gsf.i(sbe, dir)` 锚点 + 端点圆命中半径 `f4=32/f3`；
RTL 支 `f5 = 72/f3 + f4`（命中窗口向左翻移）。

## 会话起始角 `ms1:520-525`

```java
if (yj8Var == yj8.G) {
    fFloatValue3 = ((Number) si5.a.getValue()).floatValue(); // = π
} else {
    fFloatValue3 = 0.0f;
}
gufVar.h = new vtf(id, mapI, j3, jC2, fFloatValue2 + fFloatValue3, j3, msf);
```

`vtf.e`(startingRadians) 在 RTL 下 +π——补偿锚边翻转使起始增量为零。
Harmony `resizeStartAngle` 直接取按下实测触点角（左侧触点角≈π），
无需显式补偿即自洽。

## Harmony 移植（Phase 1458 前固定右锚，登记差异已结清）

- `selectionRotateHandleRtl` @State ← `i18n.isRTL(i18n.System.getSystemLanguage())`,
  `@Prop` 传 SelectionOverlay。
- 茎 Rect `x = rtl ? left−56 : right`；端点双层圆同向镜像。
- `selectionRotateHandleAt` 命中圆心 `cx = rtl ? left−56 : right+56`。
