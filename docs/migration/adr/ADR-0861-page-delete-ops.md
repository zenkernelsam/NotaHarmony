# ADR-0861 — ge8/s83/je8/tdf 四表读图

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `ge8` ModifyPage{pages:cxc[], moveTo:lxc SeqMove,
  background:m2d SetPageBackground, bookmarked:oz9}。
- `s83` DeleteEntities{entityDeletes:qo5[],
  entityUndeletes:qo5[], pageDeletes:cxc[],
  pageUndeletes:cxc[]}——**双墓碑对**（实体+页面各带
  删除/复活向量），同步可逆软删除。
- `je8` ModifyPositions{modifications:ie8[]}。
- `tdf` TransientInteractionEnded{interactionId:qo5 必填,
  replacedByOp:qo5}——sdf 建立↔tdf 终结成对。

## Harmony 决策

页面修改四字段、删除双墓碑、瞬态终结编码对齐。

## Parity 状态

等价。

## 验证

- `d02-page-delete-ops.mjs`：18/18 通过。
- 全量 Replay 790 文件绿，见 Phase 917 提交。
