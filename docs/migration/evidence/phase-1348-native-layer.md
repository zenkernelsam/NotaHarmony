# Phase 1348 证据 — 原生 C++ 层（microtex LaTeX + natives）

来源：`note/src/main/cpp/{nota_math.cpp,nota_recording.cpp,
CMakeLists.txt}`+`third_party/microtex`（144 源文件）+
`third_party/tinyxml2`。

## `nota_math.cpp` = 原生数学渲染器（libnota_math）

```
NAPI + OH_Drawing_*（Harmony native-drawing API：
  Bitmap/Brush/Canvas/Font/Pen/RoundRect/TextBlob/Typeface）
+ microtex/clatexmath（latex.h/render.h/graphic.h ——
  LaTeX→排版→位图）
界限：MAX_LATEX_BYTES=64K / MAX_BITMAP_EDGE=4096 /
  MAX_BITMAP_BYTES=16MB / MAX_FONT_SIZE=512 /
  ITALIC_SKEW_X=-0.25f / gMathMutex 守卫初始化
```

→ 数学引擎 = **真原生 C++ 移植**：LaTeX（clatexmath/
microtex 排版引擎）经 Harmony native-drawing 出位图 —
— 对照原版 `libglmath.so`（`nativeInit`/`nativeMeasure`/
`nativeDraw`+SharedMemory），Harmony 用 microtex+
native-drawing 替代 GL 管线。

## `third_party/microtex` = clatexmath 排版引擎

144 源文件：`atom`/`box`/`core`/`graphic`/`parser`/`platform`
(skia/cairo)/`res`（fonts: cyrillic/latin/greek/maths/euler）
—— 完整 LaTeX 数学排版器。

## `nota_recording.cpp` = 录音原生（libnota_recording）

录音 native 实现 + `tinyxml2`（XML 解析）。

## Harmony 决策

数学 = microtex clatexmath + `OH_Drawing` 原生渲染
（替代原版 GLMath/`libglmath.so` GL 管线）；录音 =
`nota_recording` 原生 —— 原生层真移植。

## 产出

- fixture `d02-native-layer.mjs`（10 断言）。
- ADR-1290；中文报告。
