// Phase 1197 — stylus haptic (HapticPreferencesInitializer startup Initializer)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const F = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/gingerlabs/notability/data/stylus/haptic/HapticPreferencesInitializer.java';
const s = readFileSync(F, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('class HapticPreferencesInitializer', s.includes('class HapticPreferencesInitializer'));
t('implements g06 (Initializer)', s.includes('implements g06'));
t('create(Context) method', s.includes('create(Context'));
t('getApplicationContext', s.includes('getApplicationContext'));
t('NbApplication check', s.includes('NbApplication'));
t('xj2.A coroutine launch', s.includes('xj2.A'));
t('q65 coroutine scope', s.includes('q65'));
t('c60 coroutine', s.includes('c60'));
t('dependencies() empty hw3', s.includes('dependencies()') && s.includes('hw3'));
t('returns mof.a (Unit)', s.includes('mof.a'));
console.log('stylus-haptic replay: ' + n + '/10 checks green');
