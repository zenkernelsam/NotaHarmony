# Phase 1144 证据 — v69.y 受影响 id 批量收集

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `v69.y(Collection ops, Set, u69 cb)→LinkedHashSet`

遍历 op 集，逐 op 分类受影响实体：

```java
for (uq9 op : ops) {
  … classifier u69 …
  new bl2(op.l(), new tz9(((tz9)x).a), TRUE)   // 页墓碑条
  new r09(((tz9)x).a)                            // 页实体 ref
  new t09(null, listF)                           // id-list 实体 ref
  lia.add(op)                                    // op 入缓冲
}
→ LinkedHashSet<u09>
```

产出 `u09` 实体 id 的 `LinkedHashSet` —— 调和的受影响
集合构建器。

## id 变体

- `bl2` = 墓碑条 `{opId, tz9页, TRUE}`（页面删除标）。
- `r09` = 页实体 ref（`tz9` 页包装）。
- `t09{null, List}` = id-list 实体 ref（多实体容器）。
- `u69` = per-op 分类 lambda。

## `v69.x(coll, ff2)→Serializable`

`x82` 并行分区收集（复杂未反编译）——`w`→`x` 委托的
suspend 主体，CPU 分区收 op。

## 与调和链

`c` 调和 → `y` 收受影响 `u09` 集 → `g`/`ba6.y` 解析 →
`e0a` 计划 → `yc6.z` 应用。

## Harmony 决策

- 受影响集 = ops→分类（页墓碑`bl2`/页`r09`/容器`t09`）
  →`LinkedHashSet<u09>`。
- Harmony：同构分类收集。

## 产出

- fixture `d02-v69-collect.mjs`（10 断言）。
- ADR-1088；中文报告。
