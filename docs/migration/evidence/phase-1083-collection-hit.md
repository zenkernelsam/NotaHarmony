# Phase 1083 证据 — ba6.M 父集合解析 + O 偏移命中 + P 包围过滤

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `ba6.M(v69, qo5) → o4c` = 实体父集合解析

```java
e4c default = v69.o();             // 默认根集合
if id==null → default
if K(id, al2VarJ) → null           // tombstone
oy0 e = qja.r().I.get(id) ?: uia.i().get(id);
if e instanceof xhe → ((cie)e).c   // 实体的成员集合
else if e instanceof hp5 → hp5.d
return m4c 或 default
```

实体知道自己所属集合（`m4c` 字段）——组/嵌套归属。

## `ba6.O(float y, List<fw4>) → ehf` = 垂直偏移命中

```java
累加 fw4.b(bmb).d().c()（项高），f2>y 时命中
→ ehf{index, fw4.a(id), apb.g(0,f2) 偏移}
```

= **滚动 Y→项命中**（页面/块的 y 位置定位，用于分页滚动）。

## `ba6.P(k11 bounds, list)` = 包围相交过滤

`{f=b.b, f2=b.d}` 按包围盒筛选项。

## Harmony 决策

- 实体持父集合引用（`m4c`）；`M` 解析归属。
- `O` = y-偏移命中（滚动定位）。

## 产出

- fixture `d02-collection-hit.mjs`（10 断言）。
- ADR-1027；中文报告。
