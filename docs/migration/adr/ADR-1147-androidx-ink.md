# ADR-1147：AndroidX Ink 依赖边界（fail-closed）

## 状态

已接受（Phase 1203）。

## 决策

AndroidX Ink SDK（57 文件，`brush`/`geometry`/`strokes`
`*Native` JNI + nativeloader）→ Harmony **无对应库**，
fail-closed：自研 ArkTS `StrokeInputBatch` +
`BoxAccumulator`（语义对齐、无 native）。

## 理由

26 defpackage 文件仅用 `StrokeInput`×9 + 批处理
native×7 + `geometry` 盒×13 —— 输入/几何子集；
渲染为自研 GL（Phase 1177/1183），brush 未用。
`*Native` = JNI 桥 → 不可移植。

## 后果

Harmony 笔迹输入 = 自研批量点模型（对齐 `bi8`
预测器 Phase 1175），不引入 native 依赖。
