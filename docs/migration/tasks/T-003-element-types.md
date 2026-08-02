# T-003 笔记元素体系

## 目标

创建笔记元素类型文件，定义元素基类、各具体元素类型（椭圆/多边形/文本/图片）和联合类型。

## 参考

- 知识库：REVERSE_ANALYSIS.md §33（共享抽象层 c9e 基类/三渲染路径/transform）、§24（形状元素 yc7/wv8/ina）、§30（文本块 cde TextBlockInfo）
- 契约：`docs/migration/phase-1-data-model.md` §3.4

## 实现要求

### 创建文件

`note/src/main/ets/core/model/ElementTypes.ets`

### 必须导出

- `enum ElementType { STROKE=0, ELLIPSE=1, POLYGON=2, TEXT=3, IMAGE=4, SELECTION=5 }`
- `interface NoteElementBase { id: string; type: ElementType; transform: TransformMatrix; bounds: Rect2D }`
- `interface EllipseElement extends NoteElementBase`（+center/radiusX/radiusY/rotationRadians/color/strokeWidth）
- `interface PolygonElement extends NoteElementBase`（+vertices/isClosed/color/strokeWidth）
- `interface TextBlockElement extends NoteElementBase`（+richText/textOrigin/blockWidth/blockHeight/rotationRadians/contentLeftInset/contentTopInset/fontSize/fontColor）
- `interface ImageElement extends NoteElementBase`（+assetHash/cropRect）
- `type NoteElement = StrokeElementData | EllipseElement | PolygonElement | TextBlockElement | ImageElement`

### 依赖

- `import { Point2D, Rect2D, TransformMatrix } from './GeometryTypes'`
- `import { StrokeElementData } from './StrokeTypes'`

### 鸿蒙特有约束

- 禁止平台 import。
- ArkTS 中 interface 继承用 `extends`。
- 联合类型用 `type ... = A | B | C` 语法。
- ImageElement.cropRect 类型为 `Rect2D | null`（可选裁剪）。

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] NoteElement 联合类型包含 StrokeElementData
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-003-完成.md`
