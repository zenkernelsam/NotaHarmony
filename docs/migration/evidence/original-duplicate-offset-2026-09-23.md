# 原版证据：DUPLICATE 粘贴位置偏移（cg2.a()）— Phase 618

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## lg2.java:171-191 — b()（DUPLICATE 协程）的位置计算

```java
long jA = cg2VarB.a();          // 偏移向量
long jC = cg2VarB.c();          // 基准点
float fE = ei3.e(jA);           // jA.x
float f2 = ei3.f(jA);           // jA.y
float fE2 = ei3.e(jC);          // jC.x
Object objE = e(cg2VarB,
    ei3.a(fE2 + fE, ei3.f(jC) + f2),   // 位置 = c() + a() 分量相加
    jA, n8eVar);
```

## cg2.java:21-26,33-35 — a()/c() 语义

```java
public final long a() {
    cmb cmbVar = this.b;                 // 剪贴板负载的选区矩形
    float fMin = Math.min((f - cmbVar.a) * 0.1f, 30.0f);
    return ei3.a(fMin, fMin);            // (min(宽*0.1,30), 同值)
}
public final long c() {
    return fi3.b(this.b);                // 矩形中心
}
```

- `fi3.java:34-38`：`b(cmb) = ((a+c)/2, (b+d)/2)` = 矩形中心。
- 结论：原版 DUPLICATE 副本中心 = 原选区中心 +
  `min(选区宽×0.1, 30)`（x/y 同值，页面单位）——副本向右下
  错开一小段。常规 PASTE 不经过 `cg2.a()`，无此偏移。

## Harmony 差异与修复

旧实现：`duplicateSelected` 用 `selectionPasteTarget()`（选区
矩形中心，与 PASTE 共用）——副本与原选区**完全重合**。

Phase 618：`duplicateSelected` 内计算
`rectWidthCanvas = (selectionRect.right - left) / zoom`
（屏幕像素 → 页面单位），`nudge = min(width×0.1, 30)`，
粘贴目标 = `target + nudge`（x/y 同加）。PASTE 路径与
`selectionPasteTarget` 本身不变。
