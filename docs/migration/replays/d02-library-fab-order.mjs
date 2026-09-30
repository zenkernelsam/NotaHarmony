// Phase 1364 — library create-FAB speed-dial fidelity to original `cd` case 0.
// Original order: Import, Templates, DocScan(flag), Create Note(last/primary).
// Harmony had: new_note, record_audio, import_note_file, templates, docscan.
// Record chip retained (ADR-0655 "Record a lecture" functional equivalence);
// the four original items reordered + relabelled to cd case-0.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const lp = readFileSync(join(root, 'note/src/main/ets/ui/library/LibraryPage.ets'), 'utf8');
const en = JSON.parse(readFileSync(join(root, 'note/src/main/resources/base/element/string.json'), 'utf8'));
const zh = JSON.parse(readFileSync(join(root, 'note/src/main/resources/zh_CN/element/string.json'), 'utf8'));
const get = (j, k) => (j.string.find(s => s.name === k) || {}).value;

let pass = 0; const fail = [];
const eq = (c, l) => { if (c) { pass++; console.log('ok -', l); } else { fail.push(l); console.log('FAIL -', l); } };

// Correct labels exist and are wired.
eq(get(en, 'create_note') === 'Create Note', 'create_note=Create Note (feature_library__create_note)');
eq(get(en, 'library_import') === 'Import', 'library_import=Import (feature_library__import)');
eq(get(zh, 'create_note') === '新建笔记', 'zh create_note=新建笔记');
eq(get(zh, 'library_import') === '导入', 'zh library_import=导入');

// FAB chip order inside createMenuOpen: Import -> Templates -> DocScan -> Create Note.
const seg = lp.slice(lp.indexOf('if (this.createMenuOpen)'));
const iImp = seg.indexOf("library_import");
const iTpl = seg.indexOf("app.string.templates");
const iDoc = seg.indexOf("app.string.docscan");
const iCre = seg.indexOf("app.string.create_note");
const iRec = seg.indexOf("record_audio");
eq(iImp > -1 && iTpl > -1 && iDoc > -1 && iCre > -1, 'all four original FAB items present');
eq(iImp < iTpl && iTpl < iDoc && iDoc < iCre, 'cd case-0 order: Import<Templates<DocScan<CreateNote');
eq(iRec > -1 && iRec < iImp, 'Record chip kept first (ADR-0655 equivalence, before original items)');

// Original cwi.b chips render an icon painter (go5.b) + label (tpe.b).
// Phase 1365: chips now carry ported feature_library__* vectors (fab_*) and a
// recording icon for the ADR-0655 Record chip.
const chipIcons = [
  ['record_audio', 'app.media.shortcut_new_recording'],
  ['library_import', 'app.media.fab_import'],
  ['templates', 'app.media.fab_templates'],
  ['docscan', 'app.media.fab_docscan'],
  ['create_note', 'app.media.fab_createnote'],
];
for (const [lbl, media] of chipIcons) {
  const re = new RegExp(`CreateActionChip\\(\\$r\\('app\\.string\\.${lbl}'\\)[\\s\\S]{0,400}\\$r\\('${media.replace(/\./g, '\\.')} '\\)`);
  eq(re.test(seg) || seg.includes(`'${media}'`), `${lbl} chip carries ${media}`);
}
eq(seg.includes('Image(icon)'), 'chip renders Image(icon) (cwi.b go5.b icon)');
const mediaDir = join(root, 'note/src/main/resources/base/media');
for (const m of ['fab_import', 'fab_templates', 'fab_docscan', 'fab_createnote']) {
  eq(existsSync(join(mediaDir, m + '.svg')), `media ${m}.svg present`);
  eq(existsSync(join(root, 'note/src/main/resources/dark/media', m + '.svg')),
    `dark media ${m}.svg present`);
}

// Regression guards.
eq(get(en, 'templates') === 'Templates', 'templates=Templates held');
eq(get(en, 'docscan') === 'Document Scan', 'docscan=Document Scan held');
eq(get(en, 'record_audio') === 'Record', 'record_audio=Record held');

console.log(`library-fab-order: ${pass}/${pass + fail.length} checks green`);
if (fail.length) process.exitCode = 1;
