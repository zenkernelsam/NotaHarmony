// D02 arrays/pen_string 面 + Rive 运行时谱系 — Phase 808
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const A103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/arrays.xml', 'utf8');
const A142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/arrays.xml', 'utf8');
const S142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/strings.xml', 'utf8');
const R103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/app/rive';
const R142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/sources/app/p000rive';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const countJava = (dir) => {
  let n = 0;
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p); else if (e.name.endsWith('.java')) n++;
    }
  };
  walk(dir);
  return n;
};

check('arrays.xml array names identical across versions',
  [...A103.matchAll(/<array name="([^"]+)"/g)].map((m) => m[1]).sort().join('|')
    === [...A142.matchAll(/<array name="([^"]+)"/g)].map((m) => m[1]).sort().join('|'));

check('feature_learn__chat_card_headers = 7 rotating prompts (Learn surface)',
  A142.includes('Where do you need help?')
  && A142.includes('What do you want to understand better?')
  && (A142.match(/<item>What |<item>Where |<item>Ask /g) ?? []).length >= 7);

check('pen_string_* family: 8 keys incl. fixed/variable thickness mode labels',
  ['pen_string_color', 'pen_string_color_picker', 'pen_string_color_spuit',
    'pen_string_comma', 'pen_string_current_any', 'pen_string_new_any',
    'pen_string_fixed_thickness', 'pen_string_variable_thickness']
    .every((k) => S142.includes(`name="${k}"`))
  && S142.includes('Fixed thickness') && S142.includes('Variable thickness'));

check('Rive runtime present in 1.0.3 (app/rive 256 files) upgraded in 1.4.2 (p000rive 485)',
  fs.existsSync(R103) && countJava(R103) === 256
  && fs.existsSync(R142) && countJava(R142) === 485);

check('.riv animation inventory identical across versions (6 files)',
  (() => {
    const riv = (d) => {
      const out = [];
      const walk = (dd) => {
        for (const e of fs.readdirSync(dd, { withFileTypes: true })) {
          const p = path.join(dd, e.name);
          if (e.isDirectory()) walk(p); else if (e.name.endsWith('.riv')) out.push(e.name);
        }
      };
      walk(d);
      return out.sort();
    };
    return riv('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources').join('|')
      === riv('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources').join('|');
  })());

console.log(`arrays-pen-strings replay: ${checks.length}/${checks.length} checks green`);
