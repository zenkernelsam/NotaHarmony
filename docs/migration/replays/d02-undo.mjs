// Phase 1190 — undo/redo history (nnf capped op-stacks + ekd Parcelable op-list)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const nnf = R('nnf.java');
t('nnf has capacity int + 2 ekd', nnf.includes('int a') && (nnf.match(/ekd/g)||[]).length>=2);
t('nnf ctor(int,List,List)', nnf.includes('nnf(int i, List list, List list2'));
t('nnf capacity-positive guard', nnf.includes('Capacity must be a positive integer'));
t('nnf size-guard undo+redo<=cap', nnf.includes('size greater than the given capacity'));
t('nnf undo+redo lists', nnf.includes('addAll'));
const ekd = R('ekd.java');
t('ekd implements Parcelable+List', ekd.includes('implements Parcelable') && ekd.includes('List'));
t('ekd RandomAccess', ekd.includes('RandomAccess'));
t('ekd CREATOR', ekd.includes('CREATOR'));
t('ekd isd backing field', ekd.includes('isd I'));
t('nnf used by other classes (gcb/vle/wx5/tgi)', ['gcb','vle','wx5','tgi'].some(f=>{try{return R(f+'.java').includes('nnf')}catch(e){return false}}));
console.log('undo replay: ' + n + '/10 checks green');
