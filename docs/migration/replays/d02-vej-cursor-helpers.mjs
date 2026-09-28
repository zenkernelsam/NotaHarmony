// Phase 952 — vej 完整面：RemoveChars 工厂 a + 光标移动契约 b–r
// 静态核查 decompiled_1.0.3 结构断言
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const vej = readFileSync(`${ROOT}/vej.java`, 'utf8');
const hqe = readFileSync(`${ROOT}/hqe.java`, 'utf8');
const t4g = readFileSync(`${ROOT}/t4g.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// vej.a — RemoveChars 工厂：与 q 写器成对，序列化后反读自检
ok(/public static qub a\(AbstractList abstractList, qo5/.test(vej), 'a() = qub factory (AbstractList+qo5)');
ok(/dk4\.a\(c8dVar\)/.test(vej), 'a() builder via dk4.a(c8d)');
ok(/aVarA\.D\(12, size, 4\)/.test(vej), 'a() D(12,size,4) 12B struct vector');
ok(/sg5\.f\(aVarA, \(exc\) abstractList\.get/.test(vej), 'a() sg5.f scratch-write loop');
ok(/aVarA\.j\(1, rh8\.O\(qo5Var/.test(vej), 'a() f1 = rh8.O(textField)');
ok(/aVarA\.z\(iN, 4\)[\s\S]{0,80}aVarA\.p\(iN\)/.test(vej), 'a() z(iN,4) required + p(iN) finish');
ok(/qubVar\.d\(byteBufferWrap/.test(vej), 'a() reads back via d()');
ok(/ybg\.c\(qubVar\)/.test(vej), 'a() ybg.c validation');
ok(/rh8\.q\(c8dVar/.test(vej), 'a() rh8.q builder close (try/finally)');

// hqe — {paraIdx, offset} position value class
ok(/public final class hqe implements ui1/.test(hqe), 'hqe = ui1 position impl');
ok(/public static final hqe K = new hqe\(0, 0\)/.test(hqe), 'hqe.K = (0,0) sentinel');
ok(/public final int I;[\s\S]{0,100}public final int J;/.test(hqe), 'hqe {I=paraIdx, J=offset}');
ok(/L0\(\)[\s\S]{0,60}return this\.I/.test(hqe) && /d1\(\)[\s\S]{0,60}return this\.J/.test(hqe), 'hqe ui1: L0=I, d1=J');

// t4g — Affinity{Start,End}
ok(/new t4g\("Start", 0\)/.test(t4g) && /new t4g\("End", 1\)/.test(t4g), 't4g = Affinity{Start,End}');

// vej.b–r — cursor movement contract
ok(/public static final hqe b\(ti3 ti3Var, hqe hqeVar, di3/.test(vej), 'b = line-down (di3 remembered-x)');
ok(/public static final hqe r\(ti3 ti3Var, hqe hqeVar, di3/.test(vej), 'r = line-up mirror');
ok(/breakIterator\.following/.test(vej), 'grapheme fwd via BreakIterator.following');
ok(/breakIterator\.preceding/.test(vej), 'grapheme/word bwd via preceding');
ok(/cq\.f0\(/.test(vej), 'whitespace skip cq.f0 in word nav');
ok(/si3Var\.d\(\) == 1/.test(vej), 'c = isEmpty via si3.d()==1');
ok(/public static final hqe k\(ti3 ti3Var, hqe hqeVar\)[\s\S]{0,200}\.b\(\)\)/.test(vej), 'k = paragraph end');
ok(/hqe\.a\(hqeVar, 0\)/.test(vej), 'l = paragraph start (offset 0)');

console.log(`\nvej-cursor-helpers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
