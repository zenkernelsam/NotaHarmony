# Phase 1136 证据 — au1 集合门面 + *nb Ref 捕获类

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `au1` = Kotlin 集合门面

```java
c1(List) = first()          // 空→throw s5c.u
e1(Iterable) = firstOrNull() // List 空→null else it.next
f1(List) = firstOrNull()
g1(i, List) = getOrNull(i)  // i<0|>=size→null
h1(it, it2) = intersect()→LinkedHashSet
```

`au1.c1(gxc)` = `gxc.first()` = 首个线锚（`exc`）；
`au1.g1(pos, e.g)` = `list.getOrNull(pos)`。

## `*nb` = Kotlin Ref 捕获类

```java
mnb { Object I }      // Ref.ObjectRef — 捕获对象
hnb { boolean I }     // Ref.BooleanRef
knb { int I }         // Ref.IntRef
```

Serializable 外壳——`e4c.g`/`e4c.h` 的 `njj.t` DFS 回调
（`ix4`/`wc`/`zm7` lambda）里跨闭包改的可变态。

## 语义修正

此前把 `au1.g1(pos, e.g)` 当 "pos→cursor" —— 实际是
`e.g`（子表 List）`.getOrNull(pos)` 取第 pos 个 `swc`
节点；`swc.d(hr5)` 才产锚。tombstone 查仍三步。

## Harmony 决策

- 集合工具 = 一等函数等价（first/getOrNull/intersect）。
- Ref 捕获 = 逃逸分析前的 box；Harmony 用 `{I}` 对象或
  `let`/`var` 等价。

## 产出

- fixture `d02-stdlib-refs.mjs`（10 断言）。
- ADR-1080；中文报告。
