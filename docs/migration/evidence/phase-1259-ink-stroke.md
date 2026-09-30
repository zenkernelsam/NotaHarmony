# Phase 1259 证据 — ka8/i5g/t16/nfe 墨笔迹模型

来源：`defpackage/{ka8,i5g,t16,nfe,ofe}.java`。

## `ka8` = 笔迹渲染模型

```java
ka8 { Path a;        // 主路径
      List b;        // 点列表
      i5g c;         // InkStyle
      Path d;        // 次路径（中线/选中）
      Float e; }     // 宽度
```

## `i5g` = InkStyle

```java
i5g { int a=color; float b=size; t16 c=tool;
      boolean d,e; }   // 特性标志
a()/b()/c()/d()/e()  // accessors
```

## `t16` = InkStyle 枚举

```java
VARIABLE_WIDTH(0), FIXED_WIDTH(1), DASH(2), DOTS(3)
final byte I;       // 序列化序号
```

## `nfe`/`ofe` = `Path()` 工厂 lambda

`nfe=new ty4(Function0<Path>)` —— `new Path()`。

## 语义

- `ka8` = **笔迹可绘制模型**（主 Path + 点 List +
  `i5g` 样式 + 次 Path + width）；
- `i5g` = 笔迹样式 `{color, size, t16 tool, 2×bool}`；
- `t16` = **InkStyle 枚举**（VARIABLE_WIDTH/FIXED/
  DASH/DOTS —— 笔宽模式）;
- `nfe`/`ofe` = Path 工厂（懒生成路径）。

## Harmony 决策

Path+InkStyle → Harmony `Path2D`/`canvas.Path`+工具
枚举 —— 笔迹模型语义保真。

## 产出

- fixture `d02-ink-stroke.mjs`（10 断言）。
- ADR-1203；中文报告。
