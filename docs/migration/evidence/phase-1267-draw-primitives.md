# Phase 1267 证据 — xd1/po3/f31/qu1/bt 绘制图元

来源：`defpackage/{xd1,po3,f31,qu1,bt,wd1,b40}.java`。

## `xd1` = Compose `CanvasDrawScope`（DrawScope 绘制委托）

```java
xd1 implements no3 {
    wd1 I;                 // DrawParams
    b40 J;                 // Android Canvas 适配
    bt K, L;               // Paint 池
    b(...)→bt              // 取/配 Paint（paint.getColor→kkf.d）
    B0/I/...               // drawRect/Line/Circle/...
}
```

## `po3` = `Brush`（渐变/纯色画刷）

`abstract po3` —— 画刷基类（子类=SolidColor/LinearGradient/
RadialGradient/SweepGradient/ShaderBrush）。

## `f31` = `ShaderBrush`/draw-style

`a(float alpha, long size, bt paint)` —— 画刷应用到
Android Paint（alpha+size+Paint）。

## `qu1` = `ColorFilter` 包装

`{ColorFilter a}` —— Android ColorFilter（BlendMode
色彩矩阵）适配。

## `bt` = `Paint` 包装

`{Paint a}` —— Android Paint 池对象（xd1 复用）。

## 语义

- `xd1` = CanvasDrawScope（Paint 池+Canvas 适配+draw 调用）；
- `po3`/`f31`/`qu1`/`bt` = Brush/ShaderBrush/ColorFilter/
  Paint —— Compose 图形图元；
- `jw6.I=xd1` → `vle` 编辑器绑定 → DrawScope 绘制笔记。

## Harmony 决策

CanvasDrawScope/Brush/ColorFilter → Harmony
`CanvasRenderingContext2D`+`LinearGradient`+
`colorFilter` —— 绘制图元语义保真。

## 产出

- fixture `d02-draw-primitives.mjs`（10 断言）。
- ADR-1211；中文报告。
