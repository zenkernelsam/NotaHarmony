# ADR-1293：形状检测基线归属更正

## 状态

已接受（Phase 1352，更正 Phase 1327）。

## 决策

形状检测基线更正为 `g5d`/`uf8`/`f5d`/`h8d`/`mih` 族；
`b90`（Phase 1327 误标）实为 `AbstractSet`。

## 理由

Phase 1327 误把 `b90.java`（AbstractSet collection）当
形状检测器。真实原版：`g5d`=`ShapeDetectorOutput{
confidence,offset,shape}`（toString 实证）、`uf8`/`xf8`
检测器接口、`f5d` 0.05f 点聚类、`h8d` 点、`mih` 距离。
Harmony `ShapeDetector`（hold-detect+置信度+Douglas
Peucker）结构与真实基线对齐；常量 0.6/60/120 为文档化
近似（原值未在可读字段暴露）。

## 后果

基线归属更正；语义对齐真实检测器但阈值为近似 —
— 修正审计证据准确性。
