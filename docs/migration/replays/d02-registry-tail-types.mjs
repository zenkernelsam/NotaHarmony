// Phase 967 — z0c 注册表尾部 8 类型定名
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const files = Object.fromEntries(
  ['vt9','q89','nz9','sw9','sdf','ua0','p9','k3a'].map(f => [f, readFileSync(`${ROOT}/${f}.java`, 'utf8')]));

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// names via toString
ok(/OpsBundle\(ops=/.test(files.vt9), 'vt9 = OpsBundle');
ok(/NoteMutationResponse\(noteId=/.test(files.q89), 'q89 = NoteMutationResponse');
ok(/PageBackground\(paper=/.test(files.nz9), 'nz9 = PageBackground');
ok(/PDFAsset\(metadata=/.test(files.sw9), 'sw9 = PDFAsset');
ok(/TransientInteraction\(interactionId=/.test(files.sdf), 'sdf = TransientInteraction');
ok(/AssetHash\(bits0=/.test(files.ua0), 'ua0 = AssetHash');
ok(/AcknowledgeAppendedOpsEvent\(acks=/.test(files.p9), 'p9 = AcknowledgeAppendedOpsEvent');
ok(/Paper\(flair=/.test(files.k3a), 'k3a = Paper');

// ua0: 64B struct, 8 longs @0..56
ok(/class ua0 extends xwd/.test(files.ua0), 'ua0 extends xwd (inline struct)');
ok(/getLong\(this\.I \+ 56\)/.test(files.ua0), 'ua0: j() = long@56 (8th)');
ok(/getLong\(this\.I \+ 40\)/.test(files.ua0), 'ua0: h() = long@40');

// vt9 OpsBundle: ops vector @f0 + schemaVersion @f1
ok(/uq9 l\(uq9 uq9Var, int i\)[\s\S]{0,60}c\(4\)/.test(files.vt9), 'vt9: ops = uq9 vector @f0');
ok(/short k\(\)[\s\S]{0,60}c\(6\)/.test(files.vt9), 'vt9: schemaVersion short @f1');

// p9: single vq9 vector @f0
ok(/void j\(vq9 vq9Var, int i\)[\s\S]{0,60}c\(4\)/.test(files.p9), 'p9: acks = vq9 vector @f0');

// sw9/nz9/k3a field names present
ok(/cropBoxes/.test(files.sw9) && /layoutBehavior/.test(files.sw9), 'sw9: cropBoxes+layoutBehavior');
ok(/pdf=/.test(files.nz9) && /margins=/.test(files.nz9), 'nz9: pdf+margins fields');
ok(/flairSpacing/.test(files.k3a) && /legacyPaperIndex/.test(files.k3a), 'k3a: flairSpacing+legacyPaperIndex');

console.log(`\nregistry-tail-types replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
