# ADR-1009：实体 spec = CREATE-op 物化；apply 即 merge

## 状态

已接受（Phase 1065）。

## 决策

- `n5d` spec 由 `uq9`+`ao2` CREATE 操作物化，存 14 初始寄存器
  快照 + 溯源 op。
- `do6.g` 快照→builder；**无独立 merge** —— 远端 op 的
  `fqb.c` LWW 写即合并。

## 依据

`(logicalTime, site)` 全序使 op 回放收敛；spec 的不可变快照
提供初值，builder 承接后续 LWW 写。

## 后果

Harmony：实体生命周期 = `create→spec → live(regs) → op.apply`；
无需 join 函数。
