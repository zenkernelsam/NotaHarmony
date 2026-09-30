# Phase 1176 证据 — 墨迹笔画渲染模型（ka8 + i5g + t16=InkStyle）

来源：`defpackage`（obf）墨迹渲染类。

## `t16` = **`InkStyle` 枚举**（Phase-1150 泄名坐实）

```java
enum t16:                       // = core.flatbuffers.InkStyle
  VARIABLE_WIDTH(0)   // 可变宽（压感）
  FIXED_WIDTH(1)      // 固定宽
  DASH(2)             // 虚线
  DOTS(3)             // 点线
```

## `i5g` = 笔画样式值对象

```java
i5g{int a, float b, t16 c(InkStyle), boolean d, boolean e}
  a()→float  // 尺寸
  b()→int    // 颜色
  c()→t16    // InkStyle
```

## `ka8` = 墨迹笔画渲染模型

```java
ka8{Path a(outline), List b(points), i5g c(style),
    Path d(fill), Float e(width)}
```

一笔 = outline Path + fill Path + 点列 + `{颜色, 尺寸,
InkStyle}` + 宽度 —— pressure 笔画渲染成轮廓/填充 Path。

`nfe`/`ofe` = `new Path()` 工厂 lambda。

## 判定

**墨迹渲染管线**：输入预测（Phase 1175）→ `ka8`
笔画模型（Path+样式）→ Canvas drawPath。
`InkStyle`（VARIABLE/FIXED/DASH/DOTS）+ `i5g`（色/宽/
样式）→ `InkStyle`/`InkTool` schema（Phase 1150/1158）。

## Harmony 决策

- `Path` → Harmony `Path2D`/`drawing.Path`。
- `t16`=`InkStyle` 枚举**直接保留**（VARIABLE_WIDTH/
  FIXED_WIDTH/DASH/DOTS — 4 值字面）—— schema 语义
  完美对齐。
- `i5g`/`ka8` → Harmony 笔画样式 + Path 渲染结构体。

## 产出

- fixture `d02-ink-stroke.mjs`（10 断言）。
- ADR-1120；中文报告。
