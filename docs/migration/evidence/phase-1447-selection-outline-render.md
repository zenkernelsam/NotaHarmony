# Phase 1447 证据：1.4.2 `sen`/`gsf` 选区轮廓渲染

## 原版证据（`decompiled_1.4.2/sources/defpackage`）

### 相位动画驱动（`sen.java:513`）

```java
nbl.h(nbl.T(0, qh2Var, "selection-dash"), 0f, 1f,
  ne9.D(ne9.V(600, 0, ji4.d, 2), jne.F, 4), "selection-dash-phase", ...)
```

无限循环 600ms 线性 0→1 相位动画，`f12 = (9.0/zoom) * 2 * phase`
（= 2 个虚线周期偏移，无缝循环）馈入所有选区虚线描边。

### `sen` 渲染分发（~1045-1052）

元素层之上、画布变换内：`isf → sen.t`；`hsf → gsf.d(hsf.j(), zoom,
false, f12)`。仅此两支（其余 msf 类型 `NoWhenBranchMatched`）。

### `gsf.d`（轨迹描边）

`list<2` 早退；path = moveTo 首点 + lineTo 各点；`z=true` 时 closePath；
描边 `t1h(4dp/zoom, dash=[9dp/zoom,9dp/zoom], phase=f12)`；色 `z ? c : a`。

### `sen.t`（isf 完成态轮廓）

```java
gsf.g(qe4, isf.a, zoom, list != null, phase, isf.h ? gsf.c : gsf.a);
if (list != null) gsf.d(qe4, list, zoom, true, phase);   // 闭合 ghost
```

- `gsf.g`：`z=true`（`isf.k` 轨迹非空 = 绘制型）→ 实线 `t1h(2dp/zoom)`
  矩形界；`z=false`（k=null = 程序化集合）→ 4dp 蚂蚁线虚线界。
- 颜色：`isf.h`（deselectMode）→ `c`（a 的 32% 透明），否则 `a`。
- ghost：`gsf.d(k, close=true)` → 恒 `c` 色闭合蚂蚁线轨迹。

### 常量（`gsf` 静态块）

- `a = qxk.e(4282546431) = 0xFF4278FF`（固定蓝，不随主题）。
- `c = p52.b(a, 0.32f)` = a 的 32% 透明变体。
- `b = 0xFFFFFFFF`、`d = 0xFF444DE0`、`e = 0xFFB3B3B3`（角柄/其它绘制用）。

### `hsf`/`isf` 轨迹来源

- `lr` case13：手势 move 逐点 `e52.O3(hsf.a, 点)` 追加并扩 `hsf.b` 界——
  `a` = 原始指针轨迹（lasso/rect 两模式共用追踪器）。
- `z6c` case6：完成时 `new isf(b,b,b,null,null,false,set,hsf.a,hsf.a,
  set2,set2,896)` —— `isf.k/l` = 轨迹；程序化选区 `k=null`。

## Harmony 对齐（NoteCanvasView.ets / SelectionOverlay.ets）

| 原版 | Harmony |
|---|---|
| hsf 进行中轨迹蚂蚁线 | `renderSelectionGestureTrail`：lasso→`lassoPoints` 开放 path；rect→`state.rect` 轮廓（原版同画 `hsf.a` 指针轨迹；矩形轨迹近似对角线，轮廓呈现意图等价） |
| 4dp/zoom + 9dp 虚线 + 相位 | `lineWidth=4/zoom`、`setLineDash([9/zoom,9/zoom])`、`lineDashOffset=-phase*2*dash`（f12 等价） |
| 600ms 相位循环 | `startSelectionDashTicker`：33ms tick、phase+=33/600、renderFrame 驱动（仅手势期；抬起即停） |
| isf.k 非空 → 实线 2dp 界 | `selectionDrawnSource = drawnRect !== null` → overlay `BorderStyle.Solid` width 2 |
| k==null → 4dp 虚线界 | `BorderStyle.Dashed` width 4 |
| isf.h → 32% 降色 | overlay `.opacity(deselectMode ? 0.32 : 1.0)` |
| 闭合 ghost 恒 32% | `renderSelectionTrailGhost`：selectionVisible 且 lassoPoints≥3 → 闭合虚线 `globalAlpha=0.32` |
| 色 `#FF4278FF` | `SELECTION_OUTLINE_COLOR` 常量（界与轨迹统一） |

## 适配登记

1. **提交态轮廓的相位行进未动画化**：overlay 边框为 ArkUI `border`
   （不支持相位偏移），ghost 静态相位 0 呈现。常驻选区空转重绘代价
   过大，不引入 idle ticker——差异见 ADR-1382。
2. **矩形模式进行中轨迹**：原版画 `hsf.a` 指针轨迹（矩形手势近似
   对角线段）；Harmony 画当前 `state.rect` 轮廓——同一蚂蚁线描边
   勾勒选区范围的语义等价呈现。
3. `jsf`/`lsf` 轮廓（`gsf.h`/`gsf.b`/`gsf.c` 路径）属另一渲染管线
   未在本 Phase 展开。
