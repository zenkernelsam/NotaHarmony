# Phase 1315 报告 — op-payload 编码器 + 算法层

## 完成内容

- `data/` 逐 op `Original*PayloadEncoder`（CreateBlock/
  Ink/Page/Shape/DeleteEntities/AddPath + 各 `*Mutation
  Codec`）= 本地编辑→原版 `haa` op FlatBuffer 线格式；
  `core/algorithm`（CubicFitter 贝塞尔拟合/ForceSmoother
  压力平滑/PencilSplat 生成/ShapeDetector 形状检测/
  WidthOutline 宽度轮廓）= 笔画算法 —— CRDT 编码+
  几何算法保真。

## 产出

- evidence `phase-1315-op-encoders-algorithms.md`
- fixture `d02-op-encoders.mjs`（10/10）
- ADR-1259
