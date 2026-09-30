# Phase 1145 证据 — k85/l85 成员集合 spec↔live

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `k85 implements h85, xy3` = live 成员集合实体

```java
fl6[] d = {w1b(k85,"members","getMembers()Ljava/util/List;")}
                                          // 真名 "members"!
fqb c;                                    // members LWW reg
k85(l85 spec)                             // spec→live
M()→List = (List) c.b                      // 成员=reg 值!
O()→uq9                                   // create op
build()→yy3; c(List,Set) apply; e() bool
```

成员集合 = **单个 `fqb` LWW register 持 List<opId>**；
`M()` = 读 `c.b` reg 值。

## `l85 implements yy3, h85` = 成员集合 spec 快照

```java
fl6[] h = {w1b(l85,"members",…)}; j0 g=new j0(18)  // Companion
l85(uq9 createOp, cm2, yc6)                          // CREATE 造!
E()→int                                            // 子索引
M()→List = xj2.v(this.d, h[0])                      // 委托读
O()→uq9
```

同 `n5d`/`ry0`/`qy0` 对称：`l85` 由 CREATE op 造 spec，
`k85` spec→live（`members` reg）。

## 语义

member-collection 实体的全部状态 = **一个 LWW List**：
- 改成员 = 整个 List 覆盖写（`fqb.c(opId,list)` LWW）。
- `ba6.y`/`z` 的 `h85.M()` 读的即此 reg 值（子 opId 表）。
- `l85`(spec)↔`k85`(live)↔`yy3`(snapshot build) 三段。

## Harmony 决策

- 成员集合 = LWW-reg 持 List；spec/livesnapshot 三段；
  `M()`=reg 值。
- Harmony：Register<List<opId>> + spec↔live 对称。

## 产出

- fixture `d02-k85-member.mjs`（10 断言）。
- ADR-1089；中文报告。
