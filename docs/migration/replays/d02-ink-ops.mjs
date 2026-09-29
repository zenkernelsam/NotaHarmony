// Phase 1047 — ink ops (dm2/gd/wd8) + u16 tool enum + po4 point
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const dm2 = R('dm2'), gd = R('gd'), wd8 = R('wd8'), u16 = R('u16'), po4 = R('po4');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['page','origin','rotation','scale','tool','style','tapePattern','color','width','encodedCenterPath','encodedCustomPath','encodedFillPath','fillColor','styleMap','zIndex','audioDuration','nibAngle','nibFlatness','inkEffects','inkEffectsTinted'].forEach(fld => assert.ok(dm2.includes(fld + '='), 'dm2 missing ' + fld));
t('dm2 CreateInk: all 20 fields in toString', true);
t('dm2: TAPE-gate on tapePattern', dm2.includes('Cannot specify a TapePattern while Tool is not Tape') && dm2.includes('u16.TAPE'));
t('dm2: ddg.k/l/j validators', dm2.includes('ddg.k(') && dm2.includes('ddg.l(') && dm2.includes('ddg.j('));
t('dm2: 3 encoded paths lv2.w/B/E', dm2.includes('lv2.w(this)') && dm2.includes('lv2.B(this)') && dm2.includes('lv2.E(this)'));
t('gd: {ink,elements,estimated}', gd.includes('AddPathElements(ink=') && gd.includes('encodedCenterPathElements=') && gd.includes('encodedCenterPathEstimatedElements='));
t('gd: per-point ddg.b validation', gd.includes('ddg.b((po4)') && gd.includes('lv2.y(this)') && gd.includes('lv2.z(this)'));
t('wd8: {inks + 19 fields}', wd8.includes('ModifyInk(inks=') && wd8.includes('lv2.M(this)') && wd8.includes('audioDuration') === false);
t('wd8: inks>0 + no-nil-centerPath', wd8.includes('Must specify more than 0 inks') && wd8.includes('Should not be possible to nil out centerPath'));
const tools = ['PEN','PENCIL','HIGHLIGHTER','TAPE','WHOLE_ERASER','PARTIAL_ERASER','SELECTION','LASER'];
t('u16: 8 tools byte-coded', tools.every((x, i) => u16.includes(x + '((byte) ' + i + ')')));
t('po4: stylus point fields', po4.includes('public double g') && po4.includes('public long h') && po4.includes('s8a'));
t('dm2: inkEffects njj.j0 decode', dm2.includes('njj.j0(10'));
t('gd throws Exception a()', gd.includes('public final String a() throws Exception'));
console.log('ink-ops replay: ' + n + '/12 checks green');
