# Phase 1253 证据 — od8 Modifier.Node 基座

来源：`defpackage/{od8,j73,tn9,ry8,xc6,zo7}.java`。

## `od8 implements j73` = Modifier.Node

```java
hi2 J;                 // coroutine scope（owner 提供）
int K;                 // kind-set（委托聚合）
od8 M,N;               // parent/child 链
tn9 O;                 // node-coordinator
ry8 P;                 // LayoutNode owner
boolean Q,R,S,T; fp U; boolean V;
od8 I = this;          // 自身 node
int L = -1;            // 聚合 kind-mask（未算=-1）
```

## 生命周期

```java
U0() → hi2;   // coroutine scope（xc6 Job 挂 owner pp）
V0() → attached?
W0() — "node attached multiple times"
        "attach invoked on a node without a coordinator"
X0() — "Cannot detach a node that is not attached"
        s01.n(J, ModifierNodeDetachedCancellationException)  // cancel
Y0()/Z0()  onAttach/onDetach 钩子
a1()/b1()   onReset/reset（"reset() called on unattached"）
c1()/d1()   attach/detach 内部（"node detached multiple times"）
```

## 语义

- `od8` = **Compose `Modifier.Node` 基类**：`I`=self、
  `L`=kind-mask、`K`=kind-set、`M`/`N`=parent/child、
  `P`=LayoutNode、`J`=节点协程域；
- `U0` = `n0(this)` owner `pp` 的协程 ctx + `xc6` Job —
  节点级结构化协程；
- `X0` detach 时 `ModifierNodeDetachedCancellationException`
  cancel `J` —— 节点 detach 自动取消协程；
- `W0`/`X0`/`d1` = attach/detach 双重守卫；
- `ry8`/`tn9`/`fp`/`zo7.Q` = LayoutNode/coordinator/Job。

## Harmony 决策

Modifier.Node+协程 scope+kind-mask → Harmony 组件
Node+协程域+能力位 —— 节点基座语义保真。

## 产出

- fixture `d02-modifier-node.mjs`（10 断言）。
- ADR-1197；中文报告。
