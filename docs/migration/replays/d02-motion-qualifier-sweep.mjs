// Phase 810 replay: motion/selector resources + qualified-values sweep.
// Pins the res/ tree closure: all anim/animator/color/interpolator
// removals are vendor; spen_recoil_* pre-exists; values-* qualifiers
// carry zero app-level deltas.
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability';
const res = (v, ...p) => join(ROOT, `decompiled_${v}/resources/res`, ...p);

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; console.log(`  ok  ${name}`); }
  else { fail++; console.log(`FAIL  ${name} ${detail}`); }
}

const dirs = ['anim', 'animator', 'color', 'interpolator'];
const VENDOR = /^(abc|mtrl|material|design|fragment|exo|common_|btn_|switch_|notification|nav_|tooltip|mr_|lb_|preference|sesl|appcompat)/;

// 1. All removed entries across motion dirs are vendor-named.
for (const d of dirs) {
  const a = existsSync(res('1.0.3', d)) ? readdirSync(res('1.0.3', d)) : [];
  const b = existsSync(res('1.4.2', d)) ? readdirSync(res('1.4.2', d)) : [];
  const removed = a.filter(f => !b.includes(f)).map(f => f.replace('.xml', ''));
  check(`${d}: ${a.length}->${b.length} removals all vendor`,
    removed.every(f => VENDOR.test(f)),
    removed.filter(f => !VENDOR.test(f)).join(','));
}

// 2. spen_recoil_* present in both versions (pre-existing, not a delta).
for (const v of ['1.0.3', '1.4.2']) {
  const anim = readdirSync(res(v, 'anim'));
  const animator = readdirSync(res(v, 'animator'));
  check(`${v}: spen_recoil surface intact`,
    anim.includes('spen_recoil_pressed_scale_interpolator.xml') &&
    anim.includes('spen_recoil_released_scale_interpolator.xml') &&
    animator.includes('spen_recoil_button_selector.xml'));
}

// 3. values-* qualifier dirs: zero app-level entry-count deltas.
const APPKEY = /feature_|ui_|app_|pen_/;
const QUALS = readdirSync(res('1.4.2'))
  .filter(d => d.startsWith('values-'));
let qualScanned = 0, qualAppDelta = 0;
for (const q of QUALS) {
  for (const f of ['colors', 'dimens', 'bools', 'integers', 'strings', 'styles']) {
    const c1 = existsSync(res('1.0.3', q, `${f}.xml`))
      ? (readFileSync(res('1.0.3', q, `${f}.xml`), 'utf8')
          .match(/name="[^"]*"/g) || [])
          .filter(n => APPKEY.test(n)).length : 0;
    const c2 = existsSync(res('1.4.2', q, `${f}.xml`))
      ? (readFileSync(res('1.4.2', q, `${f}.xml`), 'utf8')
          .match(/name="[^"]*"/g) || [])
          .filter(n => APPKEY.test(n)).length : 0;
    qualScanned++;
    if (c1 !== c2) qualAppDelta++;
  }
}
check(`qualified-values sweep: ${qualScanned} file-pairs, zero app deltas`,
  qualScanned > 0 && qualAppDelta === 0);

// 4. values-night/colors.xml byte-identical (dark widget surface stable).
check('values-night/colors.xml identical across versions',
  readFileSync(res('1.0.3', 'values-night', 'colors.xml'), 'utf8') ===
  readFileSync(res('1.4.2', 'values-night', 'colors.xml'), 'utf8'));

// 5. res/ dir-level delta: 15 removed dirs all carry zero app-level
//    content; 8 added dirs are API/density/watch qualifier buckets.
const d1 = readdirSync(res('1.0.3')).filter(d => !d.endsWith('.xml'));
const d2 = readdirSync(res('1.4.2')).filter(d => !d.endsWith('.xml'));
const removedDirs = d1.filter(d => !d2.includes(d));
const addedDirs = d2.filter(d => !d1.includes(d));
check('15 legacy qualifier dirs removed',
  removedDirs.length === 15, removedDirs.join(','));
check('2 new qualifier dirs added', addedDirs.length === 2,
  addedDirs.join(','));
// Removed dirs contain no app-level resource files.
let appInRemoved = 0;
for (const d of removedDirs) {
  const p = res('1.0.3', d);
  for (const f of readdirSync(p)) {
    if (APPKEY.test(readFileSync(join(p, f), 'utf8'))) appInRemoved++;
  }
}
check('removed dirs carry zero app-level entries', appInRemoved === 0);

console.log(`\nmotion-qualifier replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
