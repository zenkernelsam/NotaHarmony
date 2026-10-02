# Phase 1460 证据 — 原版 ttf 顶点拖拽吸附链

证据来源：`decompiled_1.4.2/sources/defpackage/`（`guf.java`/`e2n.java`/
`fil.java`/`twm.java`/`e52.java`）。

## `guf.c(ttf, j)` 吸附前置（guf.java:161-246）

1. `twm.e(ttfVar.l())`——形状**会话起始旋转**非零 → `jB=j2`
   直接取原触点，全链跳过吸附。
2. 解析顶点世界点 `jA = e8d.c()+ttfVar.j().c()`（成员页内位置+顶点
   局部坐标）与页框原点 `s64Var`；页框缺失仅日志、不吸附。
3. `l4g`（多边形）支：`fil.a(listB)` 为假（非规整四边形）且
   `iF` 合法 → `e2n.d(cur, prevV, nextV, exj.a)` 邻边吸附；
   命中 → `z(em4.F)` 置吸附旗、`s64Var2` 为吸附点。
4. 邻边落空 → `twm.b(ne1Var, jA, 页原点, dragStart, cur)`——
   ne1 候选引擎对**拖顶点单点**逐轴吸附（候选 `jG` = 顶点页坐标
   + cur−dragStart 位移），返回校正点+导线旗（zjg/em4）。

## `e2n.c`（e2n.java:151）— 45° 邻边射线

`θ = atan2(cur−neighbor)` → `wv9.E(θ/(π/8))·(π/8)` 取最近 45°
倍数；`|Δ·sinθs − Δ·cosθs|`（垂距）> `5/f`（f=exj.a=zoom）则
不啮合；啮合返回射线 `p0(neighbor, cosθs, sinθs)`。

## `e2n.d`（e2n.java:166）— 双射线交点

prev/next 两射线都啮合：`cross(dir1,dir2)≠0` 解交点
`o1 + dir1·cross(o2−o1,dir2)/cross(dir1,dir2)`；平行退化
（|cross|<1e-9）→ 取 ray1 上拖点投影；单射线 → 投影；全空 → null。

## `fil.a`（fil.java:17-57）— 规整四边形排除

`size==4` 且 `max(质心距²)≥0.001` → true（排除）。`take(1)` 循环
体内空（反编译确认）——等效判定只剩"4 顶点非退化"。

## `twm.b`（twm.java:9-36）— ne1 单点吸附

`jG = (vertexPos − pageOrigin) + (cur − dragStart)` 页坐标候选点；
逐候选 `ne1.l` 求 x/y 轴胜者 → 校正偏移 + `ne1.k` 导线旗；
结果转回世界系返回。

## Harmony 移植

- `snapVertexDragPoint`：`applyVertexDrag` 内 `|rot|≤1e-4` 门后调用；
  多边形非 `filQuadrilateral` 时先 `polygonNeighborSnap`（dots
  世界坐标 + prev/next 取模邻点），落空/非多边形回退
  `planOriginalSnapMove([顶点基准], 位移, 候选, zoom)`（选中元素
  已由 collectSnapCandidates 排除）——命中置 `snapGuides`。
- 旋转≠0 时不吸附（与 xtf 移动吸附同一 `twm.e` 门）。
