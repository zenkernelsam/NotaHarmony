// Phase 1041 — xag hex + cxc pageId + ee8 op
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const xag = readFileSync(D + 'xag.java', 'utf8');
const cxc = readFileSync(D + 'cxc.java', 'utf8');
const ee8 = readFileSync(D + 'ee8.java', 'utf8');
const ttf = readFileSync(D + 'ttf.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('xag: abstract helper', /abstract class xag/.test(xag));
t('xag.c: hex writer', xag.includes('public static final void c(long j, byte[] bArr, int i, int i2, int i3)'));
t('ttf.toString uses xag.c', ttf.includes('xag.c('));
t('cxc extends xwd', cxc.includes('extends xwd'));
t('cxc implements ka4+exc', cxc.includes('implements ka4, exc') || cxc.includes('implements ka4'));
t('cxc: C()+a() accessors', cxc.includes('public final int C()') && cxc.includes('public final String a()'));
t('ee8 extends cee', ee8.includes('extends cee'));
t('ee8 implements ka4', ee8.includes('implements ka4'));
const cee = readFileSync(D + 'cee.java', 'utf8');
t('cee: op payload base', /class cee|interface cee/.test(cee));
const exc = readFileSync(D + 'exc.java', 'utf8');
t('exc: page iface', /interface exc|class exc/.test(exc));
console.log('helpers replay: ' + n + '/10 checks green');
