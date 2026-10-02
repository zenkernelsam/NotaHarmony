# Phase 1462 — l4g 矩形多边形顶点拖拽 = 旋转矩形重拟合（rsm.c / oem.a / fil.a/b）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### fil.java — 四边形判定
- `fil.a(List<e8d>)`：`size==4` 且各角点到质心距²与首角点相差
  ≤ `maxDist²·0.001`（`e52.C3`=max、`e52.l3`=drop(1)），且
  `maxDist²≥0.001`。质心等距 = 矩形/菱形类四边形。
- `fil.b(w,h)`：`max>0 && |w−h| ≤ max·0.001` → 正方形判定。

### oem.java — RotatedRect 解码
- `oem.a(List<ae1>) → nze(corners, radians, center)`：
  - `θ = atan2(1,0) − atan2(ex,ey)`，`ex,ey` = 角0→角1 边向量
    （即 `π/2 − atan2(Δx,Δy)`，等价边方向角）。
  - 角点绕 (0,0) 反旋 `−θ`（`sem.c`），求 AABB（`sem.b`）。
  - 反旋后每个 AABB 角须被某个反旋角点在容差
    `max(1, max(w,h))·0.01` 内命中（逐轴 |dx|,|dy| 均 ≤tol）；
    否则输出回退为 AABB 角重旋 `+θ` 的规整矩形。
  - `center` = 输出角 0 与角 2 中点（`ae1.d` 加 /2）。
- `p0` = (x,y,w,h) 四元组；`p0.a()` 角序 **[BL,BR,TR,TL]**：
  `(x,y+h) → (x+w,y+h) → (x+w,y) → (x,y)`；
  `p0.e = {-1,+1,-1,+1}` 对角符号数组。

### rsm.java:c — l4g（多边形）顶点应用
`rsm.c(def, i, f, f2, rot)` 中 `l4g` 支（约 L128-291）：
1. `listC0 = vpm.c0(l4g.b)` 局部顶点表；`i` 越界 → 原样返回。
2. `fil.a(listC0)` 为真（矩形四角）→ **旋转矩形重拟合**：
   - `oem.a` 解出 θ 与中心；顶点绕中心反旋 `−θ` 得轴对齐框；
   - 拖拽角 `unrot[i]` 在 AABB 角序中命中索引 `i3`（容差同上）；
   - 未旋转增量 `(d7,d8) = rot((f,f2), −θ)`；
   - `i3≥0 且增量非零` 时：`arr[i3] += (d7,d8)`；
     `i4=(i3+1)%4`、`i5=i3-1`（模4）两邻角沿共享边轴跟随——
     `i4%2==0 → (moved.x, own.y)` 否则 `(own.x, moved.y)`；
     `i5%2==0 → (own.x, moved.y)` 否则 `(moved.x, own.y)`；
     再对约束结果取 AABB（`sem.b`）归一化；
   - `zB = fil.b(原角点 AABB 宽,高)`（正方形）时先做分量耦合：
     `d9=w/h`、`d10=h/w`、`sign=p0.e[i3]`；`d7==0→d7=d8·d9·sign`、
     `d8==0→d8=d7·d10·sign`；`w>h → d8=sign·d10·d7` 否则
     `d7=sign·d9·d8`（主轴主导，副轴按比例耦合）；
   - AABB 角重旋 `+θ` 回局部系，再过 `oem.a` 归一化输出。
3. `zB`（正方形）最终再替换输出：取 `nzeVarA2.a[(i+2)%4]` 为锚角、
   `[i]` 为拖拽角，`s = max(0.5, (|dx|+|dy|)/2)`，按对角符号
   `(sign(dx), sign(dy))` 从锚角向拖拽方向建**轴对齐正方形**，
   再过 `oem.a` —— 正方形顶点拖拽后轴对齐（旋转归零）。
4. `fil.a` 为假 → 顶点直移（`ben.h(x+dx, y+dy)`）。

### guf.java:c — 吸附门（Phase 1460 已移植门控，本 Phase 收紧判定）
`fil.a(listC0)` 为真时跳过 e2n.d 邻边射线吸附（矩形拖拽已由
重拟合保持矩形性），仍走 `twm.b` 页/对象候选回退。

## 差距（修复前）

`vertexDraggedShape` 的 POLYGON 支对所有多边形一律顶点直移：
- 拖矩形一角 → 破坏矩形性（原版保持矩形——邻角跟随、对角固定）；
- 拖正方形一角 → 原版按对角线重建轴对齐正方形，Harmony 无此语义；
- `filQuadrilateral` 只有 `size==4 && maxDist²≥0.001`，缺等距判定，
  导致 guf.c 的 fil.a 门对非矩形四边形误触发（梯形被排除出邻边吸附）。

## Harmony 实现（本 Phase）

`note/src/main/ets/ui/editor/NoteCanvasView.ets`：

- `filQuadrilateral` 补全等距判定（`fil.a` 全语义）：四角质心距²与
  首角相差 ≤0.1%·max。
- `filSquare(w,h)` = `fil.b`：`|w−h| ≤ 0.001·max`。
- `rotAround` = `sem.c`；`aabbCorners` = `p0.a()`（BL,BR,TR,TL）。
- `decodeRotatedRect` = `oem.a`：θ 取自边0→1、反旋校验、非矩形回退
  规整矩形、`center=(c0+c2)/2`。
- `rectRefitVertexDrag(verts, i, dx, dy)` = `rsm.c` l4g+fil.a 支：
  反旋→i3 命中→邻角约束→（正方形分量耦合）→重旋→二次 `oem.a`→
  （正方形）轴对齐正方形重建。
- `vertexDraggedShape` POLYGON 支：`filQuadrilateral` 为真走
  `rectRefitVertexDrag`，否则维持直移。

坐标系：`vertexDraggedShape` 收到的 `(dx,dy)` 已是 `applyVertexDrag`
中 `fq9.n0` 等价物反旋过的**形状局部增量**，`orig.vertices` 为局部
顶点表——与 rsm.c 的 `(f,f2)`+`listC0` 同域，直接对应。

## 验证

- `d02-original-shape-vertex-drag.mjs` 扩展 8 项静态断言 +
  可执行模型（轴对齐矩形拖 TR：邻角沿共享边跟随、对角固定）。
- 全量 Desktop Replay 1304/1304；`note@default`/`note@ohosTest`
  clean 构建通过。
