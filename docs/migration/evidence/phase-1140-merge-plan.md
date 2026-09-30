# Phase 1140 证据 — e0a 合并计划 + ba6.y 实体解析

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `e0a{ArrayList a, LinkedHashSet b}` = 合并计划

`a` = 已解空间实体（`wnd.c` 元素 + `vnd` 节点）；
`b` = 未解 opId 集（实体未物化 → 留待下轮）。

## `v69.g(List entityKeys, LinkedHashMap dedupe)→e0a`

```java
for (qo5 op : entityKeys) {            // 键并集
  wnd w = ba6.y(this, op, dedupeMap);  // op→实体解析
  au1.O0(arrayList, w.c);              // addAll w.c
  vnd v = w.a;
  if (v!=null) arrayList.add(v);        // 已解→a
  else linkedHashSet.add(op);           // 未解→b
}
return new e0a(arrayList, linkedHashSet);
```

`ba6.y` = per-op 实体解析器 → `wnd{vnd a, c list}`：
- `w.c` 元素 → `a`（addAll）；
- `w.a` 空间节点 → `a`（已解）或 `op`→`b`（未解）。

## `wnd` = 解析结果

`{vnd a, List c}` —— 空间节点 + 元素表的解析产物
（对应 `ba6.k/R` bounds-resolver 家族）。

## 与调和链衔接

`v69.c` label1：键并集→`g`→`e0a{a:已解实体,b:未解op}`
→`yc6.z(e0a,…)` 空间应用（Phase 1139 `e0a.b` 循环）。

## Harmony 决策

- 合并计划 = `{resolved:[], unresolved:Set}`；
  per-op `wnd{vnd,elems}` 解析，未解入 set。
- Harmony：同构 `{Array,Set}` 计划 + resolver。

## 产出

- fixture `d02-merge-plan.mjs`（10 断言）。
- ADR-1084；中文报告。
