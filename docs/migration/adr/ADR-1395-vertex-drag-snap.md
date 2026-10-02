# ADR-1395：ttf 顶点拖拽吸附链（e2n.d 邻边 45° + twm.b 页候选）

- 状态：已采纳
- Phase：1460（结清 Phase 1454 登记差异）

## 背景

原版 `guf.c` 在写回形状定义前对拖点做两级吸附：多边形邻边
45° 射线吸附（`e2n.d`），落空回退页/对象候选吸附（`twm.b`/`ne1`）；
`twm.e` 旋转≠0 时全链跳过。Harmony 顶点拖拽此前不吸附。

## 决策

1. `neighborSnapRay`/`polygonNeighborSnap` 模块函数逐字复刻
   `e2n.c`/`e2n.d`：π/4 步进角度吸附、垂距阈值 `5/zoom`、
   双射线交点解/平行退化回 ray1 投影/单射线投影。
2. `filQuadrilateral`：`vertices.length===4 && maxDist²≥0.001`
   ——原版 `fil.a` 的 take(1) 内循环为空体，等效判定即此。
3. 邻边吸附落空或非多边形 → `planOriginalSnapMove` 以拖顶点
   为唯一锚点（`twm.b` 页坐标等价），命中置 `snapGuides`。
4. 旋转门 `twm.e`：`shapeVertexRotation(orig)` 取会话前快照
   （`ttf.l()`=originalRotation 语义）——`|rot|>1e-4` 不吸附。

## 已知差异（登记）

- 邻边吸附命中时原版 `z(em4.F)` 可能渲染对齐辅助线；Harmony
  清 `snapGuides` 不画射线——仅点吸附生效。
- `oem.a`/`zB` 正多边形规整约束（拖拽受限保持正多边形）仍未
  解码完全——`fil.a` 只影响邻边吸附门，不改变形变自由度。

## 验证

- `d02-original-shape-vertex-drag.mjs` 扩至 32 项（旋转门、
  射线吸附、fil.a 排除、页候选回退、可执行交点模型）。
