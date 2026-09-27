# ADR-0847 — `f8d` SharedNodeData + CRDT 节点引用层

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `f8d` = SharedNodeData{rawSiteId:short, rawTimestamp:int,
  rawAudioTime:long, parent:qwc, values:List}——CRDT
  共享树节点（身份+父链+值表）。
- `hr5` = 线上节点身份 {siteId,timestamp,index} =
  cxc 同型三元组（880）。
- `swc` 引用接口（a/c/d/e/getParent/getValue）；
  `qwc` 已解析引用；`rwc` 惰性引用（未设 →
  `d0("sharedData")` 抛）。

## Harmony 决策

序列身份 cxc 同构对齐 hr5；元素树 provenance 对齐
SharedNodeData 父链/值表；未解析引用 fail-closed。

## Parity 状态

等价（共享树节点模型实名对齐）。

## 验证

- `d02-sharednode-crdt.mjs`：14/14 通过。
- 全量 Replay 776 文件绿，见 Phase 903 提交。
