# ADR-0894 — 注册表新五类型实名

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `p9`=AcknowledgeAppendedOpsEvent{acks}。
- `q89`=NoteMutationResponse{noteId:utf,acks}。
- `xq3`=DuplicateOp 24B{opId:qo5,
  originalServerTime,duplicateServerTime}。
- `r60`/`yq3`=抽象 cee 密封基。

## Harmony 决策

事件/响应/DuplicateOp 布局对齐。

## Parity 状态

等价。

## 验证

- `d02-registry-newcomers.mjs`：10/10 通过。
- 全量 Replay 823 文件绿，见 Phase 950 提交。
