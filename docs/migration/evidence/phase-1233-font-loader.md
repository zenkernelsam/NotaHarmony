# Phase 1233 证据 — 字体加载 + ReplacementSpan（lyb/mac/ifj/nlf）

来源：`defpackage/{lyb,mac,ifj,nlf,klf,ze,mlf}.java`。

## `lyb` = ResourcesCompat.Font 异步加载器

```java
static ThreadLocal a;
static WeakHashMap b;           // 缓存
static Typeface a(Context, resId);
static Typeface b(Context, resId, TypedValue, i, ifj callback, b, b);
    if (!isFontResource) throw Resources.NotFoundException("...is not a Font");
    typeface = klf.b.c(klf.d(resources, resId, string, assetCookie, i));
```

ThreadLocal + WeakHashMap 缓存 + `klf` 资源工具 +
`ifj` 异步回调 —— support-library 字体加载。

## `ifj` = FontCallback（异步字体回调）

```java
abstract class ifj {
    static Handler c();
    void b(Typeface);            // 主线程投递
    abstract e(Typeface);        // onFontRetrieved
}
```

## `mac` = 文本绘制 Paint holder

```java
final g9c a;                    // 文本源
final Paint d, e;               // 双 Paint
paint.setTypeface(Typeface.DEFAULT);
```

## `nlf extends ReplacementSpan` = 内嵌可绘制 span

```java
draw(Canvas, CharSeq, i, i2, x, top, y, bottom, Paint) {
    CharacterStyle[] styles = ((Spanned)text).getSpans(i,i2,CharacterStyle.class);
    // 取 ze.J Typeface 应用到独立 paint → 内嵌图/数学绘制
    paint2.setTypeface(ze.J);
}
getSize(Paint, CharSeq, i, i2, FontMetricsInt);
```

## 语义

- `lyb` = 资源字体异步加载（FontCallback 主线程回调）；
- `nlf` = 内嵌图像/数学 span —— 读 `CharacterStyle` span
  的 Typeface → 独立 Paint 绘制（baseline 对齐 via
  `getSize`+FontMetrics）;
- `mac`/`ifj`/`klf`/`ze`/`mlf` = 字体管线支撑。

## Harmony 决策

ResourcesCompat+Typeface → Harmony `font` 框架 +
`registerFont`/`FontDescriptor`；`nlf` ReplacementSpan →
StyledString `CustomSpan`/`ImageSpan`。

## 产出

- fixture `d02-font-loader.mjs`（10 断言）。
- ADR-1177；中文报告。
