#!/usr/bin/env node
import fs from 'node:fs';

const ingress = fs.readFileSync('note/src/main/ets/data/OriginalPhotoIngress.ets', 'utf8');
const fixture = fs.readFileSync('note/src/test/OriginalPhotoIngress.test.ets', 'utf8');
const fixtureList = fs.readFileSync('note/src/test/List.test.ets', 'utf8');

const checks = [
  ['original bgj copies URI through cache and enforces exactly 104857600 bytes',
    ingress.includes('ORIGINAL_PHOTO_MAX_BYTES: number = 104857600') &&
    ingress.includes('temp_') && ingress.includes('readPhotoUriWithLimit')],
  ['original tf9 validates the selected URI list all-or-nothing',
    ingress.includes('export function validateOriginalPhotoSelection') &&
    fixture.includes("expect(validateOriginalPhotoSelection(invalid)).assertFalse()")],
  ['original oj3 extension allowlist is preserved fail-closed',
    ingress.includes("'png', 'jpg', 'jpeg', 'webp', 'tif', 'tiff', 'gif', 'heif', 'heic'") &&
    fixture.includes("expect(isValidOriginalPhotoUri('file:///media/image.bmp')).assertFalse()")],
  ['ingress preserves URI order and returns normalized metadata',
    ingress.includes('for (const uri of uris)') &&
    ingress.includes('normalized.rewroteBytes ?') &&
    ingress.includes('rewroteBytes: normalized.rewroteBytes') &&
    ingress.includes('`photo-${temporaryPaths.length}` :') &&
    ingress.includes('`photo-${temporaryPaths.length}.${fileExtension(uri)}`') &&
    ingress.includes('orientedWidth: normalized.orientedWidth')],
  ['oversized or empty photos are rejected after bounded read',
    ingress.includes('export function isOversizedOriginalPhoto') &&
    ingress.includes('await readOriginalPhotoUri(uri,') &&
    ingress.includes('if (isOversizedOriginalPhoto(bytes.byteLength))')],
  ['temporary copies are always removed on success and failure',
    ingress.includes('const temporaryPaths: string[] = [];') &&
    ingress.includes('finally {') && ingress.includes('removeTemporaryCopies(temporaryPaths);')],
  ['URI reader is injectable for static fixtures without launching a picker',
    ingress.includes('export type OriginalPhotoUriReader') &&
    ingress.includes('setOriginalPhotoUriReaderForTest')],
  ['ArkTS fixtures cover allowlist all-or-nothing and byte gate',
    fixture.includes("['file:///a/1.jpg', 'file:///b/2.heic']") &&
    fixture.includes('104857600') && fixture.includes('Number.MAX_SAFE_INTEGER + 1')],
  ['fixture suite registers photo-ingress tests',
    fixtureList.includes("import originalPhotoIngressTest from './OriginalPhotoIngress.test';") &&
    fixtureList.includes('originalPhotoIngressTest();')],
  ['production caller and toolbar UI remain explicitly deferred',
    !fs.existsSync('note/src/main/ets/data/PhotoPickerCaller.ets') &&
    !ingress.includes('PhotoViewPicker')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed += 1;
}
console.log(`D02_ORIGINAL_PHOTO_INGRESS_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
