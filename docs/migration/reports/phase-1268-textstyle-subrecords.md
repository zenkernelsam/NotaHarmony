# Phase 1268 报告 — TextStyle 子记录

## 完成内容

- `gnd`=SpanStyle（xoe Brush/fontSize/FontWeight/
  FontStyle/FontSynthesis/FontFamily/letterSpacing/
  BaselineShift/LocaleList/background）；`e5a`=
  ParagraphStyle（textAlign/lineHeight/TextIndent/
  LineHeightStyle/lineBreak/hyphens/TextMotion）；
  `ima`=PlatformTextStyle；`rq4`=FontResolver ——
  Compose 文本样式三段分解。

## 产出

- evidence `phase-1268-textstyle-subrecords.md`
- fixture `d02-textstyle-subrecords.mjs`（10/10）
- ADR-1212
