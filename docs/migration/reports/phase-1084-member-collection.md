# Phase 1084 报告 — 成员集合实体 + m4c spec

## 完成内容

- `cie`/`hp5` = 块 spec 变体，持 `m4c` 子集合（嵌套）；
  `cie` 文本块、hp5 媒体块（`dp5`+caption）。
- `m4c implements qg2,o4c,t3c` = 集合 spec（margins/纵横/
  子项/细节类型）+ `D` copy-with。
- `dp5` = 块详情 FlatBuffers 表。

## 产出

- evidence `phase-1084-member-collection.md`
- fixture `d02-member-collection.mjs`（10/10）
- ADR-1028
