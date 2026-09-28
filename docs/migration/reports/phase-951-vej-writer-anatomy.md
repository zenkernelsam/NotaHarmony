# Phase 951 报告 — 典型 op 写器解剖

## 范围

vej.q(qub) 写器全机制。纯审计。

## 原版发现

- 元素提供器 wj9(9,cxcScratch,table) +
  sg5.f 零分配写 + D(12,len,4) 向量 +
  rh8.O qo5 写器 + z(iN,4) required。
- 负长度经 yn7.MODEL 记日志。

## 产出

- 证据：`phase-951-vej-writer-anatomy.md`
- Fixture：`d02-vej-writer-anatomy.mjs`（8/8）
- ADR-0895；全量 Replay 824 文件绿。
