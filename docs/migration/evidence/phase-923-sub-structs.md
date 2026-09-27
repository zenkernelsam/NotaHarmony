# Phase 923 证据 — 剩余子结构四枚（ukb/bmb/qqe/yyd）

## 目的

载荷引用的内联结构/子表实名收尾。

## `ukb` = `RecordingSegment`（xwd 16B）

`{startTime:long@0, endTime:long@8}` ——
`njj.j0` 无符号格式化；yn2 segmentation 向量元素。

## `bmb` = `Rect`（xwd）

`{origin:fqa@0(8B), size:qed@8(8B)}` —— 16B；
rl2 cropRect 与 p2d SetRect 载荷。

## `qqe` = `TextSelection`（cee 表）

`{anchor:v01@0(c4), focus:v01@1(c6)}` ——
双 Boundary 锚定文本选区。

## `yyd` = `StyleMap`（xwd 20B）

`{backingPencilSeed:int@0, backingPencilReferencePoint:
fqa@4, backingDashPhase:float@12,
backingDashPeriod:float@16}` —— 墨迹样式贴图的
虚线渲染参数（种子+参考点+相位+周期）。

## 结构宽度谱系

qo5 8B / cxc 12B / ukb 16B / bmb 16B / yyd 20B /
ua0 64B——内联结构向量元素宽度全部实证。

## Harmony 核对

`RecordingSegment`/`Rect`/`TextSelection`/`StyleMap`
对应模型对齐；向量寻址宽度表对齐。

## 结论

op 载荷全引用图闭合——所有 cee 表与 xwd 结构
实名完毕。
