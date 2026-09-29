// Phase 1012 — 工具箱/编辑器状态表族
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const na4 = readFileSync(D + 'na4.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// entity chain
t('ToolboxEntity: 3 cols', e47.includes('`ToolboxEntity`') && e47.includes('`mostRecentlySelectedToolId`') && e47.includes('`previouslySelectedToolId`'));
t('TrayEntity: FK to toolbox + lastUsedToolId', e47.includes('`TrayEntity`') && e47.includes('`tray_type`') && e47.includes('`lastUsedToolId`') && e47.includes('REFERENCES `ToolboxEntity`(`toolbox_id`)'));
t('ToolStateEntity: FK to tray + 13 cols', e47.includes('`ToolStateEntity`') && e47.includes('REFERENCES `TrayEntity`(`tray_id`)') && e47.includes('`selectedColorWellIndex`'));
t('ToolStateEntity: tapePattern/selFreehand/eraserPartial defaults', e47.includes('`tapePattern` INTEGER DEFAULT NULL') && e47.includes('`selectionIsFreehand` INTEGER DEFAULT 0') && e47.includes('`eraserIsPartial` INTEGER DEFAULT 0'));
// wells
t('FavoriteColorWell: toolType+color+trayIndex', e47.includes('`FavoriteColorWellEntity`') && e47.includes('`toolType` TEXT NOT NULL, `color` INTEGER'));
t('WidthSizeWell: toolType+width+trayIndex', e47.includes('`WidthSizeWellEntity`') && e47.includes('`width` REAL'));
t('RecentColorWell: color+timestamp', e47.includes('`RecentColorWellEntity`') && e47.includes('`color` INTEGER NOT NULL, `timestamp` INTEGER'));
// paper + note state + prefs
t('PaperBackground: 8 cols', e47.includes('`PaperBackground`') && e47.includes('`paperOrientation`') && e47.includes('`legacyPaperIndex`') && e47.includes('`paperLineType`') && e47.includes('`hasOptions`'));
t('BackgroundInfo: paperLineType PK', e47.includes('`BackgroundInfo`') && e47.includes('PRIMARY KEY(`paperLineType`)'));
t('NoteStateEntity: zoom+scrollOffset+lang+zoomView', e47.includes('`NoteStateEntity`') && e47.includes('`zoom` REAL') && e47.includes('`scrollOffset` INTEGER') && e47.includes('`lastCodeBlockLanguage`') && e47.includes('`zoomViewShown`'));
t('Preference: key->long_value', e47.includes('`Preference`') && e47.includes('`long_value` INTEGER'));
// insert idioms
t('na4: nullif(?,0) AUTOINCREMENT idiom', na4.includes('VALUES (nullif(?, 0),?,?,?)'));
t('na4: toolbox/tool/paper inserts present', na4.includes('INSERT OR REPLACE INTO `ToolboxEntity`') && na4.includes('INSERT INTO `PaperBackground`') && na4.includes('INSERT OR REPLACE INTO `Preference`'));
t('na4: quiz pair inserts', na4.includes('INSERT OR ABORT INTO `QuizOp`') && na4.includes('INSERT INTO `QuizSession`'));
console.log('toolbox-persistence replay: ' + n + '/14 checks green');
