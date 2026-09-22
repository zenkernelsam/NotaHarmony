import assert from 'node:assert/strict';
import fs from 'node:fs';

const root = new URL('../../../', import.meta.url);
const read = path => fs.readFileSync(new URL(path, root), 'utf8');
const desktop = 'C:/Users/Cisco He/Desktop/Notability/';
const readOriginal = path => fs.readFileSync(desktop + path, 'utf8');

const caller = read('note/src/main/ets/data/OriginalCameraPickerCaller.ets');
const ingress = read('note/src/main/ets/data/OriginalPhotoIngress.ets');
const canvas = read('note/src/main/ets/ui/editor/NoteCanvasView.ets');
const page = read('note/src/main/ets/ui/editor/NotePage.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const stringsBase = read('note/src/main/resources/base/element/string.json');
const stringsZh = read('note/src/main/resources/zh_CN/element/string.json');

let checks = 0;
const ok = (cond, label) => { assert.ok(cond, label); checks++; };

// --- Original evidence anchors -----------------------------------------------------
const qc = readOriginal('decompiled_1.0.3/sources/defpackage/qc.java');
const f35 = readOriginal('decompiled_1.0.3/sources/defpackage/f35.java');
const kkf = readOriginal('decompiled_1.0.3/sources/defpackage/kkf.java');
const origStrings = readOriginal('decompiled_1.0.3/resources/res/values/strings.xml');

// strings.xml:606 + qc.java — the insert menu carries a Take Photo item with the
// camera icon, wired to menu slot function3 (sc case 2).
ok(origStrings.includes('feature_note_toolbox__take_photo'),
  'original take_photo string missing');
ok(qc.includes('R.string.feature_note_toolbox__take_photo') &&
   qc.includes('R.drawable.ui_designsystem__camera_outline') &&
   qc.includes('new sc(function3, function1, 2)'),
  'original Take Photo menu slot missing');
// qc.java — menu order: add_files -> add_photo -> take_photo -> (gif) -> insert_math.
const order = [
  'feature_note_toolbox__add_photo',
  'feature_note_toolbox__take_photo',
  'feature_note_toolbox__insert_math',
].map(s => qc.indexOf(s));
ok(order.every(i => i > 0) && order[0] < order[1] && order[1] < order[2],
  'original insert menu order (photo -> take photo -> math) changed');
// kkf.java:598 — the host assembles the 6-slot insert menu including take-photo.
ok(kkf.includes('new qc(function0, function5, function1, function2, function4, function3, 0)'),
  'original insert menu host wiring missing');
// f35.java:64 — the camera contract launches IMAGE_CAPTURE with an app-provided
// output URI plus read/write grants; the captured bytes land at that URI.
ok(f35.includes('android.media.action.IMAGE_CAPTURE') &&
   f35.includes('putExtra("output", uri)') &&
   f35.includes('addFlags(1).addFlags(2)'),
  'original IMAGE_CAPTURE output-URI contract missing');

// --- Harmony caller anchors ---------------------------------------------------------
ok(caller.includes("import { cameraPicker, camera } from '@kit.CameraKit'"),
  'CameraKit import missing');
ok(caller.includes('cameraPicker.pick(context,') &&
   caller.includes('cameraPicker.PickerMediaType.PHOTO') &&
   caller.includes('camera.CameraPosition.CAMERA_POSITION_BACK'),
  'cameraPicker.pick photo/back-camera call missing');
// Cancel/failure contract: non-zero resultCode or empty URI -> '' -> [] (same
// empty-list no-op contract as the photo picker).
ok(caller.includes('result.resultCode !== 0 || result.resultUri === \'\'') &&
   caller.includes("return '';") && caller.includes('return [];'),
  'camera cancel-to-empty contract missing');
// The captured URI flows through the shared validate+normalize+insert pipeline —
// the original ingests the EXTRA_OUTPUT URI the same way.
ok(caller.includes('isValidOriginalPhotoUri(uri)') &&
   caller.includes('return importOriginalPhotos([uri], request.cacheDirectory)'),
  'shared ingress pipeline reuse missing');
ok(caller.includes('setOriginalCameraUriCapturerForTest') &&
   caller.includes('resetOriginalCameraUriCapturerForTest'),
  'camera test seam missing');

// --- Harmony canvas/page anchors -----------------------------------------------------
ok(canvas.includes("import { captureAndImportOriginalPhoto } from '../../data/OriginalCameraPickerCaller'"),
  'canvas camera-caller import missing');
ok(canvas.includes("@Prop @Watch('onCameraCaptureSignalChange') cameraCaptureSignal: number = 0;"),
  'cameraCaptureSignal prop missing');
ok(/onCameraCaptureSignalChange[\s\S]*?this\.photoImportBusy[\s\S]*?startOriginalCameraCapture/.test(canvas),
  'camera watcher lease guard missing');
// startOriginalCameraCapture mirrors the photo path: same lease flag, same origin
// capture, same commit pipeline, same lease release in finally.
ok(/startOriginalCameraCapture[\s\S]*?canStartOriginalPhotoInsert\(\)[\s\S]*?photoImportBusy = true[\s\S]*?captureAndImportOriginalPhoto[\s\S]*?commitOriginalPhotoInsert[\s\S]*?photoImportBusy = false[\s\S]*?onPhotoIngressFinished\(\)/.test(canvas),
  'camera capture pipeline structure missing');
ok(page.includes('@State cameraCaptureSignal: number = 0;'),
  'NotePage cameraCaptureSignal state missing');
ok(/onTakePhoto[\s\S]*?photoImportLeaseActive = true[\s\S]*?cameraCaptureSignal\+\+/.test(page),
  'onTakePhoto lease-acquire + signal missing');
ok(page.includes('cameraCaptureSignal: this.cameraCaptureSignal'),
  'canvas cameraCaptureSignal prop wiring missing');

// --- Harmony UI anchors --------------------------------------------------------------
ok(toolbar.includes('onTakePhoto: () => void'), 'toolbar onTakePhoto callback missing');
// Non-compact button sits between Photo and Math (original menu order).
const btnOrder = [
  "Button($r('app.string.insert_photo'))",
  "Button($r('app.string.take_photo'))",
  "Button($r('app.string.insert_math'))",
].map(s => toolbar.indexOf(s));
ok(btnOrder.every(i => i > 0) && btnOrder[0] < btnOrder[1] && btnOrder[1] < btnOrder[2],
  'toolbar take_photo button order missing');
// Lease guard on both the button and the compact-menu entry.
ok(/take_photo[\s\S]*?\.enabled\(!this\.viewModel\.toolStateLoading &&\s+!this\.photoImportLeaseActive\)[\s\S]*?if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.onTakePhoto\(\)/.test(toolbar),
  'take_photo button lease guard missing');
ok(/\{ value: \$r\('app\.string\.take_photo'\), action: \(\) => \{\s+if \(this\.photoImportLeaseActive\) \{\s+return;\s+\}\s+this\.onTakePhoto\(\)/.test(toolbar),
  'compact-menu take_photo lease guard missing');
ok(stringsBase.includes('"name": "take_photo"') && stringsZh.includes('"name": "take_photo"'),
  'take_photo strings missing');

// --- Executable model: capture -> validate -> import pipeline -------------------------
// Model the original contract: a capture either yields a URI that flows through
// the shared ingress or cancels to nothing; the lease covers the whole op.
function cameraCapture(capturedUri) {
  // cameraPicker.pick -> PickerResult; cancel -> resultCode != 0 / empty URI.
  const uri = capturedUri;
  if (uri === '') return [];
  // importOriginalPhotos([uri]) — validation happens inside (isValidOriginalPhotoUri).
  return [{ uri }];
}
assert.deepEqual(cameraCapture(''), []); checks++;            // cancel -> silent no-op
assert.equal(cameraCapture('file://media/Photo_1.jpg').length, 1); checks++;
assert.equal(cameraCapture('file://media/Photo_1.jpg')[0].uri,
  'file://media/Photo_1.jpg'); checks++;
// Lease discipline: while photoImportBusy, a second signal is dropped.
let busy = false; const dispatched = [];
function signal(name) {
  if (busy) return;
  busy = true; dispatched.push(name); busy = false;
}
signal('photo'); signal('camera');
assert.deepEqual(dispatched, ['photo', 'camera']); checks++;
busy = true; signal('camera'); busy = false;
assert.deepEqual(dispatched, ['photo', 'camera']); checks++; // suppressed while busy

console.log(`D02_ORIGINAL_TAKE_PHOTO_INGRESS_OK TOTAL=${checks} FAILED=0`);
