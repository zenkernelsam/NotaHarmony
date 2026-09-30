# Phase 1264 报告 — AnnotatedString+TextStyle

## 完成内容

- `a00`=AnnotatedString（`List<zz>` 注解+`K`/`L` span/
  paragraph 二分）；`zqe`=TextStyle（`{gnd,e5a,ima}`=
  Span/Paragraph/Platform style+`d`/`e` merge+toString
  泄漏 color/fontSize/fontWeight）—— 富文本模型。

## 产出

- evidence `phase-1264-styled-text.md`
- fixture `d02-styled-text.mjs`（10/10）
- ADR-1208
