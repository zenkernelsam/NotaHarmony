# Phase 945 报告 — 写↔读对称首证

## 范围

haj.c ln2 写器 + nti.X cxc 写器。纯审计。

## 原版发现

- haj.c：C(4)+j(0,X)+h(1,L)+e(2,def1)+c(3,def0)
  = f0-f3 与读端 4 偏移镜像。
- nti.X：t(4,12)+w(iC)+w(iD)+s(2)+y(sC) 逆序
  → {site@0,pad@2,ts@4,idx@8} 读端逐字节一致。

## 产出

- 证据：`phase-945-write-side-symmetry.md`
- Fixture：`d02-write-side-symmetry.mjs`（9/9）
- ADR-0889；全量 Replay 818 文件绿。
