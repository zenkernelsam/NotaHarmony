# ADR-1271：ShapeDetector 形状识别

## 状态

已接受（Phase 1327）。

## 决策

`ShapeDetector` 实现 `RecognitionProvider`（hold-to-
detect 触发）—— 原版阈值/分类/仲裁保真移植。

## 理由

`ShapeDetector`（hold 触发几何分类 LINE/ELLIPSE/
POLYGON；lineThreshold=0.6/lineMinLength=60/ellipse
MaxGap=120；`b16.h` uneven 覆盖门+`e5d` 仲裁元数据）
—— 对照原版形状识别保真。

## 后果

长按形状识别（笔→直线/椭圆/多边形）与原版阈值/
仲裁语义一致 —— 识别保真。
