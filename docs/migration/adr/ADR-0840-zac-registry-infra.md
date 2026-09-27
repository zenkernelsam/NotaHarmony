# ADR-0840 — `zac` 会话基类 + 序列化注册基建

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `zac` = Closeable 会话基类：AtomicBoolean 幂等关闭
  （`close()`+`finalize()` 双路径），`a()` 子类关闭体；
  `tzc` 编辑会话继承此契约。
- `npb` = kotlin-reflect 类键工厂（`b(Class)→KClass`）；
  `mpb` = 惰性 `opb` 提供者（失败回落 npb）；
  `wx4` = Function2 序列化 lambda 类型。
- zwd/ree 注册表 = `{KClass → Function2}`；缺失 →
  `rgc.b`+抛 fail-closed。

## Harmony 决策

会话 dispose 幂等对齐；类型分派走编译期 switch
（无反射，行为等价 + fail-closed 对齐）。

## Parity 状态

等价（生命周期契约 + 注册派发语义对齐）。

## 验证

- `d02-zac-registry-infra.mjs`：12/12 通过。
- 全量 Replay 769 文件绿，见 Phase 896 提交。
