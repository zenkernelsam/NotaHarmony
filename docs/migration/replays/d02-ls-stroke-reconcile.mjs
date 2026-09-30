// Phase 1237 — ls MotionEvent<->StrokeInput reconcile + link paste
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const ls = R('ls.java');
t('ls implements ol4', ls.includes('implements ol4'));
t('ls ClipData link', ls.includes('ClipData.newPlainText("link"'));
t('ls StrokeInput ueg.e', ls.includes('StrokeInput strokeInput = ueg.e'));
t('ls lx5.j.d LinkedHashMap', ls.includes('lx5Var2.j.d') && ls.includes('LinkedHashMap'));
t('ls jw5 strokeId -> hx5', ls.includes('new hx5(matrix2, jLongValue, false, strokeInput.e)'));
t('ls MotionEvent/StrokeInput mismatch warn', ls.includes('was started with a MotionEvent but finished with a StrokeInput'));
t('ls o14.s warning', ls.includes('o14.s("Stroke ID '));
t('ls jw5 key', ls.includes('jw5Var3'));
t('ls ix5 StrokeInput state', ls.includes('ix5 ix5Var'));
t('ls n37.d dispatch', ls.includes('n37Var.d'));
console.log('ls-stroke-reconcile replay: ' + n + '/10 checks green');
