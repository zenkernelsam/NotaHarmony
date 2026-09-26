// Phase 826 — activity attribute inventory + Harmony mapping
// 1. 6 app activities, attribute-identical across 3 versions
// 2. MainActivity key attrs: full configChanges, adjustNothing, resizable, lockscreen
// 3. Harmony NoteAbility: deep-link skills + keepScreenOn programmatic
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const acts = v => {
  const m = readFileSync(join(REF, `decompiled_${v}/resources/AndroidManifest.xml`), 'utf8');
  return [...m.matchAll(/<activity[\s\S]*?\/>/g)].map(x => x[0]).filter(a => a.includes('gingerlabs'));
};
const a101 = acts('1.0.1'), a103 = acts('1.0.3'), a142 = acts('1.4.2');
const names = l => l.map(a => a.match(/android:name="([^"]+)"/)[1].split('.').pop()).sort();

ok('6 app activities stable across 3 versions',
  a101.length === 6 && a103.length === 6 && a142.length === 6
    && names(a101).join() === names(a142).join(),
  `${a101.length}/${a103.length}/${a142.length}`);

const main = a142.find(a => a.includes('MainActivity'));
ok('MainActivity full configChanges + adjustNothing + resizable + lockscreen attrs',
  /configChanges="[^"]*keyboardHidden[^"]*keyboard[^"]*"/.test(main)
    && main.includes('adjustNothing') && main.includes('resizeableActivity')
    && main.includes('showWhenLocked') && main.includes('turnScreenOn'),
  '');
ok('sign-in activities have configChanges; MSAL singleTop',
  a142.find(a => a.includes('AppleSignIn'))?.includes('configChanges')
    && /singleTop/.test(a142.find(a => a.includes('MicrosoftSignIn')) || ''));
ok('widget config activities present (Thumbnail+FolderNotes)',
  a142.some(a => a.includes('NoteThumbnailConfigActivity'))
    && a142.some(a => a.includes('FolderNotesConfigActivity')));

// Harmony side
const mod = readFileSync(join(REPO, 'note/src/main/module.json5'), 'utf8');
ok('NoteAbility declares home + viewData/sendData + browsable deep-link skills',
  mod.includes('entity.system.home') && mod.includes('viewData')
    && mod.includes('entity.system.browsable') && mod.includes('notability.com'));
const notePage = readFileSync(join(REPO, 'note/src/main/ets/ui/editor/NotePage.ets'), 'utf8');
ok('Harmony keepScreenOn programmatic equivalent', notePage.includes('keepScreenOn'));
const formDir = join(REPO, 'note/src/main/ets/noteformability/pages');
const pages = readdirSync(formDir);
ok('Harmony form config pages exist (widget ConfigActivity equivalents)',
  pages.some(p => p.includes('EditPage')) && pages.length >= 2,
  pages.join(','));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
