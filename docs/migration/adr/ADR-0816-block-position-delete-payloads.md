# ADR-0816 — 块/位置/删除 op payload 登记（类型 22–25）

## 状态

accepted（文档+fixture，无源改动；Harmony 写手已等价）

## 原版契约（`decompiled_1.0.3`）

- `rl2` CREATE_BLOCK：21 字段（ty0 类型/cxc/fqa/Float/qed×2/
  dp5/bmb/String/hu1/k3a/vy7/bool×5）。
- `td8` MODIFY_BLOCK：18 槽（缺 f9）——f0=qo5 目标向量、f2=cxc、
  f4/5=k2d/y2d、f6=qed、f7=ive、f10–f13=z2d/g2d/p2d/n2d setter、
  f8+f14–f17=Boolean×5。
- `je8` MODIFY_POSITIONS：单字段位置向量。
- `s83` DELETE_ENTITIES：四向量字段——entityDeletes(qo5)、
  entityUndeletes(qo5)、pageDeletes(cxc)、pageUndeletes(cxc)；
  实体按 op-id、页面按位置寻址，删除/复活同表双向。

## Harmony 决策

`OriginalDeleteEntitiesPayloadEncoder` 四字段向量与原版字段
顺序/元素类型一致，空向量省略；Create/ModifyBlock、
ModifyPositions 编码器及 DeletePageCompensation/
PageDeleteCheckpoint 配套层齐。

## Parity 状态

等价。

## 验证

- `d02-block-position-delete-payloads.mjs`：29/29 通过。
- 全量 Replay 与双 HAP 构建见 Phase 872 提交。
