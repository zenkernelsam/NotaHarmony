# Phase 1223 证据 — 文本布局栈（vpe/fp0/wh8/upe = Compose 实名）

来源：`defpackage/{wpe,vpe,fp0,wh8,upe}.java`。

## Compose 文本布局实名映射

| 类 | 真实类型 | 关键字段 |
|---|---|---|
| `vpe` | **TextLayoutInput** | `a00 AnnotatedString, zqe TextStyle, List placeholders, int maxLines, bool softWrap, int overflow, r93 Density, nv6 LayoutDirection, rq4 FontFamily.Resolver, long constraints` |
| `fp0` | **MultiParagraphIntrinsics** | `(a00,zqe,List,r93,rq4)` + `J`文本 + `N` ParagraphIntrinsicInfo 列表 |
| `wh8` | **MultiParagraph** | `fp0 intrinsics, int maxLines, bool ellipsis, float w/h, int lineCount, ArrayList g(placeholder rects)+h(ParagraphInfo)` |
| `upe` | **Paragraph**（AndroidParagraph） | `TextPaint, TruncateAt, 2×bool, android.text.Layout f, int lineCount` |
| `wpe` | **TextLayoutResult** | `vpe layoutInput, wh8 multiParagraph, long size, float firstBaseline+lastBaseline, ArrayList placeholderRects` |

## 辅助类型

- `a00` = AnnotatedString、`zqe` = TextStyle、
  `rq4` = FontFamily.Resolver、`nv6` = LayoutDirection、
  `r93` = Density、`z4a` = ParagraphInfo（`upe d`+`f` 偏移）。
- `wh8.n(i)/m(i)` = 偏移→段落定位；`b(i,z)`/`i(l)`/`d(l)`/
  `f(i)`/`j(offset)` = x/top/bottom/line 几何。
- `wpe.a(i)→kxb`/`b(i)→cmb`/`j(i,i2)→jt` = 光标盒/
  字符盒/选区路径。

## 判定

文本布局 = Compose `TextLayoutResult` 完整栈 —
`AndroidParagraph`（`StaticLayout`+`TextPaint`）
逐段渲染，`MultiParagraph` 聚合，`vpe` 输入归一 —
Android `text.Layout` 是最终度量引擎。

## Harmony 决策

`StaticLayout`/`TextPaint`/`BoringLayout` → Harmony
`@kit.ArkGraphics2D`/`Paragraph`/`TextMeasurer`（
段落+字体度量）；`TextLayoutResult` API 面 →
`TextLayoutInfo` 等价。

## 产出

- fixture `d02-text-layout-stack.mjs`（10 断言）。
- ADR-1167；中文报告。
