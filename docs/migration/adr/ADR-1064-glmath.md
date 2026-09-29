# ADR-1064：数学渲染桥（native glmath）

## 状态

已接受（Phase 1120）—— **fail-closed**。

## 决策

- 数学/LaTeX 渲染 = native `libglmath`（`nativeInit/Measure/Draw`）。
- `MathDrawTarget` = native→Canvas 原语回调面。
- `GLMathTextMeasurer` = `Paint` 度量 `{w,ascent,descent}`。

## 依据

`loadLibrary("glmath")` + 3 native 方法 + Canvas 回调。
**Harmony 无 `libglmath` → fail-closed**：数学块退化渲染
（占位/禁编）或需移植等价排版引擎；度量桥可对齐 ArkUI measure。

## 后果

数学编辑功能在 Harmony 版受限（若无等价引擎），记录差异；
度量回调语义保留。
