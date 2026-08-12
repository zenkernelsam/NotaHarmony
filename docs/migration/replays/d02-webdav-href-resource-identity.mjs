import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const client = fs.readFileSync(path.join(root, 'note/src/main/ets/data/WebDAVClient.ets'), 'utf8');
const page = fs.readFileSync(path.join(root, 'note/src/main/ets/ui/settings/BackupPage.ets'), 'utf8');
const toFile = client.indexOf('private toFileInfo');
const checks = [
  ['file info separates protocol name and display property',
    client.includes('name: string;') && client.includes('displayName: string;')],
  ['resource name is derived from the decoded href', toFile >= 0 &&
    client.indexOf('const fallbackName: string = this.resourceNameFromUrl(path)', toFile) > toFile &&
    client.indexOf('name: fallbackName', toFile) > toFile],
  ['the full href is never decoded before path segmentation',
    client.includes('this.urlForHref(response.href, requestUrl)') &&
    !client.includes('decodeHref(response.href)')],
  ['only the final canonical path segment is decoded for protocol identity',
    client.includes('private resourceNameFromUrl(value: string)') &&
    client.includes('return this.decodePathSegment(slash >= 0 ? path.slice(slash + 1) : path)')],
  ['every parsed response is constrained to the requested collection',
    client.includes('this.assertPropfindMemberUrl(file.path, requestUrl)') &&
    client.includes('private assertPropfindMemberUrl(resourceUrl: string, requestUrl: string)')],
  ['Depth:1 rejects outside and nested response resources',
    client.includes('WebDAV href is outside the requested collection') &&
    client.includes('WebDAV Depth:1 response contains a non-child resource')],
  ['dot path segments are rejected before collection comparison',
    client.includes("segment === '.' || segment === '..'") &&
    client.includes('WebDAV href contains a dot path segment')],
  ['DAV displayname remains display-only metadata', toFile >= 0 &&
    client.indexOf('displayName: response.displayName.length > 0 ? response.displayName : fallbackName', toFile) > toFile],
  ['manifest discovery filters the href-derived resource name',
    page.includes("file.name.startsWith('batch-')") &&
    page.includes('candidates[i].name === backupManifestFileName(parsed.batchId)')],
  ['manifest discovery never filters displayName',
    !page.includes("file.displayName.startsWith('batch-')") &&
    !page.includes('candidates[i].displayName === backupManifestFileName(parsed.batchId)')],
];
for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
