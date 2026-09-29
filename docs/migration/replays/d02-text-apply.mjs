// Phase 1106 — e4c.b op dispatch + sentinel + uwc record + UTF-8 decode
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e4c = R('e4c');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e4c implements o4c', e4c.includes('final class e4c implements o4c'));
t('sentinel opId rh8.b(-1,0)', e4c.includes('rh8.b(-1, 0)'));
t('e4c.b(uq9)→i4c', e4c.includes('i4c b(uq9 uq9Var)'));
t('dispatch on op ordinal', e4c.includes('uq9Var.m().ordinal()'));
t('case7: e46→uwc record', e4c.includes('(e46) z5c.x(uq9Var)') && e4c.includes('new uwc('));
t('uwc: {length,qo5,cxc,J,tmf,pos}', e4c.includes('fsi.J(uq9Var)') && e4c.includes('cxcVarJ'));
t('case8: f46→ByteBuffer UTF-8', e4c.includes('(f46) z5c.x(uq9Var)') && e4c.includes('f46Var.g(6)'));
t('UTF-8 CoderResult decode loop', e4c.includes('CoderResult'));
t('h4c apply wrapper', e4c.includes('new h4c('));
t('tombstone check xj2.f(exc,g.I)', e4c.includes('xj2.f(excVarD, this.g.I)') && e4c.includes('.d(new hr5())'));
console.log('text-apply replay: ' + n + '/10 checks green');
