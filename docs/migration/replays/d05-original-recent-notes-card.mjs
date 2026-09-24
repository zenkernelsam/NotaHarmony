// Phase 667 — 原版 RecentNotesWidgetProvider 数据小部件
// （qk9.java + app_widgets__widget_notes*.xml + RecentNotesWidgetProvider.java）。
// 原版证据（decompiled_1.0.3）：
//   RecentNotesWidgetProvider.java   onUpdate → qk9 RemoteViews 集合
//   qk9.java                         头部位图 → xld.d()=VIEW+show_recent
//                                    创建钮 → xld.a()=CREATE_NOTE
//                                    行 = 48dp 缩略图(content://…/thumbnail/
//                                    <ttf>?f=<fp>) 或 page_new_note_fill 占位
//                                    + 标题 + 分隔线；行点击 fillInIntent =
//                                    nbnote:<ttf> + putExtra("note_id",…)
//                                    空态 app_widgets__widget_recent_notes_empty
//   app_widgets__recent_notes_widget_info.xml  targetCell 4×2 + 双向 resize
//   au1.N1(10)/mk9                   最近列表上限 10 条 lastOpened 排序
// Harmony 对齐：recent_notes_card ArkTS 卡片（2*4 默认，2*2/4*4 支持 =
//   resizeMode）；RecentNotesFormFeed 以 formProvider.updateForm 推送
//   items+formImages；onAddForm/onRemoveForm 登记实例 formId 到 filesDir
//   JSON（Harmony 无活动实例枚举 API——文档化适配）；onAddForm/onUpdateForm
//   先推标题（扩展进程无 UIAbilityContext/仅 ~5s 后台——缩略图由 UIAbility
//   侧 refreshRecentNotesForms 补齐，等价原版 WidgetImageProvider 懒加载）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';
const wRecent = fs.readFileSync(
  `${originalRoot}sources/com/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider.java`, 'utf8');
const qk9 = fs.readFileSync(`${originalRoot}sources/defpackage/qk9.java`, 'utf8');
const infoRecent = fs.readFileSync(
  `${originalRoot}resources/res/xml/app_widgets__recent_notes_widget_info.xml`, 'utf8');
const rowXml = fs.readFileSync(
  `${originalRoot}resources/res/layout/app_widgets__widget_notes_row.xml`, 'utf8');
const notesXml = fs.readFileSync(
  `${originalRoot}resources/res/layout/app_widgets__widget_notes.xml`, 'utf8');
const origStrings = fs.readFileSync(`${originalRoot}resources/res/values/strings.xml`, 'utf8');

