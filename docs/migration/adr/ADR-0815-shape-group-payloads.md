# ADR-0815 — 形状/组 op payload 登记（类型 18–21）

## 状态

accepted（文档+fixture，无源改动；Harmony 写手已等价）

## 原版契约（`decompiled_1.0.3`）

- `ao2` CREATE_SHAPE：17 槽（缺 f5）——cxc/fqa/Float/qed/z4d/
  u16/t16/ife/hu1×2/tmf/bool×3/long。
- `le8` MODIFY_SHAPE：16 读字段（17 槽 writer）——f0=qo5 目标
  向量、f8=ife 样式、f10=hu1 颜色、f11=Float 边宽、f12=g2d
  填充色 setter、f14=Boolean 锁定。
- `cm2` CREATE_GROUP：单字段成员向量；`vd8` MODIFY_GROUP：
  f0=qo5 目标 + f1=成员向量。

## Harmony 决策

`OriginalModifyShapePayloadEncoder` 17 槽 vtable，锚点
style@8/color@10/borderWidth@11/fillColor@12/lock@14 与
`u5j.x` 原版写序一致；`OriginalGroupPayloadEncoder` 写 cm2
单字段 qo5 成员向量（重复成员 fail-closed）；GroupMutation
codec 覆盖 vd8。

## Parity 状态

等价。

## 验证

- `d02-shape-group-payloads.mjs`：32/32 通过。
- 全量 Replay 与双 HAP 构建见 Phase 871 提交。
