# Phase 1142 证据 — h85 成员集合 + ba6.z 递归子解

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `h85` = 成员集合接口

```java
interface h85 { List M(); }   // 成员/pending opId 表
```

`k85 implements h85`（Phase 1137 活实体）——实体若持有
子成员（`M()`→opId 表）即 member-collection。

## `ba6.z(v69, map, list, set, h85)` = 递归子成员解析

```java
for (qo5 child : h85.M()) {              // 每子 opId
  wnd w = y(v69, child, map);            // 递归 y 解析!
  if (w.a!=null) list.add(w.a);           // vnd→已解
  au1.O0(list, w.c);                      // 已解元素并入
  au1.O0(set,  w.b);                      // 未解 op 并入
  set.add(new o09(child));                // 标记 child 已访
}
```

- 对 `h85` 的每子 opId **递归调 `y`** → 深度优先成员树
  展平到 `wnd{list,set}` 累积器。
- `set.add(new o09(child))` = 访问标记（`o09` 实体 id
  包装）——防止环/重复，入未解 set。

## 语义

member-collection 的解析 = DFS 展平：`h85.M()` 每子 →
`y` → vnd/list/set 累积 + `o09` 访问标记。嵌套集合
（`cie`/`hp5` 的 `m4c` member-collection）借此展平。

## Harmony 决策

- member-collection = `{M()→opIds}`；递归 `y` DFS 展平
  + `o09` 访问标记。
- Harmony：同构递归 + visited-set 防环。

## 产出

- fixture `d02-h85-z.mjs`（10 断言）。
- ADR-1086；中文报告。
