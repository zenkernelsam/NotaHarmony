// Phase 661 — 外部共享/打开 PDF 入口（VIEW/SEND intent → 导入管线）。
// 原版证据（decompiled_1.0.3）：
//   AndroidManifest.xml  MissingNativeLibraryActivity 注册
//                VIEW(content/file, application/pdf) 与
//                SEND(application/pdf) intent-filter；
//   fag.java       fag.h0(intent)：SEND+application/pdf → EXTRA_STREAM URI；
//                VIEW+content/file scheme → data URI；其余 → null；
//   hv7.java       hv7.i(intent)：fag.h0 != null（或 CREATE_NOTE/deep link）
//                → Q.j=true 标记 + kx(10) 协程走同一导入管线。
// Harmony 对齐：module.json5 skills 追加 viewData/sendData/
//   sendMultipleData + file/application/pdf；SharedFileIngress 把
//   want.uri / want.parameters['ability.params.stream'] 入进程内队列；
//   LibraryPage.onPageShow drain → importSharedUris →
//   importPickedFilesStandalone（与多选导入同一读取+嗅探+逐文件物化），
//   密码回调同 Phase 660；成功后打开最后一篇导入笔记。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');
const fag = fs.readFileSync(`${originalRoot}sources/defpackage/fag.java`, 'utf8');
const hv7 = fs.readFileSync(`${originalRoot}sources/defpackage/hv7.java`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const ability = fs.readFileSync('note/src/main/ets/noteability/NoteAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const ingress = fs.readFileSync('note/src/main/ets/data/SharedFileIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：manifest 声明 + fag.h0 提取 ---
check(manifest.includes('android.intent.action.SEND') &&
  manifest.includes('android:mimeType="application/pdf"'),
  'manifest registers SEND application/pdf on the launcher activity');
check(/android\.intent\.action\.VIEW[\s\S]*?android:scheme="content"[\s\S]*?android:mimeType="application\/pdf"/.test(manifest),
  'manifest registers VIEW content/file application/pdf');
const h0 = section(fag, 'public static final Uri h0(Intent intent)',
  'public static final kz9 i(');
check(h0.includes('action.equals("android.intent.action.SEND")') &&
  h0.includes('ba6.o(type, "application/pdf")') &&
  h0.includes('"android.intent.extra.STREAM"'),
  'fag.h0 maps SEND+pdf to the EXTRA_STREAM URI');
check(h0.includes('action.equals("android.intent.action.VIEW")') &&
  h0.includes('data.getScheme(), "content"') &&
  h0.includes('data.getScheme(), "file"'),
  'fag.h0 maps VIEW to content/file data URIs');
check(hv7.includes('fag.h0(intent) != null') &&
  hv7.includes('this.Q.j = true'),
  'hv7.i flags the launch when h0 extracted a shared URI');

// --- Harmony：manifest 等价 skill ---
check(moduleJson.includes('"ohos.want.action.viewData"') &&
  moduleJson.includes('"ohos.want.action.sendData"') &&
  moduleJson.includes('"ohos.want.action.sendMultipleData"'),
  'module.json5 declares viewData/sendData/sendMultipleData');
check(/"scheme":\s*"file"[\s\S]{0,80}"type":\s*"application\/pdf"/.test(moduleJson),
  'module.json5 uris restrict the share skill to application/pdf');

// --- Harmony：want 解析队列 ---
check(ingress.includes("ACTION_VIEW_DATA: string = 'ohos.want.action.viewData'") &&
  ingress.includes("ACTION_SEND_DATA: string = 'ohos.want.action.sendData'") &&
  ingress.includes("PARAMS_STREAM: string = 'ability.params.stream'"),
  'SharedFileIngress mirrors the wantConstant keys');
check(ingress.includes('want.uri') && ingress.includes('want.parameters[PARAMS_STREAM]'),
  'enqueueSharedWantUris reads want.uri (viewData) and params.stream (sendData)');
check(ingress.includes('Array.isArray(stream)') &&
  ingress.includes("typeof item === 'string'"),
  'sendData stream array is iterated item-wise (multi-file share)');
check(ingress.includes('export function drainSharedUris()') &&
  ingress.includes('pendingSharedUris.splice(0'),
  'drainSharedUris empties the queue atomically');

// --- Harmony：ability 生命周期接线 ---
check(ability.includes('enqueueSharedWantUris(want)') &&
  ability.indexOf('enqueueSharedWantUris(want)') < ability.indexOf('ThemeStore.init()'),
  'onCreate enqueues the launch want before init');
check(ability.includes('onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam)') &&
  ability.indexOf('onNewWant') < ability.indexOf('enqueueSharedWantUris(want);',
    ability.indexOf('onNewWant')),
  'onNewWant enqueues hot-launch wants');

// --- Harmony：导入入口复用同一分发表 ---
check(importer.includes('async importSharedUris(uris: string[],') &&
  importer.includes('passwordPrompt?: PdfPasswordPrompt') &&
  importer.includes('this.importPickedFilesStandalone(uris, passwordPrompt)'),
  'importSharedUris delegates to the rv5 per-file dispatch (sniff + standalone notes)');

// --- Harmony：LibraryPage drain + 打开导入笔记 ---
const drain = section(library, 'private drainSharedIngress(): void {',
  'private async importSharedAndOpen(');
check(drain.includes('drainSharedUris()') && drain.includes('uris.length === 0'),
  'drainSharedIngress no-ops on an empty queue');
check(library.includes('this.drainSharedIngress();') &&
  library.indexOf('this.drainSharedIngress();') >
    library.indexOf('onPageShow(): void {'),
  'onPageShow drains the shared-ingress queue');
const sharedOpen = section(library, 'private async importSharedAndOpen(',
  '// Original empty_note__import_file');
check(sharedOpen.includes('importer.importSharedUris(uris, this.pdfPasswordPrompt)'),
  'shared import threads the Phase 660 password prompt');
check(sharedOpen.includes("router.pushUrl({ url: 'ui/editor/NotePage'") &&
  sharedOpen.includes('report.noteId'),
  'a successful shared import opens the materialized note');
check(sharedOpen.includes('createBusy = true') &&
  sharedOpen.includes('lifecycleGeneration'),
  'shared import observes the busy flag and lifecycle generation');

console.log(`D05_ORIGINAL_SHARED_PDF_INGRESS_REPLAY_OK TOTAL=${total} FAILED=0`);
