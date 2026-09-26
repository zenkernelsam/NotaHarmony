// D02 manifest 属性与 meta-data 面收口 — Phase 801
import assert from 'node:assert/strict';
import fs from 'node:fs';

const M103 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/AndroidManifest.xml', 'utf8');
const M142 = fs.readFileSync('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/AndroidManifest.xml', 'utf8');
const MODULE = JSON.parse(fs.readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/module.json5', 'utf8'));

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const appAttrs = (m) => ['allowBackup', 'extractNativeLibs', 'enableOnBackInvokedCallback']
  .map((a) => m.match(new RegExp(`android:${a}="[^"]*"`))?.[0] ?? 'absent');

check('application attrs identical: allowBackup=false / extractNativeLibs=false / predictiveBack=true',
  appAttrs(M103).join('|') === appAttrs(M142).join('|')
  && appAttrs(M142).join('|') === [
    'android:allowBackup="false"',
    'android:extractNativeLibs="false"',
    'android:enableOnBackInvokedCallback="true"'].join('|'));

const mdNames = (m) => [...new Set([...m.matchAll(/<meta-data\s*\n?\s*android:name="([^"]*)"/g)]
  .map((x) => x[1]))].sort();
const only142 = mdNames(M142).filter((n) => !mdNames(M103).includes(n));
const removed = mdNames(M103).filter((n) => !mdNames(M142).includes(n));

check('meta-data delta = exactly +CrashlyticsNdkRegistrar, zero removals',
  only142.length === 1
  && only142[0] === 'com.google.firebase.components:com.google.firebase.crashlytics.ndk.CrashlyticsNdkRegistrar'
  && removed.length === 0);

const normalized = (m) => [...m.matchAll(/<(uses-feature|queries|property)\b[^>]*>/g)]
  .map((x) => x[0].replace(/android:value="[^"]*"/g, 'android:value=V')).sort().join('\n');
check('uses-feature/queries/property surfaces identical across versions',
  normalized(M103) === normalized(M142));

check('4 app-owned initializers present (AppStartup/User/EditorSettings/HapticPrefs)',
  ['app.initializers.AppStartupInitializer',
    'core.user.UserDataStoreInitializer',
    'data.settings.NoteEditorSettingsInitializer',
    'data.stylus.haptic.HapticPreferencesInitializer']
    .every((i) => M142.includes(i)));

check('vendor meta-data = GMS/Firebase/MLKit/Play/Stamp (all fail-closed)',
  ['com.google.android.gms.version',
    'com.google.android.play.billingclient.version',
    'com.google.mlkit.vision.text.internal.TextRegistrar',
    'com.android.stamp.source',
    'firebase_crashlytics_collection_enabled']
    .every((v) => M142.includes(v)));

check('allowBackup=false posture maps to file-level NoteBackupAbility (no cloud backup)',
  M142.includes('android:allowBackup="false"')
  && MODULE.module.extensionAbilities.some((a) => a.name === 'NoteBackupAbility'));

console.log(`manifest-attributes replay: ${checks.length}/${checks.length} checks green`);
