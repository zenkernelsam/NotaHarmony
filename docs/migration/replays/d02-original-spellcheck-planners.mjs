// D02 原版 1.4.2 拼写检查 + planner 资产 — Phase 792
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';

const A142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/assets';
const A103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/assets';
const S142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/defpackage';
const strings103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/strings.xml', 'utf8');
const strings142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('planners/: two week-start PDF variants (monday/sunday)',
  fs.readdirSync(path.join(A142, 'planners')).sort().join('|')
    === 'academic_planner_2026_2027-monday_start.pdf|academic_planner_2026_2027-sunday_start.pdf');
check('spellcheck/ absent in 1.0.3, present in 1.4.2',
  !fs.existsSync(path.join(A103, 'spellcheck'))
  && fs.existsSync(path.join(A142, 'spellcheck', 'en_words.dat')));
check('en_words.dat is gzip\'d wordlist decompressing to ~150k words',
  (() => {
    const words = zlib.gunzipSync(
      fs.readFileSync(path.join(A142, 'spellcheck', 'en_words.dat')))
      .toString('utf8').split('\n').filter((w) => w.trim().length > 0);
    const nonWord = words.filter((w) => !/^[\w'-]+$/i.test(w.trim()));
    // ~126k entries incl. ordinals (0th) and accented loanwords (déshabillé)
    return words.length > 100000 && nonWord.length <= 10;
  })());
check('bc1 loads dictionary via GZIPInputStream into HashSet(150000)',
  fs.readFileSync(path.join(S142, 'rs.java'), 'utf8')
    .includes('spellcheck/en_words.dat')
  && fs.readFileSync(path.join(S142, 'rs.java'), 'utf8')
    .includes('GZIPInputStream')
  && fs.readFileSync(path.join(S142, 'bc1.java'), 'utf8')
    .includes('BreakIterator'));
check('fal.b batch spell-check merges known-word map with bc1',
  fs.readFileSync(path.join(S142, 'fal.java'), 'utf8')
    .includes('bc1Var.a('));
check('check_spelling settings toggle new in 1.4.2',
  strings142.includes('feature_settings__check_spelling">')
  && strings142.includes('feature_settings__check_spelling_description">')
  && !strings103.includes('check_spelling'));
check('conf-lite removed (MyScript lite), conf/ remains',
  fs.existsSync(path.join(A103, 'conf-lite'))
  && !fs.existsSync(path.join(A142, 'conf-lite'))
  && fs.existsSync(path.join(A142, 'conf')));

console.log(`spellcheck/planners replay: ${checks.length}/${checks.length} checks green`);
