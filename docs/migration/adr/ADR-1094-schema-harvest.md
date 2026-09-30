# ADR-1094：w1b schema 名丰收

## 状态

已接受（Phase 1150 milestone）。

## 决策

- `w1b` 委托描述符保留全部真属性名 + `core.flatbuffers`
  类型签名 —— 12 个 FlatBuffers 表真名复原：
  `BlockCornerType/BlockWrapSupport/Color/InkStyle/InkTool/
  LayoutMode/PageBackground/Paper/Rect/Size/TapePattern/
  TextWrapMode`。
- 实体属性真名（cropRect/paper/members/layoutMode/…）。

## 依据

`$$delegatedProperties` 描述符全量扫描。

## 后果

迁移命名对齐：FlatBuffers 表 + 实体属性用真名；
画笔缓存属（bezierPaint/blitPaint/…）→ Harmony
Canvas/Paint 等价。
