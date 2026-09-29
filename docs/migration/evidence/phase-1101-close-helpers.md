# Phase 1101 证据 — rh8.q closeFinally + x82.x 委托取值 + ldj/k1a

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `rh8.q(AutoCloseable, Throwable)` = Kotlin `use` 的 closeFinally

```java
if (th != null) { try { do6.x(ac); } catch (t2) { s01.h(th, t2); } }
else if (ac instanceof AutoCloseable) ac.close();
else if (ac instanceof ExecutorService) { …terminated/shutdown 判定… }
```

- 带异常时 `do6.x` 尝试 close，二次异常 `s01.h(th,t2)` = addSuppressed。
- 无异常直 close；ExecutorService/ForkJoinPool 走 terminated 分支 —
  Kotlin 对 JDK7 `AutoCloseable` 的 commonization。
- `rh8.b` 的 try/finally 借此回收 `c8d` arena（成败皆回收）。

## `x82.x(cz8, fl6)` = 属性委托取值

`cz8` 池化缓存 + `fl6` 属性描述 → 线程本地/惰性取 holder（16KB buffer）。

## `ldj` = mega-merge 工具基类

- 静态段：`o22` 惰性槽、`tt` 优先级常量（1002/1007/1008 = CredentialOption）、
  `Q` = `'0'-'9','A'-'F'` hex 表。
- `A0(i,i2,List)` 二分插入位置等集合工具。`c8d extends ldj` 仅继承静态方法
  （mega-merge 副作用，无语义耦合）。

## `k1a` = `Serializable` Pair `{I, J}`

`c8d` 用它装 `{ByteBuffer, SharedMemory}`。

## Harmony 决策

- try/finally 资源回收 + addSuppressed → Harmony 用 try/finally + error cause。
- 委托取值 → ArkTS 显式 getter 惰性初始化。
- Pair/arena 结构直移。

## 产出

- fixture `d02-close-helpers.mjs`（10 断言）。
- ADR-1045；中文报告。
