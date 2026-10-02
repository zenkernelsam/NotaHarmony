# Phase 1454 证据 — lsf 形状顶点拖拽（ttf ControlPointDrag / guf.c / rsm.c）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### 会话构造（ms1.java:243）

```java
// lsf 单元素选区 + 形状成员 + 顶点命中时：
new ttf(
    lsfVar.b,          // stateId
    jE,                // dragStartPoint（世界坐标）
    i,                 // controlPointIndex
    lsfVar.a,          // shapeId
    f5gVar2.U(),       // originalDefinition（形状定义快照）
    f5gVar2.U().w,     // originalOrigin
    f5gVar2.U().v,     // originalPage
    f5gVar2.U().j(),   // originalRotation
    jE,                // transientOperationId
    lsfVar             // initialSelectionState
)
```

`ttf` toString：`ControlPointDrag(stateId, dragStartPoint, controlPointIndex,
shapeId, originalDefinition, originalOrigin, originalPage, originalRotation,
transientOperationId, lastDragPoint, initialSelectionState)`——**快照原始形状
定义**，逐帧在原定义上应用增量（非累积）。

### 顶点命中（ms1.java 顶点探测段）

```java
// tap 经选区旋转反变换入形状局部系后：
float f9 = 44.0f / zoom;          // guf.l=44，命中半边长
for (控制点 p : f5g.U().b() 顶点集) {
    if (Math.abs(localX - p.x) < f9 && Math.abs(localY - p.y) < f9) {
        i = 控制点序号; → new ttf(...)
    }
}
```

- 轴对齐**方框**（局部系，宽高各 `88/zoom`）；
- 顶点序 = `m4g.b()` / `f5g.U().b()` 渲染序（与 Phase 1451 圆点同集）；
- 顶点命中在角柄/旋转柄判定**之前**（ms1 命中链中 ttf 构造先于
  wtf/vtf 分发）。

### 拖拽应用（guf.java c(ttf, point)）

```java
public static ... c(ttf ttfVar, long j) {
    // 1. 拖拽点可选经多边形邻边对齐吸附（fil.a 有吸附目标时）；
    // 2. 页框吸附（zB 支）；
    long jF = xxb.f(j_cur, ttfVar.b());          // cur − dragStart 增量
    // 3. fq9.n0 反旋转：增量转入形状局部系（originalRotation）
    // 4. rsm.c(originalDefinition, controlPointIndex, dx, dy, …)
    //    → 新形状定义
    // 5. ybn.F(shapeId, newDef) 应用到页模型
}
```

关键点：**世界增量 → 局部系**（反旋转 originalRotation），编辑永远
作用于 `originalDefinition` 快照——取消时原定义直接可恢复。

### rsm.c — 逐型控制点编辑

```java
static f5g c(f5g def, int i, float dx, float dy, ...) {
    if (def instanceof q89) {                    // LINE
        // i==0 → start+=Δ；i==size-1 → end+=Δ
        // 中间控制点支（i==1）：
        //   cp2!=null → f5=4/3（三次）；否则 f5=2（二次）
        //   cp1 += Δ·f5；cp2 != null → cp2 += Δ·f5
        // 直线退化保持：z=(cp1==null || (cp1==start && cp2==end))
        //   → 端点拖动时重合控制点跟随端点
    }
    if (def instanceof k4g) {                    // ELLIPSE
        // i 序：0=top,1=bottom,2=left,3=right（fil.b 包围盒基向点）
        // 拖动边随指针移动，对侧固定：
        //   top/bottom → cy += Δy/2, ry += ±Δy/2
        //   left/right → cx += Δx/2, rx += ±Δx/2
        // 正圆（宽高相等）→ rx=ry 同步缩放
    }
    if (def instanceof l4g) {                    // POLYGON
        // vertices[i] += Δ；另有 oem.a 规范坐标系 +
        // fil.a/zB 正多边形规整约束（拖拽受限保持规整，
        // 反编译未能完整解码——登记差异）
    }
}
```

### 落点（guf.c → ybn.F）

每次 move 产新 `f5g` 定义经 `ybn.F` 替换页元素；会话结束一次提交
（`ch1` 手势完成 → 历史组）。`ttf.h=initialSelectionState` 保留选区
——拖拽结束不重建选区。

## Harmony 映射

| 原版 | Harmony |
|------|---------|
| `ttf` 会话 | `vertexDrag/vertexDragShapeId/vertexDragIndex/vertexDragStart/vertexDragOrigShape/vertexDragChanged` 会话组 |
| `f5g.U().b()` 顶点集 | `shapeVertexDots`（P1451 同源顶点序） |
| `44/zoom` 局部方框命中 | `tryStartShapeVertexDrag` ±`44/zoom` 反旋转方框 |
| `fq9.n0` 反旋转入局部系 | `shapeVertexRotation` → `rotateDx/Dy` |
| `rsm.c` 逐型编辑 | `vertexDraggedShape` 三支（LINE/ELLIPSE/POLYGON） |
| `ybn.F` 应用 | `applyVertexDrag` 替换 `shapes[id]` + `recomputeShapeBounds` |
| `initialSelectionState` 保留 | 会话结束不动选区 |
| `oem.a`/`zB` 正多边形约束 | **未实现——ADR-1389 登记差异** |
| 邻边/页框吸附 | **未实现——登记差异** |

## 门槛对齐

`tryStartShapeVertexDrag` 条件 ↔ ms1 ttf 构造前提：

- 选区可见且非 deselectMode（lsf 语义：`supportsDeselectMode=false`）；
- `selectedShapeIds.length === 1` 且无其它元素类型（lsf 单形状）；
- 无组选区、非锁定、无照片导入冲突；
- 顶点命中先于 `tryStartSelectionResize`（ms1 命中序）。
