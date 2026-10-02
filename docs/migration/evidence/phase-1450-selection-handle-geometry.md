# Phase 1450 证据：1.4.2 `gsf.b`/`gsf.e` 选区手柄几何与式样

## 原版证据（`decompiled_1.4.2/sources/defpackage/gsf.java`）

### 角柄（`gsf.b:30-42`）

```java
float f3 = 12.0f / f2;   // 半径 12dp（页单位随 zoom 除）
float f4 = 10.0f / f2;   // 半径 10dp
for (s64 corner : u64.c(sbeVar)) {     // 四角
    qe4.u0(qe4Var, p52.e, f3, corner.a, null, 120);  // 白圆
    qe4.u0(qe4Var, a,     f4, corner.a, null, 120);  // gsf.a 蓝圆
}
```

- `qe4.u0(color, radius, center)`：双层同心圆——外层 `p52.e` 白
  （半径 12dp）+ 内层 `gsf.a=#FF4278FF`（半径 10dp）。
- 视觉直径 24/20dp；命中半径另有独立容差域。

### 旋转柄（`gsf.e:84-103` + `gsf.i:164-168`）

```java
long jI = i(sbeVar, layoutDirection);   // 锚点
float f3 = (56.0f / f2) * (dir == LTR ? 1 : -1);  // 茎长 ±56dp
float f4 = 2.0f / f2;                    // 茎宽 2dp
qe4.U(qe4Var, d, jI, packed(f3, f4), ...);        // #FF444DE0 茎线
// 端点圆心 = jI + (f3, f4/2)
qe4.u0(p52.e, 16.0f/f2, endpoint);   // 白圆半径 16dp
qe4.u0(d,      14.0f/f2, endpoint);   // #FF444DE0 半径 14dp
```

`gsf.i` 锚点：

```java
return s64.a(dir == LTR ? sbeVar.c : sbeVar.a, (sbeVar.b + sbeVar.d) / 2.0f);
```

→ **右（RTL 左）边中点**，茎沿水平方向延出 56dp，端点双层圆
（视觉直径 32/28dp），端点中心 y 下偏移茎宽一半（1dp）。

## 关键纠偏

此前 Harmony 实现按 iOS 惯例把旋转柄放在**顶边中点上方 28vp**——
1.4.2 精证为**侧边中点 + 水平茎**（Notability Android 形态）。

## Harmony 对齐

- `SelectionOverlayLayout`：`SELECTION_HANDLE_DOT_OUTER/INNER`=24/20vp、
  `SELECTION_ROTATE_HANDLE_STEM`=56vp、`SELECTION_ROTATE_DOT_OUTER/INNER`
  =32/28vp（移除 `SELECTION_ROTATE_HANDLE_OFFSET`）。
- `SelectionOverlay`：四角双层圆（白 Ø24 + `#FF4278FF` Ø20 居中）；
  旋转柄 `Rect` 茎（右边中点→+56vp、2vp、`#FF444DE0`）+ 端点双层圆
  （白 Ø32 + `#FF444DE0` Ø28）。
- `NoteCanvasView.selectionRotateHandleAt`：命中域迁至茎端点
  （`rect.right+56, midY+1`，半径 22vp 不变）。

## 登记差异

- RTL：原版左边缘 + 反向茎；Harmony 固定右边缘（登记，布局方向
  API 查询留待后续）。
