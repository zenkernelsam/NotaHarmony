// D02 原版组件面→Ability 映射 — Phase 800
import assert from 'node:assert/strict';
import fs from 'node:fs';

const M103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml', 'utf8');
const M142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/AndroidManifest.xml', 'utf8');
const MODULE = JSON.parse(fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/module.json5', 'utf8'));

const acts103 = [...M103.matchAll(/android:name="(com\.gingerlabs[^"]*Activity)"/g)]
  .map((m) => m[1]).sort();
const acts142 = [...M142.matchAll(/android:name="(com\.gingerlabs[^"]*Activity)"/g)]
  .map((m) => m[1]).sort();

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('app Activity inventory identical across versions (6 app activities)',
  acts103.join('|') === acts142.join('|') && acts142.length === 6);
check('widget config activities map to FormEditAbilities',
  acts142.includes('com.gingerlabs.notability.app.widgets.FolderNotesConfigActivity')
  && acts142.includes('com.gingerlabs.notability.app.widgets.NoteThumbnailConfigActivity')
  && MODULE.module.extensionAbilities
    .some((a) => a.name === 'FolderFormEditAbility')
  && MODULE.module.extensionAbilities
    .some((a) => a.name === 'NoteThumbnailFormEditAbility'));
check('5 widget providers + WidgetImageProvider declared',
  ['CreateNoteWidgetProvider', 'CreateRecordingWidgetProvider',
    'FolderNotesWidgetProvider', 'NoteThumbnailWidgetProvider',
    'RecentNotesWidgetProvider', 'WidgetImageProvider']
    .every((w) => M142.includes(`app.widgets.${w}`)));
check('Harmony NoteFormAbility + three card pages cover widget surface',
  MODULE.module.extensionAbilities.some((a) => a.name === 'NoteFormAbility')
  && fs.existsSync('note/src/main/ets/noteformability/pages/RecentNotesCard.ets')
  && fs.existsSync('note/src/main/ets/noteformability/pages/FolderNotesCard.ets')
  && fs.existsSync('note/src/main/ets/noteformability/pages/NoteThumbnailCard.ets'));
check('MissingNativeLibraryActivity is Android-only fallback',
  M142.includes('MissingNativeLibraryActivity')
  && fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/com/gingerlabs/notability/app/MissingNativeLibraryActivity.java', 'utf8')
    .includes('app__missing_native_library_title')
  && fs.existsSync('note/src/main/ets/noteformability/NoteFormAbility.ets'));
check('HwrEngineService + RecordingForegroundService + ExportFileProvider declared',
  M142.includes('HwrEngineService')
  && M142.includes('RecordingForegroundService')
  && M142.includes('ExportFileProvider')
  && M142.includes('AppUpgradeReceiver'));

console.log(`component-map replay: ${checks.length}/${checks.length} checks green`);
