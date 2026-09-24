// Phase 664 — 原版 /app/note/<id> 深链（notability.com → 打开本地笔记）。
// 原版证据（decompiled_1.0.3）：
//   AndroidManifest.xml  intent-filter autoVerify + BROWSABLE：
//                scheme http/https，host notability.com +
//                *.notability.com，pathPrefix /app/note（同filter还有
//                /authlink 与 /event/learn-from-home、/event/plus25）。
//   py2.java     a=["app","note"]；f(uri)=scheme http/https + host
//                notability.com 或 endswith .notability.com；
//                a(uri)=段数=a.size+1 且前缀相等；b(uri)=wtf.f(第3段)；
//                d=e(/event/learn-from-home)|g(/event/plus25)。
//   m18.java     r0(str)：恰好 32 个字符、每位经 ug5.c（0-9a-fA-F 表）
//                解析成两个 long → ttf。
//   hv7.java     hv7.i：py2.d(data) → Q.j=true + kx 协程。
// Harmony 对齐：module.json5 skills 增挂 entity.system.browsable +
//   ohos.want.action.viewData + uris(http/https, host notability.com,
//   pathStartWith app/note)；DeepLinkIngress 按 py2.f/py2.a/m18.r0
//   同规则解析 want.uri → 队列；LibraryPage drain →
//   resolveDeepLinkNoteId（note_meta.id 直查 + legacy_id 兜底）→
//   pushUrl NotePage。fail-closed：*.notability.com 子域（uris host
//   无通配）、domainVerify 托管关联文件、/authlink VerifyLink 与
//   /event/* 营销事件、本地未命中的后端同步取回 —— 均登记。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');
const py2 = fs.readFileSync(`${originalRoot}sources/defpackage/py2.java`, 'utf8');
const m18 = fs.readFileSync(`${originalRoot}sources/defpackage/m18.java`, 'utf8');
const hv7 = fs.readFileSync(`${originalRoot}sources/defpackage/hv7.java`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const ingress = fs.readFileSync('note/src/main/ets/data/DeepLinkIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const ability = fs.readFileSync('note/src/main/ets/noteability/NoteAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/NoteRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');

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

// ---------- 原版证据 ----------
check(manifest.includes('android:autoVerify="true"') &&
  manifest.includes('android.intent.category.BROWSABLE'),
  'manifest declares autoVerify + BROWSABLE deep-link filter');
check(manifest.includes('android:host="notability.com"') &&
  manifest.includes('android:host="*.notability.com"'),
  'manifest hosts notability.com + wildcard subdomain');
check(manifest.includes('android:pathPrefix="/app/note"') &&
  manifest.includes('android:pathPrefix="/authlink"'),
  'manifest path prefixes /app/note + /authlink');
check(manifest.includes('android:path="/event/learn-from-home"') &&
  manifest.includes('android:path="/event/plus25"'),
  'manifest exact event paths');
check(py2.includes('lvd.e1("/app/note"') &&
  py2.includes('m18.m0("event", "learn-from-home")') &&
  py2.includes('m18.m0("event", "plus25")'),
  'py2 segment lists: app/note + two event paths');
check(py2.includes('ba6.o(uri.getScheme(), "http")') &&
  py2.includes('ba6.o(uri.getScheme(), "https")') &&
  py2.includes('host.equals("notability.com")') &&
  py2.includes('svd.f0(host, ".notability.com", false)'),
  'py2.f host/scheme predicate');
check(py2.includes('list.size() + 1') &&
  py2.includes('ba6.o(pathSegments.subList(0, list.size()), list)'),
  'py2.a requires exactly app/note + one id segment');
check(py2.includes('wtf.f(str)'),
  'py2.b parses the id segment through wtf.f');
check(m18.includes('public static ttf r0(String str)') &&
  m18.includes('length == 32'),
  'm18.r0 accepts exactly 32 chars');
check(hv7.includes('py2.d(data)') && hv7.includes('Q.j = true'),
  'hv7.i flags deep-link intents (py2.d → Q.j) before kx');

// ---------- Harmony：声明 ----------
check(moduleJson.includes('entity.system.browsable') &&
  moduleJson.includes('ohos.want.action.viewData'),
  'module.json5 declares browsable + viewData skill');
check(moduleJson.includes('"host": "notability.com"') &&
  moduleJson.includes('"pathStartWith": "app/note"'),
  'module.json5 uris host + pathStartWith');
check((moduleJson.match(/"scheme": "https"/g) || []).length >= 1 &&
  (moduleJson.match(/"scheme": "http"/g) || []).length >= 1,
  'module.json5 uris cover both https and http');
check(moduleJson.indexOf('entity.system.browsable') >
  moduleJson.indexOf('entity.system.home'),
  'browsable skill is a separate skill object after home');

// ---------- Harmony：解析（py2.f/py2.a/m18.r0 同规则） ----------
check(ingress.includes('enqueueDeepLinkWant') &&
  ingress.includes('drainDeepLinkNoteIds') &&
  ingress.includes('pendingDeepLinkNoteIds'),
  'DeepLinkIngress exposes enqueue + drain queue');
check(ingress.includes('parseDeepLinkNoteId') &&
  ingress.includes("want.action !== ACTION_VIEW_DATA"),
  'ingress only parses viewData wants');
check(ingress.includes("host === DEEP_LINK_HOST") &&
  ingress.includes('host.endsWith(DEEP_LINK_HOST_SUFFIX)') &&
  ingress.includes("scheme !== 'http' && scheme !== 'https'"),
  'ingress replicates py2.f host/scheme predicate');
check(ingress.includes('segments.length !== 3') &&
  ingress.includes("segments[0] !== 'app'") &&
  ingress.includes("segments[1] !== 'note'"),
  'ingress replicates py2.a exact 3-segment path');
check(ingress.includes('DEEP_LINK_ID_LENGTH: number = 32') &&
  ingress.includes('segment.length !== DEEP_LINK_ID_LENGTH'),
  'ingress enforces m18.r0 32-char id');
check(ingress.includes('code >= 0x30 && code <= 0x39') &&
  ingress.includes('code >= 0x61 && code <= 0x66') &&
  ingress.includes('code >= 0x41 && code <= 0x46'),
  'ingress hex table covers 0-9 a-f A-F like ug5.c');

// ---------- Harmony：管线 ----------
const onCreate = section(ability, 'onCreate(want: Want', 'ThemeStore.init()');
check(onCreate.includes('enqueueDeepLinkWant(want)'),
  'NoteAbility onCreate enqueues deep links');
const onNewWant = section(ability, 'onNewWant(want: Want', '}');
check(onNewWant.includes('enqueueDeepLinkWant(want)'),
  'NoteAbility onNewWant enqueues deep links');
check(library.includes('this.drainDeepLinkIngress()') &&
  library.includes('drainDeepLinkNoteIds()'),
  'LibraryPage drains deep-link queue on show');
const openMethod = section(library, 'private async openDeepLinkNotes', '} finally {');
check(openMethod.includes('resolveDeepLinkNoteId(deepLinkId)') &&
  openMethod.includes("router.pushUrl({ url: 'ui/editor/NotePage'") &&
  openMethod.includes('noteId: noteId'),
  'resolved deep link opens NotePage by id');
check(openMethod.includes('deep_link_note_missing') &&
  openMethod.includes('noteId === null'),
  'unresolved deep link toasts fail-closed message');
check(openMethod.includes('this.createBusy = true') &&
  openMethod.includes('this.pageActive') &&
  openMethod.includes('lifecycleGeneration'),
  'deep-link open keeps busy/lifecycle guards');

// ---------- Harmony：解析落地 ----------
const resolve = section(repo, 'async resolveDeepLinkNoteId', 'async getAllNotes');
check(resolve.includes("new relationalStore.RdbPredicates('note_meta')") &&
  resolve.includes("equalTo('id', deepLinkId)") &&
  resolve.includes("isNull('deleted_at')"),
  'resolveDeepLinkNoteId direct-hits active note_meta.id');
check(resolve.includes("new relationalStore.RdbPredicates('note_sync_metadata')") &&
  resolve.includes("equalTo('legacy_id', deepLinkId)") &&
  resolve.includes("getColumnIndex('note_id')"),
  'resolveDeepLinkNoteId falls back to legacy_id');
check(baseStrings.includes('"deep_link_note_missing"') &&
  zhStrings.includes('"deep_link_note_missing"'),
  'deep_link_note_missing string in both locales');

// ---------- 回归保护：共享/快捷入口不受影响 ----------
check(ability.includes('enqueueSharedWantUris(want)') &&
  ability.includes('enqueueLaunchAction(want)'),
  'shared + launcher ingress still enqueued');

console.log(`D05_ORIGINAL_NOTE_DEEP_LINK_OK TOTAL=${total} FAILED=0`);
