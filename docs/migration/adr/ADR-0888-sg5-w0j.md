# ADR-0888 — sg5 草稿池 + w0j 工厂

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `sg5`=ThreadLocal 序列化草稿池：v1b 委托
  属性登记 ID/SEQ_ID/STYLE_MAP/RECORDING_
  SEGMENT/POINT/SIZE/MODIFY_POSITION/
  DUPLICATE_OP/OP_ACK/OP holders——KProperty
  名反向确认 Id=qo5/SeqId=cxc/StyleMap=yyd/
  Point=fqa/Size=qed/ModifyPosition=ie8/
  OpAck=vq9/Op=uq9 真名。
- `jmf`=路径向量 provider 接口。
- `w0j`=ie8 工厂+序列化+Bundle 读写。

## Harmony 决策

写端可复用 struct 实例；零分配语义可选。

## Parity 状态

等价（性能优化语义，不影响线型）。

## 验证

- `d02-sg5-w0j.mjs`：17/17 通过。
- 全量 Replay 817 文件绿，见 Phase 944 提交。
