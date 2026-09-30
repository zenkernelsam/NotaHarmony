# ADR-1129：文本 span 层（ReplacementSpan + 字库缓存）

## 状态

已接受（Phase 1185）。

## 决策

- `nlf extends ReplacementSpan` 内联可绘 span（baseline
  嵌图/数学）→ Harmony `StyledString`/`TextSpan` + 内联
  span。
- `StaticLayout`/`TextPaint` → Harmony 文本排版。
- `lyb` Typeface 缓存（WeakHashMap+ThreadLocal）→
  Harmony font 缓存；`ifj`/`mac` 字库持有者保留。

## 理由

`extends ReplacementSpan`、`draw(Canvas,…,Paint)`、
`FontMetricsInt`、`lyb{ThreadLocal,WeakHashMap}`。

## 后果

文本渲染 = s3c 分段→Spanned（ReplacementSpan 嵌入）→
排版；数学/图经内联 span 落行内；字库缓存对齐。
