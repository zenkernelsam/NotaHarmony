// Phase 1049 — block/positions/delete ops + cz0/ty0/ive enums
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const rl2 = R('rl2'), td8 = R('td8'), je8 = R('je8'), s83 = R('s83'), cz0 = R('cz0'), ty0 = R('ty0'), ive = R('ive');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['type=','corner=','page=','origin=','rotation=','scale=','size=','textWrap=','enableCaption=','zIndex=','image=','cropRect=','webUrl=','mathLatex=','mathColor=','paper=','imageFlippedHorizontally=','imageFlippedVertically=','resizesWidthToFitText=','margins=','positionLocked='].forEach(fld => assert.ok(rl2.includes(fld), 'rl2 missing ' + fld));
t('rl2 CreateBlock: all 21 toString fields', true);
t('td8 ModifyBlock: 16 fields + blocks list', td8.includes('ModifyBlock(blocks=') && td8.includes('lv2.u(this)') && td8.includes('mathLatex=') && td8.includes('cropRect=') && td8.includes('textWrap='));
t('td8: blocks>0', td8.includes('Must specify more than 0 Blocks'));
t('je8 ModifyPositions: >0 target', je8.includes('ModifyPositions(modifications=') && je8.includes('Must target more than 0 Inks/Shapes/Blocks') && je8.includes('lv2.S(this)'));
t('s83: delete/undelete 4 lists', s83.includes('entityDeletes=') && s83.includes('entityUndeletes=') && s83.includes('pageDeletes=') && s83.includes('pageUndeletes='));
t('s83: lv2.I/J/W/X accessors', s83.includes('lv2.I(this)') && s83.includes('lv2.J(this)') && s83.includes('lv2.W(this)') && s83.includes('lv2.X(this)'));
t('cz0: TEXT/IMAGE/MATH', cz0.includes('TEXT((byte) 0)') && cz0.includes('IMAGE((byte) 1)') && cz0.includes('MATH((byte) 2)'));
t('ty0: SQUARE/ROUND', ty0.includes('SQUARE((byte) 0)') && ty0.includes('ROUND((byte) 1)'));
t('ive: PIXEL_ALIGN/NO_WRAP', ive.includes('PIXEL_ALIGN((byte) 0)') && ive.includes('NO_WRAP((byte) 1)'));
t('rl2: dp5 image + k3a paper + vy7 margins + bmb crop', rl2.includes('dp5') && rl2.includes('k3a') && rl2.includes('vy7') && rl2.includes('bmb'));
t('rl2: bool getters via c(slot)+byte', rl2.includes('this.J.get(iC + this.I) == 0'));
t('td8: fa2.z/od4 sb helpers used in rl2', rl2.includes('fa2.z(sb') && rl2.includes('od4.m(sb'));
console.log('block-ops replay: ' + n + '/12 checks green');
