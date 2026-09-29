# ADR-0979 — Kotlin 协程原语

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `sfb implements s7d,ml4,cz4` = **MutableSharedFlow**
  （v7d 委托）。
- **`ml4` = SharedFlow 接口**（修正 1019
  "会话状态 iface" 误判）。
- `em8 extends bwc implements cm8` = **Mutex**
  （owner CAS AtomicRefUpdater）；`fm8` = 工厂
  （NO_OWNER）。

## Harmony 决策

`sfb`/`ml4`→@Observed/EventEmitter（无 Flow）；
`em8`→async lock（事件循环单线程简化）。

## Parity 状态

语义等价（协程原语→ArkTS 事件原语）。

## 验证

- `d02-coroutine-primitives.mjs`：10/10 通过。
