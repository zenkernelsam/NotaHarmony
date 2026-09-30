# Phase 1310 报告 — `.note` 导入

## 完成内容

- Harmony `NoteImporter` = **iOS `.note` ZIP 导入**：
  ZipReader→`Session.plist`（加密检测）→manifest/录音/
  页/元素解析→`%PDF-` magic 嗅探→资产解码→副本导入；
  对照原版 `jv5`(500MB URI 上限）/`qc`(Add Files)/`yq8`
  （未映射 fail-closed）+ `recordings.json`→`CREATE_
  RECORDING` 同步；`NotabilitySessionParser`（GLKeyed
  Archiver/bplist00/小端 IEEE-754/InkedSpatialHash 形状
  层）—— `.note` 导入语义保真。

## 产出

- evidence `phase-1310-note-import.md`
- fixture `d02-note-import.mjs`（10/10）
- ADR-1254
