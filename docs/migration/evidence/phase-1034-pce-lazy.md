# Phase 1034 证据 — pce Kotlin Lazy 实现（cx6 定案）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `pce implements cx6, Serializable` = Kotlin Lazy

```java
public final class pce implements cx6, Serializable {
    public Function0 I;          // 初始化 lambda
    public volatile Object J;    // 缓存值（volatile）
    public final Object K;       // 锁对象
    public pce(Function0);
    public final boolean a() {   // isInitialized
        return this.J != <UNINITIALIZED>;
    }
    public final Object getValue() {
        Object o = this.J;             // 快路
        if (o != <UNINIT>) return o;
        synchronized (K) {             // DCL
            if (J == <UNINIT>) J = I.invoke();
            return J;
        }
    }
}
```

- **双检锁 Lazy**：volatile J + K 同步块 +
  Function0 初始化。
- `a()` = isInitialized（J≠UNINIT）；
  `getValue()` = 懒读。

## `cx6` = **Lazy 接口**（定案 1021）

```java
public interface cx6 {
    boolean a();        // isInitialized
    Object getValue();  // 懒读
}
```

- Phase 1021 曾标"检查 iface"——实为 **Kotlin Lazy
  委托接口**（`by lazy {}` 的委托协议）。

## `pce` 普及度

- 每个 DAO/服务都持 `pce`（qr1/jl3/ssf/xrf/…）——
  Kotlin `by lazy` 的标准实现。

## HarmonyOS 决策

- `pce`/`cx6` → ArkTS `get value() { return cached
  ??= init() }` 属性或 `Lazy<T>` 包装；
  DCL 在 ArkTS（单线程事件循环）不需同步。

## 产出

- fixture `d02-pce-lazy.mjs`（10 断言）。
- ADR-0978；中文报告。
