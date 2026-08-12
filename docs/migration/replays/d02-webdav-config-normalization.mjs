import fs from 'node:fs';
import path from 'node:path';

const root = process.env.NOTA_HARMONY_ROOT ?? path.resolve(import.meta.dirname, '../../..');
const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const client = read('note/src/main/ets/data/WebDAVClient.ets');
const transaction = read('note/src/main/ets/data/WebDAVConfigTransaction.ets');
const store = read('note/src/main/ets/data/WebDAVConfigStore.ets');
const settings = read('note/src/main/ets/ui/settings/WebDAVSettingsPage.ets');
const tests = read('note/src/test/WebDAVClient.test.ets') +
  read('note/src/test/WebDAVConfigTransaction.test.ets');

const checks = [
  ['one exported normalizer owns the configuration boundary',
    client.includes('export function normalizeWebDAVConfig') &&
    client.includes('this.config = normalizeWebDAVConfig(config, true)')],
  ['Harmony URL parser validates server scheme and authority',
    client.includes("import { buffer, url, xml } from '@kit.ArkTS'") &&
    client.includes('parsed = url.URL.parseURL(value)') &&
    client.includes("parsed.protocol !== 'https:' && parsed.protocol !== 'http:'")],
  ['server URL rejects embedded credentials query fragment backslash and controls',
    client.includes('parsed.username.length > 0 || parsed.password.length > 0') &&
    client.includes("value.indexOf('?') >= 0 || value.indexOf('#') >= 0") &&
    client.includes("value.indexOf('\\\\') >= 0") &&
    client.includes('CONTROL_CHARACTER_PATTERN.test(raw)')],
  ['Basic Auth username cannot change identity through a colon',
    client.includes("config.username.indexOf(':') >= 0") &&
    tests.includes("username: 'user:name'")],
  ['backup path rejects empty dot and encoded hierarchy-changing segments',
    client.includes("decoded === '.' || decoded === '..'") &&
    client.includes("decoded.indexOf('/') >= 0 || decoded.indexOf('\\\\') >= 0") &&
    client.includes('WebDAV backup path contains an empty segment')],
  ['canonical paths are encoded and decoded only at segment boundaries',
    client.includes('canonicalSegments.push(encodeURIComponent(decoded))') &&
    client.includes('decoded.push(decodeURIComponent(segment))') &&
    client.includes('encoded.push(encodeURIComponent(segment))')],
  ['directory creation and object URLs share canonical segments',
    client.includes('this.ensureDirectorySegments(this.backupPathSegments())') &&
    client.includes('const segments: string[] = this.backupPathSegments()') &&
    client.includes('this.urlUnderRootSegments(current, false)')],
  ['every authenticated request is constrained to the configured root',
    client.includes('this.assertRequestUrlUnderServerRoot(url)') &&
    client.includes('WebDAV request URL contains a forbidden component') &&
    client.includes('WebDAV request URL points to a different server origin') &&
    client.includes('WebDAV request URL escapes the configured server root') &&
    client.includes('WebDAV URL path contains invalid percent-encoding')],
  ['transaction validates before secret or record writes',
    transaction.indexOf('normalized = normalizeWebDAVConfig(config)') >= 0 &&
    transaction.indexOf('normalized = normalizeWebDAVConfig(config)') <
      transaction.indexOf('await this.storage.writeSecret')],
  ['stored records validate before credential reads',
    transaction.indexOf('parseStoredWebDAVConfig(raw)') >= 0 &&
    transaction.indexOf('parseStoredWebDAVConfig(raw)') < transaction.indexOf('readSecret(record.secretAlias)') &&
    transaction.includes('parsed.serverUrl.length === 0 && parsed.secretAlias.length > 0')],
  ['obsolete invalid records can be safely replaced using trusted aliases only',
    transaction.includes('parseStoredWebDAVConfigForReplacement(oldRaw)') &&
    transaction.includes('Replacement may proceed when the record envelope')],
  ['legacy migration uses the shared normalizer',
    store.includes('const normalized: WebDAVConfig = normalizeWebDAVConfig(legacy.config)') &&
    store.includes('await transaction.save(normalized, [LEGACY_WEBDAV_PASSWORD_ALIAS])')],
  ['settings test and save paths use the same shared normalizer',
    settings.includes('return normalizeWebDAVConfig({') &&
    settings.includes('config = this.normalizedDraft(allowInsecureHttp)')],
  ['settings display preserves literal percent signs across round trips',
    client.includes("decodeURIComponent(segment).replace(/%/g, '%25')") &&
    settings.includes('webDAVBackupPathForDisplay(config.backupPath)')],
  ['tests cover canonical identity ambiguous inputs HTTP consent and replacement',
    tests.includes('keeps canonical backup paths idempotent across save and UI round trips') &&
    tests.includes('rejects ambiguous server and backup path configurations') &&
    tests.includes('requires explicit consent for HTTP') &&
    tests.includes('does not send credentials to a cross-origin or root-escaping URL') &&
    tests.includes('allows a valid replacement to retire an obsolete invalid stored path')],
];

for (const [name, ok] of checks) {
  if (!ok) throw new Error(`FAILED: ${name}`);
  console.log(`PASS: ${name}`);
}
console.log(`TOTAL=${checks.length} FAILED=0`);
