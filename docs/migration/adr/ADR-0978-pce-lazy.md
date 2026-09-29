# ADR-0978 — pce Kotlin Lazy + cx6 定案

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `pce implements cx6, Serializable` = Kotlin `lazy`
  ——`Function0 I` 初始化 + `volatile J` 缓存 +
  `K` 锁（DCL）；`a()`=isInitialized，getValue 懒读。
- **`cx6` = Kotlin Lazy 委托接口**（定案 1021
  "检查 iface" 误判）。
- 全代码库普及（qr1/jl3/ssf/xrf/… 全持 pce）。

## Harmony 决策

`pce`→ArkTS `get value(){ return cached ??= init() }`
或 `Lazy<T>`；DCL 不需（ArkTS 事件循环单线程）。

## Parity 状态

等价（单线程简化）。

## 验证

- `d02-pce-lazy.mjs`：10/10 通过。
