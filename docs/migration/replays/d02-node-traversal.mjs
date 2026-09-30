// Phase 1251 — xp4 Modifier.Node traversal / focus events
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const xp4 = R('xp4.java');
t('xp4 extends od8 5 ifaces', xp4.includes('extends od8 implements q52, kv6, sn9, rd8, j73'));
t('xp4 a0 kindMask', xp4.includes('int a0'));
t('xp4 wx4 X callback', xp4.includes('wx4 X'));
t('xp4 h1 onFocusStateChange', xp4.includes('h1(sp4 sp4Var, sp4 sp4Var2)') && xp4.includes('wx4Var.invoke'));
t('xp4 visitAncestors unattached', xp4.includes('visitAncestors called on an unattached node'));
t('xp4 K & 5120 focus bit', xp4.includes('& 5120'));
t('xp4 K & 3072/2048 bits', xp4.includes('& 3072') && xp4.includes('& 2048'));
t('xp4 od8.L chain walk', xp4.includes('(od8) hw6VarM0.o0.O'));
t('xp4 k1()->qz6 owner', xp4.includes('qz6 k1()') && xp4.includes('zv0.a()'));
t('xp4 n73 delegate traversal', xp4.includes('instanceof n73'));
console.log('node-traversal replay: ' + n + '/10 checks green');
