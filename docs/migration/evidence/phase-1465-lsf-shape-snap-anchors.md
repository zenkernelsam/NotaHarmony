# Phase 1465 — guf.b lsf 单形状拖拽吸附锚点 = og0.e 轮廓点 + og0.h/i 质心

## 原版证据（decompiled_1.4.2）

### guf.java:104-157 `b(xtf, j)`

xtf 移动会话每帧吸附（`!twm.e(fJ)` 旋转门后）按选区类型构造
`kdc(锚点列 F, s64 中心 G)`：

- **ksf/有 sbe 选区**：`kdc(u64.c(sbe), s64(u64.b(sbe)))` = sbe 四角 +
  选区中心。
- **lsf 单元素**：`zq.p0(r0b, t87, 6)` 取 hv6 元素模型；
  - `og0.e(r0b, hv6)` 返回非空 → 锚点列 = 该轮廓点列；
  - 否则回退 `u64.c(s40.t(zq.o(t87, r0b)))` = 界框四角（sbe）；
  - 中心 = `og0.h(hv6, listC)`（hv6!=null 时）或 `og0.i(listC)`。

### og0.java:494-533 `e(r0b, hv6)` — 轮廓点列

- `f5g` 形状：`U().b()` 定义点列：
  - `j4g` 线 → `oag.y2(p3(listB), y3(listB))` = **仅首末端点**
    （`m4g.b()` 产 [o(), 贝塞尔 t=0.5 中点(0.125/0.375/0.375/0.125 权),
    n()]，j4g 支只取两端）；
  - 其余形状：`U().b()` 全列；`size>1 && zx7.r(first,last)`（闭合重尾）
    → `e52.m3(1)` drop 末点；
  - `k4g.b()`（NORMAL_SHAPE）= `oag.y2` 局部框四边中点 (fD,0)(fD,c)
    (0,fC)(d,fC)；
  - `l4g.b()` = `vpm.c0(p9d)` 顶点列。
- 非形状（笔画/文本/图/数）：`hv6.H()` 局部界四角
  (a,b)(c,b)(c,d)(a,d)。
- 每点经 `kw9.c(pt, hv6.Q(null))` 元素变换 + `xxb.g(jJ0)` 页原点换算
  → 页坐标锚点。

### og0.h:571-601 / og0.i:603-613 — 中心

- `h`：`hv6 instanceof f5g && U() instanceof l4g && size>=3` →
  **鞋带公式质心**（d=Σcross=2·有向面积；cx=Σ(xi+xi+1)·ci/(3d)）；
  d==0 或非多边形 → `i` 均值中心。

### ne1.java:410-446 `w(j, j2, list)`

锚点集 = 每锚点+位移（`xxb.g(anchor, delta)`）**再追加
center+位移**（L423 `pa9VarE2.add`），逐 kdc 候选 `l()` 逐轴裁决
→ mkg(校正位移, 导线集)。

## Harmony 缺口（P1456 登记「lsf 锚点粒度」）

`planSelectionSnap` 一律 `originalSnapMoveAnchors(bounds)` = 界框
四角+框心——单形状拖拽时顶点/端点本身不参吸（如斜三角形拖过时
顶点不对齐页网格/邻元）。

## 实现（NoteCanvasView.ets）

新增 `singleShapeSnapAnchors()`：

- 门：恰好单选且为形状成员（total==1 && shapeIds==1）；
- LINE：`[transformMemberPoint(start), transformMemberPoint(end)]`
  （j4g 首末端点，不含贝塞尔中点）；
- POLYGON：顶点精确等重尾去一（`first===last` → `slice`），
  `transformMemberPoint` 逐点入世界系；中心 = 鞋带质心
  （twice=2A，退化回退均值）；
- 其它（ELLIPSE）：`shapeVertexDots` 四基向点 = k4g 四边中点等价；
- `anchors.push(center)`（ne1.w 追加语义）。
- `planSelectionSnap`：`singleShapeSnapAnchors() ?? 
  originalSnapMoveAnchors(bounds)`——ksf/非形状 lsf 维持界框锚点。

## 验证

- `d02-original-snap-to-grid.mjs`：47→57 项（逐支锚点断言 +
  鞋带质心/退化回退可执行模型）。
- `note@default` 构建通过；全量 Replay + `note@ohosTest` 收尾验证。
