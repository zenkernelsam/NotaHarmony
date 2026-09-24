// Phase 668 — 原版 FolderNotesWidgetProvider 配置型数据小部件
// （extends qk9 + FolderNotesConfigActivity + wyi widget_bindings）。
// 原版证据（decompiled_1.0.3）：
//   FolderNotesWidgetProvider.java   extends qk9；g() = wyi.c(context,i)
//     读 widget_bindings["folder_"+id] → euh.c 解析 utf → mc7Var.a
//     文件夹 → xld(title=文件夹名, create=CREATE_NOTE+folder_id,
//     header=VIEW+folder_id, collection=文件夹笔记)；配置缺失 → null
//   wyi.java                          widget_bindings SharedPreferences
//                                     "folder_"+appWidgetId / "note_"+id
//   FolderNotesConfigActivity.java    配置活动（添加时选文件夹）
//   strings.xml                       widget_folder_no_notes =
//                                     "No notes in this folder"、
//                                     widget_folder_empty =
//                                     "Tap to open Notability"
//   app_widgets__folder_notes_widget_info.xml（若存在）尺寸与 resize
// Harmony 对齐：folder_notes_card + FolderNotesFormFeed（formId→
//   folderId 存 filesDir JSON = widget_bindings 等价）+
//   FolderFormEditAbility（type=formEdit = 配置活动）+
//   FolderNotesEditPage（文件夹列表）；卡片编辑入口
//   postCardAction(message{edit:true}) → onFormEvent →
//   formProvider.openFormEditAbility；folder_id 落地走
//   OpenTargetIngress → vm.setFolder（缺失 fail-closed）；
//   CREATE_NOTE+folder_id → createAndLaunch(folderId) →
//   vm.createNote(folderIdOverride)。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const wFolder = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/FolderNotesWidgetProvider.java`, 'utf8');
const cfgActivity = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/FolderNotesConfigActivity.java`, 'utf8');
const wyi = fs.readFileSync(`${originalRoot}sources/defpackage/wyi.java`, 'utf8');
const origStrings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const formsCfg = fs.readFileSync('note/src/main/resources/base/profile/forms_config.json', 'utf8');
const mainPages = fs.readFileSync('note/src/main/resources/base/profile/main_pages.json', 'utf8');
const formAbility = fs.readFileSync('note/src/main/ets/noteformability/NoteFormAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editAbility = fs.readFileSync('note/src/main/ets/noteformeditability/FolderFormEditAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const card = fs.readFileSync('note/src/main/ets/noteformability/pages/FolderNotesCard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editPage = fs.readFileSync('note/src/main/ets/noteformability/pages/FolderNotesEditPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const feed = fs.readFileSync('note/src/main/ets/data/FolderNotesFormFeed.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const sharedFeed = fs.readFileSync('note/src/main/ets/data/RecentNotesFormFeed.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const openIngress = fs.readFileSync('note/src/main/ets/data/OpenTargetIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const launchIngress = fs.readFileSync('note/src/main/ets/data/LaunchActionIngress.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const vm = fs.readFileSync('note/src/main/ets/ui/library/LibraryViewModel.ets', 'utf8')
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
check(wFolder.includes('extends qk9'),
  'FolderNotesWidgetProvider shares the qk9 collection base');
check(wyi.includes('"widget_bindings"') &&
  wyi.includes('"folder_" + i') &&
  wyi.includes('"note_" + i'),
  'wyi persists per-instance folder/note bindings in SharedPreferences');
check(wFolder.includes('wyi.c(context, i)') &&
  wFolder.includes('putExtra("folder_id"'),
  'g() resolves the bound folder and fires folder_id intents');
check(wFolder.includes('setAction("android.intent.action.CREATE_NOTE")') &&
  wFolder.includes('setAction("android.intent.action.VIEW")'),
  'create button fires CREATE_NOTE+folder_id; header fires VIEW+folder_id');
check(cfgActivity.length > 0 &&
  manifest.includes('FolderNotesConfigActivity'),
  'original ships a configuration activity');
check(origStrings.includes('app_widgets__widget_folder_no_notes') &&
  origStrings.includes('>No notes in this folder<') &&
  origStrings.includes('app_widgets__widget_folder_empty') &&
  origStrings.includes('>Tap to open Notability<'),
  'original strings: empty folder + unconfigured states');

// ---------- Harmony：声明 ----------
check(formsCfg.includes('"name": "folder_notes_card"') &&
  formsCfg.includes('"src": "./ets/noteformability/pages/FolderNotesCard.ets"'),
  'forms_config declares folder_notes_card');
check(moduleJson.includes('"name": "FolderFormEditAbility"') &&
  moduleJson.includes('"type": "formEdit"'),
  'module.json5 registers the formEdit extension');
check(mainPages.includes('noteformability/pages/FolderNotesEditPage'),
  'edit page registered in main_pages');

// ---------- Harmony：feed / 配置存取 ----------
check(feed.includes("FOLDER_NOTES_FORM_NAME: string = 'folder_notes_card'") &&
  feed.includes('folder_notes_form_config.json'),
  'feed pins form name + config file (widget_bindings equivalent)');
check(feed.includes('registerFolderNotesForm') &&
  feed.includes('unregisterFolderNotesForm') &&
  feed.includes('setFolderNotesFormFolder'),
  'feed manages the formId->folderId binding');
check(feed.includes('repo.getNotesByFolder') &&
  repo.includes("orderByDesc('updated_at')") &&
  feed.includes('folderRepo.getAllFolders'),
  'folder feed queries notes by folder + resolves folder names');
check(feed.includes('pushNoteListForms'),
  'folder feed reuses the shared list push engine');
check(feed.includes('configured: target.folderId.length > 0'),
  'unconfigured state propagates to the card (wyi.c null equivalent)');
check(sharedFeed.includes('pushNoteListForms') &&
  sharedFeed.includes('NoteListFormPush') &&
  sharedFeed.includes('NoteListFormExtras'),
  'shared engine exposes pushes + extras for both cards');

// ---------- Harmony：卡片 ----------
check(card.includes("@LocalStorageProp('folderId')") &&
  card.includes("@LocalStorageProp('folderName')") &&
  card.includes("@LocalStorageProp('configured')"),
  'card binds folder id/name/configured');
check(card.includes('folder_id: this.folderId'),
  'header + create button route folder_id');
check(card.includes('note_id: item.id'),
  'row click routes note_id');
check(card.includes("action: 'message'") &&
  card.includes('edit: true'),
  'edit affordance posts a message event');
check(card.includes('form_folder_notes_empty') &&
  card.includes('form_folder_notes_unconfigured'),
  'card shows empty + unconfigured strings');

// ---------- Harmony：formEdit 配置链 ----------
check(editAbility.includes('extends FormEditExtensionAbility') &&
  editAbility.includes('onSessionCreate') &&
  editAbility.includes('session.loadContent') &&
  editAbility.includes('editFormId'),
  'formEdit ability loads the edit page with the formId');
check(editPage.includes('getAllFolders') &&
  editPage.includes('setFolderNotesFormFolder') &&
  editPage.includes('pushFolderNotesTitles'),
  'edit page picks a folder and pushes titles');
check(formAbility.includes('onFormEvent') &&
  formAbility.includes('formProvider.openFormEditAbility') &&
  formAbility.includes('FolderFormEditAbility'),
  'onFormEvent opens the edit ability');

// ---------- Harmony：folder_id extras ----------
check(openIngress.includes("EXTRA_FOLDER_ID: string = 'folder_id'") &&
  openIngress.includes('LANDING_FOLDER_PREFIX'),
  'OpenTargetIngress queues folder landings');
check(launchIngress.includes("EXTRA_FOLDER_ID: string = 'folder_id'") &&
  launchIngress.includes('LaunchRequest') &&
  launchIngress.includes('drainLaunchRequests'),
  'LaunchActionIngress carries folderId per request');
check(library.includes('drainLaunchRequests') &&
  library.includes('request.folderId') &&
  library.includes('createAndLaunch(autoRecord, undefined, startCamera,\n        request.folderId ?? undefined)'),
  'drain passes folderId into createAndLaunch');
check(library.includes('landInFolder') &&
  library.includes('getAllFolders') &&
  library.includes('setFolder(folderId, this.searchText)'),
  'folder landing validates then setFolder (g() null -> no-op)');
check(vm.includes('folderIdOverride') &&
  vm.includes('folderIdOverride !== undefined ?\n      folderIdOverride : this.currentFolderId'),
  'createNote honors the folder_id override');

// ---------- 字符串 ----------
check(baseStrings.includes('"form_folder_notes_empty"') &&
  baseStrings.includes('No notes in this folder') &&
  baseStrings.includes('Tap to open Notability') &&
  zhStrings.includes('"form_folder_notes_empty"') &&
  zhStrings.includes('"form_folder_notes_unconfigured"'),
  'folder card strings localized in both locales');

// ---------- 剩余 fail-closed ----------
check(formAbility.includes('fail-closed') &&
  formAbility.includes('NoteThumbnail'),
  'NoteThumbnail remains registered fail-closed');

console.log(`D05_ORIGINAL_FOLDER_NOTES_CARD_OK TOTAL=${total} FAILED=0`);
