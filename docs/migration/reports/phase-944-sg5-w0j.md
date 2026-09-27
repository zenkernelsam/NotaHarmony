# Phase 944 报告 — sg5 草稿池 + w0j

## 范围

写端 ThreadLocal 草稿池 + jmf + ie8 工厂。
纯审计。

## 原版发现

- sg5=v1b 委托属性草稿池——KProperty 名直接
  确认 Id/SeqId/StyleMap/Point/Size/
  ModifyPosition/DuplicateOp/OpAck/Op 真名。
- jmf=路径 provider 接口；w0j=ie8 全生命周期。

## 产出

- 证据：`phase-944-sg5-w0j.md`
- Fixture：`d02-sg5-w0j.mjs`（17/17）
- ADR-0888；全量 Replay 817 文件绿。
