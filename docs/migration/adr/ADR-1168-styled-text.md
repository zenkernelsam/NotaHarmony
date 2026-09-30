# ADR-1168：样式文本栈（AnnotatedString/TextStyle）

## 状态

已接受（Phase 1224）。

## 决策

`a00` AnnotatedString + `zqe` TextStyle + `gnd`
SpanStyle + `ima` ParagraphStyle + `f31` Brush →
ArkUI `StyledString`/`TextStyle`/`ParagraphStyle`/
`LinearGradient`。

## 理由

`a00` 按 `zz` 分 K(span)/L(paragraph) 双列；
`zqe.toString` 泄漏 `TextStyle(color/fontSize/
fontWeight)` —— Compose 双层样式实名。

## 后果

Harmony 样式文本 = StyledString + 双层样式注记 —
与 Compose AnnotatedString 语义对齐。
