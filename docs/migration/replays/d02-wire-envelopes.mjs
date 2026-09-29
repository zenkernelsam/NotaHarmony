// Phase 1055 — wire envelopes: uq9 Op + vt9 OpsBundle + r29 NoteBundle + sdf
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const uq9 = R('uq9'), vt9 = R('vt9'), r29 = R('r29'), sdf = R('sdf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

['id=','clientTime=','serverTime=','audioTime=','payload=','transientInteraction='].forEach(f => assert.ok(uq9.includes(f), 'uq9 missing ' + f));
t('uq9 Op envelope: 6 fields', true);
t('uq9: id→qo5, payload→z5c.x', uq9.includes('qo5 l()') && uq9.includes('z5c.x(this)'));
t('uq9: transient→sdf + qo5/sdf accessors', uq9.includes('sdf o()') && uq9.includes('qo5 p(qo5') && uq9.includes('sdf r(sdf'));
t('vt9 OpsBundle{ops,schemaVersion}', vt9.includes('OpsBundle(ops=') && vt9.includes('schemaVersion=') && vt9.includes('lv2.U(this)'));
t('vt9: ops vector + count', vt9.includes('uq9 l(uq9 uq9Var, int i)') && vt9.includes('public final int j()'));
['noteId=','legacyNoteId=','editorSite=','editorUserId=','createdAt=','creatorUserId=','ops='].forEach(f => assert.ok(r29.includes(f), 'r29 missing ' + f));
t('r29 NoteBundle: 7+ fields', true);
t('r29: utf noteId×2 + ops→uq9', r29.includes('utf n()') && r29.includes('utf o()') && r29.includes('uq9 r(uq9 uq9Var, int i)'));
t('r29: editorSite/creator via ymf/String', r29.includes('ymf.a(l())') && r29.includes('String m()') && r29.includes('String k()'));
t('sdf: {interactionId:qo5,timeout:mmf}', sdf.includes('TransientInteraction(interactionId=') && sdf.includes('timeout=') && sdf.includes('qo5 j()') && sdf.includes('mmf k()'));
t('sdf: required+unused-timeout msgs', sdf.includes('Interaction Id is currently required') && sdf.includes('Timeout is currently unused'));
t('all 4 extend cee+ka4', [uq9, vt9, r29, sdf].every(s => s.includes('extends cee') && s.includes('implements ka4')));
t('uq9: clientTime njj.j0 fmt', uq9.includes('njj.j0(10, k())'));
console.log('wire-envelopes replay: ' + n + '/12 checks green');
