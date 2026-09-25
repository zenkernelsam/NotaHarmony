# Phase 755 证据：Zoom 面板 AnimatedVisibility 靠缘滑入/滑出

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0695（面板落地）、ADR-0702（几何修正）、ADR-0703（本 Phase）。

## 1. 原版证据（fgg.b，defpackage/fgg.java:74-201）

```java
boolean z2 = ggg.b == qeg.I;                 // 顶停靠
iw0 iw0Var = z2 ? is1.S : is1.U;             // 滑入缘：Top / Bottom
ky3 ky3VarA = ey3.c(s01.Y(500, 0, iq2Var, 2), iw0Var, 12)
               .a(ey3.d(s01.Y(500, 0, iq2Var, 2), 2));   // slideIn + fadeIn
c44 c44VarA = ey3.j(s01.Y(500, 0, iq2Var, 2), iw0Var, 12)
               .a(ey3.e(s01.Y(500, 0, iq2Var, 2), 2));   // slideOut + fadeOut
l96.J(z3=isShown, pd8VarI, ky3VarA, c44VarA, null, cgg);  // AnimatedVisibility
```

- `s01.Y(500, 0, iq2, 2)`：500ms tween、0 延迟、iq2 插值器。
- `cs3.java:9`：`iq2 a = new iq2(0.25f, 0.1f, 0.25f, 1.0f)` —— 标准
  ease 三次贝塞尔。
- `ey3.c/.d` = slideIn+fadeIn 组合、`ey3.j/.e` = slideOut+fadeOut 组合；
  边缘取停靠侧（顶停靠从 Top 滑入、底停靠从 Bottom）。

## 2. Harmony 修复

`NoteCanvasView.ets` zoom 挂载 Column 追加：

```ts
.transition(TransitionEffect
  .move(this.zoomDockBottom ? TransitionEdge.BOTTOM : TransitionEdge.TOP)
  .combine(TransitionEffect.OPACITY)
  .animation({ duration: 500, curve: Curve.Ease }))
```

`Curve.Ease` = cubic(0.25,0.1,0.25,1) 与 `cs3.a` 精确一致；
`TransitionEdge` 方向映射停靠缘；`.combine(OPACITY)` 对应
`slide∘fade` 组合进出。

## 3. 近似登记

- 原版拖拽中连续 y 位移动画（z5c.H + l6a 浮点流）保持 ADR-0695 登记的
  落点判定近似；slide/fade 进出本身已等价。

## 4. 文件清单

- `note/src/main/ets/ui/editor/NoteCanvasView.ets`：挂载 Column
  `.transition`。
- `docs/migration/replays/d02-original-zoom-view.mjs`：+4 p755 钉。
