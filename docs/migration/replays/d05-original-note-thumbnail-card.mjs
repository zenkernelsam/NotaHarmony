// Phase 669 — 原版 NoteThumbnailWidgetProvider 配置型单缩略图小部件
// （extends ec0 + NoteThumbnailConfigActivity + wyi.e widget_bindings）。
// 原版证据（decompiled_1.0.3）：
//   NoteThumbnailWidgetProvider.java   wyi.e(context,i) 读
//     widget_bindings["note_"+id] → ttf；xf9 渲染首页位图；有图显
//     thumbnail_image(contentDesc=标题) 否则 thumbnail_placeholder；
//     点击 = VIEW+note_id（ttf 非空）或 MAIN+LAUNCHER（未配置）
//   NoteThumbnailConfigActivity.java   "Choose a note" 配置活动 +
//     query 搜索（widget_note_picker_search_hint）
//   app_widgets__note_thumbnail_widget_info.xml  2×2 targetCell +
//     40–190dp 双向 resize + configure=ConfigActivity
//   strings.xml                        widget_note_thumbnail_label="Note"、
//     _picker_title="Choose a note"、widget_picker_no_notes=
//     "No notes yet"、_description="Quick access to one of your notes."
// Harmony 对齐：note_thumbnail_card（2*2 默认 + 1*2/2*4/4*4 =
//   40–190dp resize）+ NoteThumbnailFormFeed（formId→noteId 存
//   filesDir JSON = widget_bindings）+ NoteThumbnailFormEditAbility
//   （type=formEdit）+ NoteThumbnailEditPage（搜索 + 笔记列表）；
//   点击 postCardAction → note_id（复用 OpenTargetIngress）；未配置
//   → 纯拉起 NoteAbility（= MAIN+LAUNCHER）；编辑入口
//   message{edit:true} → onFormEvent 按 formId 归属分发
//   openFormEditAbility。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const wThumb = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/NoteThumbnailWidgetProvider.java`, 'utf8');
const cfgActivity = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/NoteThumbnailConfigActivity.java`, 'utf8');
const wyi = fs.readFileSync(`${originalRoot}sources/defpackage/wyi.java`, 'utf8');
const infoThumb = fs.readFileSync(
  `${originalRoot}resources/res/xml/app_widgets__note_thumbnail_widget_info.xml`, 'utf8');
const origStrings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');
const manifest = fs.readFileSync(`${originalRoot}resources/AndroidManifest.xml`, 'utf8');

const moduleJson = fs.readFileSync('note/src/main/module.json5', 'utf8');
const formsCfg = fs.readFileSync('note/src/main/resources/base/profile/forms_config.json', 'utf8');
const mainPages = fs.readFileSync('note/src/main/resources/base/profile/main_pages.json', 'utf8');
const formAbility = fs.readFileSync('note/src/main/ets/noteformability/NoteFormAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editAbility = fs.readFileSync(
  'note/src/main/ets/noteformeditability/NoteThumbnailFormEditAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const card = fs.readFileSync('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const editPage = fs.readFileSync('note/src/main/ets/noteformability/pages/NoteThumbnailEditPage.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const feed = fs.readFileSync('note/src/main/ets/data/NoteThumbnailFormFeed.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const sharedFeed = fs.readFileSync('note/src/main/ets/data/RecentNotesFormFeed.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const library = fs.readFileSync('note/src/main/ets/ui/library/LibraryPage.ets', 'utf8')
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
check(wThumb.includes('wyi.e(context, i)') &&
  wyi.includes('"note_" + i'),
  'provider reads widget_bindings note_<appWidgetId>');
check(wThumb.includes('setImageViewBitmap(R.id.app_widgets__widget_thumbnail_image') &&
  wThumb.includes('app_widgets__widget_thumbnail_placeholder'),
  'provider shows the rendered bitmap or the placeholder');
check(wThumb.includes('putExtra("note_id"') &&
  wThumb.includes('setAction("android.intent.action.VIEW")'),
  'configured click fires VIEW + note_id');
check(wThumb.includes('android.intent.action.MAIN') &&
  wThumb.includes('android.intent.category.LAUNCHER'),
  'unconfigured click falls back to MAIN+LAUNCHER');
check(cfgActivity.includes('query') &&
  origStrings.includes('app_widgets__widget_note_thumbnail_picker_title') &&
  origStrings.includes('>Choose a note<') &&
  origStrings.includes('widget_note_picker_search_hint'),
  'config activity is a "Choose a note" picker with search');
check(origStrings.includes('app_widgets__widget_note_thumbnail_label') &&
  origStrings.includes('>Note<') &&
  origStrings.includes('widget_picker_no_notes') &&
  origStrings.includes('>No notes yet<') &&
  origStrings.includes('Quick access to one of your notes.'),
  'original strings: Note / Choose a note / No notes yet / description');
check(infoThumb.includes('targetCellWidth="2"') &&
  infoThumb.includes('targetCellHeight="2"') &&
  infoThumb.includes('resizeMode="vertical|horizontal"') &&
  infoThumb.includes('configure='),
  'widget is 2x2 with resize + a configure activity');
check(manifest.includes('NoteThumbnailWidgetProvider') &&
  manifest.includes('NoteThumbnailConfigActivity'),
  'manifest registers provider + config activity');

// ---------- Harmony：声明 ----------
check(formsCfg.includes('"name": "note_thumbnail_card"') &&
  formsCfg.includes('"src": "./ets/noteformability/pages/NoteThumbnailCard.ets"') &&
  formsCfg.includes('"1*2"'),
  'forms_config declares note_thumbnail_card (2*2 + resizable dims)');
check(moduleJson.includes('"name": "NoteThumbnailFormEditAbility"') &&
  (moduleJson.match(/"type": "formEdit"/g) || []).length === 2,
  'module.json5 registers both formEdit extensions');
check(mainPages.includes('noteformability/pages/NoteThumbnailEditPage'),
  'edit page registered in main_pages');

// ---------- Harmony：feed / 配置存取 ----------
check(feed.includes("NOTE_THUMBNAIL_FORM_NAME: string = 'note_thumbnail_card'") &&
  feed.includes('note_thumbnail_form_config.json'),
  'feed pins form name + config file (widget_bindings equivalent)');
check(feed.includes('registerNoteThumbnailForm') &&
  feed.includes('unregisterNoteThumbnailForm') &&
  feed.includes('setNoteThumbnailFormNote') &&
  feed.includes('noteThumbnailFormIds'),
  'feed manages the formId->noteId binding');
check(feed.includes('repo.getNote(entry.noteId)') &&
  feed.includes('pushNoteThumbnailTitles') &&
  feed.includes('refreshNoteThumbnailForms'),
  'feed resolves bound notes + exposes both push paths');
check(feed.includes('renderFormThumbImages') &&
  sharedFeed.includes('export async function renderFormThumbImages'),
  'thumbnail rendering reuses the shared engine');

// ---------- Harmony：卡片 ----------
check(card.includes("@LocalStorageProp('noteId')") &&
  card.includes("@LocalStorageProp('thumb')") &&
  card.includes("@LocalStorageProp('configured')"),
  'card binds noteId/thumb/configured');
check(card.includes("'memory://' + this.thumb") &&
  card.includes('shortcut_new_note'),
  'card shows memory:// thumbnail or placeholder');
check(card.includes('note_id: this.noteId'),
  'configured click routes note_id (original VIEW+note_id)');
check(card.includes("abilityName: 'NoteAbility'\n        });") ||
  card.includes("abilityName: 'NoteAbility'"),
  'unconfigured click plain-launches NoteAbility (MAIN+LAUNCHER)');
check(card.includes("action: 'message'") &&
  card.includes('edit: true'),
  'edit affordance posts a message event');

// ---------- Harmony：formEdit 配置链 ----------
check(editAbility.includes('extends FormEditExtensionAbility') &&
  editAbility.includes('session.loadContent') &&
  editAbility.includes('editFormId'),
  'formEdit ability loads the picker page with the formId');
check(editPage.includes('getAllNotes') &&
  editPage.includes('TextInput') &&
  editPage.includes('filteredNotes') &&
  editPage.includes('setNoteThumbnailFormNote') &&
  editPage.includes('pushNoteThumbnailTitles'),
  'picker page lists + searches notes and writes the binding');
check(formAbility.includes('NOTE_THUMBNAIL_FORM_NAME') &&
  formAbility.includes('registerNoteThumbnailForm') &&
  formAbility.includes('pushNoteThumbnailTitles') &&
  formAbility.includes('noteThumbnailFormIds') &&
  formAbility.includes('THUMB_EDIT_ABILITY'),
  'NoteFormAbility wires the thumbnail card + edit dispatch');

// ---------- 页面 feed 钩子 ----------
check(library.includes('refreshNoteThumbnailForms'),
  'LibraryPage hooks the thumbnail feed at loadNotes completions');

// ---------- 字符串 ----------
check(baseStrings.includes('"form_note_thumbnail_display"') &&
  baseStrings.includes('Quick access to one of your notes.') &&
  baseStrings.includes('Choose a note') &&
  baseStrings.includes('No notes yet') &&
  zhStrings.includes('"form_note_thumbnail_pick"') &&
  zhStrings.includes('"form_picker_no_notes"'),
  'thumbnail card strings localized in both locales');

console.log(`D05_ORIGINAL_NOTE_THUMBNAIL_CARD_OK TOTAL=${total} FAILED=0`);
