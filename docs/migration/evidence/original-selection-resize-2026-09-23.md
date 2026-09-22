# 原版证据：选区覆盖层角柄自由变换（htc.e / qpi.b / fvb.f）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 596 依据。

## 1. 覆盖层状态接口（`htc.java`）

```java
public interface htc extends ktc {
    cmb a();   // 覆盖层矩形
    cmb d();   // 当前变换矩形
    htc e(boolean z, ei3 ei3Var, Float f, Float f2, ei3 ei3Var2);  // 变换入口
    Float g(); // 当前旋转角
}
```

`e()` 参数：`(commit 标志 z, 平移点, 缩放, 旋转, 枢轴点)`——
覆盖层支持缩放 + 旋转的自由变换。

## 2. 选区状态持有矩形 + 旋转（`gtc.java`）

```java
public final class gtc implements htc {
    public final cmb c;    // 起始矩形
    public final cmb d;    // 当前矩形
    public final Float e;  // 起始旋转角
    public final cmb f;    // 基矩形（预览基）
    public final Float g;  // 基旋转角
    ...
    public final htc e(boolean z, ei3 p, Float scale, Float rot, ei3 pivot) {
        ehf ehfVarB = qpi.b(this.f, this.g, ei3Var, f, f2, ei3Var2);
        ...
        return z ? j(this, cmbVar, cmbVarF, f3, cmbVar, f3, 131)      // 提交
                 : j(this, cmbVar, cmbVarF, f3, null, null, 227);     // 预览
    }
}
```

`z` = 提交标志：`false` 预览（只写当前 rect/rotation）、
`true` 提交（基 rect/rotation 一并更新）。

## 3. 变换数学（`qpi.java:50-68`）

```java
public static final ehf b(cmb rect, Float baseRot, ei3 translate,
                          Float scale, Float rotDelta, ei3 pivot) {
    long jE = ei3Var2 != null ? ei3Var2.a : fi3.e(cmbVar);  // pivot=参数??rect 中心
    long j  = ei3Var  != null ? ei3Var.a  : 0L;             // 平移
    float s = f2 != null ? f2.floatValue() : 1.0f;          // 缩放
    float[] m = y18.a();
    y18.f(m, pivotX, pivotY, tx, ty, 0, 0, s, s, 1264);     // 等比缩放+平移（绕 pivot）
    cmb newRect = g(cmbVar, m);                              // 变换矩形角
    Float rot = f3 != null ? f3 + baseRot : baseRot;         // 旋转角叠加基角
    return new ehf(new y18(m), new fi3(newRect), rot);
}
```

旋转不入主矩阵——单独存 `f3`，渲染/落矩形时经 `qpi.f(cmb,rot,m)`
构造**绕新矩形中心**（`fi3.b(cmb)`）的旋转矩阵。

## 4. 手势产出（`avc.java`/`fvb.java`）

```java
// avc.java:487  —— 移动变体：f(id,false, point, null,null,null)
// avc.java:689  —— 变换变体：f(id,false, null, scale, rot非0?rot:null, ei3(pivot))
fvb.f(ttfVarB, false, null, f7, !(f8==0)?f8:null, new ei3(oucVar.i()));
```

`fvb.f(id, z, point, scale, rotation, pivot)` → `htc.e`——
手势一次产出缩放 + 旋转 + 枢轴；旋转为 0 时传 null。

## 5. `msc.c` = selectionHasRotationHandle

`msc = ShowMenuOptions(options=esc, showSubmenu, selectionHasRotationHandle)`
——原版覆盖层存在旋转柄（条件出现），进一步佐证覆盖层支持旋转变换。

## 6. Harmony 侧

Harmony 此前 `SelectionOverlay` 只画虚线框 + 菜单按钮；`SelectionTool`
的 `scaleSelected`/`rotateSelected` 无任何调用方（死代码）。本 Phase
补齐：四角柄 UI + 画布命中 + 自由变换会话 + 撤销提交。
