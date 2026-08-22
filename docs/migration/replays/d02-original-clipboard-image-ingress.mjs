import fs from 'node:fs';

const ingress = fs.readFileSync('note/src/main/ets/data/OriginalClipboardImageIngress.ets', 'utf8').replaceAll('\r\n', '\n');
const permission = fs.readFileSync('note/src/main/ets/data/OriginalClipboardPermissionGateway.ets', 'utf8').replaceAll('\r\n', '\n');
const moduleManifest = fs.readFileSync('note/src/main/module.json5', 'utf8');
const canvas = fs.readFileSync('note/src/main/ets/ui/editor/NoteCanvasView.ets', 'utf8').replaceAll('\r\n', '\n');
const fixture = fs.readFileSync('note/src/test/OriginalClipboardImageIngress.test.ets', 'utf8');
const fixtureList = fs.readFileSync('note/src/test/List.test.ets', 'utf8');
const evidence = fs.readFileSync('docs/migration/evidence/original-clipboard-image-ingress-jadx-2026-08-23.md', 'utf8');

function between(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  if (start < 0) return '';
  const next = source.indexOf(endMarker, start + startMarker.length);
  return next < 0 ? source.slice(start) : source.slice(start, next);
}

const importSource = between(ingress, 'export async function importOriginalClipboardImage', '\nasync function packWebpLossy');
const probeSource = between(ingress, 'async function probeWithHarmonyPasteboardMimeTypes',
  '\nexport async function isOriginalClipboardImageAvailable');
const availabilitySource = between(ingress,
  'export async function isOriginalClipboardImageAvailable', '\nasync function readWithHarmonyPasteboard');
const listenerSource = between(ingress,
  'export function addOriginalClipboardImageChangeListenerForTest', '\nasync function readWithHarmonyPasteboard');
const menuSource = between(canvas, '@Builder\n  private ClipboardPasteContextMenu', '\n  // === 文本框 ===');
const pasteSource = between(canvas, 'private async startOriginalClipboardImagePaste', '\n  private canUseOriginalClipboardImage');
const base = JSON.parse(fs.readFileSync('note/src/main/resources/base/element/string.json', 'utf8'));
const zh = JSON.parse(fs.readFileSync('note/src/main/resources/zh_CN/element/string.json', 'utf8'));

function hasValue(json, name, value) {
  return json.string.some((entry) => entry.name === name && entry.value === value);
}

