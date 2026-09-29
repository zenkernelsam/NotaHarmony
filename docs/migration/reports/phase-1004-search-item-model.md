# Phase 1004 报告 — SearchItem 模型 + 折叠算法

## 范围

wkc 模型、me2 类型枚举、nnc.a 折叠、ba6.s 键、
glc 行映射。纯审计。

## 原版发现

- `wkc{noteId, type, subId, rawText, pageId, key}`；
  写入 `glc` 时 `foldedText = nnc.a(rawText)`。
- `me2` 七类：TITLE/MAIN_BODY_TEXT/TEXT_BLOCK/INK/
  RECORDING_TRANSCRIPT/IMAGE/PDF。
- `nnc.a` = NFD + `\p{Mn}+` 剥离 + ROOT 小写 +
  16 项定制折叠表（ß→ss, æ→ae, œ→oe, ø→o, ł→l,
  đ→d, ð→d, þ→th, ħ→h, ŧ→t, ı→i, ﬀ→ff, ﬁ→fi,
  ﬂ→fl, ﬃ→ffi, ﬄ→ffl）。
- `ba6.s` 键 = `"noteId typeOrdinal [subId]"`。

## Harmony 决策

折叠算法逐字复刻（独立于 FTS 可用性）。

## 产出

- 证据：`phase-1004-search-item-model.md`
- Fixture：`d02-search-item-model.mjs`（16/16）
- ADR-0948；全量 Replay 见本提交。
