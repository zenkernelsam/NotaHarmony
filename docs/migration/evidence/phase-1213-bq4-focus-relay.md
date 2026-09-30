# Phase 1213 证据 — bq4 焦点/事件中继子节点

来源：`defpackage/{bq4,xp4,bq1}.java`。

## `bq4 extends n73 implements mvc,o65,q52,sn9,vff`

```java
xp4 d0 = new xp4(i, new bq1(2, this, bq4.class,
    "onFocusStateChange",
    "onFocusStateChange(FocusState;FocusState)V",0,3));
g1(d0);              // ← FocusEventModifierNode 委派
```

`bq1` = `onFocusStateChange` 方法引用（kotlin
`FunctionReference`——焦点变化回调），`xp4` =
承载它的 Modifier.Node —— 即 **FocusEventModifierNode**。

## `bq4.h(xvc)` = 语义填充

```java
xvc.g(wvc, Boolean zB);                    // focused 态
xvc.g(ivc.w, new y6(null,
    new dp(0,this,bq4.class,"requestFocus","requestFocus()Z")));
                                          // ← requestFocus 动作
```

`ivc.w` = `SemanticsActions.RequestFocus` —— 暴露
焦点请求无障碍动作（Phase 1206 语义无衔）。

## `bq4.j1(wj8,t76)` = 事件中继

```java
if (…) wj8Var.b(t76Var);                   // trySend
else xj2.A(U0(),…,new e2(wj8,t76,
    wc6?.d1(new zl2(22,wj8,t76)),…));      // 挂起 emit
```

`k1(wj8)` = 通道重绑时向旧通道补 `ap4(zo4)` 结束事件
—— **保证手势对账完整**（Phase 1202 down/end 配对）。

## `s()→Object`/`t0()`/`f(ry8)`/`V0()/a1()`

`vff` 能力发现 iface（节点局部/接口查找）+ 焦点/
布局钩子。

## 判定

`bq4` = **焦点+事件中继节点**：`FocusEvent` 回调 +
`requestFocus` 语义 + `t76` 中继（重绑时补结束事件）
—— vle 语义/选择/媒体 iface 的实际落点之一。

## Harmony 决策

`FocusEventModifierNode`/`requestFocus` → ArkUI
`focusControl`/`focusable` + `onFocus` 回调；
`j1` 事件中继 → Harmony 事件转发 + 结束事件补齐。

## 产出

- fixture `d02-bq4-focus-relay.mjs`（10 断言）。
- ADR-1157；中文报告。
