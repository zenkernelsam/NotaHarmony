// Phase 964 — zq9 写侧：类→haa 逆映射 + e() 7 字段信封写器
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const zq9 = readFileSync(`${ROOT}/zq9.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// a = mx7 class->haa map (30 entries)
ok(/public static final mx7 a;/.test(zq9), 'zq9.a = mx7 map');
const mapPairs = [
  ['l2d', 'SET_METADATA'], ['ra0', 'ASSET_CLOUD_PERSISTED'],
  ['ln2', 'CREATE_PAGE'], ['ge8', 'MODIFY_PAGE'],
  ['yn2', 'CREATE_RECORDING'], ['ke8', 'MODIFY_RECORDING'],
  ['e46', 'INSERT_CHAR'], ['f46', 'INSERT_STRING'],
  ['pub', 'REMOVE_CHAR'], ['qub', 'REMOVE_CHARS'],
  ['f2c', 'REVIVE_CHARS'], ['me8', 'MODIFY_STYLE'],
  ['he8', 'MODIFY_PARAGRAPH_STYLE'], ['io1', 'CLEAR_STYLE'],
  ['dm2', 'CREATE_INK'], ['gd', 'ADD_PATH_ELEMENTS'],
  ['wd8', 'MODIFY_INK'], ['ao2', 'CREATE_SHAPE'],
  ['le8', 'MODIFY_SHAPE'], ['cm2', 'CREATE_GROUP'],
  ['vd8', 'MODIFY_GROUP'], ['rl2', 'CREATE_BLOCK'],
  ['td8', 'MODIFY_BLOCK'], ['je8', 'MODIFY_POSITIONS'],
  ['s83', 'DELETE_ENTITIES'], ['tdf', 'TRANSIENT_INTERACTION_ENDED'],
  ['ee8', 'MODIFY_PDF_FIELD'], ['mqf', 'UPDATE_CHECKBOX'],
  ['yda', 'PEER_INTERACTION'], ['tl2', 'CREATE_COMMENT'],
  ['ud8', 'MODIFY_COMMENT'],
];
for (const [cls, haa] of mapPairs) {
  ok(zq9.includes(`npbVar.b(${cls}.class), haa.${haa}`), `a map: ${cls} -> ${haa}`);
}

// b = reverse lookup + fail-loud
ok(/haa\) a\.get\(npbVar\.b\(cls\)\)/.test(zq9), 'b: map.get(KClass)');
ok(/rgc\.b\(npbVar\.b\(ceeVar\.getClass\(\)\)/.test(zq9), 'b: unknown -> rgc.b');

// e = 7-field envelope writer
ok(/aVar\.C\(7\)/.test(zq9), 'e: C(7) fields');
ok(/aVar\.j\(0, rh8\.O\(qo5Var/.test(zq9), 'e: f0 = rh8.O(id)');
ok(/aVar\.f\(1, j\)/.test(zq9), 'e: f1 = clientTime long');
ok(/aVar\.f\(2, tmfVar\.I\)/.test(zq9), 'e: f2 = serverTime ULong');
ok(/aVar\.f\(3, tmfVar2\.I\)/.test(zq9), 'e: f3 = audioTime ULong');
ok(/aVar\.c\(4, b\(ceeVar\)\.I, 0\)/.test(zq9), 'e: f4 = payloadType byte via b()');
ok(/aVar\.h\(5, iA\)/.test(zq9), 'e: f5 = payload offset');
ok(/aVar\.h\(6, numValueOf\.intValue\(\)\)/.test(zq9), 'e: f6 = transientInteraction');
ok(/aVar\.z\(iN, 4\);[\s\S]{0,30}aVar\.z\(iN, 14\)/.test(zq9), 'e: required f0(slot4)+f5(slot14)');
ok(/ree\.a\(ceeVar, aVar\)/.test(zq9), 'e: payload first via ree.a');
ok(/qqi\.d\(sdfVar, aVar\)/.test(zq9), 'e: sdf via qqi.d');

// d = accessor-shim entry; a(qo5,cee,long,xgb) = factory
ok(/uq9Var\.l\(\), z5c\.x\(uq9Var\), uq9Var\.k\(\), uq9Var\.n\(\), uq9Var\.j\(\), uq9Var\.o\(\)/.test(zq9), 'd = e(l(), x(), k(), n(), j(), o())');
ok(/static uq9 a\(qo5 qo5Var, cee ceeVar, long j, xgb xgbVar\)/.test(zq9), 'zq9.a = op factory');

console.log(`\nzq9-envelope-writer replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
