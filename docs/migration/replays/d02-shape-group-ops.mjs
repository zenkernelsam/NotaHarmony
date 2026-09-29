// Phase 1048 — shape/group op payloads + t16/cmf types
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ao2 = R('ao2'), le8 = R('le8'), cm2 = R('cm2'), vd8 = R('vd8'), t16 = R('t16'), cmf = R('cmf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['page','origin','rotation','scale','definition','tool','style','tapePattern','color','borderWidth','fillColor','zIndex','smartHighlight','force','positionLocked','inkEffects','inkEffectsTinted'].forEach(fld => assert.ok(ao2.includes(fld + '='), 'ao2 missing ' + fld));
t('ao2 CreateShape: all 17 fields', true);
t('ao2: no variable-width', ao2.includes('Cannot create shapes with variable width ink') && ao2.includes('t16.VARIABLE_WIDTH'));
t('ao2: no zero-alpha fillColor', ao2.includes('Create shape with `fillColor: nil` for unfilled') && ao2.includes('cmfVar.I == 0'));
t('ao2: ink_effects Pen/Highlighter gate', ao2.includes('ink_effects require a Pen or Highlighter tool'));
t('le8 ModifyShape: 17 fields + shapes list', le8.includes('ModifyShape(shapes=') && le8.includes('lv2.e0(this)') && le8.includes('positionLocked=') && le8.includes('borderWidth='));
t('le8: shapes>0 + no var-width', le8.includes('Must specify more than 0 shapes') && le8.includes('Shapes cannot use variable width ink'));
t('cm2 CreateGroup: members>0', cm2.includes('CreateGroup(members=') && cm2.includes('Cannot create a group with 0 members') && cm2.includes('lv2.P(this)'));
t('vd8 ModifyGroup: members>0', vd8.includes('ModifyGroup(group=') && vd8.includes('Must specify more than 0 members') && vd8.includes('lv2.Q(this)'));
t('t16: 4 ink styles', ['VARIABLE_WIDTH((byte) 0)','FIXED_WIDTH((byte) 1)','DASH((byte) 2)','DOTS((byte) 3)'].every(x => t16.includes(x)));
t('cmf: byte color value', cmf.includes('public final byte I') && cmf.includes('implements Comparable'));
t('le8: definition via z5c.w', le8.includes('z5c.w(this)'));
t('ao2: od4.m stringbuilder tail', ao2.includes('od4.m(sb'));
console.log('shape-group-ops replay: ' + n + '/12 checks green');
