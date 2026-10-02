# Phase 1461 证据：选区外铬件壳旋转（gsf.c xke.s + isf.d/jsf.g + ms1 旋转系命中）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### gsf.java:44-63 — `c(qe4, mp4, f2, z, j)` 外铬件绘制

```java
float fC = mp4Var.c();            // mp4 旋转角
long jB = mp4Var.b();             // mp4 枢轴 = sbe 中心
dge dgeVarT0 = qe4Var.t0();
((xke) dgeVarT0.G).s(jB, fC);     // 画布绕 sbe 中心旋 fC
try {
    qe4.U(qe4Var, j, sbe leftTop, w|h, ...);  // 2dp 实线界
    if (z) { e(...); b(...); }                // 茎柄 + 四角柄
} finally { zu2.B(dgeVarT0, jE); }
```

**外铬件整体绕框中心旋转**——界、四角柄、旋转茎柄同转，无一遗漏。

### gsf.h 分发（gsf.java:122-160）

- **jsf** 支：`fF0 = jsfVar.g() != null ? fq9.f0(g) : 0` → `c(qe4, new mp4(u64.b(sbe), sbe, fF0, false, 0), f2, true, e)`——灰盒 `e=#FFB3B3B3`，**旋转角 = `jsf.g()`**（jsf.java:98 `g()=this.e`，组选区携带的 Float 旋转字段）。
- **isf** 支：`Float f3 = isfVar.d` → 同样 `fF0=fq9.f0(d)` → `c(...)`——**旋转角 = `isf.d`**（isf.java:15 字段 d，`isf.e()` 变换提交时 `j(this,...,f3,f3,...)` 写入 —— 即会话旋转后外盒保持旋转，重选重建 isf 时归零）。
- **lsf/hsf** → return（无外盒，成员级铬件承担）。

### isf.d 生命周期（isf.java:106-138 `e(z,...)`）

`y7jVarG = hsm.g(this.b, this.e, s64Var, f, f2, s64Var2)` 变换后 `f3=H`（旋转增量后的壳角）→ `z=true` 支 `j(this, sbeVar, sbeVar, sbeVarH, f3, f3, ...)`——**d 与 e 同写新角**。选区重建（z6c case6 `new isf(...)`）时 d=null → 外盒回轴对齐。

### ms1.java:295-327 — 旋转系命中

角柄命中 `|dx|<f15 ∧ |dy|<f15` 在 `kw9.c` 旋入的**旋转系**内测四角；旋转柄端点同源。Harmony 等价=触点绕框中心反旋 −θ 再在未旋转壳上测。

## Harmony 落点

- `uniformRotationUnrotatedScreenRect()`（早期 yxi.e 命中移植所建）= 统一旋转成员的去旋并集屏框 + θ——与 isf.d/jsf.g 同源等价（会话 transform 旋转实时反
  映在成员 rotationRadians；jsf.g 以组叶子公共旋转为代理——Harmony `OriginalSelectionGroup` 无旋转字段）。
- `selectionChromeGeom()`/`unrotateChromePoint()`/`selectionScreenCorners()`（旋转屏角）构成命中层。
- 覆盖层：铬件块画在未旋转 `selectionChromeRect` 上，外层 Stack `.rotate(angle, center=框中心)`——`xke.s(center,θ)` 的 ArkUI 等价。
- wtf 轴分解：`resizeAxisVecX/Y` = 对角 D 在框轴单位向量上的投影；`resizeSelectedAxes` 增 `shellRadians` 参数走 `R(θ)·diag(sx,sy)·R(−θ)` 共轭缩放。

## 差异登记

- 纯笔画壳（含笔画的 isf/jsf）：笔画旋转烘进 `pathPoints`，无 rotationRadians 载体 → 壳 θ=0（与 yxi.e 命中模型同款缺口，登记延续）。
- `jsf.g()` 为组实体持久旋转字段；Harmony 组模型无该字段——以成员叶子公共旋转代理（组的成员旋转一致时等价）。
