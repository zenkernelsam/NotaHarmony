# Phase 1120 证据 — glmath 数学渲染桥（GLMathNative + MathDrawTarget + TextMeasurer）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
（`com/gingerlabs/notability/core/glmath/` 未混淆）

## `GLMathNative` = JNI 数学渲染（`loadLibrary("glmath")`）

```java
native boolean nativeInit(String resPath);
native float[] nativeMeasure(String latex, float width, float fontSize);
native boolean nativeDraw(String latex, float w, float h,
                          float fontSize, int argbColor,
                          MathDrawTarget target);
```

`@Metadata` 真实签名保留 —— LaTeX→布局→绘制全在 native `glmath`。

## `MathDrawTarget(Canvas)` = native 回调的绘制面

`drawLine / drawRect / drawRoundRect / drawText / fillRect` —
native 库通过这些原语画到 Android `Canvas`。

## `GLMathTextMeasurer` = Android 侧字体度量桥

`measure(text, fontFile, fontStyle, fontSize) → float[3]
{width, ascent, descent}` —— `Paint` + `lz4.a.a(style,file)`
typeface + `getFontMetrics`。native 布局回调取字度量。

## Harmony 决策

- 数学渲染 = native LaTeX 引擎 —— Harmony 无 `libglmath`；
  fail-closed ADR：若无等价引擎，退化渲染为占位/位图或禁用
  数学块（按原版 graceful-degradation）。
- 度量桥 = `measure→{w,ascent,descent}` 可对齐到
  `@kit.ArkUI`/`measure` 工具。

## 产出

- fixture `d02-glmath.mjs`（10 断言）。
- ADR-1064；中文报告。
