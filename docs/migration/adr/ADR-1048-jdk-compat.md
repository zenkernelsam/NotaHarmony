# ADR-1048：JDK7 兼容层（close + suppressed）

## 状态

已接受（Phase 1104）。

## 决策

- `do6.x` = Kotlin stdlib AutoCloseable/ExecutorService 统一 close。
- `s01.h` = addSuppressed：SDK≥19 直接；否则 `qla.a` 反射回退；
  `th != th2` 去重。

## 依据

stdlib vendored；`ua6.a` SDK 探针 + `qla.a` Method 缓存。

## 后果

Harmony（ArkTS）：直接 try/finally + close；suppressed 无语义 →
fail-closed 记差异（主异常 + cause 保留，suppressed 列表省略）。
