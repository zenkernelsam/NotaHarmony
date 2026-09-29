# Phase 1064 证据 — m5d CRDT 实体（14 寄存器 + materialize）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `m5d implements be5, k5d, fi0`

= 活实体（图形/块等可变换对象），持有 **14 个 `fqb` 寄存器** `c..p`。

### 构造：`m5d(n5d spec)`

- `n5d` = 实体模式，每个属性一个 `yc6` 默认寄存器快照（e..r）。
- `do6.g(yc6, yc6)` = 以快照初始化 builder（真名 register-init）。
- `q = new e4c(m4c)`、`v = n5d.A`（非寄存器字段）。

### `fi0` 寄存器访问器映射（Phase 1062 的 `ei0` 引用目标）

```java
fqb o() → c   // 变换·origin/page 系
fqb n() → d   // rotation
fqb w() → e   // scale
fqb J() → f   // zIndex
```

### `be5` 读取器 = materialize（读寄存器 `.b` 值）

```java
k11 G() {          // 包围盒
    v4d v = (v4d) this.g.b;                // 边界寄存器值
    return v.a(((Number) this.l.b).floatValue());  // 另一寄存器值
}
```

- `fl6[] w` = Kotlin 委托属性数组（KProperty —— 寄存器经
  `by observable/delegated` 委托）。
- `A()` = `r++` —— 本地版本计数器（每变更递增）。

## Harmony 决策

- 实体 = `{spec: n5d, regs: LWWRegister[14]}`；materialize 时读
  `reg.value`；属性委托保留语义（读寄存器非裸字段）。
- `r++` 版本戳保留。

## 产出

- fixture `d02-crdt-entity.mjs`（10 断言）。
- ADR-1008；中文报告。
