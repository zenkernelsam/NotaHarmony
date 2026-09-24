// D02 原版 AUDIO 全生命周期组合矩阵 — Phase 702（handover P1(c)）
// 录音链路的五段生命周期放入同一矩阵复核接缝不变量：
//   1) 录制 capture（controller+backend+source selector）→
//      persistCapturedOriginalRecording；
//   2) 持久化 = 资产 + CREATE_RECORDING op 同事务（与同步 op 同一
//      applyTable 应用器）；assetAvailabilityHub + 临时文件清理；
//   3) 音频文件 ingress 复用同一 persist 管线；
//   4) .note 导入 recordings.json → insertImportedOriginalRecordings；
//   5) 导出 includeRecordings（yk9.O 语义）→ assets + recordings.json；
//   6) 播放链 playback/timeline/linked-ink/audio-time 组件齐备；
//   7) CREATE=5/MODIFY=6 双 payload + deleted 可见性过滤。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');

const persist = read('note/src/main/ets/data/OriginalRecordingPersistence.ets');
const operation = read('note/src/main/ets/data/OriginalRecordingOperation.ets');
const store = read('note/src/main/ets/data/OriginalRecordingStore.ets');
const capture = read('note/src/main/ets/core/adaptation/OriginalRecordingCaptureController.ets');
const playback = read('note/src/main/ets/core/adaptation/OriginalRecordingPlaybackController.ets');
const timeline = read('note/src/main/ets/core/adaptation/OriginalRecordingTimeline.ets');
const exporter = read('note/src/main/ets/data/NoteExporter.ets');
const importer = read('note/src/main/ets/data/NoteImporter.ets');

let total = 0;
const check = (cond, name) => {
  total++;
  if (!cond) console.error(`FAILED: ${name}`);
  assert.ok(cond, name);
};

// --- 1) 录制 capture 管线 ---
check(capture.includes('export class OriginalRecordingCaptureController') &&
  capture.includes('export interface OriginalRecordingCaptureBackend') &&
  capture.includes('export interface OriginalRecordingAudioSourceSelector') &&
  capture.includes('OriginalRecordingCaptureResult'),
  'capture controller + backend + audio-source selector produce a CaptureResult');

// --- 2) 持久化：资产 + CREATE_RECORDING op 同事务 ---
check(persist.includes('export async function persistCapturedOriginalRecording(') &&
  persist.includes('assetMutationMutex.runExclusive') &&
  persist.includes('editorPersistenceMutex.runExclusive') &&
  persist.includes('store.beginTransaction()') &&
  persist.includes('store.commit()') &&
  persist.includes('store.rollBack()'),
  'persist runs asset+op inside nested mutexes + transaction with rollback');
check(persist.includes('encodeOriginalLocalCreateRecording') &&
  persist.includes('encodeOriginalOperationEnvelope') &&
  persist.includes('new OriginalRecordingOperationApplier().applyTable(') &&
  persist.includes('local CreateRecording was deferred'),
  'local recording rides the same CREATE_RECORDING op applier as sync ops');
check(persist.includes('await markAssetLocal(store, noteId, completed)') &&
  persist.includes('appendOperation(store,') &&
  persist.includes('uploadImmediately: true') &&
  persist.includes('assetAvailabilityHub.publish(result.assetHash, [noteId])'),
  'asset marked local + op queued uploadImmediately + availability published');
check(persist.includes('unlinkIfPresent(capture.temporaryPath)'),
  'temporary capture file is always unlinked (finally cleanup)');

// --- 3) 音频文件 ingress 复用同一 persist ---
check(importer.includes('importAudioFromBytes') &&
  importer.includes('importAudioIntoNote') &&
  importer.includes('await persistCapturedOriginalRecording(this.db,'),
  'audio-file ingress materializes a CaptureResult into the same persist path');

// --- 4) .note 导入：recordings.json → CREATE_RECORDING ops ---
check(importer.includes('NOTE_RECORDINGS_ENTRY') &&
  importer.includes('parsePackagedRecordings(bytesToString(recordingsEntry.data))') &&
  importer.includes('insertImportedOriginalRecordings(this.db,'),
  '.note import parses recordings.json and inserts CREATE_RECORDING ops');

// --- 5) 导出：includeRecordings 语义 ---
check(exporter.includes('includeRecordings: boolean = true') &&
  exporter.includes('listVisible(noteId)') &&
  exporter.includes('assetHashBits: recording.assetHashBits') &&
  exporter.includes('fileName: recording.assetFileName'),
  'export honors the includeRecordings flag and packages recording assets');
check(store.includes('COALESCE(visibility.deleted, 0) = 0'),
  'listVisible filters soft-deleted recordings (deleted flag)');

// --- 6) 播放链组件 ---
check(playback.includes('export class OriginalRecordingPlaybackController') &&
  playback.includes('clampRecordingSeek') &&
  playback.includes('isSupportedRecordingPlaybackSpeed'),
  'playback controller with seek clamp + supported-speed gate');
check(timeline.includes('buildOriginalRecordingTimeline') &&
  timeline.includes('locateOriginalRecordingTimeline') &&
  timeline.includes('nextTimelineRecordingId'),
  'cumulative multi-recording timeline navigation');
check(read('note/src/main/ets/core/adaptation/OriginalAudioLinkedInkPlayback.ets')
    .includes('resolveOriginalAudioLinkedPlayback') &&
  read('note/src/main/ets/core/adaptation/OriginalAudioLinkedInkPlayback.ets')
    .includes('sliceStrokeForAudioProgress') &&
  read('note/src/main/ets/data/OriginalOperationAudioTimeStore.ets')
    .includes('persistOriginalAppliedOperationTime') &&
  read('note/src/main/ets/data/OriginalOperationAudioTimeStore.ets')
    .includes('audioTime'),
  'audio-linked ink playback + operation audio-time store');

// --- 7) op 双 payload ---
check(operation.includes('ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE: number = 5') &&
  operation.includes('ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE: number = 6') &&
  operation.includes('payloadType === ORIGINAL_CREATE_RECORDING_PAYLOAD_TYPE') &&
  operation.includes('payloadType === ORIGINAL_MODIFY_RECORDING_PAYLOAD_TYPE'),
  'applier handles CREATE(5) + MODIFY(6) recording payloads');

console.log(`D02_ORIGINAL_AUDIO_LIFECYCLE_MATRIX_REPLAY_OK TOTAL=${total} FAILED=0`);
