# Phase 1146 证据 — xj2.v/w 委托属性读 + fl6/w1b

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `xj2.v(yc6, fl6)→Object` / `xj2.w(fqb, fl6)→Object`

```java
v(yc6, fl6) = yc6.K   // 读 yc6 的 reg/快照字段
w(fqb, fl6) = fqb.b   // 读 LWW reg 值
```

Kotlin 委托属性 `getValue(thisRef, property)` 实现——
`by` 委托的编译产物：实体属性声明成
`val members by reg`/`by snapshot` 时，getter 编译成
`xj2.v(d, h[i])`/`xj2.w(reg, h[i])`。

## `fl6`/`w1b` = 属性描述符

`fl6` = `KProperty`；`w1b(Class,"members","sig",0)` =
`PropertyReference` —— `w1b(k85,"members","getMembers()
Ljava/util/List;",0)` 把 `members` 属性反射成描述符，
`fl6[] d`/`h` 存之（编译器生 `$$delegatedProperties`）。

## `l85.M() = xj2.v(this.d, h[0])`

`this.d` = 委托对象（`yc6`/`fqb`）；`h[0]` = "members"
描述符 → `xj2.v` 读 `d.K`/`d.b`。

## `yy3.E()→int`

spec 快照的**子索引** getter（`ba6.y` 用它查 `ny3`
子界缓存）——`yy3` 实体快照的 ordinal/下标。

## 语义

CRDT 实体属性 = Kotlin `by` 委托：实体声明
`val members by register`，getter 经 `xj2.v/w` 读底层
reg —— **属性即寄存器** 的语法糖。

## Harmony 决策

- 委托属性 = 语法糖 → Harmony 直接读 reg 字段。
- `yy3.E()` = spec 子索引（sub-bounds 缓存键）。

## 产出

- fixture `d02-prop-delegate.mjs`（10 断言）。
- ADR-1090；中文报告。
