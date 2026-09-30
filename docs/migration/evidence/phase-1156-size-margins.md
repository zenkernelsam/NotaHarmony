# Phase 1156 证据 — qed/vy7 FlatBuffers 结构 + 工厂

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `qed extends xwd implements ka4` = `core.flatbuffers.Size`

```java
a()→String; c()→float; d()→float   // 名 + w + h
```

尺寸 FlatBuffers **struct**（`xwd` 结构基 + `ka4`）——
`sg5` 注册表里 `SIZE_HOLDER→flatbuffers.Size` 的实现类。

## `vy7 extends xwd implements ka4` = margins/insets 结构

```java
a()→String; c()/d()/e()→float×3(+1)  // 名 + 4 float
```

4-float insets/margins 结构（top/right/bottom/left）——
对应 Rect/margins schema。

## `apb.h(float w, float h)→qed` / `fsi.f(float×4)→vy7`

FlatBuffers 结构写工厂（同 `rh8.O`/`sg5.f` 模式：scratch
builder→写浮点字段→`ybg.c` 校验→`bs1`/bind）—— 产不可变
Size/margins 实例。

## 语义

- `qed` = Size `{w,h}` —— a79.N 默认 612×792 Letter。
- `vy7` = margins `{t,r,b,l}` —— a79.O 默认 36×4。
- `apb.h`/`fsi.f` = 结构写工厂（`dk4` 池 + 校验）。

## Harmony 决策

- Size = `{w,h}` struct；margins = `{t,r,b,l}` struct；
  工厂 = FlatBuffers 结构写。
- Harmony：`{width,height}`/`{top,right,bottom,left}`。

## 产出

- fixture `d02-size-margins.mjs`（10 断言）。
- ADR-1100；中文报告。
