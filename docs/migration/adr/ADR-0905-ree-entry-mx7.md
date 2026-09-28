# ADR-0905 — `ree` 序列化总入口 + `rgc` fail-loud 护栏

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

`ree` = 表序列化顶层入口：`b(cee)` = 池化 builder → `a()`
按 IdentityHashMap 精确分派 wx4 写器 → `p()` finish → 字节。
`rgc.b` = 未注册类 `IllegalStateException("Unknown type...data
loss...programmer error")`——**fail-loud 零容忍**。
`pce` = SynchronizedLazyImpl（DCL + t3i.c0 哨兵）；
`mx7` = MapBuilder（结构表容器，vs 表注册表用 IdentityHashMap）。

## Harmony 决策

未注册类型必须 throw（fail-closed 与原版一致）；
注册表按运行时类精确匹配语义保留。

## Parity 状态

等价。

## 验证

- `d02-ree-entry-mx7.mjs`：16/16 通过。
- 全量 Replay 834 文件绿，见 Phase 961 提交。
