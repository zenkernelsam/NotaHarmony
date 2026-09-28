// Phase 966 — pee 合并写器 switch + setter 写器 + wa0 AssetMetadata
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const z0c = readFileSync(`${ROOT}/z0c.java`, 'utf8');
const jgh = readFileSync(`${ROOT}/jgh.java`, 'utf8');
const ngh = readFileSync(`${ROOT}/ngh.java`, 'utf8');
const k1j = readFileSync(`${ROOT}/k1j.java`, 'utf8');
const wa0 = readFileSync(`${ROOT}/wa0.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// the merged pee writer switch: each case casts to its type
const cases = [
  ['vaj.k((pra)', 'pra Polygon'],
  ['qcj.c((zgb)', 'zgb ReceiveOpsEvent'],
  ['i1j.e((ra0)', 'ra0 AssetCloudPersisted'],
  ['tcj.c((akb)', 'akb RecordingAsset'],
  ['tej.g((pub)', 'pub RemoveChar'],
  ['vej.q((qub)', 'qub RemoveChars'],
  ['wfj.b((f2c)', 'f2c ReviveChars'],
  ['iaj.c((yn2)', 'yn2 CreateRecording'],
  ['egh.b((lxc)', 'lxc SeqMove'],
  ['jgh.c((z1d)', 'z1d SetBool'],
  ['kgh.d((g2d)', 'g2d SetColor'],
  ['ngh.d((k2d)', 'k2d SetFloat'],
  ['mgh.c((j2d)', 'j2d SetDecoratorStyle'],
  ['k1j.c((wa0)', 'wa0 AssetMetadata'],
  ['qgh.c((m2d)', 'm2d SetPageBackground'],
  ['rgh.e((n2d)', 'n2d SetPaper'],
  ['tgh.b((o2d)', 'o2d SetParagraphAlignment'],
  ['laj.l((ao2)', 'ao2 CreateShape'],
  ['ugh.d((p2d)', 'p2d SetRect'],
  ['zgh.c((y2d)', 'y2d setter'],
  ['dhh.c((z2d)', 'z2d setter'],
  ['ehh.g((a3d)', 'a3d SetUInt8'],
  ['qqi.d((sdf)', 'sdf TransientInteraction'],
  ['oqi.c((tdf)', 'tdf TransientInteractionEnded'],
  ['lti.d((mqf)', 'mqf UpdateCheckbox'],
  ['q7j.c((io1)', 'io1 ClearStyle'],
  ['daj.b((tl2)', 'tl2 CreateComment'],
  ['i9j.f((yda)', 'yda PeerInteraction'],
];
for (const [pat, label] of cases) {
  ok(z0c.includes(`iK = ${pat} ceeVar`), `pee case -> ${label}`);
}

// setter writer anatomy: C(1) + l=true force-write + restore
ok(/aVar\.C\(1\);[\s\S]{0,200}aVar\.l = true;[\s\S]{0,80}aVar\.a\(0, zBooleanValue, false\);[\s\S]{0,40}aVar\.l = false;/.test(jgh), 'jgh.c z1d: C(1)+l=true+bool@0');
ok(/aVar\.C\(1\);[\s\S]{0,200}aVar\.l = true;[\s\S]{0,80}aVar\.d\(0, fFloatValue, 0\.0d?\);[\s\S]{0,40}aVar\.l = false;/.test(ngh), 'ngh.d k2d: C(1)+l=true+float@0');
ok(/Boolean boolJ = z1dVar\.j\(\);/.test(jgh) && /if \(boolJ != null\)/.test(jgh), 'z1d: null=tri-state unset');

// wa0 AssetMetadata writer: 4 fields + triple required
ok(/aVar\.C\(4\)/.test(k1j), 'k1j.c wa0: C(4)');
ok(/aVar\.j\(0, aa6\.x0\(ua0VarJ, aVar\)\)/.test(k1j), 'k1j: f0 = aa6.x0(assetHash ua0)');
ok(/aVar\.h\(1, iC\)/.test(k1j) && /aVar\.h\(2, iC2\)/.test(k1j), 'k1j: f1/f2 = fileName/mimeType');
ok(/aVar\.e\(3, iL, 0\)/.test(k1j), 'k1j: f3 = fileSize int(mmf)');
ok(/aVar\.z\(iN, 4\);[\s\S]{0,40}aVar\.z\(iN, 6\);[\s\S]{0,40}aVar\.z\(iN, 8\)/.test(k1j), 'k1j: required f0+f1+f2');
ok(/AssetMetadata\(assetHash=/.test(wa0), 'wa0 = AssetMetadata');
ok(/mmf\.a\(l\(\)\)/.test(wa0) || /strA = mmf\.a/.test(wa0), 'wa0: fileSize via mmf wrapper');

console.log(`\npee-writer-switch replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
