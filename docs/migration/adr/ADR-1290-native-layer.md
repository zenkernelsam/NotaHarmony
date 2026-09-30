# ADR-1290：原生 C++ 层

## 状态

已接受（Phase 1348）。

## 决策

数学 = microtex clatexmath + `OH_Drawing` 原生渲染
（替代原版 GLMath/`libglmath.so` GL 管线）；录音 =
`nota_recording` 原生。

## 理由

`nota_math.cpp`：NAPI+`OH_Drawing_*`+microtex（`latex.h`/
`render.h`/`graphic.h`，144 文件 clatexmath 排版引擎含
cyrillic/latin/greek/maths 字体）LaTeX→位图；界限
64K/4K/16MB+mutex 初始化。对照原版 `libglmath.so` —
— Harmony 用 microtex+native-drawing 替代 GL 管线，
**真原生移植**。

## 后果

数学渲染为真原生 clatexmath 排版 —— 非 fail-closed，
LaTeX→位图管线完整。
