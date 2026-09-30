// Phase 1288 — app/widgets home-screen widgets
import { readFileSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/app/widgets/';
const R = f => readFileSync(S + f, 'utf8');
const X = f => existsSync(S + f);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const cn = R('CreateNoteWidgetProvider.java');
t('CreateNoteWidgetProvider do2', cn.includes('extends do2'));
t('CreateRecordingWidgetProvider', X('CreateRecordingWidgetProvider.java'));
const fn = R('FolderNotesWidgetProvider.java'), rn = R('RecentNotesWidgetProvider.java');
t('FolderNotes+RecentNotes qk9', fn.includes('extends qk9') && rn.includes('extends qk9'));
const nt = R('NoteThumbnailWidgetProvider.java');
t('NoteThumbnail ec0', nt.includes('extends ec0'));
t('NoteThumbnail Bitmap render', nt.includes('Bitmap') && nt.includes('fzi.d'));
const wip = R('WidgetImageProvider.java');
t('WidgetImageProvider ContentProvider', wip.includes('extends ContentProvider'));
t('WidgetImageProvider image/png', wip.includes('image/png'));
t('FolderNotesConfigActivity', X('FolderNotesConfigActivity.java'));
t('NoteThumbnailConfigActivity', X('NoteThumbnailConfigActivity.java'));
t('do2/qk9/ec0 bases', X('../widgets/CreateNoteWidgetProvider.java'));
console.log('widgets replay: ' + n + '/10 checks green');
