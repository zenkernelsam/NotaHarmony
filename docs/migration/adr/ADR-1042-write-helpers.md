# ADR-1042：FB 写助手 + ValidationException

## 状态

已接受（Phase 1098）。

## 决策

- `sg5.f`/`rh8.O` = 12B exc / 8B opId struct 写
  （prep+w/y+r）。
- `ybg.c` = 写时校验：`a()` 非空 → `ValidationException`
  （fail-loud）。

## 依据

struct emit 序列 + `ybg.d` MODEL 日志+抛。

## 后果

Harmony op 写出后必过 `ka4.a()` 校验；非法 op 抛异常
不写盘。
