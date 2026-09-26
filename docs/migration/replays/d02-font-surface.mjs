// D02 字体资产面收口 — Phase 803
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const F103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/font';
const F142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/font';
const HFONTS = 'C:/HarmonyProject/NotaHarmony/note/src/main/resources/rawfile/fonts';
const NOTEFONTS = 'C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/NoteFonts.ets';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const l103 = fs.readdirSync(F103).sort();
const l142 = fs.readdirSync(F142).sort();
const only142 = l142.filter((f) => !l103.includes(f));
const removed = l103.filter((f) => !l142.includes(f));

check('font dir = 17 files both versions; only delta is Inter opsz->wght rename',
  l103.length === 17 && l142.length === 17
  && only142.length === 2 && removed.length === 2
  && only142.every((f) => f.includes('_wght'))
  && removed.every((f) => f.includes('_opszwght')));

check('original 7 families x 17 font files pinned (10 otf + 7 ttf)',
  ['ebgaramond_variablefont', 'inter_variablefont_wght', 'roboto_variablefont',
    'proximasoft_regular', 'untitledserif_regular', 'gtflairebasic_black',
    'gtamericamono_bold'].every((f) => l142.some((x) => x.startsWith(f)))
  && l142.filter((f) => f.endsWith('.otf')).length === 10
  && l142.filter((f) => f.endsWith('.ttf')).length === 7);

check('note-text 3 families bundled and registered in Harmony',
  ['inter.ttf', 'roboto.ttf', 'ebgaramond.ttf']
    .every((f) => fs.existsSync(path.join(HFONTS, f)))
  && ['Inter', 'Roboto', 'EBGaramond']
    .every((f) => fs.readFileSync(NOTEFONTS, 'utf8').includes(`familyName: '${f}'`)));

check('brand 4 families registered as chrome-only (GTAmericaMono/GTFlaire/ProximaSoft/UntitledSerif)',
  ['gtamericamono', 'gtflairebasic', 'proximasoft', 'untitledserif']
    .every((f) => l142.some((x) => x.startsWith(f)))
  && ['gtamericamono', 'gtflairebasic', 'proximasoft', 'untitledserif']
    .every((f) => l103.some((x) => x.startsWith(f))));

check('pdftron exotic font plugin is vendor raw asset in both versions',
  fs.existsSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/raw/pdftron_exotic_font_resources.plugin')
  && fs.existsSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/raw/pdftron_exotic_font_resources.plugin'));

check('styles.xml brand fonts are Samsung system attrs (sec-roboto-light), not app fonts',
  fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/styles.xml', 'utf8')
    .includes('sec-roboto-light'));

console.log(`font-surface replay: ${checks.length}/${checks.length} checks green`);
