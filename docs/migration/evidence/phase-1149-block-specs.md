# Phase 1149 证据 — hp5/cie 块 spec + 真 schema 名泄漏

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `hp5 implements xy0,be5,bf0,ce5,oy0` = 图像块 spec

```java
m4c d;                                   // member-collection
fl6[] l = {
  w1b(hp5,"cropRect","…core/flatbuffers/Rect"),
  w1b(hp5,"imageFlippedVertically","Z"),
  w1b(hp5,"imageFlippedHorizontally","Z")}
sh8 k = new sh8(29)                       // Companion
hp5(ry0 spec, yc6, m4c, yc6, yc6)
```

**图像实体**：`cropRect`（`core.flatbuffers.Rect` 真名!）、
`imageFlippedVertically/Horizontally`（Z bool）—— 裁切
+ 双向翻转 + `m4c` 嵌套成员集合。

## `cie implements xy0,xhe,be5,bf0,ce5` = 纸块 spec

```java
m4c c;
fl6[] h = {
  w1b(cie,"paper","…core/flatbuffers/Paper"),
  w1b(cie,"resizesWidthToFitText","Z")}
cie(ry0, m4c, yc6, yc6); g = m4c.q
```

**纸/文本块**：`paper`（`core.flatbuffers.Paper` 真名!）、
`resizesWidthToFitText`（Z）+ `m4c` 成员集合。

## 真 schema 泄漏

`core.flatbuffers.{Rect, Paper}` + 属性名：
`cropRect`、`imageFlippedVertically`、`imageFlippedHorizontally`、
`paper`、`resizesWidthToFitText`。

## 语义

图像块/纸块 = `ry0`(CREATE 基 spec) + `m4c` 成员集合 +
各自属性 reg（裁切/翻转 | 纸/自适应宽）—— `xhe`
（`cie`）标"含嵌套文本"，`oy0`（`hp5`）标媒体块。

## Harmony 决策

- 图像块 = `{cropRect:Rect, flipV/H:bool, members}`；
  纸块 = `{paper:Paper, resizesW:bool, members}`。
- Harmony：同构块 spec + `Rect`/`Paper` FlatBuffers 表。

## 产出

- fixture `d02-block-specs.mjs`（10 断言）。
- ADR-1093；中文报告。
