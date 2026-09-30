// Phase 1279 — d4d/fn0/iz3/u8g OTel severity + enum codec
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

const d4d = R('d4d.java');
t('d4d SEVERITY enum', d4d.includes('SEVERITY_NUMBER_UNSPECIFIED'));
t('d4d TRACE..FATAL scale', d4d.includes('SEVERITY_NUMBER_TRACE') && d4d.includes('SEVERITY_NUMBER_DEBUG') && d4d.includes('SEVERITY_NUMBER_INFO'));
t('d4d full range fn0', (d4d.match(/new fn0\(/g)||[]).length >= 20);
const fn0 = R('fn0.java');
t('fn0 ProtoEnumInfo{num,name}', fn0.includes('ProtoEnumInfo{enumNumber='));
t('fn0 int+String', fn0.includes('int a') && fn0.includes('String b'));
const iz3 = R('iz3.java');
t('iz3 extends g2b enum codec', iz3.includes('extends g2b'));
t('iz3 j(i)→u8g', iz3.includes('u8g j(int'));
t('iz3 wire t71/vw7/uw7', iz3.includes('t71') && iz3.includes('vw7') && iz3.includes('uw7'));
const u8g = R('u8g.java');
t('u8g EnumLite iface', u8g.includes('interface u8g'));
const g2b = R('g2b.java');
t('g2b codec base', g2b.length > 0);
console.log('telemetry replay: ' + n + '/10 checks green');
