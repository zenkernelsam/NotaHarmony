# Phase 1251 证据 — xp4 Modifier.Node 遍历/焦点事件

来源：`defpackage/{xp4,ty8,sp4,qz6,rd8,zv0,l96}.java`。

## `xp4` = FocusEventModifierNode

```java
xp4 extends od8 implements q52,kv6,sn9,rd8,j73 {
    boolean W; wx4 X;                  // onFocusStateChange λ
    boolean Y,Z; int a0;               // kindMask (ctor)
    g1(i) = l96.I0(this, i).ordinal(); // 焦点状态
    h1(sp4, sp4) → X.invoke(old,new);  // 焦点变更回调
    i1()/k1()/l1() → visitAncestors;   // 节点链遍历
}
```

## `visitAncestors` = kind-bitmask 节点链走查

```java
// "visitAncestors called on an unattached node"
if (((od8)hw6.o0.O).L & 5120) != 0 {   // 5120=focus kind
    if (od8Var2.K & 5120) != 0 {
        if ((i & USER_VERIFY_ALL)!=0) → ...
        if ((i & MAX_SIZE)!=0 && M instanceof n73) → 遍历委托
    }
}
```

沿 `od8` 链（`hw6.o0.O` LayoutNode 链）按 `K & kindMask`
过滤节点 —— `5120`/`3072`/`2048` = Compose node-kind
位（focus/focusTarget/…）。

## `k1()→qz6` = 焦点 owner 查找

`rd8Var.d0().c(zv0.a())` —— `zv0` = focus-event key
（FocusEventRegistry）→ `qz6` = 焦点 owner。

## 语义

- `xp4` = FocusEventNode：注册 `onFocusStateChange` +
  `visitAncestors` 沿节点链找 focus 父级；
- `a0`/`K` = **node-kind bitmask**（`od8.L`/`K` 位标记）；
- `sp4` = FocusState（Focused/Active/etc.）；
- `qz6`/`rd8`/`zv0` = focus registry/owner/key。

## Harmony 决策

Modifier.Node 遍历 → Harmony 组件树 + focus 链 +
`onFocus` 回调 —— 节点遍历语义保真。

## 产出

- fixture `d02-node-traversal.mjs`（10 断言）。
- ADR-1195；中文报告。
