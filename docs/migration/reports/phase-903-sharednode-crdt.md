# Phase 903 报告 — SharedNodeData + CRDT 引用层实名

## 范围

实名 CRDT 共享树节点模型。纯审计。

## 原版发现

- `f8d` = SharedNodeData{site,ts,audioTime,parent,values}。
- `hr5` = 线上节点身份 {site,ts,index} = cxc 同型。
- `swc/qwc/rwc` = 引用接口/已解析/惰性三态
  （rwc 未设抛 sharedData）。

## Harmony 核对

序列身份对齐；元素树 provenance 对齐。

## 产出

- 证据：`phase-903-sharednode-crdt.md`
- Fixture：`d02-sharednode-crdt.mjs`（14/14）
- ADR-0847；全量 Replay 776 文件绿。
