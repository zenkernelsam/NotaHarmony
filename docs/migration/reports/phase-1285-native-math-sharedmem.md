# Phase 1285 报告 — 原生数学渲染 + 共享内存

## 完成内容

- `GLMathNative`（`libglmath.so`）= 原生 LaTeX→GL
  数学渲染（nativeInit/Measure(latex)→float[]/
  Draw(latex→MathDrawTarget)）；`GLMathTextMeasurer`
  文本度量；`MathDrawTarget` GL 目标 —— 数学公式
  原生排版；
- `SharedMemoryByteArena`=`SharedMemory.create().`
  `mapReadWrite()` ashmem 直接缓冲分配器（alloc 跟踪+
  ReferenceQueue+ArenaClosedException）。

## 产出

- evidence `phase-1285-native-math-sharedmem.md`
- fixture `d02-native-math-sharedmem.mjs`（10/10）
- ADR-1229（数学渲染 fail-closed）
