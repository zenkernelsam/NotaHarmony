# Phase 1456 证据 — 移动拖拽吸附旋转门（guf.b / twm.e / ne1.w）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### guf.b(xtf, j) — 移动吸附门（guf.java:104-160）

```java
public final long b(xtf xtfVar, long j) {
    ne1 ne1Var = this.j;                    // 会话期吸附引擎
    if (ne1Var != null) {
        msf msfVarC = xtfVar.c();           // initialSelectionState
        Float fJ;
        if (msfVarC instanceof ksf) {       // isf/jsf 集合选区
            fJ = ((ksf) msfVarC).g();       // 选区态旋转
        } else {
            // lsf 单元素：元素自身旋转
            fJ = (hv6VarN = n((lsf) msfVarC)) == null ? null : hv6VarN.j();
        }
        if (!twm.e(fJ)) {                   // ★ 旋转非零 → 跳过吸附
            kdcVar = (snap 候选点集, 原点)：
              sbe 界 → u64.c 四角 + u64.b 中心；
              lsf → 元素轮廓点 og0.e/s40.t + og0.h/i 中心
            mkg m = ne1Var.w(origin, j, listC);
            z(m.b());                       // 渲染对齐导线
            return m.a();                   // 校正后的位移
        }
    }
    return j;                               // 原样返回
}
```

### twm.e（twm.java:73）

```java
public static final boolean e(Float f) {
    return (f == null || zx7.p(f, 0.0f)) ? false : true;
}
// 即：fJ != null ∧ fJ != 0 → 已旋转 → !e() 为 false → 不吸附
```

### ne1.w（ne1.java:410-445）— 候选点吸附引擎

- `this.b` = (rkg 吸附线, 容差 rkg.a()/f) 对集——`guf.d` 会话期构造：
  `og0.d(note, page, set, z ? u64.b : odf.d(exj.d, f))` 页面几何 +
  缩放容差。
- 候选点 = 选区角/中心点集 + 位移偏移；
- 每轴独立胜者（h3a 桶累积）→ `mkg(校正后偏移, 导线集)`。
- `guf.z(list)`：导线 → 屏幕坐标 → `a.j.l(null, list)` 渲染通道。

## Harmony 映射

| 原版 | Harmony |
|------|---------|
| `guf.b` 每帧吸附 | `planSelectionSnap(dx,dy)` 两 move 调用点 |
| `twm.e(fJ)` 旋转门 | `selectionSnapRotation()` ≠0 → 直接返回 {0,0} |
| `ksf.g()` 选区旋转 | `state.transform` 旋转分量 atan2(m3,m0) |
| `hv6.j()` lsf 元素旋转 | 形状 `shapeVertexRotation` / 笔画 transform 旋转 / 文图数 `rotationRadians` |
| `ne1.w` 校正偏移 | `planOriginalSnapMove` 胜者 `plan.dx/dy` 增量 |
| `guf.z` 导线渲染 | `snapGuides` + renderFrame accent 导线 pass |
| lsf 候选=元素轮廓点 | bounds 锚点（`originalSnapMoveAnchors`）——登记近似 |

## 裁决

旋转选区（含旋转元素）移动拖拽在原版**完全跳过吸附**——
Harmony 此前无此门，旋转选区仍会吸附产生跳变。已修复。
