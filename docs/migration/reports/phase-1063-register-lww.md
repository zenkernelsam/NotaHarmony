# Phase 1063 报告 — Register LWW 语义 + opId 全序比较器

## 完成内容

- `fqb` = crdt.Register$Builder：`c(op,v)` LWW 写（大者胜）、
  `a()`→`yc6` 快照、`b()`=isSet。
- `yc6` = Register 快照 holder（`{J,K,L}` + ctor-14 判别）。
- `so5.a` = **opId 全序**：`compareUnsigned(logicalTime)` 先，
  `ba6.w(site&0xffff)` 后 —— Lamport-then-site。
- `fsi.J` = 寄存器时间戳：**serverTime 优先，缺省 clientTime**。

## 意义

CRDT 收敛性钉死：所有副本按同一 (lt, site) 全序裁决，
无需中心仲裁。无符号比较是正确性关键（Phase 1060 串起）。

## 产出

- evidence `phase-1063-register-lww.md`
- fixture `d02-register-lww.mjs`（11/11）
- ADR-1007
