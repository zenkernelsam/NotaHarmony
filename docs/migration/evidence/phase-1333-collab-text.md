# Phase 1333 证据 — 协作文本 op（INSERT/REMOVE/REVIVE_CHARS）

来源：`data/{OriginalLocalTextMutation,OriginalInsertText
Operation,OriginalPageOperationApplier,OriginalRichTextStyle
Operation}.ets`。

## `OriginalLocalTextMutation` = 逐字符 CRDT

```
StoredCharacter{identity, visible, …} —— 逐字符身份+墓碑
planOriginalLocalTextMutation(characters, before, after):
  remove → character.visible = false（墓碑，非物理删）
  revive → character.visible = true（复活）
  insert → predictOriginalTextInsertionIdentity(ts, siteId)
previewOriginalLocalTextMutation —— 模拟→计划
identityKey(character.identity) —— 逐字符 CRDT 身份
```

→ **逐字符 CRDT**：remove=置 `visible=false`（墓碑）、
revive=置回 `true`、insert=按 CRDT 身份插入 —— 对照
`haa` INSERT_CHARS/REMOVE_CHARS/REVIVE_CHARS（协作
文本，墓碑支持并发编辑+撤销复活）。

## `OriginalPageOperationApplier` + `RichTextStyle`

- `OriginalPageOperationApplier` —— op 落页应用。
- `OriginalRichTextStyle{Operation,State,PayloadEncoder}`
  —— characterStyleRuns 富文本样式。

## Harmony 决策

协作文本 = 逐字符身份 + visible 墓碑 + 预测身份 —
— 对照 `haa` 文本 op 语义（墓碑支持 REVIVE_CHARS）。

## 产出

- fixture `d02-collab-text.mjs`（10 断言）。
- ADR-1276；中文报告。
