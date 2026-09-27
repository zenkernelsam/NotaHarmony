# Phase 900 证据 — `be5` 元素变换契约 + `y18` 矩阵助手

## 目的

实名 ModifyPosition 应用的几何语义层。`decompiled_1.0.3`。

## `be5` = 可变换元素接口

```java
public interface be5 {
    k11 G();           // bounds
    qed b();           // scale (qed size)
    v09 f();           // entity-kind enum (865)
    long g();          // id/seq
    fqa h();           // origin 点
    cxc i();           // page 位置
    Float j();         // rotation 度
    default float[] P(fqa);   // 变换矩阵
    default k11 y(k11);       // 边界框变换
}
```

- `qsa extends be5` + `d(uq9,ie8)` = 接受 ModifyPosition
  op 的可变换元素（fi0 实现）。

## `P(fqa)` = T·R·S 变换管线（实证）

```java
float[] P(fqa origin):
    arr = y18.a()                          // I
    if origin != null: y18.l(arr, c(), d())  // T
    if j() != null:    y18.h(t2(rot), arr)   // R (deg→rad)
    if b() != null:    y18.i(arr, w, h)      // S
```

## `y18` = 4×4 矩阵助手（float[16]，列主序）

| 方法 | 语义 |
|------|------|
| `a()` | 单位阵 4×4 |
| `l(arr,x,y)` | 平移（更新 arr[12..15] 列） |
| `h(rad,arr)` | 旋转（弧度） |
| `i(arr,w,h)` | 缩放 |
| `d(arr,yk8)` | 矩形变换（yk8={a,b,c,d}） |
| `b(arr)` | 求逆/转置族 |

`y(k11)`：`yk8 ← k11 quad` + `y18.d(P(null), yk8)` +
origin 平移合成——边界框变换。

## ModifyPosition→几何映射

`ie8` 字段 = `P()` 输入：origin→T、rotation→R(度)、
scale(qed)→S、zIndex→层序（899）、page/target=目标
定位——op 语义即"对 target 元素施加 T·R·S + zIndex"。

## Harmony 侧

Harmony 元素平移/旋转/缩放合成 ↔ T·R·S 管线；
ModifyPosition 应用 ↔ be5.P 语义；度→弧度转换对齐。

## 结论

元素变换契约实名：T·R·S 顺序、度单位、4×4 列主序
矩阵、yk8/k11 矩形族。op→几何语义闭合。
纯文档+fixture 阶段。
