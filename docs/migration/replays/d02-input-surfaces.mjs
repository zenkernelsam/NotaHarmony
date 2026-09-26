// Phase 827 — input surfaces: keyboard chords + shake gesture
// 1. Original: dispatchKeyEvent chord dispatch + onProvideKeyboardShortcuts
// 2. Chord registry: text-editing map (17 chords) + navigation group
// 3. Shake: accelerometer >2.7g debounced 1s in MainActivity
// 4. Harmony: editor-level keys exist; app-level chord surface = gap
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const REF = 'C:/Users/Cisco He/Desktop/Notability';
const REPO = 'C:/HarmonyProject/NotaHarmony';
let pass = 0, fail = 0;
const ok = (name, cond, detail = '') => {
  if (cond) { pass++; console.log(`  ok ${name}`); }
  else { fail++; console.log(`  FAIL ${name} ${detail}`); }
};

const main = readFileSync(join(REF, 'decompiled_1.4.2/sources/com/gingerlabs/notability/app/MainActivity.java'), 'utf8');
ok('MainActivity dispatches key events (chord dispatch)',
  main.includes('dispatchKeyEvent') && main.includes('onProvideKeyboardShortcuts'));
ok('shake sensor registered/unregistered in onResume/onPause',
  main.includes('SensorManager') && /registerListener.*3\)/.test(main));

const shake = readFileSync(join(REF, 'decompiled_1.4.2/sources/defpackage/d4g.java'), 'utf8');
ok('shake detector: accel >2.7g + 1s debounce',
  shake.includes('9.80665f < 2.7f') && shake.includes('< 1000'));

const syh = readFileSync(join(REF, 'decompiled_1.4.2/sources/defpackage/syh.java'), 'utf8');
const chordCount = (syh.match(/new qa8\(/g) || []).length;
ok('text-editing chord map >= 17 qa8 entries', chordCount >= 17, `got ${chordCount}`);
for (const a of ['COPY', 'PASTE', 'CUT', 'SELECT_ALL', 'UNDO', 'REDO',
  'TOGGLE_BOLD', 'TOGGLE_ITALIC', 'TOGGLE_UNDERLINE', 'TOGGLE_BULLET_LIST',
  'TOGGLE_NUMBERED_LIST', 'TOGGLE_CHECKLIST', 'INCREASE_FONT_SIZE',
  'DECREASE_FONT_SIZE', 'HOME', 'END', 'DESELECT']) {
  ok(`chord action ${a}`, syh.includes('ra8.' + a), '');
}

const strings = readFileSync(join(REF, 'decompiled_1.4.2/resources/res/values/strings.xml'), 'utf8');
const kbd = [...strings.matchAll(/name="app__kbd_shortcut_([^"]+)"/g)].map(m => m[1]);
ok('7 app-level kbd_shortcut help strings', kbd.length === 7, kbd.join(','));

// Harmony side
const overlay = readFileSync(join(REPO, 'note/src/main/ets/ui/components/TextBlockOverlay.ets'), 'utf8');
ok('Harmony editor-level key handling exists',
  overlay.includes('onEditorKeyEvent') && /keyCode === 2018/.test(overlay));
const abilitySrc = readFileSync(join(REPO, 'note/src/main/ets/noteability/NoteAbility.ets'), 'utf8');
ok('Harmony no app-level chord dispatch (registered gap)',
  !abilitySrc.includes('KEYCODE_N') && !abilitySrc.includes('new_window'));

console.log(`\n${pass}/${pass + fail} checks passed`);
process.exit(fail ? 1 : 0);
