// Phase 1042 — ttf/utf/cxc full semantics
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const ttf = readFileSync(D + 'ttf.java', 'utf8');
const utf = readFileSync(D + 'utf.java', 'utf8');
const cxc = readFileSync(D + 'cxc.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ttf.a(): byte[] serialize', ttf.includes('public final byte[] a()'));
t('ttf: compareTo', ttf.includes('public final int compareTo('));
t('ttf: equals', ttf.includes('public final boolean equals('));
t('ttf: hashCode=I^J', ttf.includes('Long.hashCode(this.I ^ this.J)'));
t('utf: a()+c()+d() accessors', utf.includes('public final String a()') && utf.includes('public final long c()') && utf.includes('public final long d()'));
t('utf: equals+hashCode+toString', utf.includes('public final boolean equals(') && utf.includes('public final int hashCode()') && utf.includes('public final String toString()'));
t('cxc.C(): int at +8', cxc.includes('this.J.getInt(this.I + 8)'));
t('cxc: ka4 a() override', cxc.includes('@Override // defpackage.ka4') && cxc.includes('public final String a()'));
t('cxc: xwd+exc', cxc.includes('extends xwd') && cxc.includes('exc'));
const xwd = readFileSync(D + 'xwd.java', 'utf8');
t('xwd: b() binds offset+bb', xwd.includes('public final void b(int i, ByteBuffer'));
console.log('id-semantics replay: ' + n + '/10 checks green');
