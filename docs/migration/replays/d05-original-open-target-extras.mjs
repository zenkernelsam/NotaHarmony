// Phase 666 — 原版打开目标 extras（VIEW+note_id / nbnote URI /
// show_library / show_recent → MainActivity nav-target 队列）。
// 原版证据（decompiled_1.0.3）：
//   v50.java      近期笔记动态快捷项：VIEW + putExtra("note_id", ttf.toString())
//   qk9.java      列表小部件行 fillInIntent：data=nbnote:<ttf> + note_id extra
//   bv7.java      新窗口目标：VIEW + note_id（o69Var.I ttf）
//   RecentNotesWidgetProvider  本体：VIEW + putExtra("show_recent", true)
//   MainActivity  getStringExtra("note_id")/getBooleanExtra("show_library")
//                 → nav-target 队列 xu7(noteId)/wu7.a
//   ttf.java      toString() = 8-4-4-4-12 带连字符 UUID（36 字符）
//   m18.java      r0 同时接受 32-hex 与 36 位带连字符 UUID
// Harmony 对齐：normalizeDeepLinkNoteId 升级为两种形式归一化为小写
//   32-hex；新 OpenTargetIngress 解析 note_id extra / nbnote URI /
//   show_library / show_recent → 进程内队列；LibraryPage drain 时
//   笔记 ID 并入深链同一 resolveDeepLinkNoteId + pushUrl 管线；
//   show_library → LibrarySection.ALL_NOTES，show_recent → RECENT。
//   nbnote 内部 URI 不声明 uris skill（原版同样未在 manifest 声明）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const v50 = fs.readFileSync(`${originalRoot}sources/defpackage/v50.java`, 'utf8');
const qk9 = fs.readFileSync(`${originalRoot}sources/defpackage/qk9.java`, 'utf8');
const bv7 = fs.readFileSync(`${originalRoot}sources/defpackage/bv7.java`, 'utf8');
const wRecent = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider.java`, 'utf8');
const mainActivity = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/MainActivity.java`, 'utf8');
const ttf = fs.readFileSync(`${originalRoot}sources/defpackage/ttf.java`, 'utf8');
const m18 = fs.readFileSync(`${originalRoot}sources/defpackage/m18.java`, 'utf8');
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const deepLink = fs.readFileSync('note/src/main/ets/data/DeepLinkIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const openTarget = fs.readFileSync('note/src/main/ets/data/OpenTargetIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const ability = fs.readFileSync('note/src/main/ets/noteability/NoteAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repo = fs.readFileSync('note/src/main/ets/data/NoteRepositoryImpl.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const repoIf = fs.readFileSync('note/src/main/ets/data/RepositoryInterfaces.ets', 'utf8')
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

// ---------- 原版证据 ----------
check(v50.includes('putExtra("note_id", ttfVar.toString())'),
  'v50 recent-note shortcuts fire VIEW + note_id');
check(qk9.includes('Uri.fromParts("nbnote"') &&
  qk9.includes('putExtra("note_id", c6gVar.a().toString())'),
  'qk9 widget rows carry nbnote URI + note_id extra');
check(bv7.includes('putExtra("note_id", ttfVar.toString())'),
  'bv7 new-window intents carry note_id');
check(wRecent.includes('putExtra("show_recent", true)'),
  'RecentNotes widget body fires show_recent');
check(mainActivity.includes('getStringExtra("note_id")') &&
  mainActivity.includes('getBooleanExtra("show_library", false)') &&
  mainActivity.includes('xu7') && mainActivity.includes('wu7.a'),
  'MainActivity consumes note_id/show_library into xu7/wu7 nav targets');
check(ttf.includes('public final String toString()') &&
  ttf.includes("bArr[8] = 45") && ttf.includes("bArr[13] = 45") &&
  ttf.includes("bArr[18] = 45") && ttf.includes("bArr[23] = 45"),
  'ttf.toString produces the 8-4-4-4-12 dashed UUID');
check(m18.includes('length == 32') && m18.includes('length != 36') &&
  m18.includes("str.charAt(8) != '-'"),
  'm18.r0 accepts both 32-hex and dashed 36-char UUID');
check(!manifest.includes('nbnote'),
  'nbnote is an internal-only scheme (not manifest-declared upstream)');

// ---------- Harmony：ID 归一化（m18.r0 两形式） ----------
check(deepLink.includes('normalizeDeepLinkNoteId') &&
  deepLink.includes('raw.length === DEEP_LINK_ID_LENGTH') &&
  deepLink.includes('raw.length === DEEP_LINK_UUID_LENGTH') &&
  deepLink.includes('DEEP_LINK_UUID_LENGTH: number = 36'),
  'normalizeDeepLinkNoteId handles both m18.r0 forms');
check(deepLink.includes('i === 8 || i === 13 || i === 18 || i === 23') &&
  deepLink.includes("raw.charAt(i) !== '-'"),
  'dashed form enforces hyphen positions 8/13/18/23');
check(deepLink.includes('return raw.toLowerCase()') &&
  deepLink.includes('return hex.toLowerCase()'),
  'both forms normalize to lowercase 32-hex');

// ---------- Harmony：OpenTargetIngress ----------
check(openTarget.includes("EXTRA_NOTE_ID: string = 'note_id'") &&
  openTarget.includes("EXTRA_SHOW_LIBRARY: string = 'show_library'") &&
  openTarget.includes("EXTRA_SHOW_RECENT: string = 'show_recent'") &&
  openTarget.includes("NBNOTE_SCHEME: string = 'nbnote:'"),
  'OpenTargetIngress declares the original extra/URI contract');
check(openTarget.includes('want.parameters[EXTRA_NOTE_ID]') &&
  openTarget.includes('normalizeDeepLinkNoteId(noteId)'),
  'note_id extra is normalized through the shared validator');
check(openTarget.includes('want.uri.startsWith(NBNOTE_SCHEME)') &&
  openTarget.includes('want.uri.slice(NBNOTE_SCHEME.length)'),
  'nbnote URI scheme-specific-part feeds the validator');
check(openTarget.includes("want.parameters[EXTRA_SHOW_LIBRARY] === true") &&
  openTarget.includes("want.parameters[EXTRA_SHOW_RECENT] === true") &&
  openTarget.includes('LANDING_ALL_NOTES') && openTarget.includes('LANDING_RECENT'),
  'show_library/show_recent queue distinct landing kinds');
check(openTarget.includes('drainOpenNoteIds') &&
  openTarget.includes('drainLibraryLandings'),
  'OpenTargetIngress exposes both drain functions');

// ---------- Harmony：管线 ----------
check(ability.includes('enqueueOpenTargetWant(want)') &&
  (ability.match(/enqueueOpenTargetWant\(want\)/g) || []).length === 2,
  'NoteAbility enqueues open targets on cold and warm launches');
check(!moduleJson.includes('nbnote'),
  'nbnote stays undeclared (internal URI, same as upstream)');
const drain = section(library, 'private drainDeepLinkIngress', 'private async openDeepLinkNotes');
check(drain.includes('drainDeepLinkNoteIds()') &&
  drain.includes('drainOpenNoteIds()'),
  'note-id queue merges deep links and open targets');
const landing = section(library, 'private drainOpenTargetIngress', 'private async openDeepLinkNotes');
check(landing.includes('drainLibraryLandings()') &&
  landing.includes('LANDING_RECENT') &&
  landing.includes('LibrarySection.RECENT') &&
  landing.includes('LibrarySection.ALL_NOTES') &&
  landing.includes('this.selectSection(section)'),
  'landings route to ALL_NOTES / RECENT sections');
check(library.includes('this.drainOpenTargetIngress()'),
  'onPageShow drains the open-target queue');
check(repoIf.includes('RECENT = 1'),
  'LibrarySection.RECENT exists for the show_recent landing');

// ---------- 回归：深链解析仍走同一落地 ----------
check(repo.includes('resolveDeepLinkNoteId'),
  'open targets reuse resolveDeepLinkNoteId (id + legacy_id)');

console.log(`D05_ORIGINAL_OPEN_TARGET_EXTRAS_OK TOTAL=${total} FAILED=0`);
