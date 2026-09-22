# 原版证据：套索/矩形选区 ∩ 元素几何（fu1.f → g() uh5 分支）

- 版本：`decompiled_1.0.3`（Notability Android 1.0.3）
- Phase 607 依据。

## 1. 区域查询入口（fu1.java:439-452 `f`）

```java
public final ArrayList f(wh5 wh5Var, k11 k11Var, Collection collection,
    x09 x09Var, Set set) {
    uld uldVarT = aa6.t(x09Var, k11Var, collection);      // 宽相：k11 矩形
    ArrayList arrayListA1 = au1.A1(uldVarT.a, uldVarT.b);
    for (Object obj : arrayListA1) {
        if (set == null || set.contains(vndVar.I.getId())) {
            if (g(vndVar, wh5Var, x09Var)) {              // 精判
                arrayList.add(obj);
            }
        }
    }
}
```

`wh5` 为查询形状：`vh5`（点圆，点按探测）或 `uh5`（多边形——
套索路径、选框均走 `uh5`，`fu1.d` 即以 `uh5(wx0)` 调用）。

## 2. uh5 精判 = 多边形 ∩ 元素几何（fu1.java:454-502 `g`）

- **s06 笔迹**：`h(uh5, this.a.d(s06))` ——`h` 对 `uh5` 调
  `jy0.e(多边形, 笔迹路径)`（fu1.java:210-212）：选区多边形与
  **笔迹描边路径相交**即命中，非 bounds 中心点。
- **m4d/n5d 形状**：`n5d.T() == null || !h(uh5, 填充路径)` →
  `h(uh5, z8a.b(路径, Q()))` ——填充形先测多边形 ∩ 填充区域，
  否则/落空测多边形 ∩ 描边带宽。
- **oy0 块**：`jy0.e(uh5.a(), 本地矩形路径)` ——多边形 ∩ 矩形。
- `s06.I()`（transientInteraction）为 true 时笔迹不参测——进行中的
  瞬态操作不入选（Harmony 无对应状态：未完成笔迹不在
  completedStrokes 中，天然豁免）。

## 3. uw2 case1 调用点

矩形选完成：`fu1.f(uh5(选框), k11(选框), v09.J 全类别, x09, set)`；
套索选完成同路径，`uh5` 承载套索顶点。两种模式几何判定一致——
均为多边形 ∩ 元素。

## 4. Harmony 缺口与修复

- 旧实现：矩形模式 `rectIntersects(选框, bounds)`（bbox∩bbox）；
  套索模式 **bounds 中心点入多边形**——笔迹/形状只擦到套索边缘
  （中心在外）原版命中而 Harmony 判 miss；矩形模式 bbox 角相接
  （路径未达）原版判 miss 而 Harmony 误选。
- 修复：
  - `EraserEngine.strokeIntersectsSelectionPath(stroke, polygon)`：
    `sampleStroke` 采样点入多边形 ∪ 采样段-多边形边距
    ≤ `brushWidth·widthFactor·scale/2`（笔带 ∩ 多边形）。
  - `ShapeGeometry.selectionPathHitsShape(polygon, shape)`：形状顶点
    入多边形（小形状整体套入）∪ 闭合多边形 `shapeCoveredByPath`
    （多边形顶点入填充 ∪ 边距 ≤ strokeWidth·scale/2 描边带）。
  - `finalizeSelection` 增 `strokeHit` 注入参数（SelectionTool 保持
    纯几何），块沿用 `selectionPathHitsAffineBlock`（已是
    多边形 ∩ 本地矩形，与 `jy0.e` 等价）。
  - `NoteCanvasView` 注入 `eraserEngine.strokeIntersectsSelectionPath`。

## 5. 偏差

- 原版宽相 `aa6.t` 后精判；Harmony 直接全量精判（结果同，省宽相）。
- `jy0.e` 内部精确区域求交未反编译可得；Harmony 以采样带-多边形
  距离 + 顶点互套判定逼近（对采样分辨率内的曲线等价）。
- 笔迹半宽按采样段起点的 `widthFactor` 取值；原版按描边轮廓精确
  几何——widthFactor 沿段渐变处为近似（差值亚像素级）。
