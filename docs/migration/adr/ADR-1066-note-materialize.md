# ADR-1066：note 物化（live→snapshot MVCC）

## 状态

已接受（Phase 1122）。

## 决策

- `v69.b()` = note 物化：`s==a79.g` 版本短路 →
  `iwc.c()→bxc` + `al2.a()→cl2` + `ria` 槽折叠 `wz9.build()`
  → `bka.f()→z4` → `q07` → `f1a` → 新 `a79`。
- 快照链：rvb/f1a/q07/z4/kia/oja。

## 依据

live builder → frozen spec 级联 + 版本戳复用。

## 后果

Harmony：dirty-version 短路 + builder→snapshot 物化管
线；快照类型直移。
