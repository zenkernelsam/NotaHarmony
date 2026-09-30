# Phase 1263 报告 — 文本布局栈

## 完成内容

- Compose 文本布局管线：`vpe`=TextLayoutInput（a00+
  zqe+rq4+nv6+constraints）→`fp0`=MultiParagraphIntrinsics
  →`wh8`=MultiParagraph（fp0+lineCount+paragraphs）→
  `upe`=AndroidParagraph（TextPaint+StaticLayout+
  TruncateAt）→`wpe`=TextLayoutResult（`a`/`b` 几何）+
  `ype` holder（yme+p6a+mv6 映射）。

## 产出

- evidence `phase-1263-text-layout.md`
- fixture `d02-text-layout.mjs`（10/10）
- ADR-1207
