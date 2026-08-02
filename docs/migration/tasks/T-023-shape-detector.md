# T-023 形状识别

## 目标

实现笔画完成后的形状识别（直线/椭圆/多边形），识别成功则替换原始笔画为几何形状元素。

## 参考

- 知识库：REVERSE_ANALYSIS.md §24（触发链：笔画完成→b90 检测器→直线/椭圆/多边形候选→评分→替换；参数：重拟合偏差 5px、直线判据 距离/跨度>0.6、椭圆首尾距<120px）
- 契约：`note/src/main/ets/core/adaptation/RecognitionProvider.ets`（接口定义）
- 契约：`note/src/main/ets/core/model/ElementTypes.ets`（EllipseElement/PolygonElement）
- 依赖：T-009（CubicFitter 提供拟合段）

## 实现要求

### 创建文件

`note/src/main/ets/core/algorithm/ShapeDetector.ets`

### 接口设计

```typescript
import { Point2D } from '../model/GeometryTypes';
import { NoteElement, EllipseElement, PolygonElement } from '../model/ElementTypes';
import { RecognitionResult, RecognitionProvider } from '../adaptation/RecognitionProvider';

export interface ShapeDetectorConfig {
  lineThreshold: number;       // 直线判据：距离/跨度 > 0.6
  lineMinLength: number;       // 直线最小长度 60px
  ellipseMaxGap: number;       // 椭圆首尾最大距离 120px
  refitThreshold: number;      // 重拟合偏差 5px
  confidenceThreshold: number; // 最低置信度 0.5
}

export class ShapeDetector implements RecognitionProvider {
  private config: ShapeDetectorConfig;

  constructor(config?: Partial<ShapeDetectorConfig>)

  isAvailable(): boolean { return true; }

  recognizeShape(points: Point2D[]): RecognitionResult | null {
    // 1. 如果 points.length < 3 → null
    // 2. 尝试直线检测 → 评分
    // 3. 尝试椭圆检测 → 评分
    // 4. 尝试多边形检测 → 评分
    // 5. 取最高评分，如果 > confidenceThreshold → 返回结果
    // 6. 否则 → null（保留原始手画）
  }

  recognizeText(points: Point2D[]): string | null { return null; }  // MVP 不实现

  // 直线检测：首尾距离/路径跨度 > lineThreshold 且长度 > lineMinLength
  private detectLine(points: Point2D[]): { confidence: number; element: NoteElement } | null

  // 椭圆检测：首尾距 < ellipseMaxGap + 最小二乘拟合
  private detectEllipse(points: Point2D[]): { confidence: number; element: NoteElement } | null

  // 多边形检测：找角点（曲率突变）→ 顶点集
  private detectPolygon(points: Point2D[]): { confidence: number; element: NoteElement } | null
}
```

### 集成

在 NoteCanvasView 的 `endStroke()` 中：
```
if (shapeDetectionEnabled && currentTool == PEN) {
  const result = shapeDetector.recognizeShape(pathPoints.map(p => p.position));
  if (result && result.confidence > 0.5) {
    // 用识别结果替换原始笔画
  }
}
```

### 鸿蒙特有约束

- 禁止平台 import（纯数学）。
- 直线评分：拟合度 > 0.5 且长度 > 60 时提升为 `(1+score)*0.5`。
- 椭圆拟合：最小二乘（简化版：center = 质心，rx/ry = 标准差）。
- 多边形：Douglas-Peucker 简化 → 顶点数 3~8 为有效多边形。
- 识别失败返回 null，不替换原始笔画。

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] 画一条直线 → 识别为直线（笔画变直）
- [ ] 画一个近似圆 → 识别为椭圆
- [ ] 画一个三角形 → 识别为多边形
- [ ] 画自由曲线 → 不识别（保留手画）
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-023-完成.md`
