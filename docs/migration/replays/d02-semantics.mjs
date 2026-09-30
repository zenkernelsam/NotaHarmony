// Phase 1265 — tvc/vvc/ivc/xvc Compose semantics/accessibility
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const tvc = R('tvc.java');
t('tvc ContentDescription key', tvc.includes('"ContentDescription"'));
t('tvc Heading+Disabled+Focused keys', tvc.includes('"Heading"') && tvc.includes('"Disabled"') && tvc.includes('"Focused"'));
t('tvc wvc property keys', (tvc.match(/new wvc\(/g)||[]).length >= 10);
const ivc = R('ivc.java');
t('ivc action keys A-j', ivc.includes('wvc A') && ivc.includes('wvc j'));
const vvc = R('vvc.java');
t('vvc editableText accessor', vvc.includes('editableText'));
t('vvc textSelectionRange', vvc.includes('textSelectionRange'));
t('vvc imeAction accessor', vvc.includes('imeAction'));
t('vvc customActions', vvc.includes('customActions'));
t('vvc wk8 KProperty array', vvc.includes('new wk8(vvc.class'));
const xvc = R('xvc.java');
t('xvc SemanticsPropertyReceiver', xvc.includes('interface xvc'));
console.log('semantics replay: ' + n + '/10 checks green');
