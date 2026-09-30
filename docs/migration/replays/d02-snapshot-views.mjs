// Phase 1123 — snapshot/view collection taxonomy: rvb/kja/mja/nja/oja/ria/q07
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const f1a = R('f1a'), rvb = R('rvb'), kja = R('kja'), mja = R('mja'),
      nja = R('nja'), oja = R('oja'), ria = R('ria'), q07 = R('q07'), bka = R('bka');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('f1a page snapshot {int,rvb,cl2,kia}', f1a.includes('int a') && f1a.includes('rvb b') && f1a.includes('cl2 c') && f1a.includes('kia d'));
t('rvb implements svb {bxc,cl2×2,xgb}', rvb.includes('implements svb') && rvb.includes('bxc I') && rvb.includes('xgb K'));
t('kja extends ija lazy map', kja.includes('extends ija'));
t('mja extends jja + a(gja)→ija fork', mja.includes('extends jja') && mja.includes('ija a(gja'));
t('nja extends ija + f(hja)→jja', nja.includes('extends ija') && nja.includes('jja f(hja'));
t('oja extends jja readonly', oja.includes('extends jja'));
t('ria List {bka,ArrayList}', ria.includes('bka I') && ria.includes('ArrayList J'));
t('q07 List readonly (add)', q07.includes('implements List, ik6') && q07.includes('add('));
t('bka Collection f()', R('bka').includes('extends u4 implements Collection'));
t('lia Collection view', R('lia').includes('extends w4 implements Collection, jk6'));
console.log('snapshot-views replay: ' + n + '/10 checks green');
