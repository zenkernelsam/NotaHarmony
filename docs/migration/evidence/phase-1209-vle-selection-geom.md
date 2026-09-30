# Phase 1209 证据 — vle.G 选区几何管线（wh8/wpe/ip4）+ A 输入转发

来源：`defpackage/{vle,wh8,wpe,ip4,joe}.java`。

## `vle.A(iqa,jqa,long)` = 输入转发

```java
public final void A(iqa iqaVar, jqa jqaVar, long j) {
    this.j0.A(iqaVar, jqaVar, j);   // → u8e Density 输入控制器
}
```

## `vle.G(ip4)`（mp4）= 选区矩形计算

```java
wpe wpeVar = joeVar.b.c();           // 当前文本块
if (wpeVar != null && joeVar.d) {    // 编辑态
    ele e = joeVar.a.f();
    if (!jqe.d(e.L)) {               // 选区非坍缩
        int s = (int)(e.L>>32), t = (int)(e.L & 0xFFFFFFFF);
        wh8 w = wpeVar.b;            // 段落 Layout 适配器
        if (w.f(s) == w.f(t)) {      // 同行
            float x1 = w.b(s,true), x2 = w.b(t,true);
            int ln = w.f(s);
            cmb = new cmb(min(x1,x2), w.i(ln), max(x1,x2), w.d(ln));
        } else                        // 跨行
            cmb = wpeVar.j(g(j),f(j)).e();   // 路径包围盒
    }
    // 裁剪至可视 LayoutCoordinates 视口
    cmb = cmb.k(mv6Var.J(mv6E,false).f());
} else cmb = t3i.O;                  // 空
ip4Var.f(cmb);                       // → 浮动菜单/手柄
```

## `wh8` = `android.text.Layout` 段落适配器

`{Layout upeVar.f}`；`f(i)→line`、`b(i,bool)→x`、
`i(line)→top`、`d(line)→bottom` —— 选择手柄/光标的
几何换算（`StaticLayout.getLineForOffset` 等）。

## `wpe`/`ip4`/`joe`

- `wpe{a,b(wh8),c,d,e,f}` = 文本块值类；`j(i,i2)→jt` 选区路径。
- `ip4.f(cmb)` = 选区矩形消费 iface（ActionMode/手柄定位）。
- `joe.d` = 编辑态标志；`joe.c(wpe,ele)` = 光标矩形。

## Harmony 决策

`android.text.Layout` → ArkUI `Paragraph`/`TextController`
行/偏移几何；`ip4` 选区矩形 → 浮动选择菜单定位
（`MenuOptions`/`SelectionMenu`）。

## 产出

- fixture `d02-vle-selection-geom.mjs`（10 断言）。
- ADR-1153；中文报告。
