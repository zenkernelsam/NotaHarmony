# ADR-0850 — `r29` NoteBundle 读契约钉死

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `r29` = NoteBundle 八字段：noteId@0(utf16B)、
  legacyNoteId@1(utf)、editorSite@2(short)、
  editorUserId@3(str)、createdAt@4(long)、
  creatorUserId@5(str)、ops@6(uq9 向量)、
  schemaVersion@7(short)——accessor→c(4+2i) 全实证。

## Harmony 对照结论

`decodeOriginalNoteBundle` 逐字段对齐（noteId 16B/
editorSite u16/ops 必填向量/schemaVersion u16 +
3/5 byteVector 校验）。**有意分歧**：原版 payloadType
越界→NONE 宽容；Harmony 引导重放 throw——fail-closed
（宁拒不错放），属合规差异。

## Parity 状态

等价 + 一条已记录的 fail-closed 严格化。

## 验证

- `d02-r29-bundle-map.mjs`：15/15 通过。
- 全量 Replay 779 文件绿，见 Phase 906 提交。
