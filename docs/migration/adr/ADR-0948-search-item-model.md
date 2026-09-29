# ADR-0948 — SearchItem 模型 + nnc 折叠算法

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `wkc` = SearchItem 模型 `{noteId, type:me2, subId,
  rawText, pageId?, key=ba6.s}`；行写入时
  `foldedText=nnc.a(rawText)`（**写入侧折叠**）。
- `me2` 7 值：TITLE/MAIN_BODY_TEXT/TEXT_BLOCK/INK/
  RECORDING_TRANSCRIPT/IMAGE/PDF（序数入库）。
- `ba6.s` = `"{noteId} {typeOrdinal} {subId}"` 键。
- `nnc.a` = NFD + `\p{Mn}+` 移除 + ROOT 小写 +
  16 项定制表（ß→ss…ﬄ→ffl）。
- `glc` = search_item 行（rects:byte[]）。

## Harmony 决策

折叠算法逐字复刻（写入侧等价，与有无 FTS5 无关）；
类型序数与键格式保留。

## Parity 状态

等价（折叠层）；FTS 后端见 ADR-0947。

## 验证

- `d02-search-item-model.mjs`：16/16 通过。
