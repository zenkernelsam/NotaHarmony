# Phase 1132 证据 — njj.t 序列树 DFS 遍历 + n4c.a 码点换算

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `njj.t(jxc, exc, rwc, ix4)` = 锚点 DFS 遍历

```java
if (exc==null) { s(jxc, rwc, cb); return; }      // 空锚→全走
qwc root = Q(jxc, ixc.a);                        // 哨兵根
qwc target = Q(jxc, exc);                        // 锚节点
LinkedHashMap m = m(target);                     // parent→child map
root.d(hr5);                                     // 根锚
exc2 = m.get(hr5);                               // firstChildId
List p = p(jxc, hr5);                            // 子节点表
int iU = u(hr5, p, exc2);                        // 锚在表中索引
y80 stack push vz3{iU, p};                       // DFS 栈
while (!empty) vz3{i,list}: i>=size→pop else
  swc=list[i] → ix4 cb(i, node,…)                // 逐节点回调
```

- `Q` = 锚→`qwc` 节点查；`m` = parent→child map；`p` = 子表；
  `u` = 锚在子表索引；`vz3` = `{idx,list}` 栈帧。
- 迭代 DFS 从根 firstChild 到锚 → 找插入点/前驱。
- `ix4` 回调 = 每节点的访问者（`wc`/`zm7` 插入/找未删实现）。

## `n4c.a(CharSequence, i)` = 码点→char-index

```java
lz0 → i                       // 零换算（已字节/预布局）
ry1 → ry1.i(i)                // 自定义
else Character.offsetByCodePoints(cs, 0, i)   // 真码点偏
```

## `n4c.b(or5,mr5)` = `s3c` 段遍历（布局）

`n4c.c(List)` = 文本抽取（`atf.g()`）。

## Harmony 决策

- 锚定位 = 迭代 DFS（栈帧 {idx,list} + 回调）。
- 码点→索引 = UTF-16 offsetByCodePoints；lz0/ry1 短路。

## 产出

- fixture `d02-tree-walk.mjs`（10 断言）。
- ADR-1076；中文报告。
