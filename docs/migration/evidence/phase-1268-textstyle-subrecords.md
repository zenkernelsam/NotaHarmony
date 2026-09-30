# Phase 1268 证据 — gnd/e5a/ima/rq4 TextStyle 子记录

来源：`defpackage/{gnd,e5a,ima,rq4,wz}.java`。

## `gnd implements wz` = Compose `SpanStyle`（字符级样式）

```java
xoe a;    // Brush/color（文字颜色/渐变）
long b;   // fontSize
ns4 c;    // FontWeight
js4 d;    // FontStyle
ks4 e;    // FontSynthesis
sq4 f;    // FontFamily
String g; // fontFeatureSettings
long h;   // letterSpacing
es0 i;    // BaselineShift
cpe j;    // TextGeometricTransform
fn7 k;    // LocaleList
long l;   // background
```

## `e5a implements wz` = `ParagraphStyle`（段落级样式）

`{int a=textAlign, int b=textDirection, long c=lineHeight,
fpe d=TextIndent, tla e=PlatformParagraphStyle,
ag7 f=LineHeightStyle, int g=lineBreak, int h=hyphens,
gqe i=TextMotion}` + `a(e5a)` merge。

## `ima` = `PlatformTextStyle`

`{ama a=PlatformSpanStyle, tla b=PlatformParagraphStyle}`
—— Android 平台专有样式覆盖。

## `wz` = 样式部分公共 iface

`gnd`/`e5a` 都实现 `wz`（SpanStyle/ParagraphStyle 同一
可 merge 部分标记）。

## `rq4` = `FontFamily.Resolver` iface

字体解析（FontFamily+weight+style→Typeface）—— `vpe`
布局输入依赖。

## 语义

`zqe` TextStyle = `gnd`(SpanStyle)+`e5a`(ParagraphStyle)+
`ima`(PlatformTextStyle) 三段 —— Compose 文本样式分解。

## Harmony 决策

SpanStyle/ParagraphStyle → Harmony `TextStyle`+
`ParagraphStyle`（RichEditor/Span）—— 样式分解保真。

## 产出

- fixture `d02-textstyle-subrecords.mjs`（10 断言）。
- ADR-1212；中文报告。
