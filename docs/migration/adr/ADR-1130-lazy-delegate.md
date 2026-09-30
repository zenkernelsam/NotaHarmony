# ADR-1130：Kotlin lazy/ref 委托内部

## 状态

已接受（Phase 1186）。

## 决策

`pce`=`SynchronizedLazyImpl`（`lazy(SYNCHRONIZED)`：
`volatile J` + `Function0` init + `synchronized(K)` 双检）+
`cx6`=`Lazy` iface + `*nb` Ref 类 → ArkTS getter 惰性/
memoize（单线程无需锁）。

## 理由

`implements cx6,Serializable` + `volatile Object J` +
`Function0` + `synchronized` 双检 + `getValue`。

## 后果

Kotlin `lazy` → ArkTS `get x(){…}` 或 memoize；`*nb`
Ref（`mnb/hnb/knb`）→ ArkTS 闭包捕获对象。
