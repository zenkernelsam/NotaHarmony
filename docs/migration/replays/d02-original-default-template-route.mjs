import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = value => fs.readFileSync(new URL(value, root), 'utf8');
const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const original = name => fs.readFileSync(`${originalRoot}${name}.java`, 'utf8');

const jge = original('jge');
const kge = original('kge');
const x90 = original('x90');
const a1 = original('a1');
const z22 = original('z22');
const fcj = original('fcj');
const rge = original('rge');
const nge = original('nge');
const ss8 = original('ss8');
const vge = original('vge');
const xyd = original('xyd');

const pages = read('note/src/main/resources/base/profile/main_pages.json');
const settingsPage = read('note/src/main/ets/ui/settings/SettingsPage.ets');
const defaultTemplatePage = read('note/src/main/ets/ui/settings/DefaultTemplatePage.ets');
const panel = read('note/src/main/ets/ui/components/PageSettingsPanel.ets');
const picker = read('note/src/main/ets/core/model/OriginalTemplatePickerState.ets');
const pageManager = read('note/src/main/ets/ui/editor/PageManagerBar.ets');
const notePage = read('note/src/main/ets/ui/editor/NotePage.ets');
const store = read('note/src/main/ets/data/EditorSettingsStore.ets');
const fixture = read('note/src/test/OriginalTemplatePicker.test.ets');
const fixtureList = read('note/src/test/List.test.ets');

assert.match(jge, /selectedcontent\.noteeditor\.navigation\.TemplateRoute/);
assert.match(kge, /return "TemplateRoute"/);
assert.match(x90, /b40Var\.i\(npbVar\.b\(kge\.class\)/);
assert.match(a1, /feature_settings__template[\s\S]*vnh\.a/);
assert.match(z22, /case 23:[\s\S]*fcj\.a\(uz4Var24, 0\)/);
assert.match(fcj, /rge\.class, "onSelectBackground"/);
assert.match(fcj, /rge\.class, "onFavoriteBackground"/);
assert.match(fcj, /rge\.class, "onUnfavoriteBackground"/);
assert.match(rge, /o3dVar\.b\.f\(\)/);
assert.match(nge, /case 1:[\s\S]*o59Var\.d\(new ss8\(o59Var, l3aVar2\), this\)/);
assert.match(ss8, /case 7:[\s\S]*tk8Var\.g\(euaVar, aVar\.A\(\)\)/);
assert.doesNotMatch(vge, /\bo59\b|selectedDefaultTemplate/);
assert.match(xyd, /vge\.class, "onSelectBackground"/);

assert.match(pages, /ui\/settings\/DefaultTemplatePage/);
assert.match(settingsPage, /router\.pushUrl\(\{ url: 'ui\/settings\/DefaultTemplatePage' \}\)/);
assert.match(defaultTemplatePage, /getSelectedDefaultTemplate\(\)/);
assert.match(defaultTemplatePage, /saveSelectedDefaultTemplate\(originalDefaultTemplateFromSettings\(next\)\)/);
assert.match(defaultTemplatePage, /PageSettingsPanel\(\{/);
assert.match(panel, /stageOriginalTemplateSize/);
assert.match(panel, /stageOriginalTemplateOrientation/);
assert.match(panel, /applyOriginalTemplatePickerSelection/);
assert.doesNotMatch(panel, /set_default_template|onSetDefault/);
assert.doesNotMatch(pageManager, /onSetDefaultNoteBackground|onSetDefault/);
assert.doesNotMatch(notePage, /saveSelectedDefaultTemplate|saveDefaultNoteBackground/);
assert.match(store, /SELECTED_DEFAULT_TEMPLATE_KEY: string = 'selectedDefaultTemplate'/);
assert.match(store, /raw instanceof Uint8Array/);
assert.match(picker, /backgroundColor: packedPaperColor\(paper\)/);
assert.match(picker, /stageOriginalTemplateCustomColor[\s\S]*legacyPaperIndex: null/);
assert.match(picker, /stageOriginalTemplateLegacyPaper[\s\S]*backgroundColor: null/);
assert.match(picker, /const color = unpackOriginalArgb\(draft\.backgroundColor\)/);
assert.match(picker, /target\.legacyPaperIndex = draft\.legacyPaperIndex/);
assert.match(picker,
  /template === current\.template && current\.background\.paper !== null[\s\S]*target\.flairSpacingPt = current\.background\.paper\.flairSpacingPt/);
assert.match(picker, /packedPaperColor\(paper\) !== draft\.backgroundColor/);
assert.match(fixture, /stages size and orientation until a template card is selected/);
assert.match(fixtureList, /originalTemplatePickerTest\(\)/);

console.log('defaultTemplateRoute=settings-template-route-staged-picker-editor-separated');
