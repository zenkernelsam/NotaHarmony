# Phase 1113 证据 — bxc spec 视图类型（k5c/z4/kia/cl2）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `k5c extends y3` = 持久列表 + int[] 伴随

```java
k5c { List I; int[] J; int K }
static k5c L = new k5c(hw3.I, new int[0]);   // 空哨兵
```

List 与平行 int[]（行偏移/计数索引）—— 文本段落的行结构。

## `cl2 implements Map,ik6` = hja 惰性 map 视图

```java
cl2 { hja I; pce J/K/L }   // 3 个 pce 惰性派生
```

在 `hja` 持久 map 上叠惰性视图（`zk2` Function0 工厂）——
派生集合按需物化。

## `kia extends n5` = 计数列表 `{lgf I, int J}`

`lgf` 元素源 + 计数；`kia.K = new kia(lgf.d, 0)` 空哨兵。

## `z4 extends y3 implements zr5` = `zr5` 持久列表基类

`zr5` = 持久列表标记；`contains`/`containsAll` 委托实现。

## Harmony 决策

- 段落 = 持久列表 + 平行 int[]（行偏移）。
- map 视图 = hja + 惰性派生集合。
- `zr5` 列表基类直移。

## 产出

- fixture `d02-spec-views.mjs`（10 断言）。
- ADR-1057；中文报告。
