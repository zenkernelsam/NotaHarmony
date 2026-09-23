import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const ingress = read('note/src/main/ets/data/OriginalPhotoIngress.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors ----------------------------------------------------------
const u49 = readOriginal('decompiled_1.0.3/sources/defpackage/u49.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// u49 collects rd9 events and emits feature_note__image_too_large_to_add.
ok(u49.includes('feature_note__image_too_large_to_add'),
  'original image-too-large snackbar missing');
ok(origStrings.includes('image_too_large_to_add">Image is too large to add.'),
  'original image-too-large message missing');

// --- Harmony anchors ----------------------------------------------------------------------
ok(ingress.includes('export class OriginalPhotoTooLargeError extends Error'),
  'typed oversize error missing');
ok((ingress.match(/throw new OriginalPhotoTooLargeError/g) ?? []).length === 2,
  'both oversize gates must throw the typed error');
ok(ingress.includes('ORIGINAL_PHOTO_MAX_BYTES'), 'ingress byte cap missing');
ok(canvas.includes('OriginalPhotoTooLargeError') && canvas.includes('photoErrorToastRes'),
  'canvas error mapping missing');
ok(canvas.includes("$r('app.string.image_too_large_to_add')"),
  'oversize toast resource unused');
ok((canvas.match(/this\.photoErrorToastRes\(e as Error\)/g) ?? []).length === 4,
  'all four photo-ingress catch sites must map the typed error');
ok(stringsBase.includes('"name": "image_too_large_to_add"') &&
   stringsBase.includes('"value": "Image is too large to add."'),
  'base oversize string missing');
ok(stringsZh.includes('"name": "image_too_large_to_add"'),
  'zh oversize string missing');

// --- Executable behaviour model -----------------------------------------------------------
const MAX = 104857600;
const isOversized = size => !Number.isSafeInteger(size) || size <= 0 || size > MAX;
assert.ok(isOversized(MAX + 1) && !isOversized(MAX) && isOversized(0) && isOversized(-1));
checks += 1;

console.log(`D02_ORIGINAL_IMAGE_TOO_LARGE_OK TOTAL=${checks} FAILED=0`);
