# ADR-1229：原生数学渲染 + 共享内存

## 状态

已接受（Phase 1285）—— **数学渲染 fail-closed**。

## 决策

`glmath` LaTeX→GL 原生渲染 → Harmony 无移植，降级到
KaTeX-JS/Web 或系统公式组件；`SharedMemory` arena →
Harmony `SharedArrayBuffer`/Native Buffer。

## 理由

`GLMathNative`（`libglmath.so`：nativeInit/Measure/Draw
LaTeX→MathDrawTarget）—— 商业级原生数学排版+GL 渲染，
Harmony 无 `glmath`；`SharedMemoryByteArena`=
`SharedMemory.mapReadWrite` ashmem 直接缓冲 arena —
— Harmony 无 ashmem SharedMemory API。

## 后果

Harmony 数学公式 = KaTeX-JS/Web 渲染降级；共享内存 =
SharedArrayBuffer/Native —— 数学渲染 fail-closed，
内存语义部分保真。
