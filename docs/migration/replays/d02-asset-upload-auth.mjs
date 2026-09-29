// Phase 1002 — vqf 资产直传 + f8c 鉴权 + je3 DeviceId
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const vqf = readFileSync(D + 'vqf.java', 'utf8');
const f8c = readFileSync(D + 'f8c.java', 'utf8');
const je3 = readFileSync(D + 'je3.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// vqf GCS signed-URL asset upload
t('vqf: POST with @Url dynamic', vqf.includes('@py9') && vqf.includes('@irf String str'));
t('vqf: content-md5 header', vqf.includes('@me5("content-md5")'));
t('vqf: x-goog-content-length-range header', vqf.includes('x-goog-content-length-range'));
t('vqf: nwb body -> vyb', vqf.includes('@nz0 nwb nwbVar') && vqf.includes('ef2<? super vyb>'));
// f8c auth
t('f8c: /google/sign-in', f8c.includes('"/google/sign-in"'));
t('f8c: /microsoft/sign-in', f8c.includes('"/microsoft/sign-in"'));
t('f8c: /auth/nonce', f8c.includes('"/auth/nonce"'));
t('f8c: d8c body + ryb<e8c> response', f8c.includes('@nz0 d8c d8cVar') && f8c.includes('ryb<e8c>'));
t('f8c: nonce -> ryb<a8c>', f8c.includes('ryb<a8c>'));
// je3 DeviceId
t('je3: @fyc serializable value class', je3.includes('@fyc(with = qe3.class)'));
t('je3: ttf field', je3.includes('public final ttf a'));
t('je3.a: SecureRandom 16 bytes', je3.includes('byte[16]') && je3.includes('coc.a.nextBytes'));
t('je3.a: v4 version bits', je3.includes('bArr[6] & 15') && je3.includes('| 64'));
// wiring
const ko = readFileSync(D + 'ko.java', 'utf8');
t('ko: deviceId = je3.a in bundle URL', ko.includes('(je3) objU)'));
console.log('asset-upload-auth replay: ' + n + '/14 checks green');
