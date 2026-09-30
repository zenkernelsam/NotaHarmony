# ADR-1207：Compose 文本布局栈

## 状态

已接受（Phase 1263）。

## 决策

`vpe`→`fp0`→`wh8`→`upe`(StaticLayout)→`wpe` 布局栈
+`ype` holder → Harmony `TextInput`/`Span`+`Paragraph`
+`font.measureText`。

## 理由

`vpe`=TextLayoutInput、`fp0`=MultiParagraphIntrinsics、
`wh8`=MultiParagraph、`upe`=AndroidParagraph(StaticLayout)、
`wpe`=TextLayoutResult —— Compose 文本布局管线。

## 后果

Harmony 文本布局 = TextInput+Paragraph+measureText —
— 布局语义保真。
