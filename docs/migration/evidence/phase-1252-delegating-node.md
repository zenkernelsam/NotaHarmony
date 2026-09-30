# Phase 1252 证据 — n73 DelegatingNode 机制

来源：`defpackage/{n73,ty8,od8,j73}.java`。

## `n73 extends od8` = DelegatingNode

```java
int W = ty8.e(this);            // 本节点聚合 kind-mask
od8 X;                          // delegate 链头

W0/X0/b1/c1/d1                  // delegate 生命周期
e1(od8)                         // delegate 插入
f1(ry8)                         // LayoutNode attach
```

## `g1(j73)` = delegate 注册

```java
od8VarN0 = j73.n0();             // delegate 的 backing node
if (od8VarN0 != j73Var) {        // 它是 node
    "Cannot delegate to an already delegated node"
    "Cannot delegate to an already attached node"
    iF = ty8.f(od8VarN0);         // delegate kind-mask
    od8VarN0.K = iF;
    "Delegating to multiple LayoutModifierNodes..."
    i1(iF | this.K, false);       // kind-mask 合并
    ty8.a(od8VarN0, -1, 1);       // attach
}
return j73Var;
```

`h1(j73)` = undelegate（autoInvalidateRemovedNode）。

## `ty8` = NodeKindSet 工具

`e(this)` = 自身聚合 kind；`f(od8)` = 子节点 kind；
`a(od8,-1,1)` = attach/invalidate；`od8.K`/`L` = kind
位标记。

## 语义

- `n73` = Compose `DelegatingNode`：`g1` 注册 delegate
  node、合并 kind-mask、守卫 already-delegated/attached；
- `W = ty8.e` 自身聚合、delegate `K` 合并 → 节点树
  `K & kindMask` 匹配（Phase 1251 `xp4` 遍历依赖）;
- `j73.n0()` = delegate→node 桥（iface 可非 node）;
- `i1`/`ty8.a` = kind-mask 更新 + attach 触发。

## Harmony 决策

DelegatingNode+kind-mask → Harmony 组件 Node 组合
+能力位标记 —— 委托节点语义保真。

## 产出

- fixture `d02-delegating-node.mjs`（10 断言）。
- ADR-1196；中文报告。
