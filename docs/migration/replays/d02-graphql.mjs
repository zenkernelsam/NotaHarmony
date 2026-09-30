// Phase 1273 — gv/o20/p13/ibj/l7b Apollo GraphQL client
import { readFileSync, readdirSync, statSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
import { join } from 'path';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const gv = R('defpackage/gv.java');
t('gv implements cx8 interceptor', gv.includes('implements cx8'));
t('gv graphql accept header', gv.includes('graphql-response+json'));
t('gv defer spec', gv.includes('deferSpec'));
const o20 = R('defpackage/o20.java');
t('o20 implements mj8 operation', o20.includes('implements mj8'));
t('o20 INSERT/UPDATE/DELETE', o20.includes('"INSERT"') && o20.includes('"UPDATE"') && o20.includes('"DELETE"'));
const p13 = R('defpackage/p13.java');
t('p13 nl5 requestbody', p13.includes('implements nl5') && p13.includes('getContentType'));
const ibj = R('defpackage/ibj.java');
t('ibj z7h client', ibj.includes('extends z7h'));
const l7b = R('defpackage/l7b.java');
t('l7b fetch-policy enum', l7b.includes('int b') && l7b.includes('int c'));
const apolloDir = S + 'com/apollographql';
t('apollo package present', existsSync(apolloDir));
let cnt = 0; if (existsSync(apolloDir)) { const walk = d => { for (const f of readdirSync(d)) { const p = join(d,f); if (statSync(p).isDirectory()) walk(p); else if (f.endsWith('.java')) cnt++; } }; walk(apolloDir); }
t('apollo ~20 files', cnt >= 15);
console.log('graphql replay: ' + n + '/10 checks green');
