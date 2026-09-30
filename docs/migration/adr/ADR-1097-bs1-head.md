# ADR-1097：bs1 bundle 头

## 状态

已接受（Phase 1153）。

## 决策

- `bs1` = 线模 bundle 头 `{version:short, capacity:int,
  AtomicInteger counter}` —— 格式版本 + op 原子计数。
- `l96.M(short)` = 工厂；`l96` = IO 门面
  （`M0` stream→bytes 8KB）。

## 依据

`bs1(int,short)` + `AtomicInteger` + `M(0,s)` + `M0` 流拷。

## 后果

Harmony：bundle 头 `{version,capacity,counter}`；
原子计数等价 + IO 工具。
