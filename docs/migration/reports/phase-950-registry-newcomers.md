# Phase 950 报告 — 注册表新五类型实名

## 范围

z0c 登记的五个未映射类型实名。纯审计。

## 原版发现

- p9=AcknowledgeAppendedOpsEvent{acks}。
- q89=NoteMutationResponse{noteId:utf,acks}。
- xq3=DuplicateOp 24B{opId,原/复服务器时间}。
- r60/yq3=抽象 cee 基类。

## 产出

- 证据：`phase-950-registry-newcomers.md`
- Fixture：`d02-registry-newcomers.mjs`（10/10）
- ADR-0894；全量 Replay 823 文件绿。
