# ADR-1090：委托属性读

## 状态

已接受（Phase 1146）。

## 决策

- `xj2.v(yc6,fl6)→yc6.K`、`xj2.w(fqb,fl6)→fqb.b` =
  Kotlin `by` 委托 `getValue` —— 实体属性即寄存器的
  语法糖。
- `fl6`/`w1b` = `KProperty`/`PropertyReference` 描述符；
  `yy3.E()` = spec 子索引。

## 依据

`v=yc6.K`、`w=fqb.b` 直读 + `w1b(Class,"members",…)`。

## 后果

Harmony：直接读 reg 字段（无 `by` 语法）；`E()` 子索引
供 `ny3` 界缓存键。