const formsCfg = fs.readFileSync('note/src/main/resources/base/profile/forms_config.json', 'utf8');
const formAbility = fs.readFileSync('note/src/main/ets/noteformability/NoteFormAbility.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const card = fs.readFileSync('note/src/main/ets/noteformability/pages/RecentNotesCard.ets', 'utf8')
  .replaceAll('\r\n', '\n');
const feed = fs.readFileSync('note/src/main/ets/data/RecentNotesFormFeed.ets', 'utf8')
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
check(wRecent.includes('putExtra("show_recent", true)'),
  'RecentNotes widget body fires VIEW + show_recent');
check(qk9.includes('R.layout.app_widgets__widget_notes') &&
  qk9.includes('app_widgets__widget_notes_row'),
  'qk9 builds notes header + row RemoteViews');
check(qk9.includes('setOnClickFillInIntent') &&
  qk9.includes('putExtra("note_id"') &&
  qk9.includes('Uri.fromParts("nbnote"'),
  'row click fires nbnote:<ttf> + note_id fillInIntent');
check(qk9.includes('content://" + packageName + ".widgetimages/thumbnail/"') &&
  qk9.includes('appendQueryParameter("f"'),
  'thumbnail rows come from WidgetImageProvider content:// uris');
check(qk9.includes('app_widgets__widget_row_thumbnail_placeholder') &&
  qk9.includes('setViewVisibility(R.id.app_widgets__widget_row_thumbnail_image, 8)'),
  'rows fall back to the placeholder icon without a thumbnail');
check(qk9.includes('app_widgets__widget_create') &&
  qk9.includes('app_widgets__widget_header'),
  'qk9 binds header + create pending intents');
check(qk9.includes('app_widgets__widget_empty') &&
  qk9.includes('setEmptyView'),
  'collection has an empty view');
check(infoRecent.includes('targetCellWidth="4"') &&
  infoRecent.includes('targetCellHeight="2"') &&
  infoRecent.includes('resizeMode="vertical|horizontal"'),
  'original widget is 4x2 with bidirectional resize');
check(origStrings.includes('app_widgets__widget_recent_notes_label') &&
  origStrings.includes('>Recent Notes<') &&
  origStrings.includes('app_widgets__widget_recent_notes_empty') &&
  origStrings.includes('>No recent notes<'),
  'original strings: Recent Notes / No recent notes');
check(rowXml.includes('app_widgets__widget_row_thumbnail_image') &&
  rowXml.includes('app_widgets__widget_row_divider') &&
  rowXml.includes('page_new_note_fill'),
  'row layout: thumbnail + placeholder + divider');

// ---------- Harmony：声明 ----------
check(formsCfg.includes('"name": "recent_notes_card"') &&
  formsCfg.includes('"src": "./ets/noteformability/pages/RecentNotesCard.ets"'),
  'forms_config declares recent_notes_card');
check(formsCfg.includes('"defaultDimension": "2*4"') &&
  formsCfg.includes('"2*2"') && formsCfg.includes('"4*4"'),
  'card defaults 2*4 with resizable dimensions (matches 4x2 + resizeMode)');

// ---------- Harmony：卡片 UI + router 事件 ----------
check(card.includes("@LocalStorageProp('items')") &&
  card.includes('ForEach'),
  'card binds the items array');
check(card.includes("abilityName: 'NoteAbility'") &&
  card.includes('note_id: item.id'),
  'row click routes note_id (original note_id extra)');
check(card.includes('show_recent: true'),
  'header routes show_recent (original header intent)');
check(card.includes("launch_action: 'create_note'"),
  'create button routes launch_action=create_note');
check(card.includes("'memory://' + item.thumb") &&
  card.includes('shortcut_new_note'),
  'row shows memory:// thumbnail or placeholder (original image/placeholder)');
check(card.includes('Divider()'),
  'rows render a divider like the original layout');
check(card.includes("form_recent_notes_empty"),
  'card shows the empty-state string');

// ---------- Harmony：feed ----------
check(feed.includes("RECENT_NOTES_FORM_NAME: string = 'recent_notes_card'"),
  'feed pins the form name');
check(feed.includes('registerRecentNotesForm') &&
  feed.includes('unregisterRecentNotesForm') &&
  feed.includes('recent_notes_form_ids.json'),
  'feed persists live formIds (no enumeration API on Harmony)');
check(feed.includes('formProvider.updateForm') &&
  feed.includes('formBindingData.createFormBindingData') &&
  feed.includes('formImages'),
  'feed pushes binding data + formImages');
check(feed.includes('repo.getRecentNotes()') &&
  repo.includes('ORDER BY last_opened DESC, updated_at DESC LIMIT 10'),
  'feed reuses getRecentNotes (original au1.N1(10) ordering)');
check(feed.includes('MAX_FORM_THUMBS') &&
  feed.includes('getFirstPageThumbnailState') &&
  feed.includes('renderThumbnail') &&
  feed.includes("format: 'image/webp'"),
  'feed packs <=5 webp thumbnails via ThumbnailRenderer');
check(feed.includes('pushRecentNotesTitles') &&
  feed.includes('refreshRecentNotesForms'),
  'feed exposes extension-side title push + app-side full feed');
check(feed.indexOf('pixelMap.release()') !== -1 &&
  feed.includes('renderer.dispose()'),
  'feed releases pixelmaps and disposes the renderer');

// ---------- Harmony：FormExtensionAbility 生命周期 ----------
check(formAbility.includes('formInfo.FormParam.IDENTITY_KEY') &&
  formAbility.includes('formInfo.FormParam.NAME_KEY'),
  'onAddForm reads formId + formName from the want');
check(formAbility.includes('registerRecentNotesForm') &&
  formAbility.includes('pushRecentNotesTitles') &&
  formAbility.includes('unregisterRecentNotesForm'),
  'ability registers/unregisters and pushes titles');
check(formAbility.indexOf('onUpdateForm') !== -1 &&
  section(formAbility, 'onUpdateForm', 'onRemoveForm').includes('pushRecentNotesTitles'),
  'onUpdateForm refreshes titles');

// ---------- Harmony：页面 feed 钩子 ----------
check(library.includes("import { refreshRecentNotesForms } from '../../data/RecentNotesFormFeed';"),
  'LibraryPage imports the feed');
check(library.includes('private refreshRecentCardFeed') &&
  (library.match(/refreshRecentCardFeed\(\);/g) || []).length >= 6,
  'feed fires after every loadNotes completion (>=6 sites)');

// ---------- 字符串 ----------
check(baseStrings.includes('"form_recent_notes_display"') &&
  baseStrings.includes('>Recent Notes<') === false &&
  baseStrings.includes('No recent notes') &&
  zhStrings.includes('"form_recent_notes_display"') &&
  zhStrings.includes('"form_recent_notes_empty"'),
  'card strings localized in both locales');

// ---------- 剩余 fail-closed ----------
check(formAbility.includes('fail-closed') &&
  formAbility.includes('NoteThumbnail') && formAbility.includes('FolderNotes'),
  'NoteThumbnail/FolderNotes remain registered fail-closed');

console.log(`D05_ORIGINAL_RECENT_NOTES_CARD_OK TOTAL=${total} FAILED=0`);
