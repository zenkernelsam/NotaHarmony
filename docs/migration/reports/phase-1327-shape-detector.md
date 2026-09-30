# Phase 1327 报告 — ShapeDetector 审计

## 完成内容

- `ShapeDetector`（`RecognitionProvider` impl，hold-to-
  detect 触发）：输出 LINE/ELLIPSE/POLYGON 几何分类
  +原版阈值（lineThreshold=0.6 距离/跨度、lineMinLength
  =60px、ellipseMaxGap=120px）+`b16.h` uneven 覆盖门
  （最短边<最长边 1/4）+`e5d` 仲裁元数据 —— 形状识别
  保真移植。

## 产出

- evidence `phase-1327-shape-detector.md`
- fixture `d02-shape-detector.mjs`（10/10）
- ADR-1271
