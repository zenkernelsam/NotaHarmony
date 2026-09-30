# Phase 1263 证据 — ype/wpe/wh8/upe/vpe/fp0 文本布局栈

来源：`defpackage/{ype,wpe,wh8,upe,vpe,fp0,z4a,nv6,rq4}.java`。

## `vpe` = `TextLayoutInput`

```java
vpe { a00 a;              // AnnotatedString
      zqe b;              // TextStyle
      List c;             // annotations
      int d;              // overflow
      boolean e;          // softWrap
      int f;              // maxLines
      r93 g;              // density
      nv6 h;              // LayoutDirection
      rq4 i;              // FontResolver
      long j; }           // constraints
```

## `fp0` = `MultiParagraphIntrinsics`

`{a00,zqe,List,r93,rq4}` + lazy Function0 —— 段内秉。

## `wh8` = `MultiParagraph`

```java
wh8 { fp0 a;              // intrinsics
      int b;              // lineCount
      boolean c;          // didOverflow
      float d,e;          // w/h
      int f;              // maxLines
      ArrayList g,h; }    // ParagraphInfo + placeholders
```

## `upe` = `AndroidParagraph`

`{TextPaint, TruncateAt, bool×2, r71}` —— 包
`StaticLayout`/`BoringLayout`+`TextPaint`（Android 文本
布局引擎）。

## `wpe` = `TextLayoutResult`

`{vpe input, wh8 multiPara, long size, float w/h,
ArrayList inlineRects}` + `a(i)→kxb`/`b(i)→cmb`。

## `ype` = 布局 holder

`{yme a,b, p6a c,d,e,f, q21 g}` + `a(long)→long`
（`e()→mv6` LayoutCoordinates 位置映射）。

## 语义

`vpe`(input)→`fp0`(intrinsics)→`wh8`(MultiParagraph)→
`upe`(AndroidParagraph/StaticLayout)→`wpe`(result) —
— Compose 文本布局管线：`ype` 持有结果+布局坐标。

## Harmony 决策

Compose 文本布局 → Harmony `TextInput`/`Span`+
`Paragraph`/`font.measureText` —— 布局语义保真。

## 产出

- fixture `d02-text-layout.mjs`（10 断言）。
- ADR-1207；中文报告。
