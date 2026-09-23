# Phase 626 — .note 导出携带 Recordings/ 音频条目（x59/j0.m）

## 原版证据

- `x59.java:490-526`：写完 `<名>.pdf` 条目后循环
  `listT1`（`!aa6.V` 过滤的可见录音）：`zq6.h` 按资产哈希
  解析文件，`fileH.exists()`（:496）缺失则静默跳过；
  `MimeTypeMap.getExtensionFromMimeType(mime)`（:497）定
  扩展名、null 兜底 `"mp4"`（:498-500）；条目名
  `Recordings/` + `j0.m(name)`（:501）+ `.` + ext；
  `LinkedHashSet` 去重，重名改写 `名 (n)`（r11 自 1 起，
  :510-513）；`FileInputStream` 原样流拷贝（:514-518）。
- `j0.java:42-64`（j0.m）：非法字符
  `[/\\:*?"<>|\x00]` → `_`，剥前导 `.`，空 → `"Note"`。
- `oj3.java:32`：原版录音 mime 域 `{mp3, mp4, aac, wav,
  aiff, m4a}`。

## 排查结论

Harmony 录音链路（采集 `OriginalRecordingMicrophoneBackend`、
持久化 `OriginalRecordingStore`/`OriginalRecordingPersistence`、
导入盘点 `NoteImporter`、播放）完整，但 `NoteExporter` 只写
页面 JSON + 图片 + PDF——`.note` 导出包丢失全部录音资产，
往返导入后 `meta.hasRecording` 为假。属移植缺口而非行为
分歧。

## 修复

- `NoteExporter.ets`：图片/PDF 资产之后追加录音循环——
  `listVisible` 取可见录音；`assetState !== READY` 或
  `resolveOriginalAsset` 失败即跳过（等价 `fileH.exists()`
  fail-soft）；`readVerifiedOriginalAsset` 校验后
  `addEntry` 写入。
- `sanitizeOriginalRecordingEntryName`：逐条对齐 j0.m
  （替换 `_`、剥前导点、空→`Note`），不复用
  `safeFileName`。
- `originalRecordingExportExtension`：Android
  `MimeTypeMap` 等值映射表（m4a/aac/mp3/wav/aiff/3gp/
  amr/ogg/flac），未知 → `mp4`。
- `usedRecordingEntries` + `dedupeIndex`（自 1）实现
  `名 (n)` 去重，同构原版 `linkedHashSet`/`r11`。

## 回归验证

- `d02-original-export-recordings.mjs`（新增）：原版
  x59/j0 源码证据锚点 + Harmony 实现锚点 +
  净化/扩展名/去重模拟 → 29/29 PASS。
- 全量 Desktop Replay：515/515 PASS。
- `note@default` + `note@ohosTest` HAP 构建成功。

## 文件

- `note/src/main/ets/data/NoteExporter.ets`
- `docs/migration/replays/d02-original-export-recordings.mjs`
- `docs/migration/evidence/original-export-recordings-2026-09-28.md`
- `docs/migration/adr/ADR-0595-original-export-recordings.md`
- `docs/migration/reports/phase-626-original-export-recordings.md`
