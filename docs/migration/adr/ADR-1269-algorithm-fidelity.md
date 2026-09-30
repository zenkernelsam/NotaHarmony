# ADR-1269：算法保真度

## 状态

已接受（Phase 1325）。

## 决策

算法参数/公式对照原版逐方法移植（ForceSmoother 8ms
窗+0.15 限幅、CubicFitter、PencilSplat、ShapeDetector、
WidthOutline）—— 算法语义保真。

## 理由

`core/algorithm` 5 文件对照原版 defpackage 基线：
`ForceSmoother`（ws4 8ms 窗+dr4 0.15 限幅 EMA）、
`ms1`=浮点区间工具；CubicFitter/PencilSplat/Shape
Detector/WidthOutline 各自对应原版（sqh/xaa/b90/w4a）
—— 内联引用原版类+参数对齐。

## 后果

笔画几何/压力算法保真原版 —— 手写笔迹外观/手感
语义保真。
