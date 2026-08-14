# ADR-0209：Native Math 测量与绘制必须分离 subpixel 字体状态

## 状态

Accepted，2026-08-15。

## 问题

原版 Notability 1.0.3 的公式文字测量与绘制使用相同的字体来源、style 和 size，但没有使用相同的 Paint flags：

- `GLMathTextMeasurer.measure()` 创建 `Paint(1)`；
- `MathDrawTarget` 的 `textPaint` 创建为 `Paint(129)`；
- `129 = 1 | 128`，绘制比测量多出 Android 的 subpixel text flag。

Harmony 旧实现只保存一个 `OH_Drawing_Font`，并始终调用 `OH_Drawing_FontSetSubpixel(font, true)`。这个 Font
既交给 `OH_Drawing_FontMeasureText()`，又用于创建绘制 TextBlob，因此把原版只属于绘制阶段的 subpixel 状态错误带进了
布局测量。advance 一旦因 hinting、定位或取整不同，`TextRenderingBox` 的宽度、后续上下标位置和整体公式 fit 都可能漂移。

## 原版依据

- `decompiled_1.0.3/.../GLMathTextMeasurer.java` 明确为测量创建 `new Paint(1)`。
- `decompiled_1.0.3/.../MathDrawTarget.java` 明确为文字绘制创建 `new Paint(129)`，stroke/fill 仍为 `Paint(1)`。
- 原版 `TextLayout_Android::getBounds @ 0x220db8` 调用 `GLMathTextMeasurer.measure()` 获取 advance/ascent/descent。
- 原版 `Graphics2D_Android::drawWide @ 0x22074c` 则把相同 file/style/size 交给 `MathDrawTarget.drawText()`。
- Harmony Native Drawing 的 subpixel 是 `OH_Drawing_Font` 自身状态；同一个 Font 无法同时表达上述两套原版 flags。

## 决策

1. 一个 `HarmonyFont` 内持有两个 Native Font handle：
   - `font_`：绘制专用，subpixel 为 `true`；
   - `measureFont_`：测量专用，subpixel 为 `false`。
2. 两个 handle 必须通过同一个配置函数共享：
   - Typeface；
   - text size；
   - anti-alias edging；
   - fake bold；
   - italic skew。
3. `HarmonyTextLayout::getBounds()` 只能使用 `measureNative()` 获取 metrics 与 advance。
4. `HarmonyGraphics::drawText()` 只能使用 `native()` 创建 TextBlob。
5. 任一阶段所需 Font 分配失败时维持既有失败关闭语义：测量返回零 bounds，绘制否决整张公式位图。
6. 析构时先销毁两个 Font handle，再销毁它们共享的 Typeface。
7. replay 必须同时锁定原版 `1/129` flags、Harmony 两个 handle 的配置对称性和 measure/draw 使用边界。

## 结果

- 公式文字 advance 不再错误继承原版只用于绘制的 subpixel 状态。
- TextRenderingBox 的 width、上下标定位和整体 fit 更接近原版测量路径。
- 绘制阶段仍保留 subpixel 字形定位，不牺牲原版 `MathDrawTarget` 的文字渲染契约。
- 粗体、斜体、externalfont、fallback 与字号在测量和绘制之间仍保持一致。

## 边界

- Android Paint 与 Harmony Native Drawing 的 hinting、fallback 和栅格器不同，本决策只消除进入平台 API 前已经存在的
  flags 语义偏差，不承诺像素完全一致。
- `OH_Drawing_FontGetMetrics()` 通常不受 subpixel 影响，但仍固定使用 measure Font，避免未来平台实现出现状态分叉。
- 真机需要用含空格、小字号、斜体、CJK 与 emoji fallback 的文字公式对比宽度和右边缘像素。
