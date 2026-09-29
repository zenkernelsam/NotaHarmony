// Phase 1050 — style ops (me8/he8/io1) + paragraph enums
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const me8 = R('me8'), he8 = R('he8'), io1 = R('io1'), r4a = R('r4a'), fy2 = R('fy2'), bcg = R('bcg'), o2d = R('o2d');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['start=','end=','textField=','bold=','italic=','underline=','highlight=','familyName=','size=','foregroundColor=','link=','superscript=','subscript=','strikethrough=','code='].forEach(f => assert.ok(me8.includes(f), 'me8 missing ' + f));
t('me8 ModifyStyle: 15 fields', true);
t('me8: familyName+size validation', me8.includes('Cannot set familyString to empty') && me8.includes('Font must be > 0'));
['start=','end=','indentLevel=','alignment=','lineSpacing=','decoratorStyle=','isChecked=','textField=','programmingLanguage=','writingDirection='].forEach(f => assert.ok(he8.includes(f), 'he8 missing ' + f));
t('he8 ModifyParagraphStyle: 10 fields', true);
t('he8: isChecked deprecated', he8.includes('isChecked is deprecated, use UpdateCheckbox'));
t('he8: no-styles + empty-range', he8.includes('No paragraph styles specified') && he8.includes('Empty range: start and end cannot point at same seqId'));
t('io1 ClearStyle: {start,end,paragraph,textField}', io1.includes('ClearStyle(start=') && io1.includes('paragraph=') && io1.includes('Invalid start type'));
t('r4a: 1-based LEFT/CENTER/RIGHT', r4a.includes('LEFT((byte) 1)') && r4a.includes('CENTER((byte) 2)') && r4a.includes('RIGHT((byte) 3)'));
t('fy2: 6 decorators', ['NONE((byte) 0)','BULLET((byte) 1)','NUMBER((byte) 2)','CHECK_BOX((byte) 3)','BLOCK_QUOTE((byte) 4)','CODE_BLOCK((byte) 5)'].every(x => fy2.includes(x)));
t('bcg: LTR/RTL', bcg.includes('LEFT_TO_RIGHT((byte) 0)') && bcg.includes('RIGHT_TO_LEFT((byte) 1)'));
t('o2d: byte-enum wrapper → r4a', o2d.includes('r4a') && o2d.includes('Byte.valueOf(this.J.get('));
t('me8: field wrappers z1d/v01/z2d/g2d/k2d', ['z1d','v01','z2d','g2d','k2d'].every(w => me8.includes(w)));
t('he8: byte-slot reads', he8.includes('Byte.valueOf(this.J.get(iC + this.I))') || he8.includes('c(4)'));
console.log('style-ops replay: ' + n + '/12 checks green');
