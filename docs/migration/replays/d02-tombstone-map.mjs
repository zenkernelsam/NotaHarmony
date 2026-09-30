// Phase 1129 — al2 LWW tombstone map
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const al2 = R('al2'), bl2 = R('bl2');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('al2 implements Map,ik6', al2.includes('implements Map, ik6'));
t('al2 {gja I} builder', al2.includes('gja I'));
t('al2(cl2) ctor builder fork', al2.includes('al2(cl2 cl2Var)') && al2.includes('.builder()'));
t('al2.a()→cl2 freeze', al2.includes('cl2 a()') && al2.includes('new cl2(this.I.build())'));
t('al2.b(bl2) tombstone add', al2.includes('void b(bl2 bl2Var)'));
t('al2.b: lookup by bl2.b key', al2.includes('gjaVar.get(obj)') && al2.includes('bl2Var.b'));
t('al2.b: so5.a LWW guard', al2.includes('so5.a(qo5Var, bl2Var.a) <= 0'));
t('al2.b: only newer opId', al2.includes('qo5Var == null'));
t('al2.c(ArrayList) bulk', al2.includes('void c(ArrayList arrayList)'));
t('bl2 = {qo5,key,value} tombstone', bl2.includes('qo5 a') && bl2.includes('Object b') && bl2.includes('Object c'));
console.log('tombstone-map replay: ' + n + '/10 checks green');
