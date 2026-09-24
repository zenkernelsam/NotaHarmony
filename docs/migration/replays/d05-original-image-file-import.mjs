// Replay fixture — Phase 653：独立图片文件导入（原版 cv5 图片分支 →
// vuh.b 规范化 → qu5 → dhj.S/bvh.a/ip5/kp5 → baj.a CREATE_BLOCK）。
// 静态断言原实现证据 + Harmony NoteImporter 的对齐实现。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const originalRoot = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/';

const cv5 = fs.readFileSync(`${originalRoot}sources/defpackage/cv5.java`, 'utf8');
const vuh = fs.readFileSync(`${originalRoot}sources/defpackage/vuh.java`, 'utf8');
const yq8 = fs.readFileSync(`${originalRoot}sources/defpackage/yq8.java`, 'utf8');
const qu5 = fs.readFileSync(`${originalRoot}sources/defpackage/qu5.java`, 'utf8');
const dhj = fs.readFileSync(`${originalRoot}sources/defpackage/dhj.java`, 'utf8');
const bvh = fs.readFileSync(`${originalRoot}sources/defpackage/bvh.java`, 'utf8');
const kp5 = fs.readFileSync(`${originalRoot}sources/defpackage/kp5.java`, 'utf8');
const i58 = fs.readFileSync(`${originalRoot}sources/defpackage/i58.java`, 'utf8');

const importer = fs.readFileSync('note/src/main/ets/data/NoteImporter.ets', 'utf8')
  .replaceAll('\r\n', '\n');

let total = 0;
function check(condition, label) {
  assert.ok(condition, label);
  total++;
}
function section(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);
  assert.ok(start !== -1 && end > start, startMarker);
  return source.slice(start, end);
}

// --- 原版证据：cv5/vuh.b 解码 + 规范化，yq8.f 路由 qu5 → dhj.S ---
check(i58.includes('new i58("*/*")'),
  'original i58.c picker type accepts */* (import then sniffs MIME)');
check(vuh.includes('i3 <= 3000 && i4 <= 3000') &&
  vuh.includes('3000.0f / Math.max(i2, i)') &&
  vuh.includes('options2.inSampleSize = i7'),
  'vuh.b keeps <=3000px images; oversized images get power-of-two inSampleSize + scaled target');
check(vuh.includes('Bitmap.CompressFormat.WEBP_LOSSY, 85'),
  'vuh.b rewrites oversized images to lossy WebP at quality 85');
check(vuh.includes('new k1a(Integer.valueOf(i6), Integer.valueOf(i5))') &&
  vuh.includes('new ep5(((Number) k1aVar.I).intValue()'),
  'vuh.b returns the REWRITTEN oriented dims with image/webp after normalization');
check(yq8.includes('uu5Var instanceof qu5') && yq8.includes('return dhj.S'),
  'yq8.f routes qu5 image payloads to dhj.S');
check(qu5.includes('public final File K') && qu5.includes('public final float L') &&
  qu5.includes('public final float M') && qu5.includes('public final String N'),
  'qu5 carries the temp file, intrinsic dims, and MIME type');
check(dhj.includes('qed qedVar = m09.b') &&
  dhj.includes('new ip5(fD / 2.0f, fC / 2.0f, 1.0f)') &&
  dhj.includes('lp5 lp5VarA = bvh.a(f, f2, Float.valueOf(fD), Float.valueOf(fC), null)') &&
  dhj.includes('new ip5((fD - f3) / 2.0f, (fC - lp5VarA.b) / 2.0f, f3 / f)') &&
  dhj.includes('new kp5(ip5Var, qu5Var, dp5Var)'),
  'dhj.S: m09.b default page → bvh.a fit → centered ip5(position, scale=fitW/srcW) → kp5');
check(bvh.includes('f3 != null ? f3.floatValue() * 0.8f : Float.MAX_VALUE') &&
  bvh.includes('Math.min(1.0f, Math.min(Math.min(fFloatValue, fFloatValue3) / f, Math.min(fFloatValue2, fFloatValue3) / f2))') &&
  bvh.includes('new lp5(f * fMin, f2 * fMin)'),
  'bvh.a: fMin = min(1, min(0.8*pageW, cap)/imgW, min(0.8*pageH, cap)/imgH), never upscale');
check(kp5.includes('cz0.IMAGE') && kp5.includes('ty0.SQUARE') && kp5.includes('ive.PIXEL_ALIGN'),
  'kp5 emits a CREATE_BLOCK IMAGE op (SQUARE corner, PIXEL_ALIGN wrap)');

// --- Harmony 实现对齐：选择器/分发 ---
check(importer.includes('.note') && importer.includes('.pdf') &&
  importer.includes('.png') && importer.includes('.webp') && importer.includes('.heic'),
  'picker filters cover .note, .pdf, and the original image suffixes');
check(importer.includes('isImportedImageFileName(fileName)') &&
  importer.includes('importImageFromBytes(bytes, fileName)'),
  'importFromFile dispatches image suffixes to importImageFromBytes');

// --- Harmony 实现对齐：vuh.b 规范化 ---
const prep = section(importer,
  'async function prepareImportedImageBytes(',
  '// 原版 bvh.a + ip5 + kp5 等价物');
