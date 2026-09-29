# Phase 1087 证据 — ija 惰性物化只读因果 map

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ija implements Map,ik6`（`kja`/`pja` 父类）

```java
LinkedHashMap J;      // 物化缓存
gja I;                // 底层因果存储

get(k):
    J.get(k) → 命中即返;
    I.get(k) → null→null;
    else e(item) 物化 → J.put(k,result) → return

put/putAll/merge/computeIfPresent
    → throw UnsupportedOperationException("read-only")
f(hja) abstract      // 产子视图
```

= **物化视图**：底层 `gja` 因果集 + 按需 `e()` 物化 +
`J` LinkedHashMap 缓存 + 只读（写经 op，不直写 map）。

## 只读语义（关键）

Map 接口但写操作抛异常 —— CRDT 集合对应用层只读；
变更必须走 op→`fqb.c` 路径（保证因果序）。

## `e(obj3)` = 元素物化（因果存储原始值→实体）

## Harmony 决策

- 因果集合 = 只读物化视图：backing store + lazy cache；
  应用层禁直写。

## 产出

- fixture `d02-causal-map.mjs`（10 断言）。
- ADR-1031；中文报告。
