# Phase 908 报告 — 页面子树读图 + 读写对称闭合

## 范围

ln2/nz9/k3a 读侧 accessor→偏移图；与写侧对称实证。
纯审计。

## 原版发现

- `ln2`：c(4)=cxc、c(6)=nz9、c(8)=pageCount、c(10)=oz9。
- `nz9`：c(4)=k3a、c(6)=sw9、c(8)=rot、c(10)=qed、c(12)=vy7。
- `k3a`：c(4)=n3a、c(6)=Float、c(8,10)=Boolean、
  c(12)=hu1、c(14)=cmf。
- 全部与 haj.a/vv7.L/fag.o0 写序逐对对称——读写闭合。

## Harmony 核对

三表解码槽位对齐；映射表建立。

## 产出

- 证据：`phase-908-page-reader-maps.md`
- Fixture：`d02-page-reader-maps.mjs`（18/18）
- ADR-0852；全量 Replay 781 文件绿。
