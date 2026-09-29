// Phase 996 — pa0 asset-ref wrappers: cba/cp5/zjb + extractors
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const rd = (n) => readFileSync(`${ROOT}/${n}.java`, 'utf8');
const pa0 = rd('pa0'), cba = rd('cba'), cp5 = rd('cp5'), zjb = rd('zjb');
const u0j = rd('u0j'), kaj = rd('kaj'), sw9 = rd('sw9'), dp5 = rd('dp5'), akb = rd('akb');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// pa0 interface
ok(/interface pa0[\s\S]{0,40}wa0 a\(\)/.test(pa0), 'pa0: wa0 a() accessor');

// three wrappers — value classes
ok(/class cba implements pa0[\s\S]{0,80}public final sw9 a/.test(cba) && /return this\.a\.m\(\)/.test(cba), 'cba: PdfAsset sw9.m()');
ok(/class cp5 implements pa0[\s\S]{0,80}public final dp5 a/.test(cp5) && /return this\.a\.j\(\)/.test(cp5), 'cp5: ImageAsset dp5.j()');
ok(/class zjb implements pa0[\s\S]{0,80}public final akb a/.test(zjb) && /return this\.a\.j\(\)/.test(zjb), 'zjb: RecordingAsset akb.j()');
ok(/"PdfAsset\(asset="/.test(cba) && /"ImageAsset\(asset="/.test(cp5), 'cba/cp5 toString names');

// extractors
ok(/public static final cba d\(ge8 ge8Var\)/.test(u0j), 'u0j.d: MODIFY_PAGE->cba');
ok(/m2dVarJ\.j\(\)[\s\S]{0,140}nz9VarJ\.l\(\)/.test(u0j), 'u0j.d: ge8.j->nz9->sw9 chain');
ok(/public static final zjb a\(yn2 yn2Var\)[\s\S]{0,120}new zjb\(yn2Var\.l\(\)\)/.test(kaj), 'kaj.a: CREATE_RECORDING->zjb');

// wa0 accessors on asset tables
ok(/public final wa0 m\(\)/.test(sw9), 'sw9.m() = AssetMetadata');
ok(/public final wa0 j\(\)/.test(dp5), 'dp5.j() = AssetMetadata');
ok(/wa0 j\(\)|public final wa0/.test(akb), 'akb.j() = AssetMetadata');

// kaj.b = kotlinx MissingFieldException helper (merged)
ok(/MissingFieldException/.test(kaj), 'kaj.b: MissingFieldException helper');

console.log(`\nasset-ref-wrappers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
