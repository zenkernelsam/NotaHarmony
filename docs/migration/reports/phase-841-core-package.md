# Phase 841 — `core/` 包叶子面闭合

## 范围

`com/gingerlabs/notability/core/` 全部叶子类审计 + Harmony
对照。

## 原版发现

### 类型化异常族（9 类）

network×3（HttpStatus/NoConnectivity/NotAuthenticated）、
retrofit（HttpFailure）、analytics（SpanAborted）、
logging×2（FatalLogError/LoggedError）、memory
（ArenaClosedException）、model（CopyPasteException）——
与 840 synced 族同型：原版错误面重度类型化。

### 共享内存 arena

`SharedMemoryByteArena`——原生墨水缓冲共享内存区
（stroke 跨层零拷贝）。

### `core/glmath` —— libglmath 本地数学引擎

`GLMathNative`（`System.loadLibrary("glmath")`）四 JNI：
`nativeInit`/`nativeMeasure`/`nativeDraw`/`nativeSearchText`——
LaTeX 经 native 排版、绘制至 `MathDrawTarget`、可搜索文本
提取。`GLMathTextMeasurer` 测量门面。

## Harmony 侧

`MathEditorOverlay` 用 `image.PixelMap` 位图预览——非实时
LaTeX 排版引擎。**登记差异**：native 排版不可移植，位图化
路径保持外观语义。

## 验证

- 新 Replay `d02-core-package.mjs`：**18/18**（9 异常类、
  glmath 4 JNI + 2 门面、Harmony 位图/无原生断言）。
- ADR-0785。**`core/` 包闭合。**
