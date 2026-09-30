# Phase 1186 证据 — Kotlin lazy/ref 委托内部（pce + cx6）

来源：`defpackage/{pce,cx6}.java`。

## `pce implements cx6, Serializable` = `SynchronizedLazyImpl`

```java
pce(Function0 init):
  Function0 I          // 初始化 lambda
  volatile Object J    // 缓存值（双检锁）
  Object K             // 锁对象
  getValue():          // 双检锁懒初始化
    if (J==UNINIT) synchronized(K){ if(J==UNINIT) J=I.invoke() }
```

= Kotlin `lazy(mode=SYNCHRONIZED)` 运行时 —— `*nb` Ref
类（Phase 1136 mnb/hnb/knb）同 Kotlin 编译产物。

## `cx6` = `Lazy` iface

`SynchronizedLazyImpl`/`SafePublicationLazyImpl`/
`UnsafeLazyImpl`/`InitializedLazyImpl` 的公共接口 —
`getValue()`。

## 判定

`pce`/`cx6` = **Kotlin 委托内部**（非应用逻辑）——
`t0g`/`h0f` 的 `pce`×3 = `lazy {}` 字段（惰性场景资源）。

## Harmony 决策

- Kotlin `lazy` → ArkTS **getter 惰性**（`get x(){if(!_x)_x=…}`）或 `memoize`。
- `volatile`+synchronized → ArkTS 单线程无需锁（Harmony
  worker 内存模型不同 —— 惰性即普通 memo）。

## 产出

- fixture `d02-lazy-delegate.mjs`（10 断言）。
- ADR-1130；中文报告。
