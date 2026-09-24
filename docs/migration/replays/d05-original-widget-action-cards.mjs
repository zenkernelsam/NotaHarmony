// Phase 665 — 原版动作小部件（CreateNoteWidgetProvider /
// CreateRecordingWidgetProvider → CREATE_NOTE / +start_recording →
// hv7.i → kx 建笔记直开/自动起录）。
// 原版证据（decompiled_1.0.3）：
//   CreateNoteWidgetProvider.java       f()→CREATE_NOTE intent
//   CreateRecordingWidgetProvider.java  f()→CREATE_NOTE +
//                                        putExtra("start_recording",true)
//   app_widgets__*_widget_info.xml      均 targetCell 2×2 home_screen
//   rd9.java                            auto_start_recording_applied
//                                        一次性标记（起录后消费）
//   AndroidManifest.xml                 5 个 widget receiver
// Harmony 对齐：extensionAbilities NoteFormAbility(type=form) +
//   forms_config.json 两张 2*2 ArkTS 卡片；卡片 postCardAction
//   (router, abilityName=NoteAbility, params.launch_action) →
//   LaunchActionIngress（新动作 create_recording_note + 原版
//   start_recording/start_camera extras 兜底）→ LibraryPage drain
//   → createAndLaunch(autoRecord) → NotePage autoRecordRequested。
//   三张数据小部件（RecentNotes/NoteThumbnail/FolderNotes）与
//   show_recent extra —— form 数据通道未建，fail-closed 登记。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const wNote = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/CreateNoteWidgetProvider.java`, 'utf8');
const wRec = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/CreateRecordingWidgetProvider.java`, 'utf8');
const wRecent = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider.java`, 'utf8');
const infoNote = fs.readFileSync(
  `${originalRoot}resources/res/xml/app_widgets__create_note_widget_info.xml`, 'utf8');
