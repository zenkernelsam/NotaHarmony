# ADR-0883 — 尾批 op 偏移

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `s83`=DeleteEntities 四墓碑向量：实体
  (qo5)×删/复 + 页(cxc)×删/复。
- `tdf`={interactionId:qo5,replacedByOp:qo5}。
- `je8`={modifications:ie8[]}；`ge8`=ModifyPage
  {pages:cxc[],moveTo:lxc,background:m2d,
  bookmarked:oz9}。
- `tl2`=CreateComment{im@0,anchor@1多态,text@2}；
  `ud8`=ModifyComment{comment,anchor:**仅hd1**,
  text:z2d,resolved:z1d}——修改不能改锚类型。

## Harmony 决策

四墓碑顺序与 ud8 单锚型语义对齐。

## Parity 状态

等价。

## 验证

- `d02-op-offset-tail.mjs`：17/17 通过。
- 全量 Replay 812 文件绿，见 Phase 939 提交。
