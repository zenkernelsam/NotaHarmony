# T-002 笔刷与工具类型

## 目标

创建笔刷配置、工具枚举和工具状态类型文件，包含 BrushStyle→InkStyle 映射函数。

## 参考

- 知识库：REVERSE_ANALYSIS.md §22（Brush 模型 f21 / 工具枚举 zy5 / 样式枚举 z21/sz5）
- 契约：`docs/migration/phase-1-data-model.md` §3.3

## 实现要求

### 创建文件

`note/src/main/ets/core/model/BrushTypes.ets`

### 必须导出

- `enum BrushStyle { MONO=0, TAPER=1, DASH=2, DOT=3 }`
- `enum ToolType { DEFAULT=0, SELECTION=1, PARTIAL_ERASER=2, PEN=3, HIGHLIGHTER=4, PENCIL=5, REVIEW=6, WHOLE_ERASER=7 }`
- `interface BrushSpec`（5 字段：brushStyle/widthSize/color/selectedWidthWellIndex/selectedColorWellIndex）
- `interface ToolState`（7 字段：toolId/trayOwnerId/toolType/trayIndex/brush/selectionIsFreehand/eraserIsPartial）
- `function brushStyleToInkStyle(style: BrushStyle): InkStyle`

### 依赖

- `import { InkStyle } from './StrokeTypes'`（T-001 产出）

### 鸿蒙特有约束

- 禁止平台 import。
- 映射函数必须覆盖全部 4 个 BrushStyle 分支 + default 兜底。

## 验收标准

- [ ] 文件存在且 `check_ets_files` 零错误
- [ ] `build_project` 编译通过
- [ ] brushStyleToInkStyle(MONO)===FIXED_WIDTH, (TAPER)===VARIABLE_WIDTH, (DASH)===DASH, (DOT)===DOTS
- [ ] 不修改契约签名

## 完成报告

`docs/migration/reports/T-002-完成.md`
