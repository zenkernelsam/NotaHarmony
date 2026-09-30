# Phase 1141 证据 — ba6.y per-op 实体解析器

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ba6.y(v69, qo5, dedupeMap)→wnd`

```java
ny3 ny3 = v69.c;                       // 界服务
LinkedHashSet set; ArrayList list; vnd vnd=null;

if (K(op, v69.j())) {                  // 墓碑？
  h85 h = v69.k().get(op);             // member-collection
  if (h!=null) z(v69, map, list, set, h);   // 解子成员
  return new wnd(null, set, list);     // vnd=null→未解
}
ly3 e = v69.r().I.get(op)              // qja 存贮
     ?? v69.l().get  (s06)              // bja 存贮
     ?? v69.p().get  (m4d)              // bja 存贮
     ?? v69.i().get;                    // uia 存贮
if (e==null) {
  h85 h = v69.k().get(op);             // member-collection 解子
  if (h!=null) z(v69,map,list,set,h);
} else if (e instanceof be5) {          // 可变换
  z0 = (fromQja);                       // 是否根实体
  num = (!z0 && e instanceof yy3 && (s06|m4d))
        ? yy3.E() : null;               // 子索引?
  if (num==null) bounds = be5.y(be5.G());        // 自变换界
  else { k11 = ny3.e(id,num) ?? (be5.y(G())+ny3.a 缓存) }
  bmb = do6.i(be5.i(), v69.t);          // page→crop
  … → vnd 空间节点
}
```

## 语义

- 墓碑 op → 仅解 `h85` member-collection 子成员；
  `wnd{null,set,list}` = 未解（vnd null → `e0a.b`）。
- 活 op → 4 存贮链查 `ly3`（r→l→p→i）。
- 未知 → `h85` 子解；`be5` → 界（自变换 `y(G())` 或
  `yy3.E` 子索引 + `ny3` 缓存）→ `do6.i` page→crop →`vnd`。

## `wnd{vnd a, LinkedHashSet, ArrayList}`

3 字段解析产物：空间节点 + 未解 set + 已解元素 list
（`e0a` 的 `a`←list+vnd、`b`←set）。

## `ba6.z` = member-collection 子成员解析辅助

`z(v69, map, list, set, h85)` —— 对 `h85` 子成员递归集。

## Harmony 决策

- op 解析 = 墓碑→member-children；活→4 表链查；
  be5→界（自变换/`E()` 子索引缓存）→crop→vnd。
- Harmony：同构 resolver + bounds 缓存 + unresolved set。

## 产出

- fixture `d02-ba6-y.mjs`（10 断言）。
- ADR-1085；中文报告。
