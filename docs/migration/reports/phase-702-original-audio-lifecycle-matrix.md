# Phase 702：原版 AUDIO 全生命周期组合矩阵 — 收口审计

handover P1(c)：在 50 个录音单元级 Replay fixture 后，本轮把 AUDIO
链路五段生命周期放入同一矩阵复核接缝（对照 Phase 701 的 IMAGE
矩阵方法）。

## 审计范围

- **录制→持久化**：`OriginalRecordingCaptureController`（backend +
  audio-source selector）产出 `OriginalRecordingCaptureResult`；
  `persistCapturedOriginalRecording` 在 assetMutationMutex +
  editorPersistenceMutex 嵌套事务内完成：op 身份分配 →
  `encodeOriginalLocalCreateRecording` + envelope →
  `OriginalRecordingOperationApplier.applyTable`（**与同步 op 同一
  应用器**，deferred 即抛）→ `markAssetLocal` → `appendOperation`
  （uploadImmediately）→ `assetAvailabilityHub.publish` → finally
  `unlinkIfPresent` 临时文件必清。
- **音频文件 ingress**：`importAudioFromBytes`/`importAudioIntoNote`
  构造 CaptureResult 复用同一 persist 管线。
- **.note 导入**：`NOTE_RECORDINGS_ENTRY` →
  `parsePackagedRecordings` → `insertImportedOriginalRecordings`
  （CREATE_RECORDING ops）。
- **导出**：`includeRecordings`（yk9.O 语义）→ `listVisible`
  （deleted=0 过滤）→ assets + recordings.json。
- **播放链**：PlaybackController（clampSeek + speed 白名单）、
  RecordingTimeline（跨录音累计导航）、AudioLinkedInkPlayback
  （resolve + sliceStrokeForAudioProgress）、OperationAudioTimeStore。
- **op 双 payload**：CREATE=5 / MODIFY=6 均经同一 applyTable。

## 验证

- 新 Replay：`d02-original-audio-lifecycle-matrix.mjs`（13 断言）。
- 全套件重跑通过后记录于修复总纲。

## 结论

AUDIO 五段生命周期接缝不变量全部在位，无代码变更需求（纯审计
收口阶段）。