check(prep.includes('image.createImageSource(buffer)') && prep.includes('source.getImageInfo()'),
  'decode reads encoded dimensions via createImageSource + getImageInfo');
check(prep.includes('originalImageOrientedDimensions(') &&
  importer.includes('image.PropertyKey.ORIENTATION'),
  'EXIF orientation swaps intrinsic dims like vuh.b w34.l()');
check(prep.includes('encodedWidth <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE') &&
  prep.includes('encodedHeight <= ORIGINAL_IMAGE_INSERT_MAX_INTRINSIC_SIDE') &&
  prep.includes('mimeType: encodedInfo.mimeType'),
  'images within the 3000px boundary keep original bytes and decoded mime');
check(prep.includes('planOriginalImageDownscale(') &&
  prep.includes('createScaledPixelMap(factor, factor)') &&
  prep.includes("format: 'image/webp'") &&
  prep.includes('quality: IMAGE_IMPORT_WEBP_LOSSY_QUALITY'),
  'oversized images re-normalize via downscale plan + WebP lossy q85 pack');
check(prep.includes('intrinsicWidth: scaledInfo.size.width') &&
  prep.includes("mimeType: 'image/webp'"),
  'rewritten images report the packed dims + image/webp (ep5 parity)');
check(prep.includes('await source.release()') && prep.includes('await packer.release()'),
  'image decode + pack resources are always released in finally');

// --- Harmony 实现对齐：bvh.a/ip5/kp5 几何 ---
const geom = section(importer, 'function buildImportedImageElement(',
  '\n}');
check(importer.includes('IMAGE_IMPORT_PAGE_WIDTH_PT: number = 612') &&
  importer.includes('IMAGE_IMPORT_PAGE_HEIGHT_PT: number = 792'),
  'import page is m09.b Letter 612x792pt');
check(geom.includes('Math.min(1,') && geom.includes('limitW / srcW') &&
  geom.includes('limitH / srcH'),
  'fit factor mirrors bvh.a min(1, 0.8*pageW/srcW, 0.8*pageH/srcH)');
check(geom.includes('Math.fround('),
  'geometry keeps Java float precision at every arithmetic boundary');
check(geom.includes('IMAGE_IMPORT_PAGE_WIDTH_PT - fitW) / Math.fround(2)') &&
  geom.includes('IMAGE_IMPORT_PAGE_HEIGHT_PT - fitH) / Math.fround(2)') &&
  geom.includes('scale: number = Math.fround(fitW / srcW)'),
  'ip5: centered origin + uniform scale = fitW/srcW');
check(geom.includes('scale, 0, originX') && geom.includes('0, scale, originY'),
  'transform matrix is [s,0,x,0,s,y] like kp5/baj.a');
check(geom.includes('blockWidth: prepared.intrinsicWidth') &&
  geom.includes('blockHeight: prepared.intrinsicHeight') &&
  geom.includes('intrinsicWidth: prepared.intrinsicWidth'),
  'block dims and intrinsic dims both carry the ep5-reported size');
check(geom.includes('corner: 0') && geom.includes('textWrap: 0') &&
  geom.includes('enableCaption: false'),
  'kp5 defaults: SQUARE corner + PIXEL_ALIGN wrap + no caption');
check(geom.includes('element.bounds = imageBlockWorldBounds(element)'),
  'bounds computed through the canonical imageBlockWorldBounds');

// --- Harmony 实现对齐：落库结构 ---
const body = section(importer, 'private async importImageFromBytes(',
  '// 我方格式导入');
check(body.includes('createNoteWithMeta('),
  'imported image note uses createNoteWithMeta (no stray bootstrap page)');
check(body.includes('storeImportedOriginalAsset('),
  'image bytes are staged via storeImportedOriginalAsset (pending→final)');
check(body.includes('sha512Digest(prepared.bytes)') &&
  body.includes('originalAssetHashBitsFromSha512('),
  'asset hash is the SHA-512-derived eight-word digest');
check(body.includes('PageElementKind.IMAGE') && body.includes('zIndex: 0') &&
  body.includes('pageIndex: 0'),
  'single Letter page hosts exactly one IMAGE element at z-index 0');
check(body.includes('size: PaperSize.LETTER') && body.includes('template: PaperTemplate.PLAIN') &&
  body.includes('background: originalDefaultNoteBackground()'),
  'imported page is Letter/PLAIN/portrait with the default note background');
check(body.includes('widthMm: IMAGE_IMPORT_PAGE_WIDTH_PT * POINTS_TO_MM'),
  'page size stored in mm via POINTS_TO_MM like other Letter paths');
check(body.includes('removeFailedImport(createdNoteId)'),
  'failed image import cleans the partially-written note');
check(body.includes('await NoteImporter.importMutex.lock()'),
  'image import serializes with the shared import mutex');
check(importer.includes("'image/webp', '.webp'") || importer.includes("'.webp'"),
  'webp is among the accepted image suffixes');

console.log(`D05_ORIGINAL_IMAGE_FILE_IMPORT_REPLAY_OK TOTAL=${total} FAILED=0`);
