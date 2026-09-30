// Phase 1126 — f8d SharedNodeData + hr5 mutable anchor fields
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const f8d = R('f8d'), hr5 = R('hr5'), qwc = R('qwc');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('f8d = SharedNodeData toString', f8d.includes('SharedNodeData('));
t('f8d: rawSiteId field', f8d.includes('rawSiteId='));
t('f8d: rawTimestamp + rawAudioTime', f8d.includes('rawTimestamp=') && f8d.includes('rawAudioTime='));
t('f8d: parent= + values=', f8d.includes('parent=') && f8d.includes('values='));
t('f8d.a(hr5,i): hr5.J=site', f8d.includes('hr5Var.J = this.a'));
t('f8d.a: hr5.K=ts', f8d.includes('hr5Var.K = this.b'));
t('f8d.a: hr5.L=slot', f8d.includes('hr5Var.L = i'));
t('hr5 mutable anchor {J,K,L}', hr5.includes('int J') || hr5.includes('J'));
t('qwc.d(hr5) delegates to f8d.a', qwc.includes('this.a.a(hr5Var, this.b)'));
t('f8d fields {short,int,long,qwc,List}', f8d.includes('short a') && f8d.includes('long c') && f8d.includes('qwc d') && f8d.includes('List e'));
console.log('shared-node replay: ' + n + '/10 checks green');
