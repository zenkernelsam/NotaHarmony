# Phase 1068 证据 — qy0 活块实体 + spec→live 对称

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `qy0 implements fi0` = 活块实体

```java
qy0(ry0 spec)               // 包 spec
{ry0 b, fqb c..n (12 寄存器), v09 o=BLOCK, int p}
fl6[] q = {rotation, scale, zIndex}   // 3 委托变换属性
ctor: per-reg do6.g(spec.snap, spec.snap)
```

## spec→live 对称（完整 CRDT 实体层）

| 类别 | CREATE payload | spec | live 实体 | KProperty |
|------|---------------|------|-----------|-----------|
| Shape | `ao2` | `n5d` | `m5d` (14 reg) | 变换全集 |
| Block | `rl2` | `ry0` | `qy0` (12 reg) | rotation/scale/zIndex |

- spec 持 `yc6` 不可变快照；live 持 `fqb` 可写 builder。
- `do6.g` 桥接两者；`fi0`/`be5` 统一变换接口。
- `int p` = 版本戳（对应 `m5d.r`）。

## Harmony 决策

- 实体生命周期统一：`create→spec(yc6)→live(fqb)→op.apply`。
- shape/block 按上表分 payload/spec/live 三件套。

## 产出

- fixture `d02-live-entity.mjs`（10 断言）。
- ADR-1012；中文报告。
