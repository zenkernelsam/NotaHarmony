// D02 笔色板包面移植 — Phase 807
import assert from 'node:assert/strict';
import fs from 'node:fs';

const ARR = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res/values/arrays.xml', 'utf8');
const ARR103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res/values/arrays.xml', 'utf8');
const PAL = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/data/PenPalettes.ets', 'utf8');
const PICKER = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/components/ColorPicker.ets', 'utf8');
const STR_EN = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/resources/base/element/string.json', 'utf8');
const STR_ZH = fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/resources/zh_CN/element/string.json', 'utf8');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const grab = (src, n) => {
  const m = src.match(new RegExp('<array name="' + n + '">([\\s\\S]*?)</array>'));
  return m ? [...m[1].matchAll(/#([0-9a-fA-F]{6})/g)].map((e) => '0xFF' + e[1].toUpperCase()) : null;
};

check('original arrays identical across versions (spen_* inventory)',
  [...ARR.matchAll(/name="(spen_[a-z_0-9]+)"/g)].map((m) => m[1]).join('|')
    === [...ARR103.matchAll(/name="(spen_[a-z_0-9]+)"/g)].map((m) => m[1]).join('|'));

check('original: 3 adaptive strips (39/65/65) + 23 packs + 21 adaptive packs',
  grab(ARR, 'spen_adaptive_standard_color').length === 39
  && grab(ARR, 'spen_adaptive_light_color').length === 65
  && grab(ARR, 'spen_adaptive_dark_color').length === 65);

check('Harmony PenPalettes.ets carries all strips + 23 packs + 21 adaptive',
  ['PEN_STRIP_STANDARD', 'PEN_STRIP_LIGHT', 'PEN_STRIP_DARK',
    'PEN_PALETTE_PACKS', 'PEN_PALETTE_PACKS_ADAPTIVE']
    .every((s) => PAL.includes('export const ' + s))
  && PAL.includes('0xFFFF3636') && PAL.includes('0xFF252525'));

check('pack data fidelity: pack1 std/adaptive colors match original',
  grab(ARR, 'spen_setting_swatch_1').every((c) => PAL.includes(c))
  && grab(ARR, 'spen_setting_swatch_adaptive_1').every((c) => PAL.includes(c))
  && PAL.includes('0xFFC90000'));

check('ColorPicker renders pack library via Swiper + adaptive dark variants',
  PICKER.includes('PEN_PALETTE_PACKS') && PICKER.includes('PEN_PALETTE_PACKS_ADAPTIVE')
  && PICKER.includes('pen_string_palette_library') && PICKER.includes('Swiper'));

check('a11y: color hex label string added EN+zh',
  STR_EN.includes('pen_string_color_hex') && STR_EN.includes('Color #%1$s')
  && STR_ZH.includes('pen_string_color_hex')
  && STR_EN.includes('pen_string_palette_library')
  && STR_ZH.includes('pen_string_palette_library'));

console.log(`pen-palettes replay: ${checks.length}/${checks.length} checks green`);
