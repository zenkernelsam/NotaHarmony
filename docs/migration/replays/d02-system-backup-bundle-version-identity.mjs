import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const source = fs.readFileSync(
  path.join(root, 'note/src/main/ets/notebackupability/NoteBackupAbility.ets'), 'utf8');
const create = source.indexOf('private async createSnapshot()');
const restore = source.indexOf('private async restoreSnapshot(bundleVersion: BundleVersion)');
const validateManifest = source.indexOf('private validateManifest');
const validateVersion = source.indexOf('private validateRestoreVersion');
const checks = [
  ['runtime bundle metadata replaces the hard-coded version',
    source.includes('bundleManager.getBundleInfoForSelfSync') && !source.includes("bundleVersion: '1.0.0'")],
  ['new manifests bind both version name and code', create >= 0 &&
    source.indexOf('bundleVersion: currentVersion.name', create) > create &&
    source.indexOf('bundleVersionCode: currentVersion.code', create) > create],
  ['legacy schema-1 manifests keep an optional version code',
    source.includes('bundleVersionCode?: number;') && source.includes('schema: 1')],
  ['manifest version name and optional code are bounded', validateManifest >= 0 &&
    source.indexOf('isValidVersionName(manifest.bundleVersion)', validateManifest) > validateManifest &&
    source.indexOf('isValidVersionCode(manifest.bundleVersionCode)', validateManifest) > validateManifest],
  ['platform restore metadata is checked before object writes', restore >= 0 && validateVersion >= 0 &&
    source.indexOf('this.validateRestoreVersion(manifest, bundleVersion, currentVersion)', restore) > restore &&
    source.indexOf("this.state.phase = 'restoring'", restore) >
      source.indexOf('this.validateRestoreVersion(manifest, bundleVersion, currentVersion)', restore)],
  ['manifest version name is bound to the platform source', validateVersion >= 0 &&
    source.indexOf('manifest.bundleVersion !== source.name', validateVersion) > validateVersion],
  ['new manifest version code is bound to the platform source', validateVersion >= 0 &&
    source.indexOf('manifest.bundleVersionCode !== source.code', validateVersion) > validateVersion],
  ['raw snapshots from a newer app are rejected', validateVersion >= 0 &&
    source.indexOf('source.code > current.code', validateVersion) > validateVersion],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
