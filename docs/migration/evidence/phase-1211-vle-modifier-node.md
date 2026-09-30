# Phase 1211 证据 — vle 是 Compose Modifier.Node（od8 生命周期）

来源：`defpackage/{vle,od8,n73,j73}.java`。

## `od8` = Modifier.Node 基类

```java
abstract class od8 {
    void Y0()   // = onAttach
    void Z0()   // = onDetach
    g1(node)    // 挂子节点
    // 守卫：
    // "node attached multiple times"
    // "attach invoked on a node without a coordinator"
    // "Cannot detach a node that is not attached"
    // "reset() called on an unattached node"
}
```

## `vle extends n73 → od8` 生命周期

```java
Y0() {              // onAttach
    ijg.g0(this, new ple(this,1));   // 派 ple 动作
    this.a0.m = this.s0;             // 注册进 joe.m
    if (this.c0) g1(this.i0);        // 编辑态→挂 bq4 子节点
}
Z0() {              // onDetach
    k1();                            // 清键盘协程+el8
    this.a0.m = null;                // 注销
}
M() { this.j0.M(); }                 // 转发 u8e 输入复位
N0() { return true; }                // mvc 有效门
```

## 体系确认

`vle`（=n73→od8）本身就是 **Modifier.Node**：
编辑器控制器住在 Compose 修饰符树内，作为根节点
托管 `bq4`/`ol3`/`u8e` 子节点（Phase 1208 委托链的
实体化）——`xp4` 也是同类节点（按 iface 遍历）。

`n73` = **DelegatingNode**（`g1(j73)→j73` 委派子节点 +
`W0`–`i1` 委派生命周期 + `ty8.e` 节点类别位掩码）；
`j73` = DelegatableNode iface。`vle extends n73` 即可
委派子节点的 Modifier.Node，同时经 `xj2.A` 持有
协程作用域（`sle`/`rle`）。

## Harmony 决策

Modifier.Node 树 → ArkUI `CustomComponent` +
`@Component` 生命周期（`aboutToAppear`/`aboutToDisappear`
对齐 `Y0`/`Z0`）+ 子组件树显式持有。

## 产出

- fixture `d02-vle-modifier-node.mjs`（10 断言）。
- ADR-1155；中文报告。
