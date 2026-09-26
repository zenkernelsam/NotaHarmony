// Phase 844 — data 域异常分类学尾部闭合
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const B = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability';
const results = [];
const ck = (n, ok) => results.push([n, ok]);

// 全树 *Exception/*Error 文件计数 = 64
const files = [];
const walk = (d) => { for (const f of readdirSync(d, { withFileTypes: true })) { const p = join(d, f.name); if (f.isDirectory()) walk(p); else if (/Exception|Error/.test(f.name) && f.name.endsWith('.java')) files.push(p); } };
walk(B);
ck('全包异常类总数 64', files.length === 64);

// 本相位新增 27 类逐类核验
const tail = [
  'data/backgroundwork/PreemptedByOpenNoteException',
  'data/gallery/GalleryPublishException',
  'data/handwritingrecognition/HandwritingEngineUnavailableException',
  'data/handwritingrecognition/LanguagePackUnavailableException',
  'data/handwritingrecognition/MathRecognitionUnsupportedException',
  'data/handwritingrecognition/PlayAssetDeliveryUnavailableException',
  'data/handwritingrecognition/hwr/PenSampleDecodingException',
  'data/handwritingrecognition/hwr/RemoteEngineException',
  'data/handwritingrecognition/myscript/MyScriptEngineFeedException',
  'data/learn/LearnError',
  'data/learn/syllabus/SyllabusParseException',
  'data/library/state/NoteAccessDeniedException',
  'data/library/state/NoteNotFoundException',
  'data/library/state/RetryableUploadException',
  'data/library/state/UploadInProgressException',
  'data/library/state/folders/InvalidFolderNameException',
  'data/library/state/folders/MaxFolderDepthExceededException',
  'data/library/state/notelimit/NoteLimitRefusedException',
  'data/library/state/ntb/MissingAssetsException',
  'data/loginstate/LibraryInitTimeoutException',
  'data/loginstate/LoginTeardownException',
  'data/loginstate/PostCommitLoginException',
  'data/transcription/TranscriptionException',
  'data/transcription/TranscriptionNotFoundException',
  'data/transcription/livetranscription/LiveTranscriptionHttpException',
  'data/transcription/upload/GCSUploadException',
  'data/user/MalformedPasskeyPayloadException',
  'data/user/NullAuthTokenException',
  'data/user/PasskeyActivityGoneException',
  'data/user/SsoVerificationException',
  'core/flatbuffers/ValidationException',
  'ui/fileimport/data/importer/PartialImportException',
];
let found = 0;
for (const t of tail) { try { readFileSync(join(B, t + '.java'), 'utf8'); found++; } catch {} }
ck(`尾部 32 类全部存在（实际 ${found}）`, found === 32);

// NoteLimitRefused 消息
ck('NoteLimitRefused 消息', readFileSync(join(B, 'data/library/state/notelimit/NoteLimitRefusedException.java'), 'utf8').includes('Note limit reached'));

// Harmony 类型化错误映射
const folder = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/FolderRepositoryImpl.ets', 'utf8');
ck('Harmony MaxFolderDepthExceededError', folder.includes('class MaxFolderDepthExceededError'));
ck('Harmony InvalidFolderNameError', folder.includes('class InvalidFolderNameError'));
const guard = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/BackupSnapshotGuard.ets', 'utf8');
ck('Harmony BackupPreparation 族', guard.includes('BackupPreparationError') && guard.includes('BackupSnapshotChangedError'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
