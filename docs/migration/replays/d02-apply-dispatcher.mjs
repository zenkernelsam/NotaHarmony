// Phase 993 — z5c.x apply dispatcher + uq9.q/r accessors + aq1 row + gk4.m/o
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z5c = readFileSync(`${ROOT}/z5c.java`, 'utf8');
const uq9 = readFileSync(`${ROOT}/uq9.java`, 'utf8');
const aq1 = readFileSync(`${ROOT}/aq1.java`, 'utf8');
const gk4 = readFileSync(`${ROOT}/gk4.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// z5c.x — complete ordinal->payload-class map
const xBody = z5c.slice(z5c.indexOf('final cee x(uq9'), z5c.indexOf('final u3c y('));
const cases = [['l2d',1],['ra0',2],['ln2',3],['ge8',4],['yn2',5],['ke8',6],['e46',7],['f46',8],['pub',9],['qub',10],['f2c',11],['me8',12],['he8',13],['io1',14],['dm2',15],['gd',16],['wd8',17],['ao2',18],['le8',19],['cm2',20],['vd8',21],['rl2',22],['td8',23],['je8',24],['s83',25],['tdf',26],['ee8',27],['mqf',28],['yda',29],['tl2',30],['ud8',31]];
for (const [cls, ord] of cases)
  ok(new RegExp('case (zn5\\.\\w+|' + ord + ')[\\s\\S]{0,80}new ' + cls + '\\(\\)').test(xBody), `z5c.x[${ord}] -> ${cls}`);
ok(/case 0:[\s\S]{0,140}rgc\.b\(mpb\.a\.b\(uq9\.class\)/.test(xBody), 'z5c.x[0] NONE -> rgc.b fail-loud');
ok(/uq9Var\.q\(l2dVar\);\s*return l2dVar/.test(xBody), 'z5c.x: q(holder) init + return');

// uq9 accessors
ok(/public final void q\(cee ceeVar\)[\s\S]{0,140}c\(14\) \+ this\.I[\s\S]{0,120}ceeVar\.d\(byteBuffer\.getInt\(iC\) \+ iC/.test(uq9), 'uq9.q: payload @slot14');
ok(/public final sdf r\(sdf sdfVar\)[\s\S]{0,140}c\(16\)/.test(uq9), 'uq9.r: transient @slot16');
ok(/Op\(id=" \+ l\(\) \+ ", clientTime="/.test(uq9) && /transientInteraction="/.test(uq9), 'uq9.toString: canonical field names');

// aq1 = ClientOp row {op, opId, length}
ok(/public aq1\(uq9 uq9Var, qo5 qo5Var, long j\)/.test(aq1), 'aq1{uq9,qo5,long}');

// gk4 unpack round-trip + list codec
ok(/static qo5 m\(long j2\)[\s\S]{0,80}rh8\.b\(\(int\) \(j2 >> 32\), \(short\) j2\)/.test(gk4), 'gk4.m: unpack ts<<32|site');
ok(/while \(byteBufferWrap\.remaining\(\) >= 8\)[\s\S]{0,140}rh8\.b\(\(int\) \(j2 >> 32\), \(short\) j2\)/.test(gk4), 'gk4.o: 8B-long qo5 list codec');

console.log(`\napply-dispatcher replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
