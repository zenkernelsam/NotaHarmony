# Phase 1185 证据 — 文本 span 层（nlf ReplacementSpan + 字库缓存）

来源：`defpackage/{nlf,lyb,ifj,mac}.java`。

## `nlf extends ReplacementSpan` = 内联可绘 span

```java
nlf extends ReplacementSpan:
  TextPaint M
  Paint.FontMetricsInt I
  draw(Canvas, CharSequence, int,int, float, int,int,int,
       Paint)             // baseline 处绘嵌入内容
  getFontMetricsInt(...) // 布局度量
```

**内联 ReplacementSpan** —— 文本流中嵌入非文本内容
（图片/数学/图标），`draw` 于 baseline，`getFontMetricsInt`
给行高 —— 数学公式（glmath）等以 span 嵌入文本。

## `lyb` = 字库缓存（ThreadLocal + WeakHashMap）

```java
ThreadLocal a + WeakHashMap b + Object c(lock)
```

Typeface 懒缓存（WeakHashMap 键、ThreadLocal）——
避免重复加载字体。

## `ifj`/`mac` = 字库持有者

- `ifj`：抽象，`a(int)` 样式 + `b(Typeface)` + `c()→Handler`
  （异步字体回调）。
- `mac`：`{Typeface DEFAULT}` 包装。

## 判定

**文本渲染** = `s3c` 分段（Phase 1133）→ Spanned 文本
（`nlf` ReplacementSpan 嵌入图片/数学）+ `StaticLayout`
排版 + `lyb`/`mac`/`ifj` 字库 —— Android TextPaint/
ReplacementSpan 体系。

## Harmony 决策

- `ReplacementSpan` → Harmony **`StyledString`/
  `TextSpan` + 自定义内联 span**（`@kit.ArkUI` 文本
  span / `TextUtils`）。
- `StaticLayout`/`TextPaint` → Harmony 文本排版。
- `lyb` Typeface 缓存 → Harmony `font`/`Font` 缓存。

## 产出

- fixture `d02-text-span.mjs`（10 断言）。
- ADR-1129；中文报告。
