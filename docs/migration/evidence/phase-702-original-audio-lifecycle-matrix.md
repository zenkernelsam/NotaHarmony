# Phase 702：原版 AUDIO 全生命周期组合矩阵 — 接缝审计（2026-09-24）

handover P1(c)：在 50 个录音单元级 fixture 后，把 AUDIO 链路五段
生命周期（capture → persist → ingress → import/export → playback）
放入同一矩阵复核接缝。本文件记录矩阵覆盖的接缝地图。

## 录制 capture → 持久化

- `OriginalRecordingCaptureController`：`OriginalRecordingCaptureBackend`
  + `OriginalRecordingAudioSourceSelector`（microphone/internalAudio
  来源选择）产出 `OriginalRecordingCaptureResult`。
- `persistCapturedOriginalRecording`：`assetMutationMutex` 内
  `validateCapture` → `prepareRecordingAsset` →
  `editorPersistenceMutex` 事务 → `allocateOperationIdentity` →
  `encodeOriginalLocalCreateRecording` +
  `encodeOriginalOperationEnvelope` →
  `OriginalRecordingOperationApplier().applyTable`（与同步 op 同一
  应用器，deferred 即抛错）→ `markAssetLocal` → `appendOperation`
  （uploadImmediately）→ commit → `assetAvailabilityHub.publish` →
  finally `unlinkIfPresent(capture.temporaryPath)` 临时文件必清。

## 音频文件 ingress

- `NoteImporter.importAudioFromBytes`/`importAudioIntoNote`：把外部
  音频文件构造成 `OriginalRecordingCaptureResult`，走同一
  `persistCapturedOriginalRecording`（资产 + CREATE_RECORDING op）。

## .note 导入

- `NOTE_RECORDINGS_ENTRY` → `parsePackagedRecordings` →
  `insertImportedOriginalRecordings`：导入录音以 CREATE_RECORDING
  op 落地（与同步 ops 同机制）。

## 导出

- `includeRecordings`（对应原版 yk9.O 分享开关语义）：true 时
  `OriginalRecordingStore.listVisible`（`COALESCE(visibility.deleted,0)=0`
  过滤软删）→ assetHashBits/fileName 入 note.assets +
  `serializePackagedRecordings` 写 recordings.json。

## 播放链

- `OriginalRecordingPlaybackController`：`clampRecordingSeek` 越界
  钳制 + `isSupportedRecordingPlaybackSpeed` 速度白名单。
- `OriginalRecordingTimeline`：`build/locate/nextTimelineRecordingId`
  跨录音累计时间线导航。
- `OriginalAudioLinkedInkPlayback`：`resolveOriginalAudioLinkedPlayback`
  + `sliceStrokeForAudioProgress`（笔迹按音频进度切片）。
- `OriginalOperationAudioTimeStore`：`persistOriginalAppliedOperationTime`
  把 op 的 audioTime 写入应用侧表。

## op 双 payload

- `OriginalRecordingOperationApplier`：`CREATE=5` / `MODIFY=6` 双
  payloadType 受理，`applyTable` 分别走创建与修改（含删除可见性）。

## 结论

组合矩阵 13 断言全绿：capture→persist 同事务 op 化、ingress 复用
管线、import/export 对称、播放链完整、软删过滤在位——AUDIO 接缝
无漂移。
