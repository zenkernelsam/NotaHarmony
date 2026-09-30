# Phase 1336 报告 — `.note` 导出↔导入往返

## 完成内容

- `NoteExporter` = ZIP`.note` 包（manifest.json+pages/
  page_N.json+note.assets 录音+recordings.json，对照
  `yk9`/`v6d.j`/`zk9.a`；`MissingAssetsException` 缺资产
  fail-closed）；与 `NoteImporter`/`SessionParser`/
  `BinaryPlistParser` 读路径对称 —— 往返无损闭环。

## 产出

- evidence `phase-1336-note-roundtrip.md`
- fixture `d02-note-roundtrip.mjs`（10/10）
- ADR-1279
