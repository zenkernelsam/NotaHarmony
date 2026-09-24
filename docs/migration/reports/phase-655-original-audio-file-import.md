# Phase 655：独立音频文件导入（cv5 音频分支 / izi.M）

日期：2026-09-24
接续：Phase 654（独立文本文件导入）
ADR：ADR-0622
证据：`docs/migration/evidence/original-audio-file-import-jadx-2026-09-24.md`
专项 Replay：`docs/migration/replays/d05-original-audio-file-import.mjs`（23 项）

## 原版行为（硬证据）

- `i58.java:6`：选择器 `i58.c = new i58("*/*")`。
- `nj3.java`：音频表 —— `mp3("audio/mpeg")`、`mp4("audio/mp4")`、
  `aac("audio/aac")`、`wav("audio/wav")`、`aiff("audio/aiff")`、
  `m4a("audio/mp4")`。
- `cv5.java`：`jv5.f` 复制临时文件 → `MediaMetadataRetriever.
  extractMetadata(9)` 时长（IOException/IllegalArgument/
  IllegalState/Runtime 全兜底 `j=0`）→ MIME 回退链
  `nj3.I → fsi.I(uri) → "audio/*"` →
  `pu5(o88(...,0页,false), file, j, mime)`。
- `pu5.java`：`File K` + `long L`（时长）+ `String M`（MIME）；
  `a()` 删临时文件。
- `yq8.java:35-37`：`uu5 instanceof pu5 → izi.M`。
- `izi.java` variant 3：`xj2.T(t13.K, new re0(file, str, pu5, p29,
  ttf, null, 0))` IO 建资产 `akb` → `te0(iaj.a(null, lvd.a1(name,'.'),
  akb, 0L, duration, xgb), 0)` 单 op；IOException → 记
  `Failed to create audio recording asset` + `ozb`。
- `yn2.java`/`zq9.java:18`：CREATE_RECORDING 实体（akb required、
  start/end/name/segments/color），`haa.CREATE_RECORDING`（type 5）；
  `te0` variant 0 不建页。

## Harmony 实现（`NoteImporter`）

1. **选择器**：`fileSuffixFilters` 追加
   `.mp3/.mp4/.aac/.wav/.aiff/.m4a`。
2. **分发**：`.txt` 检查后音频后缀 → `importAudioFromBytes`。
3. **MIME**：`IMPORTED_AUDIO_SUFFIX_MIME` 精确映射（nj3 表），
   未命中回退 `'audio/*'`。
4. **暂存**：字节落 `assets/pending/audio_import_*.tmp`；
   persist 的 finally 删除（无论成败）。
5. **时长**：`extractImportedAudioDuration` ——
   `AVMetadataExtractor` + `fdSrc` 读 `metadata.duration`，
   失败/非数字 → `0`；extractor/fd 全 finally 释放。
6. **落库**：`importMutex` 内 `createNoteWithMeta`（0 页，
   `hasRecordings=true`）→ `persistCapturedOriginalRecording`
   （`startTime=now`、`endTime=now+durationMs`）→ 报告
   `pageCount: 0`；异常 → `removeFailedImport`。
7. **标题**：`importedFileStemTitle`（`lvd.a1(name,'.')` 同义）；
   `imageImportTitle` 重命名（3 条路径共用）。

## 有意差异（fail-closed / 记录项）

- **startTime**：原版 0L；Harmony 记导入时刻
  `[now, now+duration]`（本地写者校验 startTime>0）。
- **segments/color**：原版 `yn2` 支持；Harmony 本地写者省略
  segments、zIndex=0（与既有本地录音一致）。
- **`.mp4`**：nj3/Harmony 均按 `audio/mp4` 导入（视频文件会成
  录音 —— 与 nj3 表语义一致）。
- **0 页笔记**：编辑器 `loadPages` 的 zero-page recovery 打开时
  补默认页（对齐原版空笔记 action row 的等价 UX）。
- 其余原版类型（Office/Apple 等）仍 fail-closed。

## 验证

- 专项 Replay：23/23 全绿。
- 既有回归：lifecycle 7/7、create-page-outbound（计数仍为 5 —
  音频不建页）、pdf/image/text 三个 import fixture 全绿。
- 全量 Desktop Replay：540/540。
- `note@default` 构建成功，无新增错误（仅既有告警）。
- `note@ohosTest`/`note@default` clean HAP 构建均成功。
- 未做模拟器/真机验证（按项目约束）。

## 文件清单

- `note/src/main/ets/data/NoteImporter.ets`（+`@kit.MediaKit`/
  `persistCapturedOriginalRecording`/`OriginalRecordingCaptureResult`
  导入、音频后缀-MIME 常量、`.mp3...` 过滤与分发、
  `importAudioFromBytes`、`isImportedAudioFileName`/
  `audioMimeForFileName`/`extractImportedAudioDuration`、
  `imageImportTitle` → `importedFileStemTitle` 重命名）
- `docs/migration/replays/d05-original-audio-file-import.mjs`（新增）
- `docs/migration/evidence/original-audio-file-import-jadx-2026-09-24.md`
- `docs/migration/adr/ADR-0622-original-audio-file-import.md`
- `docs/migration/reports/phase-655-original-audio-file-import.md`
- 三份跟踪文档
