# Phase 1104 证据 — do6.x JDK7-close + s01.h addSuppressed 兼容层

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `do6.x(AutoCloseable)` = Kotlin JDK7 commonized close

```java
if (ac instanceof AutoCloseable) ac.close();
else if (ac instanceof ExecutorService es) {
  if (es == commonPool() || es.isTerminated()) return;
  es.shutdown();
  while (!terminated) try { terminated = es.awaitTermination(1, DAYS); }
    catch (InterruptedException) { if (!once) es.shutdownNow(); }
} else s5c.t();
```

Kotlin 对 `AutoCloseable`/`ExecutorService` 统一 close 的 stdlib 实现
（`use {}` 底层）。

## `s01.h(Throwable th, Throwable th2)` = addSuppressed 兼容

```java
if (th != th2) {
  Integer sdk = ua6.a;
  if (sdk == null || sdk >= 19) th.addSuppressed(th2);   // API≥19 直接
  else { Method m = qla.a; if (m != null) m.invoke(th, th2); }  // 反射回退
}
```

`ua6.a` = SDK_INT 探针；`qla.a` = 反射缓存的 addSuppressed Method。
相同异常去重（`th != th2`）。

## Harmony 决策

- Harmony 无 ExecutorService close 需求 → 直 `close()` + try。
- addSuppressed → Error.cause/附加异常链（ArkTS 无 suppressed →
  记 fail-closed：丢 suppressed 语义，仅保留主异常 + message 链）。

## 产出

- fixture `d02-jdk-compat.mjs`（10 断言）。
- ADR-1048；中文报告。
