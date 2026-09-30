# Phase 1207 证据 — vle 绑入 Compose 节点树（ry8/jw6/mv6）

来源：`defpackage/{vle,ry8,jw6,mv6,no3,dt7,hw6,nv6,r28,l28,ow9}.java`。

## `vle` 节点绑定点

| 方法 | 参数类型 | 角色 |
|---|---|---|
| `f(ry8)`（o65） | `ry8` = **Compose LayoutNode** | 接收编辑器容器节点 |
| `x0(jw6)`（lo3） | `jw6` = **DrawScope** | 接收绘制上下文 |
| `r(mv6)`（kv6） | `mv6` = LayoutCoordinates | 坐标参考（空实现） |

## `ry8` = Compose LayoutNode

```java
abstract class ry8 extends dt7 implements l28, mv6, ow9 {
    hw6 W;          // measure/layout 协调器
    ry8 Z, a0;      // 父/子链
    ix4 d0; r93 e0; // lambda + Density
    nv6 f0; r28 h0; jk8 i0; yk8 l0;
}
```

`dt7 extends cla implements dg8,s28` = 节点基类；
`hw6 implements c42,ow9,m42` = 度量/布局协调；
`nv6` = removed 类；`r28`/`l28`/`ow9` = 能力 iface。

## `jw6` = DrawScope 宿主

```java
final class jw6 implements no3 {
    xd1 I;             // CanvasDrawScope 委托
    lo3 J;             // ← 编辑器能力接口回链!
    B0(long×3,float,po3,qu1,int) → I.B0(...)  // draw
    B/C0 → I.B/C0                             // Density
}
```

`no3 extends r93` = DrawScope iface（draw 调用 +
dp↔px）；`jw6` 把 **编辑器绑进 Compose 绘制管线**
（`lo3 J` = vle 的接口回链）。

## `mv6` = LayoutCoordinates

```java
interface mv6 {
    mv6 A();                       // 父坐标
    long G/H/K/L/c(...);           // 坐标变换
    cmb J(mv6,boolean);            // 包围盒
    void i(float[]); k(mv6,float[]); // 矩阵
}
```

## 判定

编辑器 = Compose 自定义 LayoutNode：`ry8` 节点 +
`jw6` DrawScope + `vle` 控制器 —— `f`/`x0` 是节点树
注入点；`mv6` 坐标系把节点位置映射到 GL 场景
（对齐 `t0g` ViewportState 的 viewport rect — Phase 1183）。

## Harmony 决策

Compose LayoutNode/DrawScope → ArkUI `CustomComponent`
/`@BuilderParam`/`Canvas` 绘制上下文 + `componentUtils`
坐标变换。

## 产出

- fixture `d02-vle-compose-node.mjs`（10 断言）。
- ADR-1151；中文报告。
