# ADR-1037：FB 向量→只读 List 适配

## 状态

已接受（Phase 1093）。

## 决策

- `hvd` = FlatBuffers 向量→只读 `List` 适配器
  （`{cee payload, cxc}`，写抛异常）。
- `m2`/`y3` = 只读集合基（`ik6` 标记）；`gxc`/`g2c` 等
  wire-向量表都经此呈现。

## 依据

`hvd`/`m2` 的 UnsupportedOperationException + 继承链。

## 后果

Harmony payload 向量只读呈现；写经 op 序列化而非直接改。
