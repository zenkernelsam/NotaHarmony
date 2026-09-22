# 原版证据：选区覆盖层旋转柄（msc.c selectionHasRotationHandle）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 597 依据。

## 1. 旋转柄存在性（`msc.java`）

```java
public final class msc implements qsc {
    public final esc a;      // SelectionMenuOptionsList(main+overflow)
    public final boolean b;  // showSubmenu（MORE 展开）
    public final boolean c;  // selectionHasRotationHandle
    // toString: "ShowMenuOptions(..., selectionHasRotationHandle=...)"
}
```

选区菜单/覆盖层状态显式携带 `selectionHasRotationHandle`——
原版覆盖层存在**专用旋转柄**（条件出现）。

## 2. 旋转通道（`qpi.b` / `fvb.f`，Phase 596 证据续）

`fvb.f(id, z, point, scale, rotation, pivot)` → `htc.e`——
同一变换入口既收角柄自由变换也收旋转柄：

- `qpi.b`：`f2=null → scale=1.0f`——旋转柄不传缩放即纯旋转；
- `f3`（旋转角增量）叠加基角 `this.g`，经 `qpi.f(cmb,rot,m)`
  构造**绕新矩形中心**（`fi3.b(cmb)`）的旋转矩阵；
- `gtc.e`/`htc.e` 的 `g()` 返回当前旋转角——覆盖层矩形随
  旋转角倾斜渲染（角柄落在旋转后矩形角上）。

## 3. 旋转柄手势语义

`avc` 的变换手势一次产出 `scale + rotation + pivot`——
旋转柄 = pivot 固定于选区中心、scale≈1 的环绕拖拽：
指针绕中心角位移 → `f3`（角度增量）；径向分量不产出缩放。

## 4. Harmony 侧

Phase 596 已落地角柄自由变换会话（`resizeSelected` =
R(缩放后中心)·S(anchor)·base）。本 Phase 补齐专用旋转柄：
顶边中点上方 28vp 圆点；命中进入同一 `selectionResize` 会话，
`resizeIsRotate` 使 scale 锁 1、anchor=选区中心——即
`qpi.b` 的 `f2=null` 等价路径。
