# ADR-0996 — lv2 向量访问器范型与持久化集合

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `lv2` 向量读取范型：vtable 槽→长度→`m18.S()` builder→
  逐元素 struct→`m18.E()` 冻结；空→`hw3.I` 单例。
- 20+ 访问器覆盖所有载荷向量字段（inks/locations/
  members/deletes/pages/blocks/shapes/编码路径/styleMap/
  segmentation/selectedEntities/ops）。
- `th7` builder（array+size+frozen）、`u4` 基类、
  `hw3.I` 空表、`m18.S/E` 构建冻结——persistent
  collections vendored。

## Harmony 决策

统一向量读模型；builder/冻结两阶段集合；空表单例。

## Parity 状态

等价。

## 验证

- `d02-vector-accessors.mjs`：12/12 通过。
