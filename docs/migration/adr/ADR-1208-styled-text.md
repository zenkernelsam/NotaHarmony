# ADR-1208：AnnotatedString+TextStyle

## 状态

已接受（Phase 1264）。

## 决策

`a00` AnnotatedString+`zqe` TextStyle（gnd/e5a/ima）
→ Harmony `StyledString`/`TextStyle`+Span/ParagraphStyle。

## 理由

`a00`=`List<zz>` 注解+span/para 二分（K/L）；`zqe`=
`{gnd SpanStyle, e5a ParagraphStyle, ima PlatformStyle}`
+merge —— 富文本模型。

## 后果

Harmony 富文本 = StyledString+TextStyle+Span ——
样式语义保真。
