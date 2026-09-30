# ADR-1102：n5d/ry0 完整属性图

## 状态

已接受（Phase 1158）。

## 决策

- `n5d` 形状 spec = `{rotation,scale,ShapeDefinition,
  inkTool,inkStyle,tapePattern,color,borderWidth,fillColor,
  zIndex,positionLocked}` 11 属性。
- `ry0` 块 spec = `{rotation,scale,size,corner,textWrap,
  enableCaption,positionLocked,zIndex}` 8 属性。
- 新 schema：`ShapeDefinition`(entities 包)、`InkTool/
  InkStyle/TapePattern/BlockCornerType/TextWrapMode`。

## 依据

`fl6[]` 描述符 11+8 属性全名 + 返回类型签名。

## 后果

Harmony：形状/块 spec 全属性真名；`zIndex` ULong；
`ShapeDefinition` 几何定义表。
