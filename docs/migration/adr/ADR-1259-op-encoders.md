# ADR-1259：op-payload 编码器 + 算法层

## 状态

已接受（Phase 1315）。

## 决策

逐 op `Original*PayloadEncoder`（FlatBuffer 线编码）
+ `core/algorithm` 笔画算法自实现 —— 编码+算法
保真。

## 理由

`data/` 逐 op 编码器（CreateBlock/Ink/Page/Shape/
DeleteEntities/AddPath + `*MutationCodec`）= 本地编辑→
原版 `haa` op FlatBuffer 线格式；`core/algorithm`
（CubicFitter/ForceSmoother/PencilSplat/ShapeDetector/
WidthOutline）= 笔画几何算法 —— 编码+算法保真。

## 后果

本地编辑→原版 op 线格式逐 op 保真；笔画算法自实现
—— CRDT 编码+几何语义保真。
