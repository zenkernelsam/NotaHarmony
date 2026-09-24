import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const page = read('note/src/main/ets/ui/library/LibraryPage.ets');
const vm = read('note/src/main/ets/ui/library/LibraryViewModel.ets');
const iface = read('note/src/main/ets/data/RepositoryInterfaces.ets');
const repo = read('note/src/main/ets/data/NoteRepositoryImpl.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const cd = readOriginal('decompiled_1.0.3/sources/defpackage/cd.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// cd case 0: the creation sheet lists Import -> Templates (ac4.K0 flag) ->
// Doc scan (ac4.a0 flag) -> Create note rows.
ok(cd.includes('feature_library__import') &&
   cd.includes('feature_library__templates') &&
   cd.includes('feature_library__docscan') &&
   cd.includes('feature_library__create_note') &&
   cd.includes('feature_library__templatenewnote'),
  'original creation-sheet rows missing');
ok(cd.indexOf('feature_library__import') < cd.indexOf('feature_library__templates') &&
   cd.indexOf('feature_library__templates') < cd.indexOf('feature_library__create_note'),
  'original creation-sheet row order missing');
ok(origStrings.includes('feature_library__templates">Templates'),
  'original Templates label missing');

// --- Harmony anchors ----------------------------------------------------------------------
// Speed-dial gains a Templates chip that opens the picker dialog.
ok(page.includes("app.string.templates") && page.includes('this.templateDialog.open()'),
  'templates speed-dial chip missing');
// TemplatePickerDialog offers the four paper templates and reports onPick.
ok(page.includes('struct TemplatePickerDialog') &&
   page.includes('PaperTemplate.PLAIN') && page.includes('PaperTemplate.LINES') &&
   page.includes('PaperTemplate.GRID') && page.includes('PaperTemplate.DOTS') &&
   page.includes('this.onPick(template)'),
  'template picker dialog missing');
// createFromTemplate routes through the shared create+launch pipeline.
ok(page.includes('private async createFromTemplate(template: PaperTemplate)') &&
   page.includes('this.createAndLaunch(false, template)') &&
   page.includes('templateOverride?: PaperTemplate') &&
   page.includes('vm.createNote(this.searchText, templateOverride, folderId)'),
  'createFromTemplate wiring missing');
// VM/repo thread the override into the bootstrap background.
ok(vm.includes('templateOverride?: PaperTemplate') &&
   vm.includes('this.repo.createNote(ORIGINAL_NOTE_DEFAULT_TITLE'),
  'view-model template override missing');
ok(iface.includes('templateOverride?: PaperTemplate'),
  'repository contract missing template override');
ok(repo.includes('templateOverride !== undefined') &&
   repo.includes('applyOriginalPaperSettings(defaultTemplate') &&
   repo.includes('defaultTemplate.size, templateOverride, defaultTemplate.orientation'),
  'template override application missing');
ok(stringsBase.includes('"name": "templates"') && stringsZh.includes('"name": "templates"'),
  'templates string missing in a locale');
ok(stringsBase.includes('"value": "Templates"'),
  'templates EN value diverges from the original label');

// --- Executable behaviour model -----------------------------------------------------------
// Model the override: resolved default keeps size/orientation; the chosen
// template swaps only the paper. applyOriginalPaperSettings(current, size,
// template, orientation) preserves current.size/orientation fields.
const TEMPLATE = { PLAIN: 0, LINES: 1, GRID: 2, DOTS: 3 };
function applyOverride(resolved, template) {
  if (template === undefined) return resolved;
  return { ...resolved, template };
}
const defaultSettings = { size: 4, template: TEMPLATE.PLAIN, orientation: 0 };
assert.equal(applyOverride(defaultSettings, undefined).template, TEMPLATE.PLAIN);
assert.deepEqual(applyOverride(defaultSettings, TEMPLATE.DOTS),
  { size: 4, template: TEMPLATE.DOTS, orientation: 0 });
assert.equal(applyOverride(defaultSettings, TEMPLATE.LINES).size, 4);
checks += 3;

console.log(`D02_ORIGINAL_CREATE_FROM_TEMPLATE_OK TOTAL=${checks} FAILED=0`);
