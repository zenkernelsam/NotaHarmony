// Phase 965 — q4j.b/c r29 NoteBundle 写器：8 字段 + CAS 重入防护
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const q4j = readFileSync(`${ROOT}/q4j.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// entry: b() extracts accessors, op provider via sg5.n OP_HOLDER
ok(/static final int b\(r29 r29Var, a aVar\)/.test(q4j), 'b = r29 writer entry');
ok(/new q5\(27, \(uq9\) x82\.x\(sg5\.n, sg5\.a\[12\]\), r29Var\)/.test(q4j), 'b: op provider = q5(27, OP_HOLDER, r29)');
ok(/r29Var\.p\(\) <= 0[\s\S]{0,60}sg5\.o/.test(q4j), 'b: empty ops -> sg5.o sentinel');

// ops vector: CAS-guarded double-buffered offset collection
ok(/sg5\.e\(\)\.compareAndSet\(false, true\)/.test(q4j), 'c: CAS on usingOffsetsHolder');
ok(/zCompareAndSet \? sg5\.d\(\) : sg5\.c\(\)/.test(q4j), 'c: nested->d() else c() list');
ok(/listD\.add\(Integer\.valueOf\(ree\.a\(\(cee\) ix4Var\.invoke/.test(q4j), 'c: per-op ree.a serialize -> offset');
ok(/aVar\.D\(4, i, 4\)/.test(q4j), 'c: D(4,i,4) uoffset vector');
ok(/aVar\.g\(\(\(Number\) listD\.get\(i3\)\)\.intValue\(\)\)/.test(q4j), 'c: reverse-push offsets');
ok(/sg5\.e\(\)\.set\(false\)/.test(q4j), 'c: CAS released on both paths');

// string fields via dbj.c
ok(/dbj\.c\(charSequence, aVar\)/.test(q4j) && /dbj\.c\(charSequence2, aVar\)/.test(q4j), 'c: strings via dbj.c');

// field layout
ok(/aVar\.C\(8\)/.test(q4j), 'c: C(8) fields');
ok(/aVar\.h\(6, numValueOf\.intValue\(\)\)/.test(q4j), 'c: f6 = ops vector');
ok(/aVar\.j\(0, zwd\.a\(utfVar, aVar\)\)/.test(q4j), 'c: f0 = zwd.a(noteId utf)');
ok(/aVar\.j\(1, zwd\.a\(utfVar2, aVar\)\)/.test(q4j), 'c: f1 = legacyNoteId opt');
ok(/aVar\.i\(2, s\)/.test(q4j), 'c: f2 = editorSite short');
ok(/aVar\.h\(3, iC\)/.test(q4j), 'c: f3 = editorUserId');
ok(/aVar\.f\(4, j\)/.test(q4j), 'c: f4 = createdAt long');
ok(/aVar\.h\(5, iC2\)/.test(q4j), 'c: f5 = creatorUserId');
ok(/aVar\.i\(7, rgc\.a\)/.test(q4j), 'c: f7 = schemaVersion = rgc.a');

// required triple: noteId + editorUserId + ops
ok(/aVar\.z\(iN, 4\);[\s\S]{0,40}aVar\.z\(iN, 10\);[\s\S]{0,40}aVar\.z\(iN, 14\)/.test(q4j), 'c: required z(4)+z(10)+z(14)');

// negative-length guard
ok(/Got negative length/.test(q4j) && /new lg5\(1, numValueOf2\)/.test(q4j), 'c: neg-length log via lg5(1)');

console.log(`\nnotebundle-writer replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
