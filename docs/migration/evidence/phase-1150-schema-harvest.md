# Phase 1150 证据 — w1b 描述符 schema 名大丰收

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
`w1b(Class,"prop","sig")` 全量扫描。

## FlatBuffers 真 schema 类型（`core.flatbuffers.*`）

```
BlockCornerType   BlockWrapSupport   Color
InkStyle          InkTool            LayoutMode
PageBackground    Paper              Rect
Size              TapePattern        TextWrapMode
```

## 真实属性名（按类）

**块/实体**：`cropRect`、`imageFlippedVertically`、
`imageFlippedHorizontally`、`paper`、`resizesWidthToFitText`、
`members`、`background`、`borderWidth`、`color`、`corner`、
`fillColor`、`enableCaption`、`layoutMode`、`blockWrapSupport`、
`alignTextToLines`、`defaultFontFamily`、`defaultFontSize`、
`handwritingLanguage`。

**画笔/渲染**：`bezierPaint`、`bezierBlendPaint`、
`blitPaint`、`centralPathPaint`、`fillPaint`、
`dashPathEffectCache`、`dotsPathEffectCache`、
`colorFilterCache`、`batchScratch`。

## 语义

Kotlin `by` 委托的 `$$delegatedProperties` 保留全部真实
属性名 + 返回类型签名 → `core.flatbuffers.*` 的完整
schema 类型清单可复原 —— 迁移的命名对齐依据。

## 已对齐类型

`Rect`/`Paper`（Phase 1149）、`LayoutMode`/`BlockWrapSupport`
（Phase 1121 a79）、`InkStyle`/`InkTool`/`TapePattern`/
`TextWrapMode`/`BlockCornerType`/`PageBackground`/`Color`
/`Size` —— 12 个 FlatBuffers 表真名。

## Harmony 决策

- 实体属性 + FlatBuffers 表用真名对齐迁移。
- 画笔/渲染属（`bezierPaint`/`blitPaint`/…）为
  `Paint`/`PathEffect` 缓存 —— Harmony 用 Canvas/Paint
  等价。

## 产出

- fixture `d02-schema-harvest.mjs`（10 断言）。
- ADR-1094；中文报告。
