# Phase 1203 证据 — AndroidX Ink SDK 依赖边界

来源：`decompiled_1.0.3/sources/androidx/ink/**`（57 文件）+
`defpackage` 引用扫描（26 文件导入）。

## 库内容

| 子包 | 关键类 |
|---|---|
| `brush/` | `Brush/BrushFamily/BrushCoat/BrushPaint/BrushTip/StockBrushes` + `*Native` JNI |
| `brush/behavior/` | 节点图 12 种 `*Native`（BinaryOp/Constant/Damping/Easing/Integral/Interpolation/Noise/PolarTarget/Response/Source/Target/ToolTypeFilter） |
| `geometry/` | `AffineTransform/Angle/Box/BoxAccumulator/MutableBox/Vec/Parallelogram` `*Native` |
| `strokes/` | `StrokeInput/StrokeInputBatchNative/MutableStrokeInputBatchNative` |
| `nativeloader/` | `UsedByNative/StatusNative` — **native 库加载** |

## 应用实际使用面（26 defpackage 文件）

```text
StrokeInput            ×9   — 笔迹输入点
MutableBox/ImmutableBox/BoxAccumulator ×13 — 包围盒累积
StrokeInputBatchNative/MutableStrokeInputBatchNative ×7 — JNI 批量输入
Vec/ImmutableVec/ImmutableParallelogram/AngleNative — 几何
UsedByNative/StatusNative — 加载标记
```

→ 应用只用 Ink 的**输入批处理 + 几何边界**；
brush/render 未直接使用（笔迹渲染走自研 GL `bpd` +
`mwd/nwd/owd` — Phase 1183 对齐）。

## 判定

AndroidX Ink = Jetpack 笔迹库（native `*Native` JNI 桥 +
Skia 核心）—— 用于 StrokeInput 批处理/几何盒；
属**外部 SDK 依赖边界**（native-backed）。

## Harmony 决策（fail-closed）

- 无 AndroidX Ink on Harmony → 自研 ArkTS
  `StrokeInputBatch`（点序列+压力/tilt/timestamp）+
  `BoxAccumulator`（包围盒扩展）——语义对齐、
  无 native 依赖。
- 输入批语义对齐 `bi8` MultiPointerPredictor（Phase 1175）。

## 产出

- fixture `d02-androidx-ink.mjs`（10 断言）。
- ADR-1147；中文报告。
