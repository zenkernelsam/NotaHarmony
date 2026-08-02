# T-006 适配层四接口

## 目标

创建适配层的四个核心接口文件：输入采集、笔画渲染、预测点和可插拔识别。这些接口隔离业务代码与平台 API，是 §40 三层架构的落地。

## 参考

- 知识库：REVERSE_ANALYSIS.md §40（适配层架构：InkInputProvider/StrokeRenderer/Predictor 三接口）、§5（hda.v() 输入字段映射）、§36（Pen Kit PointPredictor）、§37（渲染三层路线）
- 契约：`docs/migration/phase-1-data-model.md` §3.8

## 实现要求

### 创建文件

1. `note/src/main/ets/core/adaptation/InkInputProvider.ets`
2. `note/src/main/ets/core/adaptation/StrokeRenderer.ets`
3. `note/src/main/ets/core/adaptation/Predictor.ets`
4. `note/src/main/ets/core/adaptation/RecognitionProvider.ets`

### InkInputProvider.ets 必须导出

- `interface RawPointerEvent`（8 字段：x/y/pressure/tiltRadians/orientationRadians/toolType/timestamp/isHistorical）
- `interface InkInputProvider`（4 方法：processEvent / hasPressureSupport / hasTiltSupport / hasOrientationSupport）

### StrokeRenderer.ets 必须导出

- `interface RenderContext`（4 方法：save/restore/clipRect/clear）
- `interface StrokeRenderer`（4 方法：renderCenterPath / renderVariableWidthOutline / renderPencilSplats / renderEraserMask）

### Predictor.ets 必须导出

- `interface Predictor`（2 方法：predict / reset）

### RecognitionProvider.ets 必须导出

- `interface RecognitionResult { confidence: number; elements: NoteElement[] }`
- `interface RecognitionProvider`（3 方法：isAvailable / recognizeShape / recognizeText）

### 依赖

- InkInputProvider: `import { InputBatch } from '../model/StrokeTypes'`
- StrokeRenderer: `import { StrokeElementData, PencilSplatPoint, RenderSpec } from '../model/StrokeTypes'` + `import { Rect2D } from '../model/GeometryTypes'`
- Predictor: `import { InputPoint } from '../model/StrokeTypes'`
- RecognitionProvider: `import { Point2D } from '../model/GeometryTypes'` + `import { NoteElement } from '../model/ElementTypes'`

### 鸿蒙特有约束

- 接口定义文件中**不 import 任何 `@ohos.*` / `@kit.*`**。
- RawPointerEvent 是平台无关的中间表示；具体实现（Phase 2）才 import TouchEvent 并转换。
- RenderContext.clipRect 参数为 `Rect2D`，不绑定平台 Canvas 类型。
- RecognitionProvider.recognizeShape/recognizeText 返回 `T | null`（无结果时 null）。
- 所有接口只定义签名，不包含实现逻辑。

## 验收标准

- [ ] 四个文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] 四个文件中无任何 `@ohos` / `@kit` import
- [ ] StrokeRenderer 包含 renderVariableWidthOutline 方法（可变宽度一步到位）
- [ ] RecognitionProvider 独立于主流程（无其他文件 import 它）
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-006-完成.md`
