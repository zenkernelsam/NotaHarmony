# ADR-1045：closeFinally + 委托取值 + 工具基类

## 状态

已接受（Phase 1101）。

## 决策

- `rh8.q` = Kotlin `use` 的 closeFinally（异常时 do6.x + s01.h
  addSuppressed；ExecutorService 特判）。opId 构造的 arena 必回收。
- `x82.x` = `cz8` 委托惰性取值。
- `ldj` mega-merge 基类（hex 表/集合工具）；`k1a` = Serializable Pair。

## 依据

std-close 语义 + 池委托 + Pair。

## 后果

Harmony try/finally + cause 链；惰性 getter；Pair 直移。
