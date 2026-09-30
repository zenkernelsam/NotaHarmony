# Phase 1158 证据 — n5d/ry0 完整属性图 + 新 schema 名

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `n5d` = 形状实体 spec（11 `w1b` 属性）

```java
rotation:Float      scale:Size
definition:core.model.entities.ShapeDefinition   // 真包!
tool:InkTool        style:InkStyle      tapePattern:TapePattern
color:Color         borderWidth:F       fillColor:Color
zIndex-tJoBMIg:J    positionLocked:Z
```

形状 = 旋转 + 缩放 + **形状定义**（`core.model.entities.
ShapeDefinition` 命名包!）+ 墨工具/样式/胶带图案 +
色 + 边宽 + 填充色 + z-index + 锁。

## `ry0` = 块实体 spec（8 `w1b` 属性）

```java
rotation:Float      scale:Size        size:Size
corner:BlockCornerType                textWrap:TextWrapMode
enableCaption:Z     positionLocked:Z  zIndex-tJoBMIg:J
```

块 = 旋转 + 缩放 + 尺寸 + 角类型 + 文本换行模式 +
标题开关 + 锁 + z-index。

## 新 schema 名

`core.model.entities.ShapeDefinition`（命名包!）、
`flatbuffers.{InkTool,InkStyle,TapePattern,BlockCornerType,
TextWrapMode}`、`zIndex-tJoBMIg`（ULong-mangled 签名）。

## 语义

- 形状 vs 块：形状有 `definition`(几何语言)+墨属
  (tool/style/tapePattern/color/borderWidth/fillColor)；
  块有 `size`+`corner`+`textWrap`+`enableCaption`。
- 共性：`rotation`/`scale`/`zIndex`/`positionLocked` ——
  `be5` 变换的 4 属性。

## Harmony 决策

- 形状 spec = `{rot,scale,ShapeDef,inkTool,inkStyle,
  tapePattern,color,borderWidth,fillColor,zIndex,locked}`。
- 块 spec = `{rot,scale,size,corner,textWrap,caption,
  locked,zIndex}`。
- Harmony：ShapeDefinition 表 + InkTool/InkStyle enum +
  全属性真名。

## 产出

- fixture `d02-entity-props.mjs`（10 断言）。
- ADR-1102；中文报告。
