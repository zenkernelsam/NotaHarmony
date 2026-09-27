# Phase 906 报告 — `r29` NoteBundle 读契约实名

## 范围

钉死线上根表 accessor→偏移图 + Harmony 对照。纯审计。

## 原版发现

- `r29` = NoteBundle 八字段：noteId@0/legacyNoteId@1
  (utf16B)、editorSite@2、editorUserId@3、createdAt@4、
  creatorUserId@5、ops@6(uq9 向量)、schemaVersion@7。

## Harmony 核对

逐字段对齐；**有意分歧**：原版 payloadType 越界→NONE，
Harmony 引导 throw（fail-closed 严格化）。

## 产出

- 证据：`phase-906-r29-bundle-map.md`
- Fixture：`d02-r29-bundle-map.mjs`（15/15）
- ADR-0850；全量 Replay 779 文件绿。