const checks = [
  ['only accepts the system PixelMap clipboard type',
    ingress.includes("mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)")],
  ['validates dimensions and byte ceiling before returning bytes',
    importSource.includes("if (!validDimensions(info.size.width, info.size.height)) {") &&
    ingress.includes('CLIPBOARD_IMAGE_MAX_BYTES: number = 104857600')],
  ['normalizes to original WebP lossy 85',
    ingress.includes("format: 'image/webp', quality: WEBP_LOSSY_QUALITY") &&
    ingress.includes('WEBP_LOSSY_QUALITY: number = 85')],
  ['reuses the exact original 3000px downscale plan',
    ingress.includes('planOriginalImageDownscale(info.size.width, info.size.height)') &&
    ingress.includes('isOriginalNormalizedImageDimensions(plan.width, plan.height)')],
  ['scales oversized PixelMaps through the SDK adapter and releases it',
    importSource.includes('createScaledPixelMap(') &&
    importSource.includes('ownedNormalized = true;') &&
    importSource.includes('await normalized.release();')],
  ['verifies scaled dimensions before encoding',
    importSource.includes("if (scaledInfo.size.width !== plan.width || scaledInfo.size.height !== plan.height) {")],
  ['always releases the clipboard source',
    importSource.includes('} finally {\n    await source.release();\n  }')],
  ['long press menu exposes the image fallback only without internal content',
    menuSource.includes('if (!this.canPasteClipboardNow() && this.canUseOriginalClipboardImage())') &&
    menuSource.includes('this.startOriginalClipboardImagePaste();')],
  ['availability uses the SDK MIME metadata probe and exact PixelMap type',
    probeSource.includes('await systemPasteboard.getMimeTypes();') &&
    ingress.includes('mimeTypes.includes(pasteboard.MIMETYPE_PIXELMAP)')],
  ['availability probing fails closed and can be restored after tests',
    availabilitySource.includes('return await probeOriginalClipboardImageAvailability();') &&
    ingress.includes('setOriginalClipboardImageAvailabilityProbeForTest(') &&
    ingress.includes('resetOriginalClipboardImageAvailabilityProbeForTest(): void')],
  ['menu visibility waits for an available PixelMap clipboard',
    canvas.includes('@State systemClipboardImageAvailable: boolean = false;') &&
    canvas.includes('this.persistence.isReady() && this.loadedPageId.length > 0 &&\n      this.systemClipboardImageAvailable;') &&
    canvas.includes('private refreshSystemClipboardImageAvailability(): void {') &&
    canvas.includes('isOriginalClipboardImageAvailable().then((available: boolean): void => {')],
  ['availability probes discard stale async results',
    canvas.includes('this.systemClipboardImageChangeListener = null;\n      this.systemClipboardImageProbeGeneration++;') &&
    canvas.includes('this.systemClipboardImageAvailable = false;\n    }\n  }\n\n  private refreshSystemClipboardImageAvailability'),

    canvas.includes('private systemClipboardImageProbeGeneration: number = 0;') &&
    canvas.includes('const probeGeneration: number = ++this.systemClipboardImageProbeGeneration;') &&
    canvas.includes('if (probeGeneration === this.systemClipboardImageProbeGeneration &&\n        this.canStartOriginalPhotoInsert()) {') &&
    canvas.includes('this.stopSystemClipboardImageAvailabilityUpdates();')],
  ['pasteboard update events refresh current clipboard image availability',
    listenerSource.includes("on('update', listener);") &&
    listenerSource.includes("off('update', listener);") &&
    canvas.includes('private startSystemClipboardImageAvailabilityUpdates(): void {') &&
    canvas.includes('addOriginalClipboardImageChangeListenerForTest(listener);') &&
    canvas.includes('removeOriginalClipboardImageChangeListenerForTest(listener);') &&
    canvas.includes('this.stopSystemClipboardImageAvailabilityUpdates();') &&
    fixture.includes('subscribes and removes the same pasteboard update listener')],
  ['page loads refresh and page switches reset image paste availability',
    canvas.includes('this.refreshSystemClipboardImageAvailability();\n      if (this.layerManager.isInitialized()) {') &&
    canvas.includes('this.systemClipboardImageAvailable = false;\n      this.refreshSystemClipboardImageAvailability();\n      this.selectionTool.deselect();') &&
    canvas.includes('this.systemClipboardImageAvailable = false;\n    this.pageLoadPromise = this.switchPageData();')],
  ['busy paste entry rechecks availability before permission and data',
    pasteSource.includes('if (!this.canUseOriginalClipboardImage()) {') &&
    pasteSource.includes('this.photoImportBusy = true;\n    try {\n      if (!await isOriginalClipboardImageAvailable()) {') &&
    pasteSource.indexOf('this.photoImportBusy = true;') <
      pasteSource.indexOf('isOriginalClipboardImageAvailable()') &&
    pasteSource.indexOf('isOriginalClipboardImageAvailable()') <
      pasteSource.indexOf('ensureOriginalClipboardReadPermission()') &&
    pasteSource.includes('if (!await isOriginalClipboardImageAvailable()) {') &&
    pasteSource.includes('this.systemClipboardImageAvailable = false;') &&
    pasteSource.indexOf('isOriginalClipboardImageAvailable()') <
      pasteSource.indexOf('ensureOriginalClipboardReadPermission()')],
  ['paste uses the long press anchor for durable insertion',
    pasteSource.includes('await this.insertOriginalPhotos([{') &&
    pasteSource.includes('}], target);') &&
    canvas.includes('pasteAnchor?: Point2D')],
  ['failures show the localized insert failure toast',
    pasteSource.includes("$r('app.string.original_photo_insert_failed')")],
  ['paste requests the SDK READ_PASTEBOARD permission before reading data',
    pasteSource.includes("if (!await ensureOriginalClipboardReadPermission()) {") &&
    canvas.includes("import { ensureOriginalClipboardReadPermission } from '../../data/OriginalClipboardPermissionGateway';")],
  ['production gateway validates one exact granted result',
    permission.includes("result.permissions[0] === permission") &&
    permission.includes("result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED")],
  ['manifest declares a localized user-grant reason',
    moduleManifest.includes('"name": "ohos.permission.READ_PASTEBOARD"') &&
    hasValue(base, 'read_pasteboard_permission_reason', 'Allows the app to paste images from the clipboard') &&
    hasValue(zh, 'read_pasteboard_permission_reason', '允许应用粘贴剪贴板中的图片')],
  ['ArkTS fixture proves empty scaling reset and resource paths',
    fixture.includes("'system pasteboard has no original clipboard image'") &&
    fixture.includes("'availability probe failed'") &&
    fixture.includes('resetOriginalClipboardImageAvailabilityProbeForTest();') &&
    fixture.includes('addOriginalClipboardImageChangeListenerForTest(listener)') &&
    fixture.includes('removeOriginalClipboardImageChangeListenerForTest(listener)') &&
    fixture.includes("'scaled clipboard probe stops before encoder'") &&
    fixture.includes('requestedScaleX') &&
    fixture.includes('3000 / 12001') &&
    fixtureList.includes('originalClipboardImageIngressTest();')],
  ['permission fixture proves exact request and fail-closed denial',
    fs.readFileSync('note/src/test/OriginalClipboardPermissionGateway.test.ets', 'utf8').includes("'ohos.permission.READ_PASTEBOARD'") &&
    fixtureList.includes('originalClipboardPermissionGatewayTest();')],
  ['JADX evidence records the ClipboardImage dispatch boundary',
    evidence.includes('hasMimeType("image/*")') &&
    evidence.includes('handleAddImageFromClipboard') &&
    evidence.includes('不声称复刻其内部实现')],
];

let failed = 0;
for (const [name, passed] of checks) {
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
  if (!passed) failed++;
}
console.log(`D02_ORIGINAL_CLIPBOARD_IMAGE_INGRESS_OK TOTAL=${checks.length} FAILED=${failed}`);
if (failed > 0) process.exitCode = 1;
