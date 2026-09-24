# ADR-0622 独立音频文件导入（cv5 音频分支 / izi.M）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：655
- 接续：ADR-0619/0620/0621（文件导入系列）、T-032（录音持久化）
- 证据：`docs/migration/evidence/original-audio-file-import-jadx-2026-09-24.md`

## 背景

原版 Import File 的音频分支（`nj3` 表：mp3/mp4/aac/wav/aiff/m4a）：
`cv5` 把选中文件复制为临时文件，`MediaMetadataRetriever.
extractMetadata(9)` 取时长毫秒（任何失败兜底 `j=0`），MIME 经
`nj3.I → fsi.I(uri) → "audio/*"` 回退链，产出
`pu5(file, duration, mime)` + `o88(..., 0页)`；`yq8.f` 路由到
`izi.M`：IO 线程 `re0` 建录音资产 `akb`，`iaj.a(null, stem, akb,
0L, duration, xgb)` 造 `yn2` CREATE_RECORDING 实体，
`te0` variant 0 单 op —— **不建页**（导入结果为仅含录音的笔记）。

Harmony 已具备 `persistCapturedOriginalRecording`（pending→final
资产 + `encodeOriginalLocalCreateRecording` + `markAssetLocal` +
op 追加）与 `AVMetadataExtractor` 时长提取原语。

## 决定

1. **选择器**：`fileSuffixFilters` 追加
   `.mp3/.mp4/.aac/.wav/.aiff/.m4a`（nj3 音频表精确子集）。
2. **分发**：`.txt` 检查后追加音频后缀 → `importAudioFromBytes`；
   其余类型继续回退 `.note` ZIP。
3. **MIME**：`IMPORTED_AUDIO_SUFFIX_MIME` 后缀→MIME 精确映射
   （mp3→audio/mpeg、mp4/m4a→audio/mp4、aac→audio/aac、
   wav→audio/wav、aiff→audio/aiff）；未命中回退 `'audio/*'`
   （原版回退链尾段）。
4. **时长**：`extractImportedAudioDuration` 用
   `media.AVMetadataExtractor` + `fdSrc` 读 `metadata.duration`，
   非数字/失败/负值 → `0`（对齐 `j=0`）；extractor 与 fd 全
   `finally` 释放。
5. **暂存**：字节落 `assets/pending/audio_import_*.tmp`（
   `persistCapturedOriginalRecording` 需要真实路径 + stat 校验）；
   persist 的 finally 删暂存（无论成败），persist 前失败手动
   unlink。
6. **落库**：`importMutex` 内 `createNoteWithMeta`（0 页，
   `hasRecordings=true`）→ `persistCapturedOriginalRecording`
   （`startTime=now`、`endTime=now+durationMs`、`durationMs`、
   `mediaDurationMs`）；异常 → `removeFailedImport` 清理后
   `CORRUPTED`。导入报告 `pageCount: 0`（对齐 `o88` 页数=0）。
7. **标题**：复用 `importedFileStemTitle`（`lvd.a1(name,'.')`
   同义）。

## 有意差异（fail-closed / 记录项）

- **startTime**：原版 `0L`（无捕获时刻）；Harmony 本地写者校验
  `startTime>0` 且 `endTime===startTime+duration` —— 记导入时刻
  `[now, now+duration]`。语义上录音时间戳=导入时间，可接受且
  fail-closed。
- **segments/color**：原版 `yn2` 支持 segments 与 `xgb` 颜色；
  Harmony 本地写者省略 segments、zIndex=0（与既有本地录音一致）。
- **`.mp4` 视频**：nj3 把 `.mp4` 归类 `audio/mp4`；Harmony 后缀
  分发同样按音频导入 —— 视频文件会导入为录音（与 nj3 表语义
  一致，fail-closed 记录）。
- **时长格式覆盖**：`AVMetadataExtractor` 与 Android
  `MediaMetadataRetriever` 覆盖略有差异；均回退 0。
- 其余原版类型（Office/Apple 格式等）仍 fail-closed。

## 验证

- 专项 Replay `d05-original-audio-file-import.mjs`：23 项全绿。
- 既有 `d02-note-import-file-handle-lifecycle.mjs`：7/7；
  `d02-local-create-page-outbound` 计数仍为 5（音频不建页）。
- 全量 Desktop Replay：见 Phase 655 报告记录的最终计数。
- `note@ohosTest` / `note@default` clean HAP 构建均成功
  （仅既有告警，无新增错误）。
- 未做模拟器/真机验证（按项目约束）。
