// Phase 831 — application 属性面 + filepaths.xml
import { readFileSync } from 'node:fs';

const R = 'C:/Users/Cisco He/Desktop/Notability';
const results = [];
const ck = (n, ok) => results.push([n, ok]);

const appAttrs = ['largeHeap="true"', 'extractNativeLibs="false"', 'supportsRtl="true"', 'allowBackup="false"', 'enableOnBackInvokedCallback="true"'];
for (const v of ['1.0.1', '1.0.3', '1.4.2']) {
  const m = readFileSync(`${R}/decompiled_${v}/resources/AndroidManifest.xml`, 'utf8');
  const app = m.match(/<application[\s\S]*?>/)[0];
  ck(`application 五属性 @${v}`, appAttrs.every(a => app.includes(a)));
  ck(`无 networkSecurityConfig @${v}`, !app.includes('networkSecurityConfig'));
}
// filepaths.xml 授权面
const fp = readFileSync(`${R}/decompiled_1.4.2/resources/res/xml/filepaths.xml`, 'utf8');
for (const p of ['images', 'exports', 'debug-logs']) ck(`filepaths 授权 ${p}`, fp.includes(`"${p}"`));
ck('filepaths 仅 cache-path（无 files-path/database-path）', !fp.includes('files-path') && !fp.includes('database-path'));
// Harmony 侧：备份扩展存在（有意分歧，ADR-0127 在先）
const nb = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/notebackupability/NoteBackupAbility.ets', 'utf8');
ck('Harmony BackupExtensionAbility 存在', nb.includes('BackupExtensionAbility'));
ck('Harmony 备份 manifest schema 版本', nb.includes('CURRENT_MANIFEST_SCHEMA'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
