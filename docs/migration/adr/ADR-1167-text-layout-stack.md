# ADR-1167：文本布局栈（StaticLayout 度量引擎）

## 状态

已接受（Phase 1223）。

## 决策

`vpe/fp0/wh8/upe/wpe` = `TextLayoutInput/
MultiParagraphIntrinsics/MultiParagraph/Paragraph/
TextLayoutResult`（`android.text.Layout`+`TextPaint`
度量）→ Harmony `Paragraph`/`TextMeasurer`
（`@kit.ArkGraphics2D`）。

## 理由

`vpe` 全字段=`TextLayoutInput`；`upe`=`StaticLayout`
+`TextPaint`+`TruncateAt`；`wpe`=`TextLayoutResult`
（baselines+placeholder rects）—— Compose 文本
布局栈实名。

## 后果

Harmony 文本布局 = Paragraph+TextMeasurer —
度量 API 面等价，引擎不同（无 StaticLayout）。
