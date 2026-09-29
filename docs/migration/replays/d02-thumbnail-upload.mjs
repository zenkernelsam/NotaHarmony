// Phase 1000 — xqf 缩略图上传 + nr1 剩余依赖
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const xqf = readFileSync(D + 'xqf.java', 'utf8');
const ssf = readFileSync(D + 'ssf.java', 'utf8');
const qr1 = readFileSync(D + 'qr1.java', 'utf8');
const jl3 = readFileSync(D + 'jl3.java', 'utf8');
const sxa = readFileSync(D + 'sxa.java', 'utf8');
const v2f = readFileSync(D + 'v2f.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// xqf multipart thumbnail upload
t('xqf: @Multipart via @vi8', xqf.includes('@vi8'));
t('xqf: POST /images/thumbnails', xqf.includes('"\\u002fimages\\u002fthumbnails"') || xqf.includes('"/images/thumbnails"'));
t('xqf: noteId + siteId + logicalTime parts', xqf.includes('@j7a("noteId")') && xqf.includes('@j7a("siteId") short') && xqf.includes('@j7a("logicalTime") int'));
t('xqf: wi8 thumbnail part + Accept header', xqf.includes('@j7a wi8 wi8Var') && xqf.includes('@me5("Accept")'));
// nr1 dep closures
t('ssf: service component fields', ssf.includes('public final q75 a') && ssf.includes('public final xrf b') && ssf.includes('public final sfb e'));
t('qr1: two lazies from Context+dbe', qr1.includes('qr1(Context context, dbe dbeVar)') && qr1.includes('new pce(new or1(context, 0)'));
t('jl3: lazies+mutex from cx6', jl3.includes('jl3(cx6 cx6Var)') && jl3.includes('public final sfb c'));
t('sxa: minimal Context holder', /class sxa[\s\S]{0,100}public final Context a;[\s\S]{0,100}this\.a = context/.test(sxa));
t('v2f: clock interface t2f a()', /interface v2f[\s\S]{0,60}t2f a\(\)/.test(v2f));
// sanity: provider t5b
const t5b = readFileSync(D + 't5b.java', 'utf8');
t('t5b = Function0 (provider base)', /interface t5b extends Function0/.test(t5b));
console.log('thumbnail-upload replay: ' + n + '/10 checks green');
