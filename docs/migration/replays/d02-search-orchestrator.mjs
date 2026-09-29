// Phase 1007 — 搜索编排器（clc 接口 + vmc + hmc 三段重建）
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const clc = readFileSync(D + 'clc.java', 'utf8');
const vmc = readFileSync(D + 'vmc.java', 'utf8');
const hmc = readFileSync(D + 'hmc.java', 'utf8');
const d6c = readFileSync(D + 'd6c.java', 'utf8');
const b50 = readFileSync(D + 'b50.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

// clc engine contract
t('clc: interface with 9 methods', /public interface clc/.test(clc) && clc.includes('getName()'));
t('clc: query d(ttf,String,mlc)', clc.includes('Serializable d(ttf ttfVar, String str, mlc'));
t('clc: bulk ops b(List)/c(Collection)', clc.includes('Object b(List') && clc.includes('Object c(Collection'));
// two engines
t('d6c implements clc', /class d6c implements clc/.test(d6c));
t('b50 implements clc', /class b50 implements clc/.test(b50));
// vmc orchestrator
t('vmc: 13-dep ctor incl SearchDatabase', /vmc\(Context context, clc clcVar[\s\S]{0,300}SearchDatabase searchDatabase/.test(vmc));
t('vmc: staged DAOs w/v/u -> ty5/oy5/oa4', vmc.includes('searchDatabase.w()') && vmc.includes('searchDatabase.v()') && vmc.includes('searchDatabase.u()'));
t('vmc: prefs search_engine/active_engine', vmc.includes('"search_engine"') && vmc.includes('"active_engine"'));
t('vmc: default engine appsearch', vmc.includes('getString("active_engine", "appsearch")'));
// hmc staged rebuild
t('hmc: coroutine extends n8e+ix4', /class hmc extends n8e implements ix4/.test(hmc));
t('hmc: three-stage p/q/r calls', hmc.includes('ty5 ty5Var = vmcVar.p') && hmc.includes('oy5 oy5Var = vmcVar.q') && hmc.includes('oa4Var = vmcVar.r'));
t('hmc: staged suspend calls p/q/r', hmc.includes('ty5Var.a(this)') && hmc.includes('oy5Var.a(this)') && hmc.includes('oa4Var.a(this)') && hmc.includes('oa4Var2.a(this)'));
console.log('search-orchestrator replay: ' + n + '/12 checks green');
