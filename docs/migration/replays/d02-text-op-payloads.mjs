// Phase 1045 — text CRDT op payloads (e46/f46/pub/qub/f2c)
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const e46 = R('e46'), f46 = R('f46'), pub = R('pub'), qub = R('qub'), f2c = R('f2c'), lv2 = R('lv2'), mmf = R('mmf');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('e46: fields {location,unicodeScalar,textField}', e46.includes('InsertChar(location=') && e46.includes('unicodeScalar=') && e46.includes('textField='));
t('e46: isValidCodePoint validation', e46.includes('Character.isValidCodePoint(l())') && e46.includes('Cannot create character from unicodeScalar'));
t('f46: fields {location,string,textField}', f46.includes('InsertString(location=') && f46.includes('string=') && f46.includes('textField='));
t('f46: string required', f46.includes('No value for (required) field string'));
t('f46: empty-string validation', f46.includes('Cannot insert empty string') && f46.includes('k().length() == 0'));
t('f46: slots 4/6/8', f46.includes('c(4)') && f46.includes('c(6)') && f46.includes('c(8)'));
t('pub: {location,textField} + required location', pub.includes('RemoveChar(location=') && pub.includes('No value for (required) field location'));
t('pub: no validation (a→null)', /String a\(\) \{\s*return null;/.test(pub));
t('qub: locations vector + count check', qub.includes('RemoveChars(locations=') && qub.includes('Must specify more than 0 locations') && qub.includes('lv2.N(this)'));
t('f2c: locations vector + count check', f2c.includes('ReviveChars(locations=') && f2c.includes('Must specify more than 0 locations') && f2c.includes('lv2.O(this)'));
t('lv2: N(qub)/O(f2c) vector accessors', lv2.includes('List N(qub ') && lv2.includes('List O(f2c '));
t('mmf.a(int): scalar formatter', mmf.includes('public static String a(int i)'));
console.log('text-op-payloads replay: ' + n + '/12 checks green');