const infoRec = fs.readFileSync(
  `${originalRoot}resources/res/xml/app_widgets__create_recording_widget_info.xml`, 'utf8');
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');
const rd9 = fs.readFileSync(`${originalRoot}sources/defpackage/rd9.java`, 'utf8');
const origStrings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const formsCfg = fs.readFileSync('note/src/main/resources/base/profile/forms_config.json', 'utf8');
const formAbility = fs.readFileSync('note/src/main/ets/noteformability/NoteFormAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const noteCard = fs.readFileSync('note/src/main/ets/noteformability/pages/NewNoteCard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const recCard = fs.readFileSync('note/src/main/ets/noteformability/pages/NewRecordingCard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const ingress = fs.readFileSync('note/src/main/ets/data/LaunchActionIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editor = fs.readFileSync('note/src/main/ets/ui/editor/NotePage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const baseStrings = fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8');
const zhStrings = fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8');
const mediaDir = fs.readdirSync('note/src/main/resources/base/media');

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
check(wNote.includes('setAction("android.intent.action.CREATE_NOTE")'),
  'CreateNoteWidgetProvider fires CREATE_NOTE');
check(wRec.includes('setAction("android.intent.action.CREATE_NOTE")') &&
  wRec.includes('putExtra("start_recording", true)'),
  'CreateRecordingWidgetProvider fires CREATE_NOTE + start_recording');
check(infoNote.includes('targetCellWidth="2"') && infoNote.includes('targetCellHeight="2"') &&
  infoRec.includes('targetCellWidth="2"') && infoRec.includes('targetCellHeight="2"'),
  'both action widgets are 2x2 target cells');
check(origStrings.includes('app_widgets__widget_new_note_label') &&
  origStrings.includes('Create a new note') &&
  origStrings.includes('app_widgets__widget_recording_label') &&
  origStrings.includes('Start recording'),
  'original widget labels: Create a new note / Start recording');
check(rd9.includes('auto_start_recording_applied'),
  'rd9 consumes auto_start_recording_applied one-shot flag');
check(manifest.includes('CreateNoteWidgetProvider') &&
  manifest.includes('CreateRecordingWidgetProvider') &&
  manifest.includes('RecentNotesWidgetProvider') &&
  manifest.includes('NoteThumbnailWidgetProvider') &&
  manifest.includes('FolderNotesWidgetProvider'),
  'manifest registers all five widget providers');
check(wRecent.includes('putExtra("show_recent", true)'),
  'RecentNotes widget body fires VIEW + show_recent');

// ---------- Harmony：声明 ----------
check(moduleJson.includes('"name": "NoteFormAbility"') &&
  moduleJson.includes('"type": "form"') &&
  moduleJson.includes('"name": "ohos.extension.form"') &&
  moduleJson.includes('"resource": "$profile:forms_config"'),
  'module.json5 registers NoteFormAbility with form metadata');
check(formsCfg.includes('"name": "new_note_card"') &&
  formsCfg.includes('"name": "new_recording_card"'),
  'forms_config declares both action cards');
check((formsCfg.match(/"uiSyntax": "arkts"/g) || []).length === 2 &&
  (formsCfg.match(/"defaultDimension": "2\*2"/g) || []).length === 2 &&
  (formsCfg.match(/"supportDimensions": \[\s*"2\*2"\s*\]/g) || []).length === 2,
  'both cards are arkts 2*2 (matching target cells)');
check(formsCfg.includes('"src": "./ets/noteformability/pages/NewNoteCard.ets"') &&
  formsCfg.includes('"src": "./ets/noteformability/pages/NewRecordingCard.ets"'),
  'forms src points at the two card pages');
check(formsCfg.includes('"updateEnabled": false'),
  'action cards disable periodic updates (pure action widgets)');
check(formAbility.includes('extends FormExtensionAbility') &&
  formAbility.includes('onAddForm') &&
  formAbility.includes('createFormBindingData'),
  'NoteFormAbility implements the form lifecycle');

// ---------- Harmony：卡片 router 事件 ----------
check(noteCard.includes("postCardAction") &&
  noteCard.includes("action: 'router'") &&
  noteCard.includes("abilityName: 'NoteAbility'") &&
  noteCard.includes("launch_action: 'create_note'"),
  'NewNoteCard routers to NoteAbility with create_note');
check(recCard.includes("postCardAction") &&
  recCard.includes("action: 'router'") &&
  recCard.includes("abilityName: 'NoteAbility'") &&
  recCard.includes("launch_action: 'create_recording_note'"),
  'NewRecordingCard routers to NoteAbility with create_recording_note');
check(noteCard.includes("$r('app.string.form_new_note_display')") &&
  recCard.includes("$r('app.string.form_new_recording_display')"),
  'cards use localized display labels');
check(mediaDir.includes('shortcut_new_note.svg') &&
  mediaDir.includes('shortcut_new_recording.svg'),
  'card icons exist in base media');

// ---------- Harmony：ingress + drain ----------
check(ingress.includes("LAUNCH_ACTION_CREATE_RECORDING_NOTE: string = 'create_recording_note'"),
  'ingress defines the recording action');
check(ingress.includes('action === LAUNCH_ACTION_CREATE_RECORDING_NOTE'),
  'ingress accepts the recording action');
check(ingress.includes("EXTRA_START_RECORDING: string = 'start_recording'") &&
  ingress.includes("EXTRA_START_CAMERA: string = 'start_camera'") &&
  ingress.includes('want.parameters[EXTRA_START_RECORDING] === true'),
  'ingress falls back to original start_recording/start_camera extras');
const drain = section(library, 'private drainLaunchIngress', 'private drainDeepLinkIngress');
check(drain.includes('LAUNCH_ACTION_CREATE_RECORDING_NOTE') &&
  drain.includes('autoRecord: boolean') &&
  drain.includes('this.createAndLaunch(autoRecord, undefined, startCamera)'),
  'drain routes recording action into createAndLaunch(autoRecord)');
check(editor.includes("params['autoRecord'] === '1'") &&
  editor.includes('autoRecordRequested'),
  'NotePage consumes the autoRecord route param (existing hook)');

// ---------- 字符串 ----------
check(baseStrings.includes('"form_new_note_display"') &&
  baseStrings.includes('"form_new_recording_display"') &&
  baseStrings.includes('Create a new note') &&
  baseStrings.includes('Start recording') &&
  zhStrings.includes('"form_new_note_display"') &&
  zhStrings.includes('"form_new_recording_display"'),
  'form labels localized in both locales');

// ---------- fail-closed 登记（数据小部件） ----------
check(formAbility.includes('fail-closed') &&
  (formAbility.includes('RecentNotes') || formAbility.includes('NoteThumbnail')),
  'data widgets registered fail-closed in the form ability comment');

console.log(`D05_ORIGINAL_WIDGET_ACTION_CARDS_OK TOTAL=${total} FAILED=0`);
