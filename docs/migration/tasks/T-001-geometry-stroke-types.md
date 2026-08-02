# T-001 基础几何与笔画类型

## 目标

创建两个纯类型文件，定义全部基础几何类型和笔画/输入相关数据结构。这是所有后续任务卡的基础依赖。

## 参考

- 反编译源码：`reference/java/audit_cxe/cxe.java`（画布编辑器，了解坐标系使用）
- 知识库：REVERSE_ANALYSIS.md §5（输入模型 hda.v() 字段映射）、§6（笔画数据模型 s78/faa/vzf）、§17（平滑算法输出 CubicCurve）
- 契约：`docs/migration/phase-1-data-model.md` §3.1 和 §3.2（完整定义，照搬即可）

## 实现要求

### 创建文件

1. `note/src/main/ets/core/model/GeometryTypes.ets`
2. `note/src/main/ets/core/model/StrokeTypes.ets`

### 必须遵守的接口签名

**GeometryTypes.ets** 必须导出：
- `interface Point2D { x: number; y: number }`
- `interface Rect2D { left: number; top: number; right: number; bottom: number }`
- `type TransformMatrix = number[]`（长度 9，行主序 3×3 仿射矩阵）
- `interface CubicSegment { p0: Point2D; p1: Point2D; p2: Point2D; p3: Point2D }`

**StrokeTypes.ets** 必须导出：
- `enum InputToolType { STYLUS=0, MOUSE=1, TOUCH=2 }`
- `interface InputPoint`（7 个字段，见契约）
- `enum InputBatchKind { REAL=0, HISTORICAL=1, PREDICTED=2 }`
- `interface InputBatch { kind: InputBatchKind; points: InputPoint[] }`
- `interface PencilSplatPoint`（5 个字段：x/y/rotation/scale/opacity）
- `interface StrokePathPoint { position: Point2D; widthFactor: number }`
- `enum InkStyle { FIXED_WIDTH=0, VARIABLE_WIDTH=1, DASH=2, DOTS=3 }`
- `interface RenderSpec`（5 个字段：color/brushWidth/inkStyle/isHighlighter/isPencil）
- `interface StrokeElementData`（10 个字段，见契约）

### 鸿蒙特有约束

- **禁止** import 任何 `@ohos.*` / `@kit.*` 模块。
- 所有类型使用 `export` 导出。
- 不使用 `any` 类型。
- StrokeTypes.ets 通过相对路径 `import { Point2D, CubicSegment, Rect2D, TransformMatrix } from './GeometryTypes'` 引用几何类型。

## 验收标准（可客观判定）

- [ ] 两个文件存在于指定路径
- [ ] `check_ets_files` 对两个文件返回零错误
- [ ] `build_project` 编译通过（module: "note@default"）
- [ ] 不引入任何平台 import
- [ ] 不修改契约接口签名（与 phase-1-data-model.md §3.1/§3.2 完全一致）
- [ ] 不引入未批准依赖

## 完成报告

工人完成后在 `docs/migration/reports/T-001-完成.md` 记录：改了什么、验收结果、遗留问题。
