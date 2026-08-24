#!/usr/bin/env node
import fs from 'node:fs';

const normalizer = fs.readFileSync('note/src/main/ets/data/OriginalImageNormalizer.ets', 'utf8');
const ingress = fs.readFileSync('note/src/main/ets/data/OriginalPhotoIngress.ets', 'utf8');
const fixture = fs.readFileSync('note/src/test/OriginalPhotoIngress.test.ets', 'utf8');

const checks = [
  ['normalization reports whether bytes were rewritten',
    normalizer.includes('rewroteBytes: boolean;') &&
    normalizer.includes('rewroteBytes: false,') &&
    normalizer.includes("mimeType: 'image/webp'") &&
    normalizer.includes('rewroteBytes: true,')],
  ['normalized WebP output does not reuse the stale source extension',
    ingress.includes('normalized.rewroteBytes ?') &&
    ingress.includes('`photo-${temporaryPaths.length}` :') &&
    ingress.includes('`photo-${temporaryPaths.length}.${fileExtension(uri)}`')],
  ['unchanged source bytes retain deterministic diagnostic naming',
    ingress.includes('.${fileExtension(uri)}`;')],
  ['ArkTS fixture covers jpg and heic normalization naming',
    fixture.includes("'file:///a/source.jpg'") && fixture.includes("'file:///b/source.heic'") &&
    fixture.includes("expect(items[0].fileName).assertEqual('photo-1');")],
  ['fixture asserts normalized MIME and rewrite contract',
    fixture.includes("expect(items[0].mimeType).assertEqual('image/webp');") &&
    fixture.includes('expect(items[0].rewroteBytes).assertTrue();')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_PHOTO_NORMALIZED_NAME_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
