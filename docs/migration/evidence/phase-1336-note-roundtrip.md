# Phase 1336 证据 — `.note` 导出→导入往返

来源：`data/{NoteExporter,NoteImporter,ZipArchive,
NotabilitySessionParser,BinaryPlistParser}.ets`。

## `NoteExporter` = ZIP `.note` 包

```
exportNote(noteId):
  ZipWriter:
    manifest.json（serializeManifest）
    pages/ 目录 + pages/page_N.json（serializePage）
    note.assets（recording/资产，对照 yk9 原版 .note
      export：录音音频并入 note.assets + recordings.json）
    MissingAssetsException —— 缺资产 fail-closed 中止
      （v6d.j/zk9.a->yk9.O 原版语义）
```

→ `.note` 导出 = ZIP {manifest.json, pages/page_N.json,
note.assets, recordings.json} —— 对照原版 `yk9`。

## 导入对称性

`NoteImporter`/`NotabilitySessionParser`/`BinaryPlistParser`
读取同一 ZIP 布局（Session.plist/metadata.plist/
GLKeyedArchiver + recordings.json）—— 导出所写即导入
所读，往返闭合。

## Harmony 决策

`.note` 导出 = ZIP+manifest+pages+assets+recordings
（对照 `yk9`），与 `NoteImporter` 读路径对称 ——
往返无损闭环。

## 产出

- fixture `d02-note-roundtrip.mjs`（10 断言）。
- ADR-1279；中文报告。
