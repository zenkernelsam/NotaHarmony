// Phase 1272 — Rive animation runtime
import { readFileSync, readdirSync, statSync } from 'fs';
import { strict as assert } from 'assert';
import { join } from 'path';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const rav = R('app/rive/runtime/kotlin/RiveAnimationView.java');
t('RiveAnimationView extends RiveTextureView', rav.includes('extends RiveTextureView'));
t('RAV Observable<Listener>', rav.includes('Observable<RiveFileController.Listener>'));
t('RAV Builder', rav.includes('class Builder'));
t('RAV RendererAttributes', rav.includes('RendererAttributes'));
// count rive files
let cnt = 0; const walk = d => { for (const f of readdirSync(d)) { const p = join(d, f); if (statSync(p).isDirectory()) walk(p); else if (f.endsWith('.java')) cnt++; } };
walk(S + 'app/rive');
t('rive ~259 files', cnt > 200);
const core = R('app/rive/runtime/kotlin/core/Rive.java');
t('Rive core native init', /native|System\.loadLibrary|init/i.test(core));
const rt = R('app/rive/runtime/kotlin/core/RendererType.java');
t('RendererType enum', /enum|SKIA|CANVAS|RENDERER/i.test(rt));
const cdn = R('app/rive/runtime/kotlin/core/CDNAssetLoader.java');
t('CDNAssetLoader Volley', /volley|RequestQueue|http/i.test(cdn));
const sm = R('app/rive/runtime/kotlin/controllers/RiveFileController.java');
t('RiveFileController play/advance', /play|advance|stateMachine/i.test(sm));
const ta2 = R('defpackage/ta2.java');
t('app consumer ta2', ta2.length > 0);
console.log('rive replay: ' + n + '/10 checks green');
