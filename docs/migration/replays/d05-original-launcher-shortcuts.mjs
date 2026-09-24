// Phase 663 — 原版 v50 桌面快捷方式（new_note / new_photo →
// CREATE_NOTE intent + start_camera extra → hv7.i → 建笔记直开）。
// 原版证据（decompiled_1.0.3）：
//   v50.java    动态 ShortcutManager 发布：dad.b="new_note" /
//                "new_photo"，intent action=
//                "android.intent.action.CREATE_NOTE"；new_photo 另加
//                putExtra("start_camera", true)；近期笔记动态快捷项由
//                mc7Var.d 驱动（fad.R setDynamicShortcuts）。
//   hv7.java    hv7.i：action==CREATE_NOTE → Q.j=true + kx 协程。
// Harmony 对齐：shortcuts_config.json（ohos.ability.shortcuts
//   metadata）声明两条静态快捷项，want.parameters.launch_action 经
//   LaunchActionIngress 队列 → LibraryPage drain → createAndLaunch；
//   new_photo 传 startCamera → NotePage 载入后 cameraCaptureSignal
//   （与 Take Photo 同一 photoImportLeaseActive）。近期笔记动态快捷项
//   无 Harmony API —— fail-closed 登记。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const v50 = fs.readFileSync(`${originalRoot}sources/defpackage/v50.java`, 'utf8');
const hv7 = fs.readFileSync(`${originalRoot}sources/defpackage/hv7.java`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const shortcutsCfg = fs.readFileSync('note/src/main/resources/base/profile/shortcuts_config.json', 'utf8');
const ingress = fs.readFileSync('note/src/main/ets/data/LaunchActionIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const ability = fs.readFileSync('note/src/main/ets/noteability/NoteAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editor = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
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
check(v50.includes('dadVar.b = "new_note"') && v50.includes('dadVar2.b = "new_photo"'),
  'v50 publishes new_note + new_photo dynamic shortcuts');
check(v50.includes('setAction("android.intent.action.CREATE_NOTE")'),
  'v50 shortcuts fire CREATE_NOTE intents');
check(v50.includes('putExtra("start_camera", true)'),
  'v50 new_photo carries the start_camera extra');
check(v50.includes('setDynamicShortcuts') || v50.includes('fad.R(context'),
  'v50 publishes recent-note dynamic shortcuts via ShortcutManager');
check(hv7.includes('android.intent.action.CREATE_NOTE') && hv7.includes('Q.j = true'),
  'hv7.i flags CREATE_NOTE launches (Q.j=true) before the kx coroutine');

// ---------- Harmony：声明 ----------
check(moduleJson.includes('"ohos.ability.shortcuts"') &&
  moduleJson.includes('$profile:shortcuts_config'),
  'module.json5 binds the shortcuts profile on NoteAbility');
check(shortcutsCfg.includes('"shortcutId": "new_note"') &&
  shortcutsCfg.includes('"shortcutId": "new_photo"'),
  'shortcuts_config declares new_note + new_photo');
check(shortcutsCfg.includes('"launch_action": "create_note"') &&
  shortcutsCfg.includes('"launch_action": "create_photo_note"'),
  'shortcut wants carry launch_action parameters');
check(shortcutsCfg.includes('$string:shortcut_new_note') &&
  shortcutsCfg.includes('$media:shortcut_new_note') &&
  shortcutsCfg.includes('$media:shortcut_new_photo'),
  'shortcut labels + icons resolve through resources');
check(fs.existsSync('note/src/main/resources/base/media/shortcut_new_note.svg') &&
  fs.existsSync('note/src/main/resources/base/media/shortcut_new_photo.svg'),
  'shortcut icon assets exist');

// ---------- Harmony：队列 + Ability ----------
check(ingress.includes('LAUNCH_ACTION_PARAM') &&
  ingress.includes("'launch_action'") &&
  ingress.includes('pendingLaunchActions'),
  'LaunchActionIngress reads want.parameters[launch_action]');
check(ingress.includes('LAUNCH_ACTION_CREATE_NOTE') &&
  ingress.includes('LAUNCH_ACTION_CREATE_PHOTO_NOTE'),
  'LaunchActionIngress whitelists the two shortcut actions');
check(ingress.includes('drainLaunchActions') && ingress.includes('splice'),
  'drainLaunchActions atomically empties the queue');
const onCreate = section(ability, 'onCreate(want: Want',
  'onNewWant(want: Want');
check(onCreate.includes('enqueueLaunchAction(want)') &&
  ability.includes('onNewWant') && ability.indexOf('enqueueLaunchAction(want)',
    ability.indexOf('onNewWant')) > 0,
  'NoteAbility enqueues launch actions on cold + warm starts');

// ---------- Harmony：库页 drain ----------
const drain = section(library, 'private drainLaunchIngress(): void {',
  'private drainSharedIngress(): void {');
check(drain.includes('drainLaunchActions()') &&
  drain.includes('LAUNCH_ACTION_CREATE_PHOTO_NOTE'),
  'LibraryPage drains launch actions and maps photo action to startCamera');
check(drain.includes('this.createAndLaunch(autoRecord, undefined, startCamera)') &&
  drain.includes('action === LAUNCH_ACTION_CREATE_PHOTO_NOTE'),
  'launch actions reuse the createAndLaunch pipeline (in-built + semantics)');
check(library.indexOf('this.drainLaunchIngress();') >
  library.indexOf('onPageShow(): void {') &&
  library.indexOf('this.drainLaunchIngress();') >
  library.indexOf('this.drainSharedIngress();'),
  'onPageShow drains launch actions alongside shared-ingress');
check(library.includes('startCamera: boolean = false') &&
  library.includes("params: { noteId: noteId, startCamera: '1' }"),
  'createAndLaunch forwards startCamera as a page param');

// ---------- Harmony：编辑器 startCamera ----------
check(editor.includes("params['startCamera'] === '1'") &&
  editor.includes('autoCameraRequested'),
  'NotePage reads the startCamera param');
const autoCam = section(editor, 'if (this.autoCameraRequested',
  '}');
check(autoCam.includes('this.photoImportLeaseActive = true') &&
  autoCam.includes('this.cameraCaptureSignal++'),
  'startCamera auto-start takes the same photo ingress lease as Take Photo');
check(editor.includes('loadGeneration === this.pageLoadGeneration') &&
  editor.includes('!this.editorDisposed'),
  'startCamera auto-start is guarded by load generation + disposal');

// ---------- 字符串 ----------
for (const key of ['shortcut_new_note', 'shortcut_new_photo']) {
  check(baseStrings.includes(`"name": "${key}"`), `base strings define ${key}`);
  check(zhStrings.includes(`"name": "${key}"`), `zh_CN strings define ${key}`);
}

// ---------- fail-closed 登记 ----------
check(ingress.includes('fail-closed') || ingress.includes('setDynamicShortcuts'),
  'recent-note dynamic shortcuts registered fail-closed in ingress docs');

console.log(`D05_ORIGINAL_LAUNCHER_SHORTCUTS_OK TOTAL=${total} FAILED=0`);
