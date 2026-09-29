// Phase 1109 — jxc union + bl2 tombstone + iwc live anchor store
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const jxc = R('jxc'), bl2 = R('bl2'), iwc = R('iwc'), e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('jxc iface', jxc.includes('interface jxc'));
t('jxc: Set b() + Maps', jxc.includes('Set b()') && jxc.includes('Map f()'));
t('bl2 {qo5 a,b,c}', bl2.includes('qo5 a') && bl2.includes('Object b') && bl2.includes('Object c'));
t('bl2 ctor 3-arg', bl2.includes('bl2(qo5 qo5Var, Object obj, Object obj2)'));
t('iwc implements jxc', iwc.includes('implements jxc'));
t('iwc has wia store + gja builder', iwc.includes('wia d') && iwc.includes('gja i'));
t('iwc pending LinkedHashMap', iwc.includes('LinkedHashMap h'));
t('e4c uses iwc (e field)', e4c.includes('iwc e'));
t('e4c gja builder + al2 tombstone', e4c.includes('gja f') && e4c.includes('al2 g'));
t('e4c m4c block spec', e4c.includes('m4c b'));
console.log('anchor-store replay: ' + n + '/10 checks green');
