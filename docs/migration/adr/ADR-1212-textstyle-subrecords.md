# ADR-1212：TextStyle 子记录

## 状态

已接受（Phase 1268）。

## 决策

`gnd`/`e5a`/`ima`/`rq4` TextStyle 子记录 → Harmony
`TextStyle`+`ParagraphStyle`+字体解析。

## 理由

`gnd`=SpanStyle（Brush/字体/字距/基线/locale）；
`e5a`=ParagraphStyle（对齐/行高/缩进/断行）；
`ima`=PlatformTextStyle；`rq4`=FontResolver ——
Compose 文本样式三段分解。

## 后果

Harmony 文本样式 = TextStyle+ParagraphStyle+Font ——
样式分解保真。
