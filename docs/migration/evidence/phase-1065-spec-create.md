# Phase 1065 证据 — n5d spec（CREATE-op 物化）+ 收敛论证

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `n5d implements yy3, bf0, be5, m4d`

```java
n5d(uq9 createOp, ao2 payload, int, yc6×14 regs, m4c, xgb)
this.b = createOp;
B = nti.y(op)?.I ?: op.k();   // 创建时间戳
```

- spec 由 **CREATE 操作物化**：`uq9` + `ao2`（CREATE_SHAPE
  payload）+ 14 个初始 `yc6` 寄存器快照。
- `n5d` 本身实现 `be5` —— spec 也可作变换源（初始态）。
- `O()→uq9` = 溯源创建操作。

## `do6.g(yc6, yc6)` = builder-init

```java
public static fqb g(yc6 a, yc6 b) { a.getClass(); return new fqb(b); }
```

忽略第一参，从快照建 builder —— `m5d` ctor 用它把 spec
快照变成可写寄存器。

## 收敛论证（无独立 merge）

CRDT 合并不用专门 merge：远端 op 到达 → `fqb.c(op,v)` 按
`(logicalTime, site)` 全序裁决 —— 同序回放必然收敛。
`fi0.d`（Phase 1062）的每属性寄存器写 = merge 本身。

## Harmony 决策

- `n5d` = 创建时物化的实体模式（含初始寄存器快照+溯源 op）。
- 无独立 join：op-apply 即 merge。

## 产出

- fixture `d02-spec-create.mjs`（10 断言）。
- ADR-1009；中文报告。
