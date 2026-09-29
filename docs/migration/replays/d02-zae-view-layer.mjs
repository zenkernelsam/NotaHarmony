// Phase 987 — zae view layer: uae/yae impls + tae/xae iterators + lv2.U/V
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const zae = readFileSync(`${ROOT}/zae.java`, 'utf8');
const uae = readFileSync(`${ROOT}/uae.java`, 'utf8');
const yae = readFileSync(`${ROOT}/yae.java`, 'utf8');
const tae = readFileSync(`${ROOT}/tae.java`, 'utf8');
const xae = readFileSync(`${ROOT}/xae.java`, 'utf8');
const lv2 = readFileSync(`${ROOT}/lv2.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// zae interface surface
ok(/x63 a\(\);\s*short b\(\);\s*ByteBuffer c\(\);\s*Iterator d\(\);\s*List e\(\);/.test(zae), 'zae: 5-method interface');

// uae merged impl — two discriminants
ok(/public uae\(r29 r29Var\)[\s\S]{0,200}this\.c = x63\.I/.test(uae), 'uae(r29): x63.I NOTE_BUNDLE');
ok(/public uae\(zgb zgbVar\)[\s\S]{0,200}this\.c = x63\.K/.test(uae), 'uae(zgb): x63.K RECEIVE_OPS_EVENT');
ok(/ByteBuffer byteBuffer = \(\(r29\) ceeVar\)\.J/.test(uae) && /ByteBuffer byteBuffer2 = \(\(zgb\) ceeVar\)\.J/.test(uae), 'uae.c(): raw backing ByteBuffer passthrough');
ok(/return lv2\.T\(\(r29\) ceeVar\)/.test(uae) && /return lv2\.V\(\(zgb\) ceeVar\)/.test(uae), 'uae.e(): lv2.T/V dispatch');

// yae — vt9 OpsBundle view
ok(/x63 c = x63\.J/.test(yae) && /this\.b = vt9Var\.k\(\)/.test(yae), 'yae(vt9): x63.J + vt9.k schema');
ok(/return lv2\.U\(this\.a\)/.test(yae), 'yae.e() = lv2.U');

// tae — shared-holder iterator
ok(/this\.J = \(\(r29\) uaeVar\.d\)\.p\(\)/.test(tae), 'tae: J = r29.p() count');
ok(/r29Var\.r\(uq9Var, i2\)/.test(tae) && /zgbVar\.m\(uq9Var, i3\)/.test(tae), 'tae.next: same-holder re-init r/m');
ok(/return this\.L < this\.J/.test(tae), 'tae.hasNext: index<count');
ok(/throw new UnsupportedOperationException\("Operation is not supported for read-only collection"\)/.test(tae), 'tae.remove: read-only throw');

// xae — vt9 variant
ok(/new xae\(this\)/.test(yae), 'yae.d() = xae iterator');
ok(/class xae implements Iterator/.test(xae), 'xae: Iterator impl');

// lv2.U/V — vt9/zgb materializers (same shape as T)
ok(/int iJ = vt9Var\.j\(\);\s*if \(iJ <= 0\)[\s\S]{0,60}return hw3\.I/.test(lv2), 'lv2.U: empty->hw3.I');
ok(/vt9Var\.l\(uq9Var, i2\)/.test(lv2), 'lv2.U: vt9.l element materialize');
ok(/int iK = zgbVar\.k\(\)/.test(lv2) && /zgbVar\.m\(uq9Var, i2\)/.test(lv2), 'lv2.V: zgb.k/m');
ok(/public static final th7 W\(s83 s83Var\)/.test(lv2), 'lv2.W: s83 tombstone materializer');

console.log(`\nzae-view-layer replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
