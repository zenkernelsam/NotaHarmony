# Phase 1266 证据 — mv6/ry8/hw6/dt7/jw6 布局/绘制节点

来源：`defpackage/{mv6,ry8,hw6,dt7,jw6,no3,xd1}.java`。

## `ry8` = Compose `LayoutNode`

```java
ry8 extends dt7 implements l28, mv6, ow9 {
    hw6 W;                 // measure/layout coordinator
    ry8 Z, a0;             // parent/child LayoutNode
    r93 e0;                // density
    nv6 f0;                // LayoutDirection
    r28 h0; jk8 i0;        // layout/lookahead
}
```

## `dt7` = `NodeCoordinator`（每 Modifier 的布局协调）

`extends cla implements dg8,s28` — `{at7 N, ela P,
et7 T, h1c U, zk8 V}` + `D0→at7` + `E0(ry8)`。

## `hw6` = `MeasureResult`/LayoutCoordinator

`{I,K,L constraints,...,Q parent}` + `A0` Undefined-
intrinsics 哨兵 + `B0`/`C0` 默认。

## `jw6` = `DrawScope`

```java
jw6 implements no3 {
    xd1 I;                 // 绘制委托
    lo3 J;                 // 编辑器 Node 引用（!）
    B(long) dpToPx; C0(int); F0/I0/L0/P;
    Q0(f31)=drawCircle; S0=drawLine; I=...;
}
```

`vle.f(ry8)` 绑 LayoutNode；`x0(jw6)` DrawScope 接入
编辑器（`lo3 J`=vle 回引用）—— 编辑器进绘制管线。

## 语义

`ry8`(LayoutNode)+`dt7`(NodeCoordinator/Modifier 布局)+
`hw6`(MeasureResult)+`jw6`(DrawScope+`lo3` 编辑器 ref) —
— Compose 布局/绘制内部：`vle` 通过 `lo3` 绑进绘制域。

## Harmony 决策

LayoutNode/DrawScope → Harmony 组件 `@Component`+
`Canvas`/`onDraw` 回调 —— 布局/绘制语义保真。

## 产出

- fixture `d02-layout-draw.mjs`（10 断言）。
- ADR-1210；中文报告。
