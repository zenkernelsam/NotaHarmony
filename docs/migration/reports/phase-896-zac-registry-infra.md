# Phase 896 报告 — `zac` 会话基类 + 注册基建实名

## 范围

实名会话生命周期基类与序列化注册基建。纯审计。

## 原版发现

- `zac` = Closeable：AtomicBoolean 幂等关闭 +
  finalize 兜底；tzc 继承 → 会话生命周期契约。
- `npb`/`mpb` = kotlin-reflect 类键工厂 + 惰性 opb
  提供者；`wx4` = Function2 序列化 lambda。
- zwd/ree 注册表 = {KClass → Function2} 派发全貌。

## Harmony 核对

dispose 幂等对齐；编译期分派行为等价 + fail-closed。

## 产出

- 证据：`phase-896-zac-registry-infra.md`
- Fixture：`d02-zac-registry-infra.mjs`（12/12）
- ADR-0840；全量 Replay 769 文件绿。
