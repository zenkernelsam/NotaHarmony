// Phase 1303 — Coil3 image loader + Samsung S-Pen SDK
import { readFileSync, existsSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const SRC = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const C = SRC + 'coil3/';
const P = SRC + 'com/samsung/android/sdk/pen/';
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const files = d => { let r = []; const w = x => { for (const e of readdirSync(x, {withFileTypes:true})) { const p = x + '/' + e.name; e.isDirectory() ? w(p) : r.push(p); } }; w(d); return r; };

t('coil3 dir', existsSync(C));
t('coil3 gif decoder', existsSync(C + 'gif'));
t('coil3 svg decoder', existsSync(C + 'svg'));
t('coil3 okhttp fetcher', existsSync(C + 'network/okhttp'));
t('coil3 HttpException', existsSync(C + 'network/HttpException.java'));
t('spen sdk dir', existsSync(P));
const penFiles = existsSync(P) ? files(P) : [];
t('spen sdk 60+ files', penFiles.length >= 60);
t('spen setting colorpicker', existsSync(P + 'setting/colorpicker'));
t('spen quicktool', existsSync(P + 'setting/quicktool'));
t('SpenConfiguration', existsSync(P + 'view/SpenConfiguration.java'));
console.log('coil-spen replay: ' + n + '/10 checks green');
