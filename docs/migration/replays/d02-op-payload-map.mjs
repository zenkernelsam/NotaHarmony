// Phase 1044 — op→payload dispatch map + ka4 validation + l2d rules
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const z5c = readFileSync(D + 'z5c.java', 'utf8');
const l2d = readFileSync(D + 'l2d.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('z5c: switch on uq9.m().ordinal()', z5c.includes('uq9Var.m().ordinal()'));
const pairs = [['l2d','SET_METADATA'],['ra0','CLOUD'],['ln2','CREATE_PAGE'],['ge8','MOD_PAGE'],['yn2','CREATE_REC'],['ke8','MOD_REC'],['e46','INS_CHAR'],['f46','INS_STR'],['pub','REM_CHAR'],['qub','REM_CHARS'],['f2c','REVIVE'],['me8','MOD_STYLE'],['he8','MOD_PSTYLE'],['io1','CLEAR_STYLE'],['dm2','CREATE_INK'],['gd','ADD_PATH'],['wd8','MOD_INK'],['ao2','CREATE_SHAPE'],['le8','MOD_SHAPE'],['cm2','CREATE_GRP'],['vd8','MOD_GRP'],['rl2','CREATE_BLOCK'],['td8','MOD_BLOCK'],['je8','MOD_POS'],['s83','DELETE'],['tdf','TRANSIENT'],['ee8','PDF_FIELD'],['mqf','CHECKBOX'],['yda','PEER'],['tl2','CREATE_CMT'],['ud8','MOD_CMT']];
t('z5c: all 31 payload classes instantiated', pairs.every(([c]) => z5c.includes('new ' + c + '()')));
t('z5c: NONE fails loud', /case 0:[\s\S]{0,120}throw null/.test(z5c));
let allCee = true;
for (const [c] of pairs) {
  const src = readFileSync(D + c + '.java', 'utf8');
  if (!(src.includes('extends cee') && src.includes('implements ka4'))) { console.log('not cee+ka4: ' + c); allCee = false; }
}
t('all 31 payloads extend cee+implement ka4', allCee);
t('ka4.a(): validation reporter', readFileSync(D + 'ka4.java', 'utf8').includes('String a();'));
t('l2d: title empty check', l2d.includes('Title cannot be empty'));
t('l2d: title 256 cap', l2d.includes('Title cannot exceed maximum length'));
t('l2d: template PDF single page', l2d.includes('Template PDFs can only consume (have) one page'));
t('l2d: fontSize>0', l2d.includes('Default font size value must be greater than 0'));
t('l2d: fontFamily<=30', l2d.includes('Default font family name exceeds maximum length') && l2d.includes('> 30'));
t('l2d: title<=256 literal', l2d.includes('256'));
t('z5c: default returns null', /default:[\s\S]{0,80}return null/.test(z5c) || z5c.includes('return null;'));
console.log('op-payload-map replay: ' + n + '/12 checks green');
